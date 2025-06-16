class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'
      t.string :priority, null: false, default: 'medium'
      t.string :category
      t.datetime :due_date
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :priority
    add_index :tasks, :category
    add_index :tasks, :due_date
  end
end
