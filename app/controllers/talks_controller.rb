# frozen_string_literal: true

class TalksController < ApplicationController
  before_action :require_login, only: %i[show]
  before_action :require_admin_login, only: %i[index]
  before_action :set_talk, only: %i[show]
  before_action :set_user, only: %i[show]
  before_action :set_members, only: %i[show]
  before_action :allow_show_talk_page_only_admin, only: %i[show]

  def index
    @target = params[:target]
    @target = 'all' unless API::TalksController::TARGETS.include?(@target)
  end

  def show; end

  private

  def allow_show_talk_page_only_admin
    return if current_user.admin? || @talk.user == current_user

    redirect_to talk_path(current_user.talk)
  end

  def set_talk
    @talk = Talk.find(params[:id])
  end

  def set_user
    @user = current_user.admin? ? @talk.user : current_user
  end

  def set_members
    @members = User.with_attached_avatar
                   .where(id: User.admins.ids.push(@talk.user_id))
                   .order(:id)
  end
end
