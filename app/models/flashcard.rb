class Flashcard < ApplicationRecord
  # Associations
  belongs_to :deck  # Each flashcard belongs to a deck

  # Difficulty levels
  enum difficulty: { easy: 0, medium: 1, hard: 2 } 

  # Callback to translate front_text before creating the flashcard
  before_create :translate_front_text 

  private

  def translate_front_text
    start_time = Time.now
    sleep(0.5)
    self.back_text = "Translated: #{front_text}"
    end_time = Time.now

    translation_time = end_time - start_time
    if translation_time > 5
      Rails.logger.warn "Translation took longer than 5 seconds, details: #{translation_time} seconds"
    end
end