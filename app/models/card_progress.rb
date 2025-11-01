class CardProgress < ApplicationRecord
  belongs_to :user
  belongs_to :card

  enum state: { new: 0, learning: 1, review: 2, relearning: 3 }

  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval_days, numericality: { greater_than_or_equal_to: 0 }
  validates :repetitions, :lapses, numericality: { greater_than_or_equal_to: 0 }

  scope :due_now, -> { where("due_at <= ?", Time.current) }
end
