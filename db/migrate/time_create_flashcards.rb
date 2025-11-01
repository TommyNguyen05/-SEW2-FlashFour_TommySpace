class CreateFlashcards < ActiveRecord::Migration[6.1]
  def change
    create_table :flashcards do |t|
      t.text :front_text
      t.text :back_text
      t.references :deck, null: false, foreign_key: true
      t.integer :difficulty, default: 0
      t.timestamps
    end
  end
end