module Pending
  extend self

  def reminders(dry: true)
    recipients = User.unauthenticated_with_tips

    recipients.each do |recipient|
      begin
        next if recipient.reminded_recently(less_than: 3.days)

        unclaimed = recipient.tips_received.unclaimed(has_been: 20.days)
        next if unclaimed.blank?

        senders = unclaimed.map {|u| u.sender }
        # senders_names = senders.map {|s| s.screen_name}
        senders_amount = unclaimed.sum(:satoshis) / SATOSHIS.to_f

        message = Tweet::Message::Pending.reminder(
          recipient.screen_name,
          senders_amount
        )

        ap message
        if !dry
          TWITTER_CLIENT.update(message)

          recipient.reminded_at = Time.now
          recipient.save
        end

      rescue Exception => e
        ap e.inspect
        ap e.backtrace

        CriticalError.new("Error in reminders: #{e.inspect}", {
          inspect: e.inspect,
          backtrace: e.backtrace
        })

        next
      end

      sleep 10 if !dry
    end
  end

  def refunds(dry: true)
    recipients = User.unauthenticated_with_tips

    recipients.each do |recipient|
      begin
        unclaimed = recipient.tips_received.unclaimed(has_been: 21.days)
        unclaimed.each do |tip|
          refund_amount = tip.satoshis - FEE

          ap tip.content
          ap tip.satoshis
          ap refund_amount

          if !dry
            tx = BitcoinAPI.send_tx(
              recipient.addresses.last,
              tip.sender.addresses.last.address,
              refund_amount)

            tip.tx_hash_refund = tx

            tip.save
          end

          sleep 10 if !dry
        end
      rescue Exception => e
        ap e.inspect
        ap e.backtrace

        CriticalError.new("Error in refunds: #{e.inspect}", {
          inspect: e.inspect,
          backtrace: e.backtrace
        })

        next
      end

      sleep 10 if !dry

    end
  end
end
