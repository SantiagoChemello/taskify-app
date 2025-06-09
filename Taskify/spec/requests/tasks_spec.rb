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
          stats: { uploaded: 0, downloaded: 0, conflicts: 0, errors: ["Network error"] }
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
  end 