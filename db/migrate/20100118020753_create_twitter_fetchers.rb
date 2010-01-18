class CreateTwitterFetchers < ActiveRecord::Migration
  def self.up
    create_table :twitter_fetchers do |t|
      t.integer :group_id
      t.text :setting_option
      t.string :since_id

      t.timestamps
    end
  end

  def self.down
    drop_table :twitter_fetchers
  end
end
