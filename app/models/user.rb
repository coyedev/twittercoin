class User < ActiveRecord::Base

  # Similar to a "Followings table"
  has_many :tips_received, class_name: "TweetTip", foreign_key: "recipient_id"
  has_many :tips_given, class_name: "TweetTip", foreign_key: "sender_id"

  has_many :addresses

  validates :screen_name, uniqueness: { case_sensitive: false }, presence: true

  def self.unauthenticated
    self.where(authenticated: false)
  end

  def self.unauthenticated_with_tips
    # TODO: remove n + 1 triggered by valid/count
    self.unauthenticated.select do |u|
      u.tips_received.is_valid.count > 0
    end
  end

  def reminded_recently(less_than: 3.days)
    self.reminded_at && self.reminded_at > less_than.ago
  end

  def all_tips
    (self.tips_received.is_valid + self.tips_given.is_valid).sort_by { |t| t.created_at }.reverse
  end

  def self.find_profile(screen_name)
    user = User.find_by("screen_name ILIKE ?", screen_name)
    return if user.blank?
    return if user.addresses.blank?
    return user
  end

  def self.create_profile(screen_name)
    return if screen_name.nil?
    user = User.find_or_create_by(screen_name: screen_name)
    user.slug ||= SecureRandom.hex(8)

    user.save

    user.addresses.create(BitcoinAPI.generate_address)
    return user
  end

  def current_address
    self.addresses.last.address
  end

  def get_balance
    info = BitcoinAPI.get_info(self.current_address)
    info["final_balance"]
  end

  def likely_missing_fee?(amount)
    return false if amount.nil?

    balance = get_balance
    difference = balance - amount

    return true if difference >= 0 && difference < FEE
    return false

  end

  def enough_balance?(amount)
    return false if amount.nil?
    get_balance >= amount + FEE
  end

  def enough_confirmed_unspents?(amount)
    begin
      BitcoinAPI.get_unspents(self.current_address, amount + FEE)
      return true
    rescue Exception => e
      ap e.inspect
      return false
    end
  end

  def withdraw(amount, to_address)
    BitcoinAPI.send_tx(
      self.addresses.last,
      to_address,
      amount)
    return true
  end

end
