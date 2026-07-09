class PagesController < ApplicationController
  # Public static pages: readable signed-out.
  allow_unauthenticated_access only: %i[privacy terms]

  def privacy
  end

  def terms
  end
end
