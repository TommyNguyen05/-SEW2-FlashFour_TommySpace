class CreateDecks < ActiveRecord::Migration[7.1]
  def change
    create_table :decks do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.boolean :is_public, null: false, default: false

      t.timestamps
    end
    add_index :decks, [:owner_id, :title]
  end
end
