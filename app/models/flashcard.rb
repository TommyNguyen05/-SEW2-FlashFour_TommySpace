class Flashcard < ApplicationRecord
  # Map this model to the "cards" table in the database
  self.table_name = 'cards'

  # Associations
  belongs_to :deck

  # column that exists in the schema
  enum card_type: { basic: 0 }

  validates :front_text, presence: true
  validates :back_text, presence: true

  # Callback to set a back_text stub from front_text (demo placeholder)
  before_create :translate_front_text

  private

  def translate_front_text
    start_time = Time.now
    sleep(0.5)
    # Only set back_text if the user didn't provide one
    self.back_text = "Translated: #{front_text}" if back_text.blank?
    translation_time = Time.now - start_time
    Rails.logger.warn("Translation took longer than 5 seconds: #{translation_time}s") if translation_time > 5
  end
end