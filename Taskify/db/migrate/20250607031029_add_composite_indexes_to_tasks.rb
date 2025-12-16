class AddCompositeIndexesToTasks < ActiveRecord::Migration[7.2]
  def change
    # Composite index for user_id + status (most common query pattern)
    add_index :tasks, [ :user_id, :status ], name: 'index_tasks_on_user_id_and_status'

    # Composite index for user_id + status + due_date (for overdue/due soon queries)
    add_index :tasks, [ :user_id, :status, :due_date ], name: 'index_tasks_on_user_id_status_due_date'

    # Composite index for user_id + priority (for priority filtering)
    add_index :tasks, [ :user_id, :priority ], name: 'index_tasks_on_user_id_and_priority'

    # Composite index for user_id + category (for category filtering)
    add_index :tasks, [ :user_id, :category ], name: 'index_tasks_on_user_id_and_category'

    # Composite index for user_id + created_at (for ordering)
    add_index :tasks, [ :user_id, :created_at ], name: 'index_tasks_on_user_id_and_created_at'

    # Composite index for user_id + updated_at (for statistics)
    add_index :tasks, [ :user_id, :updated_at ], name: 'index_tasks_on_user_id_and_updated_at'

    # Partial index for title search (only non-null titles)
    add_index :tasks, [ :user_id, :title ], name: 'index_tasks_on_user_id_and_title',
              where: "title IS NOT NULL"
  end
end
