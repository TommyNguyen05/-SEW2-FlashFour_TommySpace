require "test_helper"

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @deck = decks(:one)
    sign_in @user
  end

  test "should start quiz session" do
    get start_deck_quiz_path(@deck)
    assert_response :redirect
    assert_redirected_to deck_quiz_path(@deck)
    assert_not_nil session[:quiz_session]
  end

  test "should redirect to deck if no cards" do
    # Create a deck with no cards
    empty_deck = Deck.create!(owner: @user, title: "Empty Deck", description: "No cards")
    get start_deck_quiz_path(empty_deck)
    assert_response :redirect
    assert_redirected_to empty_deck
    assert_equal 'This deck has no cards to quiz.', flash[:alert]
  end

  test "should show quiz question" do
    get start_deck_quiz_path(@deck)
    get deck_quiz_path(@deck)
    assert_response :success
    assert_select '.quiz-question'
    assert_select '.quiz-answers'
  end

  test "should answer question and move to next" do
    get start_deck_quiz_path(@deck)
    initial_index = session[:quiz_session]['current_index']
    
    # Get the current card to answer correctly
    card_id = session[:quiz_session]['card_ids'][initial_index]
    card = Flashcard.find(card_id)
    
    post answer_deck_quiz_path(@deck), params: { answer: card.back_text }
    
    assert_response :redirect
    assert_equal initial_index + 1, session[:quiz_session]['current_index']
  end

  test "should track correct answers" do
    get start_deck_quiz_path(@deck)
    
    # Get the current card to answer correctly
    card_id = session[:quiz_session]['card_ids'][0]
    card = Flashcard.find(card_id)
    
    post answer_deck_quiz_path(@deck), params: { answer: card.back_text }
    
    assert_equal 1, session[:quiz_session]['correct_count']
  end

  test "should show completion screen when quiz complete" do
    get start_deck_quiz_path(@deck)
    
    # Answer all questions
    card_count = session[:quiz_session]['card_ids'].size
    card_count.times do |i|
      card_id = session[:quiz_session]['card_ids'][i]
      card = Flashcard.find(card_id)
      post answer_deck_quiz_path(@deck), params: { answer: card.back_text }
    end
    
    assert_response :redirect
    assert_redirected_to complete_deck_quiz_path(@deck)
  end

  test "should display score on completion" do
    get start_deck_quiz_path(@deck)
    
    # Answer all questions correctly
    card_count = session[:quiz_session]['card_ids'].size
    card_count.times do |i|
      card_id = session[:quiz_session]['card_ids'][i]
      card = Flashcard.find(card_id)
      post answer_deck_quiz_path(@deck), params: { answer: card.back_text }
    end
    
    get complete_deck_quiz_path(@deck)
    
    assert_response :success
    assert_select '.completion-card'
    assert_select '.quiz-results'
  end

  test "should restart quiz session" do
    get start_deck_quiz_path(@deck)
    old_session = session[:quiz_session]
    
    post restart_deck_quiz_path(@deck)
    
    assert_response :redirect
    assert_redirected_to start_deck_quiz_path(@deck)
  end

  test "should generate answer options with correct answer" do
    get start_deck_quiz_path(@deck)
    get deck_quiz_path(@deck)
    
    assert_response :success
    # Check that answer options are rendered
    assert_select '.answer-option', minimum: 1
  end

  test "should handle deck with single card" do
    # Create a deck with only one card
    single_card_deck = Deck.create!(owner: @user, title: "Single Card Deck", description: "Only one card")
    Flashcard.create!(deck: single_card_deck, front_text: "Test", back_text: "Answer", card_type: :basic)
    
    get start_deck_quiz_path(single_card_deck)
    get deck_quiz_path(single_card_deck)
    
    assert_response :success
    # Should show at least the correct answer
    assert_select '.answer-option', minimum: 1
  end
end
