# frozen_string_literal: true

# CardProgress tracks a user's progress on learning a specific card using spaced repetition.
# It stores the state, ease factor, interval, and when the card is due for review next.
class CardProgress < ApplicationRecord
  belongs_to :user
  belongs_to :card, class_name: 'Flashcard', foreign_key: 'card_id'

  enum state: { new: 0, learning: 1, review: 2, relearning: 3 }

  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval_days, numericality: { greater_than_or_equal_to: 0 }
  validates :repetitions, :lapses, numericality: { greater_than_or_equal_to: 0 }

  scope :due_now, -> { where("due_at <= ?", Time.current) }
end
