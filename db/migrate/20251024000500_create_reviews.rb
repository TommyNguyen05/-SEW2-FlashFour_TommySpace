# This migration creates the reviews table.
class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      # A reference to the user who performed the review.
      t.references :user, null: false, foreign_key: true
      # A reference to the card that was reviewed.
      t.references :card, null: false, foreign_key: true
      # The rating given to the card during the review.
      t.integer :rating, null: false
      # The time taken to review the card, in milliseconds.
      t.integer :time_taken_ms, null: false, default: 0
      # The scheduled interval in days before the review.
      t.integer :scheduled_interval_days, null: false, default: 0
      # The new interval in days after the review.
      t.integer :new_interval_days, null: false, default: 0
      # The new ease factor of the card after the review.
      t.decimal :new_ease_factor, precision: 5, scale: 2, null: false, default: 2.50
      # The timestamp of when the review was performed.
      t.datetime :reviewed_at, null: false, default: -> { "NOW()" }

      t.timestamps
    end
    # Add an index to the user_id, card_id, and reviewed_at columns for faster lookups.
    add_index :reviews, [:user_id, :card_id, :reviewed_at]
  end
end
