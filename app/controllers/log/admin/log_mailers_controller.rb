class Log::Admin::LogMailersController < Log::Admin::BaseController
  before_action :set_log_mailer, only: [:show, :destroy]

  def index
    q_params = {}
    q_params.merge! params.permit(:mailer, :action, :mail_to)
    @log_mailers = LogMailer.default_where(q_params).page(params[:page])
  end

  def show
  end

  def destroy
    @log_mailer.destroy
  end

  private
  def set_log_mailer
    @log_mailer = LogMailer.find(params[:id])
  end

  def q_params
    params.fetch(:q, {}).permit!
  end

end
