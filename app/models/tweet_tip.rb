class TweetTip < ActiveRecord::Base

  # Recipient/Sender is like the "Followings table"
  belongs_to :recipient, class_name: "User"
  belongs_to :sender, class_name: "User"

  validates :content, presence: true
  validates :screen_name, presence: true

  def build_link
    "https://twitter.com/#{self.screen_name}/status/#{self.api_tweet_id_str}"
  end

  def self.unclaimed(has_been: 21.days)
    unclaimed = self.where("created_at <= ?", has_been.ago).is_valid.not_refunded
  end

  def self.not_refunded
    self.where(tx_hash_refund: nil)
  end

  def self.is_valid
    self.where.not(tx_hash: nil).where.not(satoshis: nil)
  end

  def is_valid?
    !self.tx_hash.nil? && !self.satoshis.nil?
  end

end
