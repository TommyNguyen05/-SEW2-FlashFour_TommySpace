class DeckCollaborator < ApplicationRecord
  belongs_to :deck
  belongs_to :user
  enum role: { viewer: 0, editor: 1 }
  validates :user_id, uniqueness: { scope: :deck_id }
end
