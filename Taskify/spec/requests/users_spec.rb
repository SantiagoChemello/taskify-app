require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/sign_up" do
    it "displays the sign up form" do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sign up")
    end
  end

  describe "POST /users" do
    let(:valid_attributes) do
      {
        email: 'test@example.com',
        name: 'Test User',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    it "creates a new user" do
      expect {
        post user_registration_path, params: { user: valid_attributes }
      }.to change(User, :count).by(1)
    end

    it "redirects to the root path after sign up" do
      post user_registration_path, params: { user: valid_attributes }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /users/sign_in" do
    it "displays the sign in form" do
      get new_user_session_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /users/sign_in" do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    it "signs in the user with valid credentials" do
      post user_session_path, params: { user: { email: user.email, password: 'password123' } }
      expect(response).to redirect_to(root_path)
    end

    it "does not sign in with invalid credentials" do
      post user_session_path, params: { user: { email: user.email, password: 'wrong_password' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end 