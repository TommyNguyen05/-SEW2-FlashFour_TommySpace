# frozen_string_literal: true

class CardProgress < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :card, class_name: 'Flashcard'

  # Enums for card state
  enum :state, { new: 0, learning: 1, review: 2, relearning: 3 }

  # Validations
  validates :user_id, uniqueness: { scope: :card_id }
  validates :repetitions, :lapses, :interval_days, numericality: { greater_than_or_equal_to: 0 }
  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }

  # Scopes
  scope :due, -> { where('due_at <= ?', Time.current) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_deck, ->(deck) { joins(:card).where(cards: { deck_id: deck.id }) }

  # Check if card is due for review
  def due?
    due_at <= Time.current
  end

  # Get the next review date
  def next_review_date
    due_at
  end

  # Update progress based on review rating
  # Rating: 1 (again), 2 (hard), 3 (good), 4 (easy)
  def update_from_review(rating)
    case rating
    when 1, 'unfamiliar'
      # Failed - reset to learning state
      self.lapses += 1
      self.state = :learning
      self.interval_days = 0
      self.ease_factor = [ease_factor - 0.2, 1.3].max
      self.due_at = Time.current
    when 2, 'still_learning'
      # Hard - increase interval slightly
      self.repetitions += 1
      self.interval_days = [interval_days * 1.2, 1].max.to_i
      self.ease_factor = [ease_factor - 0.15, 1.3].max
      self.due_at = Time.current + interval_days.days
      self.state = :review if state == 'learning'
    when 3, 4, 'mastered'
      # Good/Easy - normal progression
      self.repetitions += 1
      if state == 'new' || state == 'learning'
        self.interval_days = 1
        self.state = :review
      else
        self.interval_days = (interval_days * ease_factor).to_i
      end
      self.ease_factor += 0.1 if rating == 4
      self.due_at = Time.current + interval_days.days
    end
    
    save
  end
end
