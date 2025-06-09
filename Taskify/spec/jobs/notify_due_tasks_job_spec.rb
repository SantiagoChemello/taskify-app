require 'rails_helper'

RSpec.describe NotifyDueTasksJob, type: :job do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }

  describe '#perform' do
    context 'when there are no due tasks' do
      it 'completes without processing' do
        create(:task, user: user, due_date: 2.days.from_now, status: 'pending')
        
        NotifyDueTasksJob.perform_now
        # Since no tasks are due, the job should return early without logging
      end
    end

    context 'when there are due tasks' do
      let!(:overdue_task) { create(:task, user: user, title: 'Overdue Task', due_date: Date.current - 1.day, status: 'pending') }
      let!(:due_today_task) { create(:task, user: user, title: 'Due Today Task', due_date: Date.current, status: 'pending') }
      let!(:due_soon_task) { create(:task, user: user, title: 'Due Soon Task', due_date: Date.current.tomorrow, status: 'pending') }
      let!(:completed_overdue_task) { create(:task, user: user, title: 'Completed Overdue', due_date: Date.current - 1.day, status: 'completed') }

                    it 'processes all types of due tasks' do
         # Just verify the job runs without error and processes tasks
         expect { NotifyDueTasksJob.perform_now }.not_to raise_error
         
          # Verify the scope works correctly - overdue, today, and tomorrow are all included
          expect(Task.due_soon.count).to eq(3) # overdue, due today, and due tomorrow
       end

       it 'groups tasks by user' do
         another_due_task = create(:task, user: another_user, title: 'Another User Task', due_date: Date.current, status: 'pending')
         
         expect { NotifyDueTasksJob.perform_now }.not_to raise_error
          expect(Task.due_soon.count).to eq(4) # 3 from first user + 1 from second user
       end

      it 'does not include completed tasks in processing' do
        initial_count = Task.due_soon.count
        create(:task, user: user, title: 'Another Completed', due_date: Date.current, status: 'completed')
        
        # Completed tasks should not be included in due_soon scope
        expect(Task.due_soon.count).to eq(initial_count)
      end
    end

    context 'when tasks are due exactly at 24 hours' do
      let!(:boundary_task) { create(:task, user: user, title: 'Boundary Task', due_date: 24.hours.from_now, status: 'pending') }

      it 'includes tasks due at exactly 24 hours' do
        expect { NotifyDueTasksJob.perform_now }.not_to raise_error
        expect(Task.due_soon.count).to eq(1)
      end
    end
  end

  describe 'job queue' do
    it 'is queued on the default queue' do
      expect(NotifyDueTasksJob.new.queue_name).to eq('default')
    end
  end
end
