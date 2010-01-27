class ChangeColumnTypeTwitterIdToBigint < ActiveRecord::Migration
  def self.up
    change_column :post_histories, :tweet_id, "BIGINT"
  end

  def self.down
    change_column :post_histories, :tweet_id, :integer
  end
end
