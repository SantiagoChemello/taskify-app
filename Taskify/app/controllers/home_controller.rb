class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    # Landing page - redirect to dashboard (Inicio) if user is already signed in
    if user_signed_in?
      redirect_to dashboard_path
    else
      # Show landing page for non-authenticated users
      render :index
    end
  end
end
