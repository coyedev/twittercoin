class Api::AccountController < ActionController::Base

  before_filter :build_account

  def index
    render json: @account
  end

  def withdraw
    ap params

    amount = params[:withdrawAmount].to_satoshis
    to_address = params[:toAddress]

    result = @user.withdraw(amount, to_address)

    @account[:balance] = (@account[:balance] - ((amount + FEE).to_BTCStr)).round(8)
    @account[:messages][:withdraw] = {
      default: false,
      success: true,
      error: false
    }

    render json: @account
  end

  protected

  def build_account
    # TODO: Add 401
    return unless session[:slug]

    @user = User.find_by(slug: session[:slug])
    @balance = @user.get_balance.to_BTCFloat
    @account = {
      messages: {
        welcome: true,
        deposit: @balance < MINIMUM_DEPOSIT.to_BTCFloat,
        withdraw: {
          default: true,
          success: false,
          error: false,
        }
      },
      deposit: {
        amount: MINIMUM_DEPOSIT.to_BTCFloat
      },
      screenName: @user.screen_name,
      address: @user.addresses.last.address,
      balance: @balance,
      minerFee: 0.0001
    }
  end

end
