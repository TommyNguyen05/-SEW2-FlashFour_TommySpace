# This migration creates the decks table.
class CreateDecks < ActiveRecord::Migration[7.1]
  def change
    create_table :decks do |t|
      # A reference to the user who owns the deck.
      t.references :owner, null: false, foreign_key: { to_table: :users }
      # The title of the deck.
      t.string :title, null: false
      # A description of the deck.
      t.text :description
      # Whether the deck is publicly available.
      t.boolean :is_public, null: false, default: false

      t.timestamps
    end
    # Add an index to the owner_id and title columns for faster lookups.
    add_index :decks, [:owner_id, :title]
  end
end
