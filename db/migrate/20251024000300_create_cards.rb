class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.references :deck, null: false, foreign_key: true
      t.integer :card_type, null: false, default: 0
      t.text :front_text, null: false
      t.text :back_text, null: false
      t.jsonb :extras, null: false, default: {}
      t.boolean :suspended, null: false, default: false

      t.timestamps
    end
    add_index :cards, :card_type
    add_index :cards, :suspended
  end
end
