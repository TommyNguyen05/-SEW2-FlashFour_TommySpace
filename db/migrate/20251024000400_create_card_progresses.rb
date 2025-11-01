class CreateCardProgresses < ActiveRecord::Migration[7.1]
  def change
    create_table :card_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :repetitions, null: false, default: 0
      t.integer :lapses, null: false, default: 0
      t.integer :interval_days, null: false, default: 0
      t.decimal :ease_factor, precision: 5, scale: 2, null: false, default: 2.50
      t.datetime :due_at, null: false, default: -> { "NOW()" }
      t.integer :state, null: false, default: 0

      t.timestamps
    end
    add_index :card_progresses, [:user_id, :card_id], unique: true
    add_index :card_progresses, [:user_id, :due_at]
    add_index :card_progresses, :state
  end
end
