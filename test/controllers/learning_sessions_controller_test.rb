require "test_helper"

class LearningSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @deck = decks(:one)
    sign_in @user
  end

  test "should start learning session" do
    get start_deck_learning_session_path(@deck)
    assert_response :redirect
    assert_redirected_to deck_learning_session_path(@deck)
    assert_not_nil session[:learning_session]
  end

  test "should redirect to deck if no cards" do
    # Create a deck with no cards
    empty_deck = Deck.create!(owner: @user, title: "Empty Deck", description: "No cards")
    get start_deck_learning_session_path(empty_deck)
    assert_response :redirect
    assert_redirected_to empty_deck
    assert_equal 'This deck has no cards to study.', flash[:alert]
  end

  test "should show learning session" do
    get start_deck_learning_session_path(@deck)
    get deck_learning_session_path(@deck)
    assert_response :success
    assert_select '.flashcard-container'
    assert_select '.flashcard'
  end

  test "should rate card and move to next" do
    get start_deck_learning_session_path(@deck)
    initial_index = session[:learning_session]['current_index']
    
    post rate_deck_learning_session_path(@deck), params: { rating: 'mastered' }
    
    assert_response :redirect
    assert_equal initial_index + 1, session[:learning_session]['current_index']
  end

  test "should not accept invalid rating" do
    get start_deck_learning_session_path(@deck)
    
    post rate_deck_learning_session_path(@deck), params: { rating: 'invalid' }
    
    assert_response :redirect
    assert_equal 'Invalid rating', flash[:alert]
  end

  test "should show completion screen when session complete" do
    get start_deck_learning_session_path(@deck)
    
    # Rate all cards
    card_count = session[:learning_session]['card_ids'].size
    card_count.times do |i|
      post rate_deck_learning_session_path(@deck), params: { rating: 'mastered' }
    end
    
    assert_response :redirect
    assert_redirected_to complete_deck_learning_session_path(@deck)
  end

  test "should display statistics on completion" do
    get start_deck_learning_session_path(@deck)
    
    # Rate cards with different ratings
    post rate_deck_learning_session_path(@deck), params: { rating: 'mastered' }
    post rate_deck_learning_session_path(@deck), params: { rating: 'still_learning' }
    
    get complete_deck_learning_session_path(@deck)
    
    assert_response :success
    assert_select '.completion-card'
    assert_select '.statistics'
  end

  test "should restart learning session" do
    get start_deck_learning_session_path(@deck)
    old_session = session[:learning_session]
    
    post restart_deck_learning_session_path(@deck)
    
    assert_response :redirect
    assert_redirected_to start_deck_learning_session_path(@deck)
  end
end
