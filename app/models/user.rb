class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :decks, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :flashcards, through: :decks
  has_many :card_progresses, dependent: :destroy
  has_many :reviews, dependent: :destroy

  # Logic to check the last study session and update the streak.
  # For when the user completes a study session
  def update_streak
    self.streak += 1
    save
  end

  # Get total cards studied (cards with at least one review)
  def total_cards_studied
    reviews.select(:card_id).distinct.count
  end

  # Get cards by state
  def cards_by_state(state)
    card_progresses.where(state: state).count
  end

  # Calculate study streak (consecutive days with reviews)
  def calculate_study_streak
    return 0 if reviews.empty?
    
    dates = reviews.pluck('DATE(reviewed_at)').uniq.sort.reverse
    streak = 0
    current_date = Date.current
    
    dates.each do |date|
      break if date < current_date
      streak += 1
      current_date -= 1.day
    end
    
    streak
  end

  # Get total study time in seconds
  def total_study_time
    reviews.sum(:time_taken_ms) / 1000.0
  end
end