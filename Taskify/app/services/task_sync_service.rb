class TaskSyncService
  class SyncError < StandardError; end

  def initialize(user)
    @user = user
    @cloud_storage_path = Rails.root.join("tmp", "cloud_sync", "#{user.id}.json")
    @sync_stats = { uploaded: 0, downloaded: 0, conflicts: 0, errors: [] }
  end

  def sync
    Rails.logger.info "Starting sync for user #{@user.email}"

    begin
      ensure_cloud_storage_directory

      # Get local and cloud tasks
      local_tasks = fetch_local_tasks
      cloud_tasks = fetch_cloud_tasks

      # Count new tasks before sync
      cloud_task_ids = cloud_tasks.map { |t| t["id"] }.to_set
      local_task_ids = local_tasks.map { |t| t["id"] }.to_set

      new_local_tasks = local_task_ids - cloud_task_ids
      new_cloud_tasks = cloud_task_ids - local_task_ids

      # Update stats with actual counts
      @sync_stats[:uploaded] = new_local_tasks.size
      @sync_stats[:downloaded] = new_cloud_tasks.size

      # Perform bidirectional sync
      sync_local_to_cloud(local_tasks, cloud_tasks)
      sync_cloud_to_local(local_tasks, cloud_tasks)

      # Save updated cloud state
      save_cloud_tasks(fetch_local_tasks)

      Rails.logger.info "Sync completed for user #{@user.email}. Stats: #{@sync_stats}"

      {
        success: true,
        message: build_success_message,
        stats: @sync_stats
      }

    rescue => e
      Rails.logger.error "Sync failed for user #{@user.email}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        message: "Error durante la sincronización: #{e.message}",
        stats: @sync_stats
      }
    end
  end

  def last_sync_time
    return nil unless File.exist?(@cloud_storage_path)

    begin
      cloud_data = JSON.parse(File.read(@cloud_storage_path))
      cloud_data["last_sync"]&.then { |time| Time.parse(time) }
    rescue
      nil
    end
  end

  private

  def ensure_cloud_storage_directory
    FileUtils.mkdir_p(File.dirname(@cloud_storage_path))
  end

  def fetch_local_tasks
    @user.tasks.order(:updated_at).map do |task|
      {
        "id" => task.id,
        "title" => task.title,
        "description" => task.description,
        "status" => task.status,
        "priority" => task.priority,
        "due_date" => task.due_date&.iso8601,
        "created_at" => task.created_at.iso8601,
        "updated_at" => task.updated_at.iso8601
      }
    end
  end

  def fetch_cloud_tasks
    return [] unless File.exist?(@cloud_storage_path)

    begin
      cloud_data = JSON.parse(File.read(@cloud_storage_path))
      cloud_data["tasks"] || []
    rescue JSON::ParserError => e
      Rails.logger.warn "Failed to parse cloud data: #{e.message}"
      []
    end
  end

  def sync_local_to_cloud(local_tasks, cloud_tasks)
    cloud_task_lookup = cloud_tasks.index_by { |t| t["id"] }

    local_tasks.each do |local_task|
      cloud_task = cloud_task_lookup[local_task["id"]]

      if cloud_task
        # Task exists in cloud, check for conflicts
        if has_conflict?(local_task, cloud_task)
          resolve_conflict(local_task, cloud_task)
        end
      else
        # New local task, will be uploaded when we save cloud tasks
        Rails.logger.debug "Uploading new task to cloud: #{local_task['title']}"
      end
    end
  end

  def sync_cloud_to_local(local_tasks, cloud_tasks)
    local_task_ids = local_tasks.map { |t| t["id"] }.to_set

    cloud_tasks.each do |cloud_task|
      unless local_task_ids.include?(cloud_task["id"])
        # New cloud task, download to local
        create_local_task_from_cloud(cloud_task)
        Rails.logger.debug "Downloading new task from cloud: #{cloud_task['title']}"
      end
    end
  end

  def has_conflict?(local_task, cloud_task)
    return false if local_task.nil? || cloud_task.nil?

    # Check if task data differs
    [ "title", "description", "status", "priority", "due_date" ].any? do |field|
      local_task[field] != cloud_task[field]
    end
  end

  def resolve_conflict(local_task, cloud_task)
    @sync_stats[:conflicts] += 1

    local_updated = Time.parse(local_task["updated_at"])
    cloud_updated = Time.parse(cloud_task["updated_at"])

    Rails.logger.info "Resolving conflict for task '#{local_task['title']}'"

    # Resolve by timestamp - keep the most recently updated version
    if local_updated > cloud_updated
      Rails.logger.debug "Local version is newer, keeping local changes"
      # Local wins - cloud will be updated when we save
    else
      Rails.logger.debug "Cloud version is newer, updating local task"
      update_local_task_from_cloud(local_task["id"], cloud_task)
    end
  end

  def create_local_task_from_cloud(cloud_task)
    due_date = cloud_task["due_date"] ? Time.parse(cloud_task["due_date"]) : nil

    @user.tasks.create!(
      id: cloud_task["id"],
      title: cloud_task["title"],
      description: cloud_task["description"],
      status: cloud_task["status"],
      priority: cloud_task["priority"],
      due_date: due_date,
      created_at: Time.parse(cloud_task["created_at"]),
      updated_at: Time.parse(cloud_task["updated_at"])
    )
  rescue => e
    @sync_stats[:errors] << "Error creating task '#{cloud_task['title']}': #{e.message}"
    Rails.logger.error "Failed to create local task: #{e.message}"
  end

  def update_local_task_from_cloud(task_id, cloud_task)
    local_task = @user.tasks.find(task_id)
    due_date = cloud_task["due_date"] ? Time.parse(cloud_task["due_date"]) : nil

    local_task.update!(
      title: cloud_task["title"],
      description: cloud_task["description"],
      status: cloud_task["status"],
      priority: cloud_task["priority"],
      due_date: due_date,
      updated_at: Time.parse(cloud_task["updated_at"])
    )
  rescue => e
    @sync_stats[:errors] << "Error updating task '#{cloud_task['title']}': #{e.message}"
    Rails.logger.error "Failed to update local task: #{e.message}"
  end

  def save_cloud_tasks(tasks)
    cloud_data = {
      "last_sync" => Time.current.iso8601,
      "user_id" => @user.id,
      "tasks" => tasks
    }

    File.write(@cloud_storage_path, JSON.pretty_generate(cloud_data))
  end

  def build_success_message
    messages = []

    if @sync_stats[:uploaded] > 0
      messages << "#{@sync_stats[:uploaded]} tarea(s) enviada(s) a la nube"
    end

    if @sync_stats[:downloaded] > 0
      messages << "#{@sync_stats[:downloaded]} tarea(s) descargada(s) de la nube"
    end

    if @sync_stats[:conflicts] > 0
      messages << "#{@sync_stats[:conflicts]} conflicto(s) resuelto(s)"
    end

    if messages.empty?
      "Sincronización completada. Todas las tareas están actualizadas."
    else
      "Sincronización completada: #{messages.join(', ')}."
    end
  end
end
