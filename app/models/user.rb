class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :decks, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :flashcards, through: :decks

  # Logic to check the last study session and update the streak.
  # For when the user completes a study session
  def update_streak
    self.streak += 1
    save
  end
end