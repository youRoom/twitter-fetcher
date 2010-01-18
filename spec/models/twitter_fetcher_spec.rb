require 'spec_helper'

describe TwitterFetcher do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    TwitterFetcher.create!(@valid_attributes)
  end
end
