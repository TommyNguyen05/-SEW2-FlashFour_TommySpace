# This migration creates the cards table.
class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      # A reference to the deck the card belongs to.
      t.references :deck, null: false, foreign_key: true
      # The type of card (e.g., basic, cloze, etc.).
      t.integer :card_type, null: false, default: 0
      # The text on the front of the card.
      t.text :front_text, null: false
      # The text on the back of the card.
      t.text :back_text, null: false
      # Extra data for the card, stored as JSON.
      t.jsonb :extras, null: false, default: {}
      # Whether the card is suspended from review.
      t.boolean :suspended, null: false, default: false

      t.timestamps
    end
    # Add an index to the card_type column for faster lookups.
    add_index :cards, :card_type
    # Add an index to the suspended column for faster lookups.
    add_index :cards, :suspended
  end
end
