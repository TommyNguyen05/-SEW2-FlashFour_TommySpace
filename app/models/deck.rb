class Deck < ApplicationRecord
  # Associations
  belongs_to :user  # Each deck belongs to a user
  has_many :flashcards, dependent: :destroy # A deck has many flashcards

  # Self-referential association for parent deck
  belongs_to :parent, class_name: 'Deck', optional: true 
  # Self-referential association for subdecks
  has_many :subdecks, class_name: 'Deck', foreign_key: 'parent_id', dependent: :destroy 
end