class PostHistory < ActiveRecord::Base
  belongs_to :twitter_fetcher

  validates_presence_of :entry_id, :tweet_id
  validates_uniqueness_of :entry_id
end
