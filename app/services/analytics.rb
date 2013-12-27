class Analytics

  attr_accessor :data

  def initialize
    @failed_tweet_tips = TweetTip.where(tx_hash: nil)
    @data = []
  end

  def parse
    @failed_tweet_tips.each do |t|
      puts t.content
      handler = Tweet::Handler.new(
        content: t.content,
        sender: t.sender.screen_name)
      handler.check_validity
      ap handler.state.to_s
      puts "\n"
      @data << {
        content: handler.content,
        state: handler.state.to_s
      }
    end

    return false
  end

  def to_json
    File.open("log/new_errors.json", "w+") do |file|
      file.write(@data.to_json)
      file.close
    end
  end

  def to_csv
    File.open("log/new_errors.csv", "w+") do |file|
      csv_string = CSV.generate do |csv|
        @data.each do |hash|
          csv << hash.values
        end
      end

      file.write(csv_string)
      file.close
    end
  end

end
