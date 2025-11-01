class User < ApplicationRecord
  has_secure_password

  has_many :owned_decks, class_name: "Deck", foreign_key: :owner_id, dependent: :destroy
  has_many :deck_collaborations, class_name: "DeckCollaborator", dependent: :destroy
  has_many :collaborating_decks, through: :deck_collaborations, source: :deck

  has_many :card_progresses, dependent: :destroy
  has_many :studying_cards, through: :card_progresses, source: :card
  has_many :reviews, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :display_name, presence: true
end
