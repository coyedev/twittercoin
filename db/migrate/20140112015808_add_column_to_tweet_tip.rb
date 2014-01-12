class AddColumnToTweetTip < ActiveRecord::Migration
  def change
    add_column :tweet_tips, :tx_hash_refund, :string
  end
end
