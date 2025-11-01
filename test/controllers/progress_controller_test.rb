require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get progress index" do
    get progress_path
    assert_response :success
  end

  test "should display analytics sections" do
    get progress_path
    assert_response :success
    assert_select '.progress-analytics'
    assert_select '.analytics-summary'
    assert_select '.analytics-decks'
    assert_select '.analytics-activity'
  end

  test "should redirect to login if not authenticated" do
    sign_out @user
    get progress_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should display overview statistics" do
    get progress_path
    assert_response :success
    assert_select '.analytics-card', minimum: 5  # Total cards, Reviewed today, Due now, Accuracy, Streak
    assert_select '.label', text: 'Total cards'
    assert_select '.label', text: 'Reviewed today'
    assert_select '.label', text: 'Due now'
    assert_select '.label', text: 'Accuracy'
    assert_select '.label', text: 'Streak'
  end
end
