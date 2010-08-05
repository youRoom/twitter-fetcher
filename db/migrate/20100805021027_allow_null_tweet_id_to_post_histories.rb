class AllowNullTweetIdToPostHistories < ActiveRecord::Migration
  def self.up
    change_column :post_histories, :tweet_id, :integer, :limit => 8, :null => true
  end

  def self.down
    change_column :post_histories, :tweet_id, :integer, :null => false
  end
end
