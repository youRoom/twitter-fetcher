require 'spec_helper'

describe TwitterFetcher do

  describe "#parent_topic_id" do
    before do
      @tf = TwitterFetcher.create!(:setting_type => "type", :setting_value => "option", :access_token => "at", :access_token_secret => "ats", :skip_fetching => true)
      @tf.stub(:root_topic_id).and_return(50)
    end
    subject { @tf.parent_topic_id(@attr) }

    it "should return root_topic_id when it is not given" do
      @attr = nil
      should == 50
    end

    it "should return root_topic_id when given tweet does not have parent" do
      @attr = 1
      @tf.stub(:parent_tweet_id).and_return(nil)
      should == 50
    end

    it "should return entry_id when the tweet has parent tweet" do
      @attr = 1
      post_entry = PostHistory.new(:entry_id => 10)
      @tf.stub(:parent_tweet_id).and_return(100)
      @tf.stub_chain(:post_histories, :find_by_tweet_id => post_entry)
      should == 10
    end
  end

  describe "#parent_tweet_id" do
    before do
      @tf = TwitterFetcher.new
      @response = stub("response", :is_a? => true, :in_reply_to_status_id => nil, :retweeted_status => nil)
      @client = stub("client", :status => @response)
      @tf.stub(:client_by_twitter).and_return(@client)
      @arg = 1
    end
    subject { @tf.parent_tweet_id(@arg) }
    it "should be nil when tweet have no parent" do
      should == nil
    end

    it "should return in_reply_status_id when it is reply" do
      @response.should_receive(:in_reply_to_status_id).and_return(100)
      should == 100
    end

    it "should return retweeted_status's id when it is retweeted" do
      @response.should_receive(:retweeted_status).and_return(stub("rtweet", :id => 200))
      should == 200
    end
  end
end
