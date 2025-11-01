# frozen_string_literal: true

class Review < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :card, class_name: 'Flashcard'

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..4 }
  validates :time_taken_ms, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :for_deck, ->(deck) { joins(:card).where(cards: { deck_id: deck.id }) }
  scope :recent, -> { order(reviewed_at: :desc) }
  scope :by_date, ->(date) { where('DATE(reviewed_at) = ?', date) }
  scope :between_dates, ->(start_date, end_date) { where(reviewed_at: start_date..end_date) }

  # Get reviews for a specific time period
  def self.in_last_days(days)
    where('reviewed_at >= ?', days.days.ago)
  end

  # Calculate average rating
  def self.average_rating
    average(:rating).to_f.round(2)
  end

  # Calculate total study time in seconds
  def self.total_study_time
    sum(:time_taken_ms) / 1000.0
  end

  # Get review count by rating
  def self.count_by_rating
    group(:rating).count
  end

  # Format time taken for display
  def formatted_time_taken
    seconds = time_taken_ms / 1000.0
    if seconds < 60
      "#{seconds.round(1)}s"
    else
      minutes = seconds / 60
      "#{minutes.round(1)}m"
    end
  end
end
