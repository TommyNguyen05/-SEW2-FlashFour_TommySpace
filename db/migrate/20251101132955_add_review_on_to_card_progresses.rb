class AddReviewOnToCardProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :card_progresses, :review_on, :date
  end
end
