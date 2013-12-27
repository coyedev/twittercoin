module Tweet::Extractor
  module Mentions
    extend self

    # Accept: String
    # Returns: Array or Strings, or nil
    def parse(content)
      usernames = content.scan(/@(\w+)/).flatten
      return [nil] if usernames.blank?
      return usernames
    end

  end

  module Amounts
    extend self

    ### Supported Currency Symbols:
    ### Order matters, higher means more priority
    SYMBOLS = [
      {
        name: :mBTC_SUFFIX,
        regex: /\s(\d*.?\d*)\s?mBTC/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS / MILLIBIT).to_i }
      },
      {
        name: :mBTC_PREFIX,
        regex: /mBTC\s?(\d*.?\d*)/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS / MILLIBIT).to_i }
      },
      {
        name: :BTC_SUFFIX,
        regex: /\s(\d*.?\d*)\s?BTC/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS).to_i}
      },
      {
        name: :bitcoin_SUFFIX,
        regex: /\s(\d*.?\d*)\s?bitcoin/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS).to_i}
      },
      {
        name: :BTC_SIGN,
        regex: /฿\s?(\d*.?\d*)/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS).to_i}
      },
      {
        name: :BTC_PREFIX,
        regex: /BTC\s?(\d*.?\d*)/i,
        satoshify: Proc.new {|n| (n.to_f * SATOSHIS).to_i}
      },
      {
        name: :USD,
        regex: /\s(\d*.?\d*)\s?USD/i,
        satoshify: Proc.new {|n| (n.to_f / Mtgox.latest * SATOSHIS).to_i }
      },
      {
        name: :dollar,
        regex: /\s(\d*.?\d*)\s?dollar/i,
        satoshify: Proc.new {|n| (n.to_f / Mtgox.latest * SATOSHIS).to_i }
      },
      {
        name: :USD_SIGN,
        regex: /\$\s?(\d*.?\d*)/i,
        satoshify: Proc.new {|n| (n.to_f / Mtgox.latest * SATOSHIS).to_i }
      },
      {
        name: :beer,
        regex: /\s(\d*.?\d*)\s?beer/i,
        satoshify: Proc.new {|n| (n.to_f * 4 / Mtgox.latest * SATOSHIS).to_i }
      },
      {
        name: :internet,
        regex: /\s(\d*.?\d*)\s?internet/i,
        satoshify: Proc.new {|n| (n.to_f * 1.337 / Mtgox.latest * SATOSHIS).to_i }
      }
    ]

    # Accept: String
    # Returns: Hash
    def parse(content)
      parse_all(content).each do |p|
        return p[0] if !p.blank? && !p[0][:satoshis].nil?
      end

      return {
        satoshis: nil,
        units: nil,
        symbol: nil
      }
    end

    # Accept: String
    # Returns: Array of arrays
    def parse_all(content)
      SYMBOLS.map do |sym|
        raw = content.scan(sym[:regex]).flatten
        raw.map do |r|
          satoshis = sym[:satoshify].call(r) if r.is_number?
          {
            satoshis: satoshis,
            units: r.strip.to_f,
            symbol: sym[:name]
          }
        end
      end
    end

  end
end
