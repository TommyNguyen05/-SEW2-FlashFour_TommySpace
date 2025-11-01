require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "should belong to user and card" do
    review = reviews(:one)
    assert_not_nil review.user
    assert_not_nil review.card
  end

  test "should have rating enum" do
    review = reviews(:one)
    assert review.respond_to?(:rating)
    assert review.respond_to?(:good?)
    assert review.respond_to?(:easy?)
  end

  test "should validate time_taken_ms is non-negative" do
    review = Review.new(
      user: users(:one),
      card: cards(:one),
      rating: :good,
      time_taken_ms: -1
    )
    assert_not review.valid?
    assert_includes review.errors[:time_taken_ms], "must be greater than or equal to 0"
  end

  test "should create review with valid attributes" do
    review = Review.new(
      user: users(:one),
      card: cards(:two),
      rating: :good,
      time_taken_ms: 5000,
      scheduled_interval_days: 1,
      new_interval_days: 3,
      new_ease_factor: 2.5,
      reviewed_at: Time.current
    )
    assert review.valid?
  end
end
