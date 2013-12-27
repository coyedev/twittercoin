module Tweet::Message

  module Valid
    extend self

    def recipient(recipient, sender, amount)
      link = "www.tippercoin.com/#/profile/#{recipient}?direct=true&r=#{rand}"
      "@#{recipient}, @#{sender} just tipped you #{amount / SATOSHIS.to_f} BTC! "\
      "See it here #{link}"
    end

    def rand(limit: 2)
      SecureRandom.urlsafe_base64[0..limit]
    end
  end

  module Invalid
    extend self

    def unauthenticated(sender)
      link = "www.tippercoin.com/auth/twitter?r=#{rand}"
      "@#{sender}, to start tipping, please authenticate via twitter "\
      "and make a deposit. Thanks! #{link}"
    end

    def direct_tweet(sender)
      "@#{sender}, I'm just a bot, a humble servant bot. Please tweet @ScottyLi to talk to a human!"
    end

    def likely_missing_fee(sender)
      "@#{sender}, don't forget the 0.0001 BTC miner fee!."
    end

    # TODO: Include link with amount
    def not_enough_balance(sender)
      link = "www.tippercoin.com/auth/twitter?r=#{rand}"
      "@#{sender}, please top up on your account before sending this tip. #{link}"
    end

    def enough_confirmed_unspents(sender)
      link = "www.tippercoin.com/#/account/deposit?r=#{rand}"
      "@#{sender}, you don't have enough confirmed unspents, pls wait for a few mins! #{link}"
    end

    def negative_amount(sender)
      link = "www.tippercoin.com/#/documentation?r=#{rand}"
      "@#{sender}, You can't send negative amounts! #{link}"
    end

    def zero_amount(sender)
      link = "www.tippercoin.com/#/how-it-works?r=#{rand}"
      "@#{sender}, please tip 0.001 BTC or more. Refer to #{link}"
    end

    def unknown(sender)
      link = "www.tippercoin.com/#/how-it-works?r=#{rand}"
      "@#{sender}, sorry, I'm not sure what you meant :s. Please refer to #{link}"
    end

    def rand(limit: 2)
      SecureRandom.urlsafe_base64[0..limit]
    end

  end
end
