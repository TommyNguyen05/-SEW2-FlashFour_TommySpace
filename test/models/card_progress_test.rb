require "test_helper"

class CardProgressTest < ActiveSupport::TestCase
  test "should belong to user and card" do
    card_progress = card_progresses(:one)
    assert_not_nil card_progress.user
    assert_not_nil card_progress.card
  end

  test "should validate ease_factor minimum" do
    card_progress = CardProgress.new(
      user: users(:one),
      card: cards(:one),
      ease_factor: 1.0
    )
    assert_not card_progress.valid?
    assert_includes card_progress.errors[:ease_factor], "must be greater than or equal to 1.3"
  end

  test "should validate interval_days is non-negative" do
    card_progress = CardProgress.new(
      user: users(:one),
      card: cards(:one),
      interval_days: -1
    )
    assert_not card_progress.valid?
    assert_includes card_progress.errors[:interval_days], "must be greater than or equal to 0"
  end

  test "should have due_now scope" do
    # Create a card progress that is due now
    due_now = CardProgress.create!(
      user: users(:one),
      card: cards(:one),
      due_at: Time.current - 1.day
    )
    
    assert_includes CardProgress.due_now, due_now
  end

  test "should not include future cards in due_now scope" do
    # Create a card progress that is not due yet
    future = CardProgress.create!(
      user: users(:one),
      card: cards(:two),
      due_at: Time.current + 7.days
    )
    
    assert_not_includes CardProgress.due_now, future
  end
end
