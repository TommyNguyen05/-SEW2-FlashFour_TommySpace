# frozen_string_literal: true

# DeckCollaborator manages deck sharing permissions between users
# Allows deck owners to share their decks with collaborators as either viewers or editors
class DeckCollaborator < ApplicationRecord
  belongs_to :deck
  belongs_to :user
  
  enum role: { viewer: 0, editor: 1 }
  
  validates :user_id, uniqueness: { scope: :deck_id }
end
