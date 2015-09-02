class ProvidersController < ApplicationController
  before_action :authenticate_user!

  def index
    @providers_accounts = current_user.provider_accounts
  end

  def create
    @provider_account = ProviderAccount.new(provider_account_params)
    if request.post?
      @provider_account.user = current_user
      redirect_to action: :index if @provider_account.save!
    end
  end

  def edit
    @provider_account = ProviderAccount.find(params[:id])
    if request.patch?
      redirect_to action: :index if @provider_account && @provider_account.update_attributes!(provider_account_params)
    end
  end

  def destroy
    current_user.provider_accounts.find(params[:id]).destroy
    redirect_to :back
  end

  private

  def provider_account_params
    params.require(:provider_account)
      .permit(:name, :address, :protocol, :port, :enable_ssl, :login, :password) if params[:provider_account]
  end
end
