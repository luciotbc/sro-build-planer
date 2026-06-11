module CurrentCharacter
  extend ActiveSupport::Concern

  included { helper_method :current_character }

  private

  # The character the user is working on. Selection is kept in the session;
  # falls back to the most recent character.
  def current_character
    return nil unless authenticated?

    @current_character ||=
      Current.user.characters.find_by(id: session[:character_id]) ||
        Current.user.characters.order(:id).last
  end

  def select_character(character)
    session[:character_id] = character.id
    @current_character = character
  end
end
