require 'rails_helper'

RSpec.describe "User Registration", type: :request do
  describe "GET /users/sign_up" do
    it "displays role selection in registration form" do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tipo de Cuenta")
      expect(response.body).to include("Ejecutor de Tareas")
      expect(response.body).to include("Creador de Tareas")
      expect(response.body).to include("Administrador")
      expect(response.body).to include("form-select")
    end
  end

  describe "POST /users" do
    let(:user_params) do
      {
        user: {
          name: "Test User",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: "task_maker"
        }
      }
    end

    it "creates user with selected role" do
      expect {
        post user_registration_path, params: user_params
      }.to change(User, :count).by(1)

      user = User.find_by(email: "test@example.com")
      expect(user).to be_present
      expect(user.role).to eq("task_maker")
      expect(user.name).to eq("Test User")
    end

    it "defaults to task_doer when no role specified" do
      user_params[:user].delete(:role)
      
      expect {
        post user_registration_path, params: user_params
      }.to change(User, :count).by(1)

      user = User.find_by(email: "test@example.com")
      expect(user.role).to eq("task_doer")
    end

    it "can create admin users" do
      user_params[:user][:role] = "admin"
      user_params[:user][:email] = "admin@example.com"
      
      expect {
        post user_registration_path, params: user_params
      }.to change(User, :count).by(1)

      user = User.find_by(email: "admin@example.com")
      expect(user.role).to eq("admin")
    end

    it "can create task_doer users" do
      user_params[:user][:role] = "task_doer"
      user_params[:user][:email] = "doer@example.com"
      
      expect {
        post user_registration_path, params: user_params
      }.to change(User, :count).by(1)

      user = User.find_by(email: "doer@example.com")
      expect(user.role).to eq("task_doer")
    end
  end
end 