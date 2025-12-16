require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) { { title: 'Test Task', description: 'Test Descripción', status: 'pending', priority: 'medium' } }
  let(:invalid_attributes) { { title: '', description: 'a' * 201 } }

  before do
    sign_in user
  end

  describe "GET /tasks/new" do
    it "displays the new task form" do
      get new_task_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Nueva Tarea")
    end

    it "includes priority dropdown with Spanish labels" do
      get new_task_path
      expect(response.body).to include("Prioridad")
      expect(response.body).to include("Alta")
      expect(response.body).to include("Media")
      expect(response.body).to include("Baja")
    end

    it "includes category input field with datalist" do
      get new_task_path
      expect(response.body).to include("Categoría")
      expect(response.body).to include("Escribe una categoría o selecciona una existente")
      expect(response.body).to include("categories-list")
    end
  end

  describe "POST /tasks" do
    context "with valid parameters" do
      it "creates a new task" do
        expect {
          post tasks_path, params: { task: valid_attributes }
        }.to change(Task, :count).by(1)
      end

      it "redirects to the tasks list with a success message" do
        post tasks_path, params: { task: valid_attributes }
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to eq('Task was successfully created.')
      end

      it "creates task with specified priority" do
        post tasks_path, params: { task: valid_attributes.merge(priority: 'high') }
        task = Task.last
        expect(task.priority).to eq('high')
      end

      it "creates task with default priority when not specified" do
        post tasks_path, params: { task: valid_attributes.except(:priority) }
        task = Task.last
        expect(task.priority).to eq('medium')
      end

      it "creates task with due date" do
        due_date = 1.week.from_now
        post tasks_path, params: { task: valid_attributes.merge(due_date: due_date) }
        task = Task.last
        expect(task.due_date).to be_within(1.second).of(due_date)
      end

      it "creates task with category" do
        post tasks_path, params: { task: valid_attributes.merge(category: 'trabajo') }
        task = Task.last
        expect(task.category).to eq('trabajo')
      end

      it "creates task without category when not specified" do
        post tasks_path, params: { task: valid_attributes }
        task = Task.last
        expect(task.category).to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a new task" do
        expect {
          post tasks_path, params: { task: invalid_attributes }
        }.not_to change(Task, :count)
      end

      it "renders the new template with unprocessable entity status" do
        post tasks_path, params: { task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Nueva Tarea")
      end

      it "raises error with invalid priority" do
        expect {
          post tasks_path, params: { task: valid_attributes.merge(priority: 'invalid') }
        }.to raise_error(ArgumentError, "'invalid' is not a valid priority")
      end

      it "creates task with any custom category" do
        post tasks_path, params: { task: valid_attributes.merge(category: 'custom_category') }
        task = Task.last
        expect(task.category).to eq('custom_category')
      end

      it "does not create task with category longer than 30 characters" do
        expect {
          post tasks_path, params: { task: valid_attributes.merge(category: 'a' * 31) }
        }.not_to change(Task, :count)
      end

      it "renders new template with validation error for long category" do
        post tasks_path, params: { task: valid_attributes.merge(category: 'a' * 31) }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Nueva Tarea")
      end
    end
  end

  describe "GET /tasks" do
    it "displays a list of pending tasks" do
      create(:task, user: user, status: :pending)
      get tasks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Mis Tareas")
    end

    it "displays an empty state message when no tasks exist" do
      get tasks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("No tasks found. Create your first task!")
    end

    it "displays action links for each task" do
      task = create(:task, user: user, status: :pending)
      get tasks_path
      expect(response.body).to include("Complete")
      expect(response.body).to include("Edit")
      expect(response.body).to include("Delete")
    end

    describe "priority display" do
      it "displays priority badges with Spanish labels" do
        high_task = create(:task, user: user, priority: 'high', title: 'High Priority Task')
        medium_task = create(:task, user: user, priority: 'medium', title: 'Medium Priority Task')
        low_task = create(:task, user: user, priority: 'low', title: 'Low Priority Task')

        get tasks_path

        expect(response.body).to include("Alta")      # High priority in Spanish
        expect(response.body).to include("Media")     # Medium priority in Spanish
        expect(response.body).to include("Baja")      # Low priority in Spanish
      end

      it "displays priority badges with color coding" do
        task = create(:task, user: user, priority: 'high')
        get tasks_path

        expect(response.body).to include("background-color: #ef4444")  # Red for high priority
      end

      it "displays creation dates and relative time" do
        task = create(:task, user: user, title: 'Date Test Task')
        get tasks_path

        expect(response.body).to include("Creada:")
        expect(response.body).to include(task.created_at.strftime("%d/%m/%Y a las %H:%M"))
        expect(response.body).to include(task.created_at_relative_es)
      end

      it "displays due date notifications" do
        overdue_task = create(:task, user: user, title: 'Overdue Task', due_date: 1.day.ago, status: 'pending')
        due_today_task = create(:task, user: user, title: 'Due Today Task', due_date: Date.current.end_of_day, status: 'pending')
        due_soon_task = create(:task, user: user, title: 'Due Soon Task', due_date: 1.day.from_now, status: 'pending')

        get tasks_path

        # Check for notification banners
        expect(response.body).to include("⚠️ Vencidas:")
        expect(response.body).to include("🕐 Hoy:")
        expect(response.body).to include("📅 Próximas:")

        # Check for specific tasks in notifications
        expect(response.body).to include("Overdue Task")
        expect(response.body).to include("Due Today Task")
        expect(response.body).to include("Due Soon Task")

        # Check for due status messages
        expect(response.body).to include("Vencida hace")
        expect(response.body).to include("Vence hoy")
        expect(response.body).to include("Vence mañana")
      end

      it "displays due dates in task cards with color coding" do
        overdue_task = create(:task, user: user, due_date: 1.day.ago, status: 'pending')
        due_soon_task = create(:task, user: user, due_date: 12.hours.from_now, status: 'pending')
        normal_due_task = create(:task, user: user, due_date: 1.week.from_now, status: 'pending')

        get tasks_path

        expect(response.body).to include("Vence:")
        # Overdue tasks should have darker red color
        expect(response.body).to include("color: #dc2626")
        # Due soon tasks should have orange color
        expect(response.body).to include("color: #ea580c")
      end

      it "includes due date field in forms" do
        get new_task_path

        expect(response.body).to include("Fecha límite (opcional)")
        expect(response.body).to include('name="task[due_date]"')
        expect(response.body).to include("Recibirás notificaciones cuando la tarea esté próxima a vencer")
      end

      it "sorts tasks by priority (high to low) then by creation date" do
        # Create tasks in reverse priority order but same time
        low_task = create(:task, user: user, priority: 'low', title: 'Low Task')
        sleep(0.01) # Small delay to ensure different creation times
        medium_task = create(:task, user: user, priority: 'medium', title: 'Medium Task')
        sleep(0.01)
        high_task = create(:task, user: user, priority: 'high', title: 'High Task')

        get tasks_path

        # Check that high priority appears before medium and low
        response_body = response.body
        high_position = response_body.index('High Task')
        medium_position = response_body.index('Medium Task')
        low_position = response_body.index('Low Task')

        expect(high_position).to be < medium_position
        expect(medium_position).to be < low_position
      end
    end

    describe "dynamic sorting" do
      let!(:old_high_task) { create(:task, user: user, priority: 'high', title: 'Old High Task', created_at: 2.days.ago) }
      let!(:new_low_task) { create(:task, user: user, priority: 'low', title: 'New Low Task', created_at: 1.hour.ago) }
      let!(:medium_task) { create(:task, user: user, priority: 'medium', title: 'Medium Task', created_at: 1.day.ago) }

      context "when sorting by priority" do
        it "sorts by priority first, then by creation date" do
          get tasks_path, params: { sort: 'priority' }

          response_body = response.body
          old_high_position = response_body.index('Old High Task')
          medium_position = response_body.index('Medium Task')
          new_low_position = response_body.index('New Low Task')

          # Priority order: high -> medium -> low
          expect(old_high_position).to be < medium_position
          expect(medium_position).to be < new_low_position
        end
      end

      context "when sorting by creation date" do
        it "sorts by creation date only (newest first)" do
          get tasks_path, params: { sort: 'created_at' }

          response_body = response.body
          new_low_position = response_body.index('New Low Task')
          medium_position = response_body.index('Medium Task')
          old_high_position = response_body.index('Old High Task')

          # Creation date order: newest -> oldest
          expect(new_low_position).to be < medium_position
          expect(medium_position).to be < old_high_position
        end
      end

      context "when no sort parameter is provided" do
        it "defaults to priority sorting" do
          get tasks_path

          response_body = response.body
          old_high_position = response_body.index('Old High Task')
          medium_position = response_body.index('Medium Task')
          new_low_position = response_body.index('New Low Task')

          # Should default to priority order
          expect(old_high_position).to be < medium_position
          expect(medium_position).to be < new_low_position
        end
      end

      context "when providing invalid sort parameter" do
        it "defaults to priority sorting" do
          get tasks_path, params: { sort: 'invalid_sort' }

          response_body = response.body
          old_high_position = response_body.index('Old High Task')
          medium_position = response_body.index('Medium Task')
          new_low_position = response_body.index('New Low Task')

          # Should default to priority order
          expect(old_high_position).to be < medium_position
          expect(medium_position).to be < new_low_position
        end
      end

      it "includes sorting dropdown with Spanish labels" do
        get tasks_path
        expect(response.body).to include("Ordenar:")
        expect(response.body).to include("Prioridad")
        expect(response.body).to include("Fecha de creación")
      end

      it "preserves status filter when changing sort order" do
        create(:task, user: user, status: 'pending', priority: 'high', title: 'Pending High')
        create(:task, user: user, status: 'completed', priority: 'low', title: 'Completed Low')

        get tasks_path, params: { status: 'pending', sort: 'created_at' }

        expect(response.body).to include("Pending High")
        expect(response.body).not_to include("Completed Low")
        expect(response.body).to include("Mis Tareas Pendientes")
      end

      it "preserves sort order when changing status filter" do
        # This test ensures that both parameters work together
        get tasks_path, params: { status: 'pending', sort: 'priority' }

        expect(response.body).to include('selected="selected" value="priority"')
        expect(response.body).to include('selected="selected" value="pending"')
      end
    end

    describe "status filtering" do
      let!(:pending_task) { create(:task, user: user, title: "Pending Task", status: :pending) }
      let!(:completed_task) { create(:task, user: user, title: "Completed Task", status: :completed) }

      context "when no status filter is applied" do
        it "displays all tasks" do
          get tasks_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Mis Tareas")
          expect(response.body).to include("Pending Task")
          expect(response.body).to include("Completed Task")
        end
      end

      context "when filtering by pending status" do
        it "displays only pending tasks" do
          get tasks_path, params: { status: 'pending' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Mis Tareas Pendientes")
          expect(response.body).to include("Pending Task")
          expect(response.body).not_to include("Completed Task")
        end

        it "shows appropriate empty state for pending tasks" do
          Task.destroy_all
          get tasks_path, params: { status: 'pending' }
          expect(response.body).to include("No pending tasks. Create your first task!")
        end
      end

      context "when filtering by completed status" do
        it "displays only completed tasks" do
          get tasks_path, params: { status: 'completed' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Mis Tareas Completadas")
          expect(response.body).to include("Completed Task")
          expect(response.body).not_to include("Pending Task")
        end

        it "shows appropriate empty state for completed tasks" do
          completed_task.destroy
          get tasks_path, params: { status: 'completed' }
          expect(response.body).to include("No completed tasks yet. Complete some tasks to see them here!")
        end
      end

      context "when providing invalid status parameter" do
        it "ignores invalid status and shows all tasks" do
          get tasks_path, params: { status: 'invalid_status' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Mis Tareas")
          expect(response.body).to include("Pending Task")
          expect(response.body).to include("Completed Task")
        end
      end

              it "includes status filter dropdown" do
          get tasks_path
          expect(response.body).to include("Estado:")
          expect(response.body).to include("Todas")
          expect(response.body).to include("Pendientes")
          expect(response.body).to include("Completadas")
        end
    end

    describe "category filtering" do
      let!(:trabajo_task) { create(:task, user: user, title: "Trabajo Task", category: "trabajo") }
      let!(:personal_task) { create(:task, user: user, title: "Personal Task", category: "personal") }
      let!(:custom_task) { create(:task, user: user, title: "Custom Task", category: "custom_category") }
      let!(:no_category_task) { create(:task, user: user, title: "No Category Task", category: nil) }

              context "when no category filter is applied" do
          it "displays all tasks" do
            get tasks_path
            expect(response).to have_http_status(:success)
            expect(response.body).to include("Trabajo Task")
            expect(response.body).to include("Personal Task")
            expect(response.body).to include("Custom Task")
            expect(response.body).to include("No Category Task")
          end
        end

      context "when filtering by trabajo category" do
        it "displays only trabajo tasks" do
          get tasks_path, params: { category: 'trabajo' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Trabajo Task")
          expect(response.body).not_to include("Personal Task")
          expect(response.body).not_to include("Estudios Task")
          expect(response.body).not_to include("No Category Task")
        end
      end

      context "when filtering by personal category" do
        it "displays only personal tasks" do
          get tasks_path, params: { category: 'personal' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Personal Task")
          expect(response.body).not_to include("Trabajo Task")
          expect(response.body).not_to include("Estudios Task")
          expect(response.body).not_to include("No Category Task")
        end
      end

              context "when filtering by custom category" do
          it "displays only custom category tasks" do
            get tasks_path, params: { category: 'custom_category' }
            expect(response).to have_http_status(:success)
            expect(response.body).to include("Custom Task")
            expect(response.body).not_to include("Trabajo Task")
            expect(response.body).not_to include("Personal Task")
            expect(response.body).not_to include("No Category Task")
          end
        end

              context "when providing nonexistent category parameter" do
          it "shows no tasks for nonexistent category" do
            get tasks_path, params: { category: 'nonexistent_category' }
            expect(response).to have_http_status(:success)
            expect(response.body).not_to include("Trabajo Task")
            expect(response.body).not_to include("Personal Task")
            expect(response.body).not_to include("Custom Task")
            expect(response.body).not_to include("No Category Task")
          end
        end

              it "includes category filter dropdown with user's categories" do
          get tasks_path
          expect(response.body).to include("Categoría:")
          expect(response.body).to include("Todas")
          # Should include the user's existing categories
          expect(response.body).to include("Trabajo")
          expect(response.body).to include("Personal")
          expect(response.body).to include("Custom_category")
        end

        it "displays category badges with correct labels and colors" do
          get tasks_path

          # Check for category badges
          expect(response.body).to include("Trabajo")
          expect(response.body).to include("Personal")
          expect(response.body).to include("Custom_category")

          # Check for category colors
          expect(response.body).to include("#3b82f6")  # Blue for trabajo
          expect(response.body).to include("#8b5cf6")  # Purple for personal
        end
    end
  end

  describe "PATCH /tasks/:id/complete" do
    let(:task) { create(:task, user: user, status: :pending) }

    it "marks a task as completed" do
      patch complete_task_path(task)
      task.reload
      expect(task).to be_completed
      expect(response).to redirect_to(tasks_path)
      expect(flash[:notice]).to eq("Task '#{task.title}' was completed!")
    end

    it "handles completing other users' tasks" do
      other_user = create(:user)
      other_task = create(:task, user: other_user)

      patch complete_task_path(other_task)
      expect(response).to redirect_to(tasks_path)
      expect(flash[:alert]).to eq('Task not found.')
    end
  end

  describe "DELETE /tasks/:id" do
    let!(:task) { create(:task, user: user) }

    it "deletes the task" do
      expect {
        delete task_path(task)
      }.to change(Task, :count).by(-1)
    end

    it "redirects to tasks with a flash message" do
      title = task.title
      delete task_path(task)
      expect(response).to redirect_to(tasks_path)
      expect(flash[:alert]).to eq("Task '#{title}' was deleted.")
    end

    it "handles deleting other users' tasks" do
      other_user = create(:user)
      other_task = create(:task, user: other_user)

      delete task_path(other_task)
      expect(response).to redirect_to(tasks_path)
      expect(flash[:alert]).to eq('Task not found.')
    end
  end

  describe "GET /tasks/:id/edit" do
    let(:task) { create(:task, user: user) }

    it "renders the edit form" do
      get edit_task_path(task)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Editar Tarea")
    end

    it "includes priority dropdown with Spanish labels in edit form" do
      get edit_task_path(task)
      expect(response.body).to include("Prioridad")
      expect(response.body).to include("Alta")
      expect(response.body).to include("Media")
      expect(response.body).to include("Baja")
    end

    it "pre-selects the current priority in edit form" do
      task.update(priority: 'high')
      get edit_task_path(task)
      expect(response.body).to include('selected="selected" value="high"')
    end

    it "includes category input field with datalist in edit form" do
      get edit_task_path(task)
      expect(response.body).to include("Categoría")
      expect(response.body).to include("Escribe una categoría o selecciona una existente")
      expect(response.body).to include("categories-list")
    end

    it "pre-fills the current category in edit form" do
      task.update(category: 'trabajo')
      get edit_task_path(task)
      expect(response.body).to include('value="trabajo"')
    end

    it "handles editing other users' tasks" do
      other_user = create(:user)
      other_task = create(:task, user: other_user)

      get edit_task_path(other_task)
      expect(response).to redirect_to(tasks_path)
      expect(flash[:alert]).to eq('Task not found.')
    end
  end

  describe "PATCH /tasks/:id" do
    let(:task) { create(:task, user: user) }
    let(:valid_attributes) { { title: "Updated Título", description: "Updated description", status: "pending", priority: "medium" } }
    let(:invalid_attributes) { { title: "", description: "a" * 201 } }

    context "with valid parameters" do
      it "updates the task" do
        patch task_path(task), params: { task: valid_attributes }
        task.reload
        expect(task.title).to eq("Updated Título")
        expect(response).to redirect_to(tasks_path)
        expect(flash[:notice]).to be_present
      end

      it "updates the task priority" do
        patch task_path(task), params: { task: valid_attributes.merge(priority: 'high') }
        task.reload
        expect(task.priority).to eq('high')
        expect(response).to redirect_to(tasks_path)
      end

      it "updates the task category" do
        patch task_path(task), params: { task: valid_attributes.merge(category: 'personal') }
        task.reload
        expect(task.category).to eq('personal')
        expect(response).to redirect_to(tasks_path)
      end

      it "can clear the task category" do
        task.update(category: 'trabajo')
        patch task_path(task), params: { task: valid_attributes.merge(category: '') }
        task.reload
        expect(task.category).to eq('')
        expect(response).to redirect_to(tasks_path)
      end
    end

    context "with invalid parameters" do
      it "renders the edit template" do
        patch task_path(task), params: { task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Editar Tarea")
      end

      it "raises error with invalid priority" do
        expect {
          patch task_path(task), params: { task: valid_attributes.merge(priority: 'invalid') }
        }.to raise_error(ArgumentError, "'invalid' is not a valid priority")
      end

      it "renders edit template with validation error for long category" do
        patch task_path(task), params: { task: valid_attributes.merge(category: 'a' * 31) }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Editar Tarea")
      end
    end
  end

  describe "POST /tasks/sync" do
    before do
      sign_in user
      # Clean up any existing sync data
      sync_dir = Rails.root.join('tmp', 'cloud_sync')
      FileUtils.rm_rf(sync_dir) if File.exist?(sync_dir)
    end

    after do
      # Clean up sync data after tests
      sync_dir = Rails.root.join('tmp', 'cloud_sync')
      FileUtils.rm_rf(sync_dir) if File.exist?(sync_dir)
    end

    context "when sync is successful" do
      it "redirects with success message when no tasks exist" do
        post sync_tasks_path

        expect(response).to redirect_to(tasks_path)
        follow_redirect!
        expect(response.body).to include("Sincronización completada. Todas las tareas están actualizadas.")
      end

      it "syncs local tasks to cloud" do
        create(:task, user: user, title: "Test Task")

        post sync_tasks_path

        expect(response).to redirect_to(tasks_path)
        follow_redirect!
        expect(response.body).to include("tarea(s) enviada(s) a la nube")
      end

      it "shows sync button in the interface" do
        get tasks_path

        expect(response.body).to include("🔄 Sincronizar")
        expect(response.body).to include("Sincronizar tareas con la nube")
      end

      it "disables sync button during submission" do
        get tasks_path

        expect(response.body).to include('data-disable-with="Sincronizando..."')
      end
    end

    context "when sync encounters errors" do
      before do
        # Mock the sync service to return an error result
        sync_service = instance_double(TaskSyncService)
        allow(TaskSyncService).to receive(:new).and_return(sync_service)
        allow(sync_service).to receive(:sync).and_return({
          success: false,
          message: "Error durante la sincronización: Network error",
          stats: { uploaded: 0, downloaded: 0, conflicts: 0, errors: [ "Network error" ] }
        })
        allow(sync_service).to receive(:last_sync_time).and_return(nil)
      end

      it "handles sync errors gracefully" do
        post sync_tasks_path

        expect(response).to redirect_to(tasks_path)
        follow_redirect!
        expect(response.body).to include("Error durante la sincronización")
      end
    end

    context "when user is not signed in" do
      before do
        sign_out user
      end

      it "redirects to sign in page" do
        post sync_tasks_path
        expect(response).to redirect_to(new_user_session_path)
              end
      end

    describe "search functionality" do
      let!(:task1) { create(:task, user: user, title: "Complete project proposal", description: "Write the final proposal for the client", category: "trabajo") }
      let!(:task2) { create(:task, user: user, title: "Buy groceries", description: "Milk, eggs, and bread", category: "personal") }
      let!(:task3) { create(:task, user: user, title: "Study for exam", description: "Review math formulas and practice problems", category: "estudios") }
      let!(:task4) { create(:task, user: user, title: "Project meeting", description: "Discuss project timeline", category: "trabajo") }

      context "when searching by title" do
        it "finds tasks with matching title (case insensitive)" do
          get tasks_path, params: { query: 'project' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).to include("Project meeting")
          expect(response.body).not_to include("Buy groceries")
          expect(response.body).not_to include("Study for exam")
        end

        it "finds tasks with partial title match" do
          get tasks_path, params: { query: 'Complete' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).not_to include("Buy groceries")
        end
      end

      context "when searching by description (no longer supported)" do
        it "does not find tasks by description content" do
          get tasks_path, params: { query: 'formulas' }
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("Study for exam")
          expect(response.body).to include('No se encontraron tareas que coincidan con los filtros seleccionados.formulas"')
        end

        it "does not find tasks by description keywords" do
          get tasks_path, params: { query: 'milk' }
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("Buy groceries")
          expect(response.body).to include('No se encontraron tareas que coincidan con los filtros seleccionados.milk"')
        end
      end

      context "when searching only by title" do
        it "finds tasks matching title only" do
          get tasks_path, params: { query: 'project' }
          expect(response).to have_http_status(:success)
          # Should find both tasks: both have "project" in title
          expect(response.body).to include("Complete project proposal")  # title match
          expect(response.body).to include("Project meeting")            # title match
          # But should include the task content since it IS found by title match
          expect(response.body).to include("Discuss project timeline")   # this task IS found because title matches
        end
      end

      context "when search is case insensitive" do
        it "finds tasks regardless of case" do
          get tasks_path, params: { query: 'PROJECT' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).to include("Project meeting")
        end

        it "finds tasks with mixed case search" do
          get tasks_path, params: { query: 'ProJeCt' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
        end
      end

      context "when no search results found" do
        it "displays appropriate empty state message" do
          get tasks_path, params: { query: 'nonexistent_term' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include('No se encontraron tareas que coincidan con los filtros seleccionados.nonexistent_term"')
          expect(response.body).not_to include("Complete project proposal")
        end
      end

      context "when combining search with other filters" do
        it "searches within filtered results by status" do
          task1.update(status: 'completed')
          get tasks_path, params: { query: 'project', status: 'completed' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).not_to include("Project meeting")  # pending task
        end

        it "searches within filtered results by category" do
          get tasks_path, params: { query: 'project', category: 'trabajo' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).to include("Project meeting")
        end

        it "preserves search query when changing other filters" do
          get tasks_path, params: { query: 'project', status: 'pending' }
          expect(response.body).to include('value="project"')  # search input should retain value
        end
      end

      context "when search input is empty" do
        it "shows all tasks when query is empty string" do
          get tasks_path, params: { query: '' }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).to include("Buy groceries")
          expect(response.body).to include("Study for exam")
        end

        it "shows all tasks when query parameter is not present" do
          get tasks_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Complete project proposal")
          expect(response.body).to include("Buy groceries")
        end
      end

      it "includes search input field with live search" do
        get tasks_path
        expect(response.body).to include("Buscar:")
        expect(response.body).to include("Buscar por nombre de tarea...")
        expect(response.body).to include('name="query"')
        expect(response.body).to include('id="search-form"')
      end

      it "includes clear filters option when filters are active" do
        get tasks_path, params: { query: 'test' }
        expect(response.body).to include("Limpiar filtros")
      end

      it "includes JavaScript for live search functionality" do
        get tasks_path
        expect(response.body).to include("addEventListener('input'")
        expect(response.body).to include("setTimeout")
        expect(response.body).to include("window.location.href")
      end

      it "shows search results header when searching" do
        get tasks_path, params: { query: 'project' }
        expect(response.body).to include('Resultados de búsqueda: "project"')
      end

      it "only searches within current user's tasks" do
        other_user = create(:user)
        create(:task, user: other_user, title: "Other user project", description: "Should not appear")

        get tasks_path, params: { query: 'project' }
        expect(response.body).to include("Complete project proposal")  # current user's task
        expect(response.body).not_to include("Other user project")     # other user's task
      end
    end
    end

  describe "Task Assignment Functionality" do
    let(:admin) { create(:user, :admin) }
    let(:task_maker) { create(:user, :task_maker) }
    let(:task_doer) { create(:user, :task_doer) }
    let(:other_task_doer) { create(:user, :task_doer) }

    describe "Admin assigning tasks" do
      before { sign_in admin }

      describe "GET /tasks/new as admin" do
        it "displays assignee dropdown for admins" do
          get new_task_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Asignar a")
          expect(response.body).to include("Sin asignar")
        end

        it "includes all users in assignee dropdown" do
          # Create the users first to ensure they exist
          task_maker
          task_doer
          other_task_doer

          get new_task_path
          expect(response.body).to include(task_maker.name)
          expect(response.body).to include(task_doer.name)
          expect(response.body).to include(other_task_doer.name)
        end
      end

      describe "POST /tasks with assignment as admin" do
        it "creates task and assigns to specified user" do
          expect {
            post tasks_path, params: valid_attributes.merge(assignee_id: task_doer.id)
          }.to change(Task, :count).by(1)

          task = Task.last
          expect(task.assignee).to eq(task_doer)
          expect(task.user).to eq(admin)
        end

        it "creates task without assignment when assignee_id is empty" do
          post tasks_path, params: valid_attributes.merge(assignee_id: '')
          task = Task.last
          expect(task.assignee).to be_nil
        end

        it "redirects with success message including assignee name" do
          post tasks_path, params: valid_attributes.merge(assignee_id: task_doer.id)
          expect(response).to redirect_to(tasks_path)
          follow_redirect!
          expect(response.body).to include("creada exitosamente")
        end
      end

      describe "GET /tasks/:id/edit as admin" do
        let(:task) { create(:task, user: admin, assignee: task_doer) }

        it "displays assignee dropdown with current assignee selected" do
          get edit_task_path(task)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Asignar a")
          expect(response.body).to include(task_doer.name)
        end

        it "allows admin to edit any task" do
          other_task = create(:task, user: task_maker)
          get edit_task_path(other_task)
          expect(response).to have_http_status(:success)
        end
      end

      describe "PATCH /tasks/:id with assignment as admin" do
        let(:task) { create(:task, user: admin, assignee: nil) }

        it "updates task assignment" do
          patch task_path(task), params: valid_attributes.merge(assignee_id: task_doer.id)
          task.reload
          expect(task.assignee).to eq(task_doer)
        end

        it "removes assignment when assignee_id is empty" do
          task.update(assignee: task_doer)
          patch task_path(task), params: valid_attributes.merge(assignee_id: '')
          task.reload
          expect(task.assignee).to be_nil
        end

        it "can reassign task to different user" do
          task.update(assignee: task_doer)
          patch task_path(task), params: valid_attributes.merge(assignee_id: other_task_doer.id)
          task.reload
          expect(task.assignee).to eq(other_task_doer)
        end
      end
    end

    describe "Task Maker assigning tasks" do
      before { sign_in task_maker }

      describe "GET /tasks/new as task_maker" do
        it "displays assignee dropdown for task makers" do
          get new_task_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Asignar a")
        end

        it "includes task_doers and task_makers in assignee dropdown" do
          # Create the users first to ensure they exist
          task_doer
          other_task_doer

          get new_task_path
          expect(response.body).to include(task_doer.name)
          expect(response.body).to include(other_task_doer.name)
        end
      end

      describe "POST /tasks with assignment as task_maker" do
        it "creates task and assigns to task_doer" do
          post tasks_path, params: valid_attributes.merge(assignee_id: task_doer.id)
          task = Task.last
          expect(task.assignee).to eq(task_doer)
          expect(task.user).to eq(task_maker)
        end

        it "can assign task to another task_maker" do
          other_maker = create(:user, :task_maker)
          post tasks_path, params: valid_attributes.merge(assignee_id: other_maker.id)
          task = Task.last
          expect(task.assignee).to eq(other_maker)
        end
      end

      describe "editing own tasks as task_maker" do
        let(:task) { create(:task, user: task_maker) }

        it "can edit own tasks" do
          get edit_task_path(task)
          expect(response).to have_http_status(:success)
        end

        it "can update assignment on own tasks" do
          patch task_path(task), params: valid_attributes.merge(assignee_id: task_doer.id)
          task.reload
          expect(task.assignee).to eq(task_doer)
        end
      end

      describe "accessing other users' tasks as task_maker" do
        let(:other_task) { create(:task, user: admin) }

        it "cannot edit other users' tasks" do
          get edit_task_path(other_task)
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include("Tarea no encontrada")
        end

        it "cannot update other users' tasks" do
          patch task_path(other_task), params: valid_attributes
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include("Tarea no encontrada")
        end
      end

      describe "task assignment restrictions for task_makers" do
        let(:own_task) { create(:task, user: task_maker) }
        let(:other_users_task) { create(:task, user: admin) }

        describe "assigning own tasks" do
          it "can assign own tasks via PATCH /tasks/:id/assign" do
            patch assign_task_path(own_task), params: { assignee_id: task_doer.id }
            expect(response).to redirect_to(tasks_path)
            follow_redirect!
            expect(response.body).to include("asignada a #{task_doer.name}")
            own_task.reload
            expect(own_task.assignee).to eq(task_doer)
          end

          it "can unassign own tasks" do
            own_task.update(assignee: task_doer)
            patch assign_task_path(own_task), params: { assignee_id: '' }
            expect(response).to redirect_to(tasks_path)
            follow_redirect!
            expect(response.body).to include("desasignada")
            own_task.reload
            expect(own_task.assignee).to be_nil
          end

                     it "shows assignee dropdown when editing own tasks" do
             get edit_task_path(own_task)
             expect(response).to have_http_status(:success)
             expect(response.body).to include("Asignar a")
             expect(response.body).to include("Sin asignar")
             # Verify that there are assignable users available (they should be shown as option tags)
             expect(response.body).to include('<option value="')
           end
        end

        describe "attempting to assign other users' tasks" do
          it "cannot assign other users' tasks via PATCH /tasks/:id/assign" do
            # First, the task maker shouldn't even be able to see this task
            # due to the set_task method using visible_to_user scope
            patch assign_task_path(other_users_task), params: { assignee_id: task_doer.id }
            expect(response).to have_http_status(:redirect)
            follow_redirect!
            expect(response.body).to include("Tarea no encontrada")
          end

          it "does not show assignee dropdown when viewing other users' tasks" do
            # This test assumes they could somehow access the edit form
            # In practice, they wouldn't be able to due to the visible_to_user scope
            # But we can test the policy logic directly
            expect(task_maker.admin?).to be_falsey
            expect(other_users_task.user_id).not_to eq(task_maker.id)

            # The can_assign_task? helper should return false for other users' tasks
            controller = TasksController.new
            controller.instance_variable_set(:@current_user, task_maker)
            allow(controller).to receive(:current_user).and_return(task_maker)

            expect(controller.send(:can_assign_task?, other_users_task)).to be_falsey
          end
        end

        describe "task ownership verification" do
          it "allows task_maker to assign when they own the task" do
            policy = TaskPolicy.new(task_maker, own_task)
            expect(policy.assign?).to be_truthy
          end

          it "prevents task_maker from assigning when they don't own the task" do
            policy = TaskPolicy.new(task_maker, other_users_task)
            expect(policy.assign?).to be_falsey
          end

          it "allows admin to assign any task" do
            policy = TaskPolicy.new(admin, other_users_task)
            expect(policy.assign?).to be_truthy
          end

          it "prevents task_doer from assigning any task" do
            policy = TaskPolicy.new(task_doer, own_task)
            expect(policy.assign?).to be_falsey
          end
        end
      end
    end

    describe "Task Doer restrictions" do
      before { sign_in task_doer }

      describe "GET /tasks/new as task_doer" do
        it "redirects task_doers away from new task page" do
          get new_task_path
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end
      end

      describe "POST /tasks as task_doer" do
        it "cannot create tasks" do
          post tasks_path, params: valid_attributes
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end
      end

      describe "accessing tasks as task_doer" do
        let(:assigned_task) { create(:task, user: task_maker, assignee: task_doer) }
        let(:unassigned_task) { create(:task, user: task_maker) }

        it "cannot edit assigned tasks" do
          get edit_task_path(assigned_task)
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end

        it "cannot access unassigned tasks" do
          get task_path(unassigned_task)
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include("Tarea no encontrada")
        end
      end
    end

    describe "Task visibility in index" do
      let!(:admin_task) { create(:task, user: admin, title: "Admin Task") }
      let!(:maker_task) { create(:task, user: task_maker, title: "Maker Task") }
      let!(:assigned_to_doer) { create(:task, user: task_maker, assignee: task_doer, title: "Assigned to Doer") }
      let!(:assigned_to_maker) { create(:task, user: admin, assignee: task_maker, title: "Assigned to Maker") }

      context "as admin" do
        before { sign_in admin }

        it "sees all tasks" do
          get tasks_path
          expect(response.body).to include("Admin Task")
          expect(response.body).to include("Maker Task")
          expect(response.body).to include("Assigned to Doer")
          expect(response.body).to include("Assigned to Maker")
        end
      end

      context "as task_maker" do
        before { sign_in task_maker }

        it "sees own tasks and tasks assigned to them" do
          get tasks_path
          expect(response.body).to include("Maker Task")
          expect(response.body).to include("Assigned to Doer")
          expect(response.body).to include("Assigned to Maker")
          expect(response.body).not_to include("Admin Task")
        end
      end

      context "as task_doer" do
        before { sign_in task_doer }

        it "sees only tasks assigned to them" do
          get tasks_path
          expect(response.body).to include("Assigned to Doer")
          expect(response.body).not_to include("Admin Task")
          expect(response.body).not_to include("Maker Task")
          expect(response.body).not_to include("Assigned to Maker")
        end
      end
    end

    describe "Assignee information display" do
      let!(:assigned_task) { create(:task, user: admin, assignee: task_doer, title: "Assigned Task") }
      let!(:unassigned_task) { create(:task, user: admin, assignee: nil, title: "Unassigned Task") }

      before { sign_in admin }

      it "displays assignee name for assigned tasks" do
        get tasks_path
        expect(response.body).to include(task_doer.name)
        expect(response.body).to include("Asignado a")
      end

      it "displays 'Sin asignar' for unassigned tasks" do
        get tasks_path
        expect(response.body).to include("Sin asignar")
      end

      it "includes assignee column header" do
        get tasks_path
        expect(response.body).to include("Asignado a")
      end
    end

    describe "Task Doer viewing assigned tasks" do
      let!(:assigned_task) { create(:task, user: task_maker, assignee: task_doer, title: "Task assigned to doer") }
      let!(:unassigned_task) { create(:task, user: task_maker, title: "Task not assigned") }
      let!(:other_assigned_task) { create(:task, user: admin, assignee: other_task_doer, title: "Task assigned to other") }

      before { sign_in task_doer }

      describe "GET /tasks as task_doer" do
        it "shows only tasks assigned to them" do
          get tasks_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Task assigned to doer")
          expect(response.body).not_to include("Task not assigned")
          expect(response.body).not_to include("Task assigned to other")
        end

        it "displays correct page title for task doers" do
          get tasks_path
          expect(response.body).to include("Tareas Asignadas")
        end

        it "does not show Nueva Tarea button for task doers" do
          get tasks_path
          expect(response.body).not_to include("Nueva Tarea")
        end

        it "shows appropriate empty state message when no tasks assigned" do
          assigned_task.destroy
          get tasks_path
          expect(response.body).to include("No tienes tareas asignadas aún")
          expect(response.body).to include("Las tareas aparecerán aquí cuando te las asignen")
        end

        it "does not show edit/delete buttons for assigned tasks" do
          get tasks_path
          expect(response.body).to include("Solo lectura")
          expect(response.body).not_to include("Editar")
          expect(response.body).not_to include("Eliminar")
        end

        it "shows complete button for pending assigned tasks" do
          get tasks_path
          expect(response.body).to include("Completar")
        end

        it "does not show complete button for completed assigned tasks" do
          assigned_task.update(status: 'completed')
          get tasks_path
          expect(response.body).not_to include("Completar")
        end
      end

      describe "task filtering for task_doers" do
        let!(:pending_assigned) { create(:task, user: task_maker, assignee: task_doer, status: 'pending', title: "Pending assigned") }
        let!(:completed_assigned) { create(:task, user: task_maker, assignee: task_doer, status: 'completed', title: "Completed assigned") }

        it "shows only assigned pending tasks when filtering by pending" do
          get tasks_path, params: { status: 'pending' }
          expect(response.body).to include("Pending assigned")
          expect(response.body).not_to include("Completed assigned")
          expect(response.body).to include("Tareas Asignadas Pendientes")
        end

        it "shows only assigned completed tasks when filtering by completed" do
          get tasks_path, params: { status: 'completed' }
          expect(response.body).to include("Completed assigned")
          expect(response.body).not_to include("Pending assigned")
          expect(response.body).to include("Tareas Asignadas Completadas")
        end
      end

      describe "task completion for task_doers" do
        it "allows task_doer to complete assigned tasks" do
          patch complete_task_path(assigned_task)
          expect(response).to redirect_to(tasks_path)
          assigned_task.reload
          expect(assigned_task.status).to eq('completed')
        end

        it "prevents task_doer from completing unassigned tasks" do
          unassigned_task.update(assignee: nil)
          patch complete_task_path(unassigned_task)
          expect(response).to redirect_to(tasks_path)
          follow_redirect!
          expect(response.body).to include("Tarea no encontrada")
        end
      end

      describe "task access restrictions for task_doers" do
        it "cannot access new task page" do
          get new_task_path
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end

        it "cannot edit assigned tasks" do
          get edit_task_path(assigned_task)
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end

        it "cannot delete assigned tasks" do
          delete task_path(assigned_task)
          expect(response).to redirect_to(dashboard_path)
          follow_redirect!
          expect(response.body).to include("No tienes permisos para realizar esta acción")
        end

        it "can view assigned task details" do
          get task_path(assigned_task)
          expect(response).to have_http_status(:success)
        end

        it "cannot view unassigned task details" do
          get task_path(unassigned_task)
          expect(response).to redirect_to(tasks_path)
          follow_redirect!
          expect(response.body).to include("Tarea no encontrada")
        end
      end

      describe "task detail view restrictions for task_doers" do
        it "does not show edit and delete buttons for assigned tasks" do
          get task_path(assigned_task)
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("Editar")
          expect(response.body).not_to include("Eliminar")
          expect(response.body).to include("Solo puedes completar esta tarea")
        end

        it "shows complete button for pending assigned tasks" do
          get task_path(assigned_task)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Completar")
        end

        it "does not show complete button for completed assigned tasks" do
          assigned_task.update(status: 'completed')
          get task_path(assigned_task)
          expect(response).to have_http_status(:success)
          expect(response.body).not_to include("Completar")
        end

        it "displays creator and assignee information" do
          get task_path(assigned_task)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Creada por")
          expect(response.body).to include("Asignada a")
          expect(response.body).to include(task_doer.name)
          expect(response.body).to include(task_maker.name)
        end
      end

      describe "priority visibility for task_doers" do
        let!(:high_priority_task) { create(:task, user: task_maker, assignee: task_doer,
                                                title: "High Priority Task", priority: 'high') }
        let!(:medium_priority_task) { create(:task, user: task_maker, assignee: task_doer,
                                                  title: "Medium Priority Task", priority: 'medium') }
        let!(:low_priority_task) { create(:task, user: task_maker, assignee: task_doer,
                                               title: "Low Priority Task", priority: 'low') }

        it "displays priority information prominently for task prioritization" do
          get tasks_path
          expect(response).to have_http_status(:success)

          # Verify priority column header is displayed
          expect(response.body).to include("Prioridad")

          # Verify all priority badges are displayed with proper CSS classes
          expect(response.body).to include('priority-badge priority-high')
          expect(response.body).to include('priority-badge priority-medium')
          expect(response.body).to include('priority-badge priority-low')
        end

        it "shows color-coded priority labels in Spanish" do
          get tasks_path
          expect(response).to have_http_status(:success)

          # Verify Spanish priority labels are displayed
          expect(response.body).to include('Alta')    # High priority
          expect(response.body).to include('Media')   # Medium priority
          expect(response.body).to include('Baja')    # Low priority
        end

        it "includes priority icons for visual identification" do
          get tasks_path
          expect(response).to have_http_status(:success)

          # Verify priority icons are present for quick visual identification
          expect(response.body).to include('icon-priority-high')
          expect(response.body).to include('icon-priority-medium')
          expect(response.body).to include('icon-priority-low')
        end

        it "allows task_doers to prioritize work based on visual cues" do
          get tasks_path
          expect(response).to have_http_status(:success)

          # Verify that high priority tasks are visually distinct
          # This ensures Task Doers can quickly identify urgent work
          expect(response.body).to include('priority-high')    # Red styling for urgent tasks
          expect(response.body).to include('priority-medium')  # Yellow/orange for medium priority
          expect(response.body).to include('priority-low')     # Green for low priority

          # Verify all assigned tasks show their priorities
          expect(response.body).to include("High Priority Task")
          expect(response.body).to include("Medium Priority Task")
          expect(response.body).to include("Low Priority Task")
        end

        it "displays priority consistently across task list views" do
          # Test priority display in pending filter
          get tasks_path, params: { status: 'pending' }
          expect(response.body).to include('priority-badge')
          expect(response.body).to include('Alta')
          expect(response.body).to include('Media')
          expect(response.body).to include('Baja')

          # Test priority display in all tasks view
          get tasks_path
          expect(response.body).to include('priority-badge')
          expect(response.body).to include('Prioridad')
        end
      end
    end

    describe "Authorization edge cases" do
      it "prevents task_doer from accessing assignee_id parameter" do
        sign_in task_doer
        # This should redirect before even reaching parameter validation
        post tasks_path, params: valid_attributes.merge(assignee_id: admin.id)
        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include("No tienes permisos para realizar esta acción")
      end

      it "prevents unauthorized users from assigning tasks" do
        sign_out admin
        post tasks_path, params: valid_attributes.merge(assignee_id: task_doer.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
  end
