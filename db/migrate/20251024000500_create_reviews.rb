class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :rating, null: false
      t.integer :time_taken_ms, null: false, default: 0
      t.integer :scheduled_interval_days, null: false, default: 0
      t.integer :new_interval_days, null: false, default: 0
      t.decimal :new_ease_factor, precision: 5, scale: 2, null: false, default: 2.50
      t.datetime :reviewed_at, null: false, default: -> { "NOW()" }

      t.timestamps
    end
    add_index :reviews, [:user_id, :card_id, :reviewed_at]
  end
end
