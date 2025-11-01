# belongs_to :user
# belongs_to :flashcard

class CardProgress < ApplicationRecord
  belongs_to :card, class_name: 'Flashcard'

  # Rename 'new' to 'fresh' to avoid conflict with the reserved keyword.
  enum state: { fresh: 0, learning: 1, review: 2, relearning: 3 }

  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval_days, numericality: { greater_than_or_equal_to: 0 }

  scope :due_for_review, -> { where("review_on <= ?", Date.today) }

  def update_from_review(quality)
    # Clamp quality between 0 and 5
    quality = [0, [quality, 5].min].max

    if quality < 3
      # If incorrect, reset progress but don't make it as difficult as a brand new card.
      self.state = 'relearning'
      self.interval_days = 1 # Come back tomorrow
      self.repetition_count = 0 # Reset repetition count
    else
      # If correct, advance progress
      self.state = 'review'
      if self.repetition_count == 0
        self.interval_days = 1
      elsif self.repetition_count == 1
        self.interval_days = 6
      else
        self.interval_days = (self.interval_days * self.ease_factor).round
      end
      self.repetition_count += 1
    end

    # Adjust ease factor
    self.ease_factor += (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    self.ease_factor = [1.3, self.ease_factor].max # EF cannot be less than 1.3

    self.review_on = Date.today + self.interval_days.days
    save
  end
end