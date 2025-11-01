class Card < ApplicationRecord
  belongs_to :deck
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :card_progresses, dependent: :destroy
  has_many :reviews, dependent: :destroy

  enum card_type: { basic: 0, cloze: 1 }

  validates :front_text, :back_text, presence: true

  scope :active, -> { where(suspended: false) }
end
