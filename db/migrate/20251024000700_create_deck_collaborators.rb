class CreateDeckCollaborators < ActiveRecord::Migration[7.1]
  def change
    create_table :deck_collaborators do |t|
      t.references :deck, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :deck_collaborators, [:deck_id, :user_id], unique: true
  end
end
