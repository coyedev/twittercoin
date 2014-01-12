namespace :pending do
  desc "Send out reminders to unauthenticated pending users with tips received"
  task reminders: :environment do
    Pending.reminders(dry: false)
  end

  desc "Refund senders who've tipped users who've not authenticated with 21 days"
  task refunds: :environment do
    Pending.refunds(dry: false)
  end

end
