# frozen_string_literal: true

# Tag allows organizing cards with labels for categorization and filtering
class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :cards, through: :taggings, source: :flashcard

  validates :name, presence: true, uniqueness: true
end
