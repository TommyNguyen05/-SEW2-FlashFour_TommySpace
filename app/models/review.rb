# frozen_string_literal: true

# Review records each study session review of a card by a user.
# It tracks the rating given, time taken, and spaced repetition parameters.
class Review < ApplicationRecord
  belongs_to :user
  belongs_to :card, class_name: 'Flashcard', foreign_key: 'card_id'

  enum rating: { again: 0, hard: 1, good: 2, easy: 3 }

  validates :time_taken_ms, numericality: { greater_than_or_equal_to: 0 }
end
