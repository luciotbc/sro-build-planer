class SharedBuildsController < ApplicationController
  include BuildViewData

  allow_unauthenticated_access

  # Throttle token guessing: the share token is short (base58×10), so cap how
  # fast anyone can probe /shared/:token. 20/min makes brute force infeasible
  # while never bothering a real visitor (spec 05 R12).
  rate_limit to: 20, within: 1.minute, with: -> { head :too_many_requests }

  def show
    @character = Character.find_by(share_token: params[:share_token])
    # A private build is indistinguishable from a missing one (spec 05 R12):
    # both return 404 so visibility never leaks through the response.
    return head :not_found unless @character&.public?

    load_build_view_data(@character)
  end
end
