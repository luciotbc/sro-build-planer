class SharedBuildsController < ApplicationController
  include BuildViewData

  allow_unauthenticated_access

  def show
    @character = Character.find_by(share_token: params[:share_token]) or
      return head :not_found
    load_build_view_data(@character)
  end
end
