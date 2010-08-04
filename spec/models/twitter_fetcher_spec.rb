require 'spec_helper'

describe TwitterFetcher do

  describe "#parent_id" do
    before do
      @tf = TwitterFetcher.new
    end
    subject { @tf.parent_id(@attr) }
    it "should return nil when is is not given" do
      @attr = nil
      should == nil
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
      @response.sho
      uld_receive(:retweeted_status).and_return(stub("rtweet", :id => 200))
      should == 200
    end
  end
end
