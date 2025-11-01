# This migration creates the deck_collaborators table.
class CreateDeckCollaborators < ActiveRecord::Migration[7.1]
  def change
    create_table :deck_collaborators do |t|
      # A reference to the deck.
      t.references :deck, null: false, foreign_key: true
      # A reference to the user who is a collaborator.
      t.references :user, null: false, foreign_key: true
      # The role of the collaborator (e.g., editor, viewer).
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    # Add a unique index to the deck_id and user_id columns.
    add_index :deck_collaborators, [:deck_id, :user_id], unique: true
  end
end
