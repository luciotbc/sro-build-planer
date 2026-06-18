class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10,
             within: 3.minutes,
             only: :create,
             with: -> do
               redirect_to new_registration_path, alert: "Try again later."
             end

  def new
  end

  def create
    unless terms_accepted?
      return(
        render_form(["You must accept the terms of use and privacy policy."])
      )
    end

    result = Users::RegisterService.call(registration_params)

    if result.success?
      redirect_to root_path,
                  flash: {
                    registered_email: result.data.email_address
                  }
    else
      render_form(result.errors)
    end
  end

  private

  def registration_params
    {
      email_address: params[:email_address],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      email_opt_in: params[:email_opt_in] == "1"
    }
  end

  def terms_accepted? = params[:terms] == "1"

  def render_form(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream:
                 turbo_stream.replace(
                   "registration_form",
                   partial: "registrations/form",
                   locals: {
                     errors: errors
                   }
                 ),
               status: :unprocessable_entity
      end
      format.html do
        redirect_to new_registration_path, alert: errors.to_sentence
      end
    end
  end
end
