class AddFullTextSearchToTasks < ActiveRecord::Migration[7.2]
  def up
    # Add a generated column for full-text search
    execute <<-SQL
      ALTER TABLE tasks#{' '}
      ADD COLUMN searchable_text tsvector#{' '}
      GENERATED ALWAYS AS (
        to_tsvector('spanish', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(category, ''))
      ) STORED;
    SQL

    # Add GIN index for fast full-text search
    add_index :tasks, :searchable_text, using: :gin, name: 'index_tasks_on_searchable_text'

    # Add regular index for user_id (will be used with searchable_text queries)
    # The existing user_id index will be sufficient for most queries
  end

  def down
    remove_index :tasks, name: 'index_tasks_on_searchable_text'
    remove_column :tasks, :searchable_text
  end
end
