class CreatePostHistories < ActiveRecord::Migration
  def self.up
    create_table :post_histories do |t|
      t.references :twitter_fetcher
      t.integer :entry_id, :null => false
      t.integer :tweet_id, :null => false
      t.timestamps
    end
    add_index :post_histories, :twitter_fetcher_id
    add_index :post_histories, :entry_id, :unique
  end

  def self.down
    drop_table :post_histories
  end
end
