require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:user) { create(:user) }
  
  describe 'validations' do
    it 'validates presence of title' do
      task = build(:task, user: user, title: nil)
      expect(task).to_not be_valid
      expect(task.errors[:title]).to include("can't be blank")
    end

    it 'validates title length maximum of 50 characters' do
      task = build(:task, user: user, title: 'a' * 51)
      expect(task).to_not be_valid
      expect(task.errors[:title]).to include("is too long (maximum is 50 characters)")
    end

    it 'validates description length maximum of 200 characters' do
      task = build(:task, user: user, description: 'a' * 201)
      expect(task).to_not be_valid
      expect(task.errors[:description]).to include("is too long (maximum is 200 characters)")
    end

    it 'validates presence of status' do
      task = build(:task, user: user, status: nil)
      expect(task).to_not be_valid
      expect(task.errors[:status]).to include("can't be blank")
    end

    it 'validates presence of priority' do
      task = build(:task, user: user, priority: nil)
      expect(task).to_not be_valid
      expect(task.errors[:priority]).to include("can't be blank")
    end

    it 'validates priority inclusion in allowed values' do
      expect {
        build(:task, user: user, priority: 'invalid')
      }.to raise_error(ArgumentError, "'invalid' is not a valid priority")
    end

    it 'allows valid priority values' do
      %w[low medium high].each do |priority|
        task = build(:task, user: user, priority: priority)
        expect(task).to be_valid
      end
    end

    it 'validates category length maximum of 30 characters' do
      task = build(:task, user: user, category: 'a' * 31)
      expect(task).to_not be_valid
      expect(task.errors[:category]).to include("is too long (maximum is 30 characters)")
    end

    it 'allows any valid category values' do
      %w[trabajo personal estudios custom_category hogar salud].each do |category|
        task = build(:task, user: user, category: category)
        expect(task).to be_valid
      end
    end

    it 'allows nil category' do
      task = build(:task, user: user, category: nil)
      expect(task).to be_valid
    end

    it 'allows empty string category' do
      task = build(:task, user: user, category: '')
      expect(task).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'enums' do
    it 'defines status enum correctly' do
      expect(Task.statuses).to eq({ 'pending' => 'pending', 'completed' => 'completed' })
    end

    it 'defines priority enum correctly' do
      expect(Task.priorities).to eq({ 'low' => 0, 'medium' => 1, 'high' => 2 })
    end

    it 'has medium as default priority' do
      task = create(:task, user: user)
      expect(task.priority).to eq('medium')
    end
  end

  describe '#completed?' do
    it 'returns true when status is completed' do
      task = create(:task, user: user, status: 'completed')
      expect(task.completed?).to be true
    end

    it 'returns false when status is pending' do
      task = create(:task, user: user, status: 'pending')
      expect(task.completed?).to be false
    end
  end

  describe '#priority_color' do
    it 'returns green for low priority' do
      task = create(:task, user: user, priority: 'low')
      expect(task.priority_color).to eq('#10b981')
    end

    it 'returns orange for medium priority' do
      task = create(:task, user: user, priority: 'medium')
      expect(task.priority_color).to eq('#f59e0b')
    end

    it 'returns red for high priority' do
      task = create(:task, user: user, priority: 'high')
      expect(task.priority_color).to eq('#ef4444')
    end
  end

  describe '#priority_label_es' do
    it 'returns "Baja" for low priority' do
      task = create(:task, user: user, priority: 'low')
      expect(task.priority_label_es).to eq('Baja')
    end

    it 'returns "Media" for medium priority' do
      task = create(:task, user: user, priority: 'medium')
      expect(task.priority_label_es).to eq('Media')
    end

    it 'returns "Alta" for high priority' do
      task = create(:task, user: user, priority: 'high')
      expect(task.priority_label_es).to eq('Alta')
    end
  end

  describe '#category_label_es' do
    it 'returns capitalized category name for any category' do
      task = create(:task, user: user, category: 'trabajo')
      expect(task.category_label_es).to eq('Trabajo')
    end

    it 'returns capitalized custom category name' do
      task = create(:task, user: user, category: 'custom_category')
      expect(task.category_label_es).to eq('Custom_category')
    end

    it 'returns "Sin categoría" for nil category' do
      task = create(:task, user: user, category: nil)
      expect(task.category_label_es).to eq('Sin categoría')
    end

    it 'returns "Sin categoría" for empty category' do
      task = create(:task, user: user, category: '')
      expect(task.category_label_es).to eq('Sin categoría')
    end
  end

  describe '#category_color' do
    it 'returns blue for trabajo category' do
      task = create(:task, user: user, category: 'trabajo')
      expect(task.category_color).to eq('#3b82f6')
    end

    it 'returns purple for personal category' do
      task = create(:task, user: user, category: 'personal')
      expect(task.category_color).to eq('#8b5cf6')
    end

    it 'returns green for estudios category' do
      task = create(:task, user: user, category: 'estudios')
      expect(task.category_color).to eq('#10b981')
    end

    it 'returns orange for hogar category' do
      task = create(:task, user: user, category: 'hogar')
      expect(task.category_color).to eq('#f59e0b')
    end

    it 'returns consistent color for custom categories' do
      task = create(:task, user: user, category: 'custom_category')
      color1 = task.category_color
      
      # Create another task with the same category
      task2 = create(:task, user: user, category: 'custom_category')
      color2 = task2.category_color
      
      expect(color1).to eq(color2)
      expect(color1).to match(/#[0-9a-f]{6}/)  # Valid hex color
    end

    it 'returns gray for nil category' do
      task = create(:task, user: user, category: nil)
      expect(task.category_color).to eq('#6b7280')
    end

    it 'returns gray for empty category' do
      task = create(:task, user: user, category: '')
      expect(task.category_color).to eq('#6b7280')
    end
  end

  describe '#created_at_relative_es' do
    let(:task) { create(:task, user: user) }

    it 'returns "hace unos segundos" for tasks created less than a minute ago' do
      task.update(created_at: 30.seconds.ago)
      expect(task.created_at_relative_es).to eq('hace unos segundos')
    end

    it 'returns minutes for tasks created within an hour' do
      task.update(created_at: 15.minutes.ago)
      expect(task.created_at_relative_es).to eq('hace 15 minutos')
    end

    it 'returns singular minute for one minute ago' do
      task.update(created_at: 1.minute.ago)
      expect(task.created_at_relative_es).to eq('hace 1 minuto')
    end

    it 'returns hours for tasks created within a day' do
      task.update(created_at: 3.hours.ago)
      expect(task.created_at_relative_es).to eq('hace 3 horas')
    end

    it 'returns singular hour for one hour ago' do
      task.update(created_at: 1.hour.ago)
      expect(task.created_at_relative_es).to eq('hace 1 hora')
    end

    it 'returns days for tasks created within a week' do
      task.update(created_at: 3.days.ago)
      expect(task.created_at_relative_es).to eq('hace 3 días')
    end

    it 'returns singular day for one day ago' do
      task.update(created_at: 1.day.ago)
      expect(task.created_at_relative_es).to eq('hace 1 día')
    end

    it 'returns formatted date for tasks older than a week' do
      old_date = 2.months.ago
      task.update(created_at: old_date)
      expect(task.created_at_relative_es).to eq(old_date.strftime("%d/%m/%Y"))
    end
  end

  describe 'class methods' do
    describe '.all_categories_for_user' do
      it 'returns all unique categories for a user' do
        create(:task, user: user, category: 'trabajo')
        create(:task, user: user, category: 'personal')
        create(:task, user: user, category: 'trabajo')  # duplicate
        create(:task, user: user, category: nil)  # should be excluded
        create(:task, user: user, category: '')   # should be excluded
        
        categories = Task.all_categories_for_user(user)
        expect(categories).to contain_exactly('personal', 'trabajo')
      end

      it 'returns categories sorted alphabetically' do
        create(:task, user: user, category: 'zzz')
        create(:task, user: user, category: 'aaa')
        create(:task, user: user, category: 'mmm')
        
        categories = Task.all_categories_for_user(user)
        expect(categories).to eq(['aaa', 'mmm', 'zzz'])
      end

      it 'only returns categories for the specified user' do
        other_user = create(:user)
        create(:task, user: user, category: 'user1_category')
        create(:task, user: other_user, category: 'user2_category')
        
        categories = Task.all_categories_for_user(user)
        expect(categories).to contain_exactly('user1_category')
      end
    end
  end

  describe 'scopes' do
    let!(:pending_task) { create(:task, user: user, status: 'pending') }
    let!(:completed_task) { create(:task, user: user, status: 'completed') }

    it 'pending_tasks scope returns only pending tasks ordered by creation date' do
      expect(Task.pending_tasks).to include(pending_task)
      expect(Task.pending_tasks).to_not include(completed_task)
    end

    describe 'due_soon scope' do
      let!(:due_today_task) { create(:task, user: user, status: 'pending', due_date: 12.hours.from_now) }
      let!(:due_tomorrow_task) { create(:task, user: user, status: 'pending', due_date: 23.hours.from_now) }
      let!(:due_later_task) { create(:task, user: user, status: 'pending', due_date: 2.days.from_now) }
      let!(:completed_due_task) { create(:task, user: user, status: 'completed', due_date: 12.hours.from_now) }

      it 'returns only pending tasks due within 24 hours' do
        due_tasks = Task.due_soon
        expect(due_tasks).to include(due_today_task, due_tomorrow_task)
        expect(due_tasks).not_to include(due_later_task, completed_due_task)
      end

      it 'excludes tasks without due dates' do
        task_without_due_date = create(:task, user: user, status: 'pending', due_date: nil)
        expect(Task.due_soon).not_to include(task_without_due_date)
      end
    end
  end

  describe 'due date methods' do
    let(:task) { create(:task, user: user) }

    describe '#due_soon?' do
      it 'returns true for pending tasks due within 24 hours' do
        task.update(due_date: 12.hours.from_now, status: 'pending')
        expect(task.due_soon?).to be true
      end

      it 'returns false for tasks due later than 24 hours' do
        task.update(due_date: 2.days.from_now, status: 'pending')
        expect(task.due_soon?).to be false
      end

      it 'returns false for completed tasks even if due soon' do
        task.update(due_date: 12.hours.from_now, status: 'completed')
        expect(task.due_soon?).to be false
      end

      it 'returns false for tasks without due date' do
        task.update(due_date: nil)
        expect(task.due_soon?).to be false
      end
    end

    describe '#overdue?' do
      it 'returns true for pending tasks past due date' do
        task.update(due_date: Date.current - 1.day, status: 'pending')
        expect(task.overdue?).to be true
      end

      it 'returns false for tasks not yet due' do
        task.update(due_date: Date.current + 1.day, status: 'pending')
        expect(task.overdue?).to be false
      end

      it 'returns false for tasks due today' do
        task.update(due_date: Date.current, status: 'pending')
        expect(task.overdue?).to be false
      end

      it 'returns false for completed tasks even if overdue' do
        task.update(due_date: Date.current - 1.day, status: 'completed')
        expect(task.overdue?).to be false
      end
    end

    describe '#days_until_due' do
      it 'returns positive number for future due dates' do
        task.update(due_date: Date.current + 2.days)
        expect(task.days_until_due).to eq(2)
      end

      it 'returns negative number for past due dates' do
        task.update(due_date: Date.current - 2.days)
        expect(task.days_until_due).to eq(-2)
      end

      it 'returns 0 for tasks due today' do
        task.update(due_date: Date.current)
        expect(task.days_until_due).to eq(0)
      end

      it 'returns nil for tasks without due date' do
        task.update(due_date: nil)
        expect(task.days_until_due).to be_nil
      end
    end

    describe '#due_status_es' do
      it 'returns "Vence hoy" for tasks due today' do
        task.update(due_date: Date.current, status: 'pending')
        expect(task.due_status_es).to eq('Vence hoy')
      end

      it 'returns "Vence mañana" for tasks due tomorrow' do
        task.update(due_date: Date.current.tomorrow, status: 'pending')
        expect(task.due_status_es).to eq('Vence mañana')
      end

      it 'returns "Vence en X días" for tasks due in multiple days' do
        task.update(due_date: Date.current + 3.days, status: 'pending')
        expect(task.due_status_es).to eq('Vence en 3 días')
      end

      it 'returns overdue message for past due tasks' do
        task.update(due_date: Date.current - 2.days, status: 'pending')
        expect(task.due_status_es).to eq('Vencida hace 2 días')
      end

      it 'returns singular form for one day overdue' do
        task.update(due_date: Date.current - 1.day, status: 'pending')
        expect(task.due_status_es).to eq('Vencida hace 1 día')
      end

      it 'returns nil for tasks without due date' do
        task.update(due_date: nil)
        expect(task.due_status_es).to be_nil
      end

      it 'returns status for tasks not due soon but have due dates' do
        task.update(due_date: Date.current + 1.week, status: 'pending')
        expect(task.due_status_es).to eq('Vence en 7 días')
      end
    end
  end
end 