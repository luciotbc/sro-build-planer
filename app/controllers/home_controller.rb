class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    if authenticated?
      last = Current.user.characters.order(:created_at).last
      redirect_to last if last
    end
  end
end
