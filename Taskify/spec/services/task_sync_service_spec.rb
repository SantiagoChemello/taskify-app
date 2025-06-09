require 'rails_helper'

RSpec.describe TaskSyncService, type: :service do
  let(:user) { create(:user) }
  let(:service) { TaskSyncService.new(user) }
  let(:cloud_storage_path) { Rails.root.join('tmp', 'cloud_sync', "#{user.id}.json") }

  before do
    # Clean up any existing cloud sync data
    FileUtils.rm_rf(File.dirname(cloud_storage_path))
  end

  after do
    # Clean up after tests
    FileUtils.rm_rf(File.dirname(cloud_storage_path))
  end

  describe '#initialize' do
    it 'sets up the service with user and cloud storage path' do
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@cloud_storage_path)).to eq(cloud_storage_path)
    end
  end

  describe '#sync' do
    context 'when there are no existing tasks' do
      it 'completes successfully with no operations' do
        result = service.sync

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Sincronización completada. Todas las tareas están actualizadas.")
        expect(result[:stats][:uploaded]).to eq(0)
        expect(result[:stats][:downloaded]).to eq(0)
        expect(result[:stats][:conflicts]).to eq(0)
      end

      it 'creates cloud storage file' do
        service.sync
        expect(File.exist?(cloud_storage_path)).to be true
      end
    end

    context 'when there are local tasks only' do
      let!(:local_task) { create(:task, user: user, title: 'Local Task', description: 'Local description') }

      it 'uploads local tasks to cloud' do
        result = service.sync

        expect(result[:success]).to be true
        expect(result[:stats][:uploaded]).to eq(1)
        expect(result[:message]).to include("1 tarea(s) enviada(s) a la nube")

        # Verify cloud storage
        cloud_data = JSON.parse(File.read(cloud_storage_path))
        expect(cloud_data['tasks'].length).to eq(1)
        expect(cloud_data['tasks'][0]['title']).to eq('Local Task')
      end
    end

    context 'when there are cloud tasks only' do
      before do
        # Create cloud storage with tasks
        cloud_data = {
          'last_sync' => 1.hour.ago.iso8601,
          'user_id' => user.id,
          'tasks' => [
            {
              'id' => SecureRandom.uuid,
              'title' => 'Cloud Task',
              'description' => 'Cloud description',
              'status' => 'pending',
              'priority' => 'medium',
              'due_date' => nil,
              'created_at' => 2.hours.ago.iso8601,
              'updated_at' => 1.hour.ago.iso8601
            }
          ]
        }
        FileUtils.mkdir_p(File.dirname(cloud_storage_path))
        File.write(cloud_storage_path, JSON.pretty_generate(cloud_data))
      end

      it 'downloads cloud tasks to local' do
        result = service.sync

        expect(result[:success]).to be true
        expect(result[:stats][:downloaded]).to eq(1)
        expect(result[:message]).to include("1 tarea(s) descargada(s) de la nube")

        # Verify local database
        expect(user.tasks.count).to eq(1)
        expect(user.tasks.first.title).to eq('Cloud Task')
      end
    end

    context 'when there are conflicts' do
      let!(:local_task) { create(:task, user: user, title: 'Task Title Local', description: 'Local version', updated_at: 1.hour.ago) }

      before do
        # Create cloud storage with conflicting task
        cloud_data = {
          'last_sync' => 2.hours.ago.iso8601,
          'user_id' => user.id,
          'tasks' => [
            {
              'id' => local_task.id,
              'title' => 'Task Title Cloud',
              'description' => 'Cloud version',
              'status' => 'pending',
              'priority' => 'medium',
              'due_date' => nil,
              'created_at' => local_task.created_at.iso8601,
              'updated_at' => 30.minutes.ago.iso8601
            }
          ]
        }
        FileUtils.mkdir_p(File.dirname(cloud_storage_path))
        File.write(cloud_storage_path, JSON.pretty_generate(cloud_data))
      end

      it 'resolves conflicts by keeping the most recent version (cloud wins)' do
        result = service.sync

        expect(result[:success]).to be true
        expect(result[:stats][:conflicts]).to eq(1)
        expect(result[:message]).to include("1 conflicto(s) resuelto(s)")

        # Cloud version should be kept (more recent - 30 min ago vs 1 hour ago)
        local_task.reload
        expect(local_task.title).to eq('Task Title Cloud')
        expect(local_task.description).to eq('Cloud version')
      end

      context 'when local version is more recent' do
        before do
          # Update local task to be more recent than cloud
          local_task.update!(title: 'Task Title Local Updated', updated_at: 10.minutes.ago)
        end

        it 'resolves conflicts by keeping local version' do
          result = service.sync

          expect(result[:success]).to be true
          expect(result[:stats][:conflicts]).to eq(1)

          # Local version should be kept (more recent)
          local_task.reload
          expect(local_task.title).to eq('Task Title Local Updated')
        end
      end

      context 'when cloud version is more recent' do
        before do
          # Update cloud data to be more recent than local
          cloud_data = JSON.parse(File.read(cloud_storage_path))
          cloud_data['tasks'][0]['updated_at'] = 10.minutes.ago.iso8601
          cloud_data['tasks'][0]['title'] = 'Task Title Cloud Updated'
          File.write(cloud_storage_path, JSON.pretty_generate(cloud_data))
        end

        it 'resolves conflicts by keeping cloud version' do
          result = service.sync

          expect(result[:success]).to be true
          expect(result[:stats][:conflicts]).to eq(1)

          # Cloud version should be kept (more recent)
          local_task.reload
          expect(local_task.title).to eq('Task Title Cloud Updated')
        end
      end
    end

    context 'when sync fails' do
      before do
        # Make the cloud storage directory read-only to cause an error
        FileUtils.mkdir_p(File.dirname(cloud_storage_path))
        FileUtils.chmod(0444, File.dirname(cloud_storage_path))
      end

      after do
        # Restore permissions
        FileUtils.chmod(0755, File.dirname(cloud_storage_path))
      end

      it 'handles errors gracefully' do
        result = service.sync

        expect(result[:success]).to be false
        expect(result[:message]).to include("Error durante la sincronización")
      end
    end
  end

  describe '#last_sync_time' do
    context 'when no sync has occurred' do
      it 'returns nil' do
        expect(service.last_sync_time).to be_nil
      end
    end

    context 'when sync has occurred' do
      before do
        service.sync
      end

      it 'returns the last sync time' do
        sync_time = service.last_sync_time
        expect(sync_time).to be_a(Time)
        expect(sync_time).to be_within(10.seconds).of(Time.current)
      end
    end

    context 'when cloud storage is corrupted' do
      before do
        FileUtils.mkdir_p(File.dirname(cloud_storage_path))
        File.write(cloud_storage_path, 'invalid json')
      end

      it 'returns nil for corrupted data' do
        expect(service.last_sync_time).to be_nil
      end
    end
  end

  describe 'integration scenarios' do
    context 'multiple sync operations' do
      let!(:task1) { create(:task, user: user, title: 'Task 1') }
      let!(:task2) { create(:task, user: user, title: 'Task 2') }

      it 'handles multiple syncs correctly' do
        # First sync
        result1 = service.sync
        expect(result1[:success]).to be true
        expect(result1[:stats][:uploaded]).to eq(2)

        # Create new task
        task3 = create(:task, user: user, title: 'Task 3')

        # Second sync
        result2 = service.sync
        expect(result2[:success]).to be true
        expect(result2[:stats][:uploaded]).to eq(1) # Only the new task

        # Verify all tasks are in cloud
        cloud_data = JSON.parse(File.read(cloud_storage_path))
        expect(cloud_data['tasks'].length).to eq(3)
      end
    end

    context 'with due dates' do
      let!(:task_with_due_date) { create(:task, user: user, title: 'Due Task', due_date: 1.day.from_now) }

      it 'syncs tasks with due dates correctly' do
        result = service.sync

        expect(result[:success]).to be true

        cloud_data = JSON.parse(File.read(cloud_storage_path))
        cloud_task = cloud_data['tasks'][0]
        expect(cloud_task['due_date']).to eq(task_with_due_date.due_date.iso8601)
      end
    end

    context 'with different priorities and statuses' do
      let!(:high_priority_task) { create(:task, user: user, title: 'High Priority', priority: 'high', status: 'completed') }

      it 'preserves task attributes during sync' do
        result = service.sync

        expect(result[:success]).to be true

        cloud_data = JSON.parse(File.read(cloud_storage_path))
        cloud_task = cloud_data['tasks'][0]
        expect(cloud_task['priority']).to eq('high')
        expect(cloud_task['status']).to eq('completed')
      end
    end
  end
end 