class CreateTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.references :category, index: true, null: false, foreign_key: true
      t.integer :priority, null: false
      t.string :status, null: false
      t.boolean :notice, null: false, default: false
      t.string :code
      t.date :limited_on

      t.timestamps
    end
  end
end
