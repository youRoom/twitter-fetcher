namespace :cron do
  desc "Fetch twitter data / */15 * * * * cd /var/www/youroom/ && RAILS_ENV=production rake cron:fetch_from_twitter"
  task :fetch_from_twitter => :environment do
    Rails.logger.info "[cron START] Processing fetch twitter"
    TwitterFetcher.fetch_all
    Rails.logger.info "[cron END] done"
    Rails.logger.flush
  end
end
