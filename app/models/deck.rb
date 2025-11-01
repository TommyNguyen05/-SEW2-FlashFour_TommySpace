class Deck < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :cards, dependent: :destroy
  has_many :deck_collaborators, dependent: :destroy
  has_many :collaborators, through: :deck_collaborators, source: :user

  validates :title, presence: true

  scope :public_or_owned_by, ->(user) {
    where("is_public = TRUE OR owner_id = ?", user.id)
  }
end
