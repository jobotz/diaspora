# frozen_string_literal: true

#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class RegistrationsController < Devise::RegistrationsController
  before_action :check_registrations_open_or_valid_invite!, except: :registrations_closed

  layout -> { request.format == :mobile ? "application" : "with_header_with_footer" }

  def create
    @user = User.build(user_params)

    if @user.sign_up
      flash[:notice] = t("registrations.create.success")
      @user.process_invite_acceptence(invite) if invite.present?
      @user.seed_aspects
      @user.send_welcome_message
      WelcomeMailer.send_welcome_email(@user).deliver_now
      sign_in_and_redirect(:user, @user)
      logger.info "event=registration status=successful user=#{@user.diaspora_handle}"
    else
      @user.errors.delete(:person)

      flash.now[:error] = @user.errors.full_messages.join(" - ")
      logger.info "event=registration status=failure errors='#{@user.errors.full_messages.join(', ')}'"
      render action: "new"
    end
  end

  def registrations_closed
    render "registrations/registrations_closed"
  end

  private

  def check_registrations_open_or_valid_invite!
    return true if AppConfig.settings.enable_registrations? || invite.try(:can_be_used?)

    flash[:error] = t("registrations.invalid_invite") if params[:invite]
    redirect_to registrations_closed_path
  end

  def invite
    @invite ||= InvitationCode.find_by_token(params[:invite][:token]) if params[:invite].present?
  end

  helper_method :invite

  def user_params
    params.require(:user).permit(
      :username, :email, :getting_started, :password, :password_confirmation, :language, :disable_mail,
      :show_community_spotlight_in_stream, :auto_follow_back, :auto_follow_back_aspect_id,
      :remember_me, :captcha, :captcha_key
    )
  end
end
