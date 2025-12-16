class TasksController < ApplicationController
  before_action :set_task, only: [ :show, :edit, :update, :destroy, :complete, :assign ]

  def index
    # Use Pundit policy scope to get tasks
    @tasks_scope = policy_scope(Task).includes(:user, :assignee).order(created_at: :desc)

    # Apply filters using a single method
    filtered_tasks = apply_filters(@tasks_scope)

    # Get paginated tasks
    @tasks = filtered_tasks.page(params[:page]).per(10)

    # Get notification data with simple queries
    current_time = Time.current
    today_start = current_time.beginning_of_day
    today_end = current_time.end_of_day
    three_days_end = 3.days.from_now.end_of_day

    # Use the base user tasks for notifications (not filtered) - based on role
    user_tasks = policy_scope(Task).where(status: "pending")
    @overdue_tasks = user_tasks.where("due_date < ?", current_time).count
    @due_today_tasks = user_tasks.where(due_date: today_start..today_end).count
    @due_soon_tasks = user_tasks.where(due_date: today_end..three_days_end).count

    # Cache user categories to avoid repeated queries
    @user_categories = Rails.cache.fetch("user_categories_#{current_user.id}", expires_in: 1.hour) do
      policy_scope(Task).where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @task
  end

  def new
    @task = Task.new
    authorize @task
    @user_categories = Task.all_categories_for_user(current_user)
    @assignable_users = assignable_users_for_select
  end

  def create
    @task = current_user.tasks.build(task_params)
    authorize @task

    if @task.save
      Rails.cache.delete("user_categories_#{current_user.id}")
      redirect_to tasks_path, notice: "Tarea '#{@task.title}' creada exitosamente."
    else
      @user_categories = Task.all_categories_for_user(current_user)
      @assignable_users = assignable_users_for_select
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
    @user_categories = Task.all_categories_for_user(current_user)
    @assignable_users = assignable_users_for_select
  end

  def update
    authorize @task
    if @task.update(task_params)
      Rails.cache.delete("user_categories_#{current_user.id}")
      redirect_to tasks_path, notice: "Tarea '#{@task.title}' actualizada exitosamente."
    else
      @user_categories = Task.all_categories_for_user(current_user)
      @assignable_users = assignable_users_for_select
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    title = @task.title
    @task.destroy

    # Clear cache when task is deleted
    Rails.cache.delete("user_categories_#{current_user.id}")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@task),
          turbo_stream.prepend("flash_messages",
            "<div class='flash-alert' data-controller='flash' data-flash-dismiss-after-value='3000'>
              Tarea '#{title}' eliminada exitosamente.
            </div>")
        ]
      end
      format.html { redirect_to tasks_path, alert: "Task '#{title}' was deleted." }
    end
  end

  def complete
    authorize @task, :complete?

    if @task.completed?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@task, partial: "tasks/task_row", locals: { task: @task }) }
        format.html { redirect_to tasks_path, alert: "Task is already completed." }
      end
    elsif @task.update(status: "completed")
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@task, partial: "tasks/task_row", locals: { task: @task }),
            turbo_stream.prepend("flash_messages",
              "<div class='flash-notice' data-controller='flash' data-flash-dismiss-after-value='3000'>
                Tarea '#{@task.title}' completada exitosamente.
              </div>")
          ]
        end
        format.html { redirect_to tasks_path, notice: "Task '#{@task.title}' was completed!" }
      end
    else
      Rails.logger.error "Failed to complete task #{@task.id}: #{@task.errors.full_messages.join(', ')}"
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@task, partial: "tasks/task_row", locals: { task: @task }) }
        format.html { redirect_to tasks_path, alert: "Error completing task: #{@task.errors.full_messages.join(', ')}" }
      end
    end
  end

  def assign
    authorize @task, :assign?

    assignee_id = params[:task]&.dig(:assignee_id) || params[:assignee_id]

    if assignee_id.present?
      assignee = User.find(assignee_id)
      @task.update(assignee: assignee)
      message = "Tarea '#{@task.title}' asignada a #{assignee.name}."
    else
      @task.update(assignee: nil)
      message = "Tarea '#{@task.title}' desasignada."
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@task, partial: "tasks/task_row", locals: { task: @task }),
          turbo_stream.prepend("flash_messages",
            "<div class='flash-notice' data-controller='flash' data-flash-dismiss-after-value='3000'>
              #{message}
            </div>")
        ]
      end
      format.html { redirect_to tasks_path, notice: message }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash_messages",
          "<div class='flash-alert' data-controller='flash' data-flash-dismiss-after-value='3000'>
            Usuario no encontrado.
          </div>")
      end
      format.html { redirect_to tasks_path, alert: "Usuario no encontrado." }
    end
  end

  def sync
    # Authorize user can create tasks (sync is similar to creating)
    authorize Task.new, :create?

    sync_service = TaskSyncService.new(current_user)
    result = sync_service.sync

    if result[:success]
      redirect_to tasks_path, notice: result[:message]
    else
      redirect_to tasks_path, alert: result[:message]
    end
  rescue => e
    Rails.logger.error "Sync action failed: #{e.message}"
    redirect_to tasks_path, alert: "Error durante la sincronizaci\u00F3n. Por favor, int\u00E9ntalo de nuevo."
  end

  private

  def apply_filters(query)
    # Apply search filter
    query = query.search(params[:query]) if params[:query].present?

    # Apply status filter
    query = query.where(status: params[:status]) if params[:status].present?

    # Apply priority filter
    query = query.where(priority: params[:priority]) if params[:priority].present?

    # Apply category filter
    query = query.where(category: params[:category]) if params[:category].present?

    # Apply due date filter
    if params[:due_date].present?
      query = case params[:due_date]
      when "today"
                query.where(due_date: Date.current.beginning_of_day..Date.current.end_of_day)
      when "tomorrow"
                query.where(due_date: Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day)
      when "week"
                query.where(due_date: Date.current.beginning_of_day..Date.current.end_of_week)
      when "next_week"
                query.where(due_date: Date.current.next_week..Date.current.next_week.end_of_week)
      else
                query
      end
    end

    query
  end

  def task_params
    permitted_params = [ :title, :description, :status, :priority, :due_date, :category ]

    # Allow assignee_id if user can assign tasks (admin or task_maker)
    if current_user.present? && (current_user.admin? || current_user.task_maker?)
      permitted_params << :assignee_id
    end

    params.permit(permitted_params)
  end

  def set_task
    @task = policy_scope(Task).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Tarea no encontrada."
    redirect_to tasks_path
  end

  def assignable_users_for_select
    return [] unless current_user.present? && (current_user.admin? || current_user.task_maker?)
    User.where.not(id: current_user.id).map { |u| [ u.name, u.id ] }
  end
end
