namespace :cron do
  def task_with_logger_and_notify(*args, &block)
    new_block = proc {
      begin
        Rails.logger.info "[pid:#{Process.pid}][time:#{Time.now.to_s(:db)}][cron START] #{args.inspect}"

        yield if block_given?

        Rails.logger.info "[pid:#{Process.pid}][time:#{Time.now.to_s(:db)}][cron END] #{args.inspect}"
      rescue => e
        Rails.logger.error "[pid:#{Process.pid}][time:#{Time.now.to_s(:db)}][cron ERROR] #{e}"
        HoptoadNotifier.notify(e)
        raise e
      ensure
        Rails.logger.flush
      end
    }
    task(*args, &new_block)
  end

  desc "Fetch twitter data / */15 * * * * cd /var/www/youroom/ && RAILS_ENV=production rake cron:fetch_from_twitter"
  task_with_logger_and_notify :fetch_from_twitter => :environment do
    TwitterFetcher.fetch_all
  end
end
