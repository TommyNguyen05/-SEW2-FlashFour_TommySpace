class Flashcard < ApplicationRecord
  self.table_name = 'cards'
  belongs_to :deck
  has_many :card_progresses, foreign_key: :card_id, dependent: :destroy
  has_many :reviews, foreign_key: :card_id, dependent: :destroy

  # BEFORE (keyword form, causing the error)
  # enum card_type: { basic: 0 }

  # AFTER (positional form – works on your Rails)
  enum :card_type, { basic: 0 }

  validates :front_text, presence: true
  validates :back_text, presence: true

  before_create :translate_front_text

  private

  def translate_front_text
    start_time = Time.now
    sleep(0.5)
    self.back_text = "Translated: #{front_text}" if back_text.blank?
    translation_time = Time.now - start_time
    Rails.logger.warn("Translation took longer than 5 seconds: #{translation_time}s") if translation_time > 5
  end
end