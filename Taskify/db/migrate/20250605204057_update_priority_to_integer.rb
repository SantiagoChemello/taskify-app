class UpdatePriorityToInteger < ActiveRecord::Migration[7.2]
  def up
    # First, map existing string values to integers
    execute <<-SQL
      UPDATE tasks SET priority = CASE 
        WHEN priority = 'low' THEN '0'
        WHEN priority = 'medium' THEN '1' 
        WHEN priority = 'high' THEN '2'
        WHEN priority = 'urgent' THEN '2'  -- Map urgent to high
        ELSE '1'  -- Default to medium
      END
    SQL
    
    # Remove default temporarily
    change_column_default :tasks, :priority, nil
    
    # Change column type to integer with USING clause
    change_column :tasks, :priority, :integer, null: false, using: 'priority::integer'
    
    # Set new default value
    change_column_default :tasks, :priority, 1
    
    # Update index
    remove_index :tasks, :priority if index_exists?(:tasks, :priority)
    add_index :tasks, :priority
  end

  def down
    # Remove default temporarily  
    change_column_default :tasks, :priority, nil
    
    # Change column type back to string first
    change_column :tasks, :priority, :string, null: false
    
    # Convert back to string values
    execute <<-SQL
      UPDATE tasks SET priority = CASE 
        WHEN priority = '0' THEN 'low'
        WHEN priority = '1' THEN 'medium'
        WHEN priority = '2' THEN 'high'
        ELSE 'medium'
      END
    SQL
    
    # Set original default
    change_column_default :tasks, :priority, 'medium'
    
    # Update index
    remove_index :tasks, :priority if index_exists?(:tasks, :priority)
    add_index :tasks, :priority
  end
end
