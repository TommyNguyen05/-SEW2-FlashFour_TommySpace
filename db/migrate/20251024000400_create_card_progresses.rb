# This migration creates the card_progresses table.
class CreateCardProgresses < ActiveRecord::Migration[7.1]
  def change
    create_table :card_progresses do |t|
      # A reference to the user whose progress is being tracked.
      t.references :user, null: false, foreign_key: true
      # A reference to the card for which progress is being tracked.
      t.references :card, null: false, foreign_key: true
      # The number of times the card has been reviewed.
      t.integer :repetitions, null: false, default: 0
      # The number of times the user has forgotten the card.
      t.integer :lapses, null: false, default: 0
      # The current interval in days between reviews.
      t.integer :interval_days, null: false, default: 0
      # The ease factor of the card, used in the SM-2 algorithm.
      t.decimal :ease_factor, precision: 5, scale: 2, null: false, default: 2.50
      # The next due date for the card.
      t.datetime :due_at, null: false, default: -> { "NOW()" }
      # The state of the card (e.g., new, learning, review).
      t.integer :state, null: false, default: 0

      t.timestamps
    end
    # Add a unique index to the user_id and card_id columns.
    add_index :card_progresses, [:user_id, :card_id], unique: true
    # Add an index to the user_id and due_at columns for faster lookups.
    add_index :card_progresses, [:user_id, :due_at]
    # Add an index to the state column for faster lookups.
    add_index :card_progresses, :state
  end
end
