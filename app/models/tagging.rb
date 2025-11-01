# frozen_string_literal: true

# Tagging is a join model connecting Tags to Cards
class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :flashcard, foreign_key: 'card_id', class_name: 'Flashcard'

  validates :tag_id, uniqueness: { scope: :card_id }
end
