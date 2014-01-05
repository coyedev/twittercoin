require 'spec_helper'

describe Tweet::Parser do
  let(:sender) { "sender" }

  let(:btc_usd) { 695.0 }

  before(:each) do
    Mtgox.stub(:latest).and_return(695.0)
  end

  context "Basic: " do

    before(:each) do
      content = "@recipient, really good article, keep it up! Here's a tip 0.001 BTC @tippercoin"
      @t = Tweet::Parser.new(content, sender)
    end

    it "should return the correct bot(tippercoin)" do
      expect(Tweet::Parser::BOT).to eq("tippercoin")
    end

    it "should not return recipient to be @tippercoin" do
      expect(@t.recipient).to_not be("tippercoin")
    end

    it "should return mentions as array" do
      expect(@t.mentions.class).to be(Array)
    end

    it "should return amount as hash" do
      expect(@t.amount.class).to be(Hash)
    end

    it "should return the correct sender" do
      expect(@t.sender).to eq("sender")
    end

    it "should return the correct value" do
      amount = 100000
      expect(@t.satoshis).to eq(amount)
    end

  end

  context "Multiple Recipients OR Amounts: " do

    before(:each) do
      content = "@recipient1, @recipient2, really good article, keep it up!
      Here's a tip 0.001 BTC but not 1 BTC @tippercoin"
      @t = Tweet::Parser.new(content, sender)
    end

    it "should identify multiple recipients" do
      expect(@t.multiple_recipients?).to eq(true)
    end

    it "should take the first recipient to be the real recipient" do
      expect(@t.recipient).to eq("recipient1")
      expect(@t.recipient).to_not eq("recipient2")
    end

    it "should take the first amount to be the real amount" do
      expect(@t.satoshis).to be(100_000)
    end
  end

  context "Invalid Tweet: " do
    it "should contain an invalid attribute for invalid tweet" do
      content = "@recipient does this btc thing actually work? @tippercoin"
      t = Tweet::Parser.new(content, sender)
      expect(t.valid?).to eq(false)
      expect(t.likely_forgot_symbol?).to eq(false)
    end

    it "should be invalid if BOT is specified as first recipient" do
      content = "@tippercoin, @BrookeInVegas I still can't get anyone to accept a
      BitCoin. My first follower to request one, gets one (only if u r new 2 BTC)"
      t = Tweet::Parser.new(content, sender)
      expect(t.valid?).to eq(false)
      expect(t.direct_tweet?).to eq(true)
    end

    it "should be invalid if amount is zero" do
      content = "@recipient1 really good article, keep it up! Here's a tip 0.000 BTC @tippercoin"
      t = Tweet::Parser.new(content, sender)
      expect(t.valid?).to eq(false)
      expect(t.satoshis).to eq(0)
    end

    it "should be invalid if sender is @tippercoin" do
      content = "@locksley someone just give yo ass 0.01 BTC, take it man!"
      sender = "tippercoin"
      t = Tweet::Parser.new(content, sender)
      expect(t.valid?).to eq(false)
    end

    it "should be invalid if sender is @tippercoin" do
      content = "@pmarreck Tip 0.0019 @tippercoin"
      content2 = "@djmsg Yo son, catch some coin! .001 #tippercoin"
      sender = "tippercoin"
      t = Tweet::Parser.new(content, sender)
      t2 = Tweet::Parser.new(content2, sender)
      expect(t.valid?).to eq(false)
      expect(t.likely_forgot_symbol?).to eq(true)
      expect(t2.valid?).to eq(false)
      expect(t2.likely_forgot_symbol?).to eq(true)
    end

  end

  context "Suffix Symbols: " do

    let(:beer) { 4 }
    let(:internet) { 1.337 }


    it "should extract/convert BTC to SATOSHIS" do
      content1 = "@recipient, really good article, keep it up! Here's a tip 0.041 BTC @tippercoin"
      # value = 0.041 * 100_000_000
      t1 = Tweet::Parser.new(content1, sender)
      expect(t1.satoshis).to eq(4_100_000)

      content2 = "@recipient, really good article, keep it up! Here's a tip 2 BTC @tippercoin"
      t2 = Tweet::Parser.new(content2, sender)
      expect(t2.satoshis).to eq(200_000_000)
    end

    it "should extract/convert bitcoin in SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's 0.01 Bitcoins @tippercoin"
      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(1_000_000)
    end

    it "should extract/convert mBTC to SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's a tip 5 mBTC @tippercoin"
      t = Tweet::Parser.new(content, sender)
      # value = 5 * 100_000_000 / 1000
      expect(t.satoshis).to eq(500_000)
    end

    it "should extract/convert USD to SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's a tip 5 USD @tippercoin"

      satoshis = ((5 / btc_usd) * SATOSHIS).to_i
      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(satoshis)
    end

    it "should extract/convert dollars to SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's a tip 5 dollars @tippercoin"

      satoshis = ((5 / btc_usd) * SATOSHIS).to_i
      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(satoshis)
    end


    it "should extract/convert beers to SATOSHIS" do
      content1 = "@recipient, really good article, keep it up! Here's a tip 2 beers @tippercoin"

      satoshis = (((2 * beer) / btc_usd) * SATOSHIS).to_i
      t1 = Tweet::Parser.new(content1, sender)
      expect(t1.satoshis).to eq(satoshis)

      content2 = "@recipient good work on the app, buy a beer! 1 Beer #tippercoin"

      satoshis2 = (((1 * beer) / btc_usd) * SATOSHIS).to_i
      t2 = Tweet::Parser.new(content2, sender)
      expect(t2.satoshis).to eq(satoshis2)
    end

    it "should extract/convert beers to SATOSHIS" do
      shatner = 0.001701

      content1 = "@recipient, nice job. Here's 1 shatner @tippercoin"
      satoshis = (shatner * SATOSHIS).to_i
      t1 = Tweet::Parser.new(content1, sender)
      expect(t1.satoshis).to eq(satoshis)

      content2 = "@recipient! 2 shatners #tippercoin"

      satoshis2 = (2 * shatner * SATOSHIS).to_i
      t2 = Tweet::Parser.new(content2, sender)
      expect(t2.satoshis).to eq(satoshis2)
    end

    it "should extract/convert internets to SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's a tip 5 internets @tippercoin"

      satoshis = (((5 * internet) / btc_usd) * SATOSHIS).to_i
      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(satoshis)
    end

    it "should extract both upper/lowercases of suffix symbols" do
      content1 = "@recipient, really good article, keep it up! Here's a tip 0.041 BTC @tippercoin"
      t1 = Tweet::Parser.new(content1, sender)

      content2 = "@recipient, really good article, keep it up! Here's a tip 0.041 btc @tippercoin"
      t2 = Tweet::Parser.new(content2, sender)

      expect(t1.satoshis).to eq(4_100_000)
      expect(t2.satoshis).to eq(4_100_000)
    end

    it "should prefer suffix btc/BTC if multiple currency symbols" do
      content = "@recipient, really good article, keep it up! Here's a tip $ 0.01 BTC @tippercoin"

      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(1_000_000)
    end

  end

  context "Prefix Symbols: " do
    it "should extract/convert ฿ to SATOSHIS" do
      content1 = "@recipient, really good article, keep it up! Here's a tip ฿0.041 @tippercoin"
      t1 = Tweet::Parser.new(content1, sender)
      expect(t1.satoshis).to eq(4_100_000)

      content2 = "@recipient, really good article, keep it up! Here's a tip ฿2 @tippercoin"
      t2 = Tweet::Parser.new(content2, sender)
      expect(t2.satoshis).to eq(200_000_000)
    end

    it "should extract/convert $ to SATOSHIS" do
      content = "@recipient, really good article, keep it up! Here's a tip $ 3 @tippercoin"

      satoshis = ((3  / btc_usd) * SATOSHIS).to_i
      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(satoshis)
    end

    it "should extract/convert when BTC is prefixed" do
      content1 = "@recipient, really good article, keep it up! Here's a tip BTC 0.01 @tippercoin"
      t1 = Tweet::Parser.new(content1, sender)
      expect(t1.satoshis).to eq(1_000_000)

      content2 = "@recipient, really good article, keep it up! Here's a tip mBTC8 @tippercoin"
      t2 = Tweet::Parser.new(content2, sender)
      expect(t2.satoshis).to eq(800_000)
    end

    it "should prefer prefix btc/BTC over other multiple currency symbols" do
      content = "@recipient, really good article, keep it up! Here's a tip BTC 0.01 USD @tippercoin"

      t = Tweet::Parser.new(content, sender)
      expect(t.satoshis).to eq(1_000_000)

    end

  end

  context "Raw values" do
    before(:each) do
      content = "@person have 1 beer #tippercoin"
      @t = Tweet::Parser.new(content, sender)
    end

    it "should return unit 1 " do
      expect(@t.units).to eq(1.0)
    end

    it "should return symbol beer" do
      expect(@t.symbol).to eq(:beer)
    end

  end

  context "screen_name contains number" do

    contents = [
      "@person123 1 beer #tippercoin",
      "@person123 1 usd #tippercoin",
      "@person123 1 BTC #tippercoin",
      "@person123 1 bitcoin #tippercoin",
      "@person123 1 internet #tippercoin",
    ]

    contents.each_with_index do |c, index|
      it "content: #{index}" do
        t = Tweet::Parser.new(c, "sender")
        # TODO: expect(t.satoshis).to eq(something)
        expect(t.satoshis).to_not eq(nil)
      end
    end
  end

end

describe 'Tweet::Parser Bulk Check' do

  # Hard coded satoshis, values reflected in tweets_spacing
  let(:satoshis) { 1_000_000}
  let(:sender) { "sender" }

  before(:each) do
    Mtgox.stub(:latest).and_return(695.0)
  end

  # Make sure contents are parsed regardless of spacing between prefix/prefix
  context "Spacing" do
    TWEETS = File.open("spec/tweet_examples/tweets_spacing").read.split("\n").compact

    TWEETS.each_with_index do |content, index|
      it "line num: #{index}" do
        t = Tweet::Parser.new(content, sender)
        expect(t.satoshis).to eq(satoshis)
      end
    end
  end

end
