class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    redirect_to characters_path if authenticated?
  end
end
