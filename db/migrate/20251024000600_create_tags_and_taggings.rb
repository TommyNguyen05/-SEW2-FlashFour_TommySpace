# This migration creates the tags and taggings tables.
class CreateTagsAndTaggings < ActiveRecord::Migration[7.1]
  def change
    # Create the tags table.
    create_table :tags do |t|
      # The name of the tag.
      t.string :name, null: false
      t.timestamps
    end
    # Add an index to the name column for faster lookups and to enforce uniqueness.
    add_index :tags, :name, unique: true

    # Create the taggings table to associate tags with cards.
    create_table :taggings do |t|
      # A reference to the tag.
      t.references :tag, null: false, foreign_key: true
      # A reference to the card.
      t.references :card, null: false, foreign_key: true
      t.timestamps
    end
    # Add a unique index to the tag_id and card_id columns.
    add_index :taggings, [:tag_id, :card_id], unique: true
  end
end
