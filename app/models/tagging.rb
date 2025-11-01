class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :card

  validates :tag_id, uniqueness: { scope: :card_id }
end
