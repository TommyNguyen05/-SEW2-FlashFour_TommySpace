class CreateTagsAndTaggings < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.timestamps
    end
    add_index :taggings, [:tag_id, :card_id], unique: true
  end
end
