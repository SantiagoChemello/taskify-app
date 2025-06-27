require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:email).case_insensitive.with_message(/has already been taken/) }
    
    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
  end

  describe 'associations' do
    it { should have_many(:tasks).dependent(:destroy) }
    it { should have_many(:assigned_tasks).dependent(:nullify) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(admin: 0, task_maker: 1, task_doer: 2).with_default(:task_doer) }
  end

  describe 'role methods' do
    let(:admin) { build(:user, role: 'admin') }
    let(:task_maker) { build(:user, role: 'task_maker') }
    let(:task_doer) { build(:user, role: 'task_doer') }

    describe '#admin?' do
      it 'returns true for admin users' do
        expect(admin.admin?).to be true
      end

      it 'returns false for non-admin users' do
        expect(task_maker.admin?).to be false
        expect(task_doer.admin?).to be false
      end
    end

    describe '#can_create_tasks?' do
      it 'returns true for admin and task_maker' do
        expect(admin.can_create_tasks?).to be true
        expect(task_maker.can_create_tasks?).to be true
      end

      it 'returns false for task_doer' do
        expect(task_doer.can_create_tasks?).to be false
      end
    end

    describe '#can_assign_tasks?' do
      it 'returns true for admin and task_maker' do
        expect(admin.can_assign_tasks?).to be true
        expect(task_maker.can_assign_tasks?).to be true
      end

      it 'returns false for task_doer' do
        expect(task_doer.can_assign_tasks?).to be false
      end
    end

    describe '#role_label' do
      it 'returns correct Spanish labels' do
        expect(admin.role_label).to eq('Administrador')
        expect(task_maker.role_label).to eq('Creador de Tareas')
        expect(task_doer.role_label).to eq('Ejecutor de Tareas')
      end
    end
  end
end 