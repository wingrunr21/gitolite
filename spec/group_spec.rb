require 'gitolite/config/group'
require 'spec_helper'

describe Gitolite::Config::Group do
  describe "#new" do
    it "should create a new group with an empty list of users" do
      group = Gitolite::Config::Group.new("testgroup")
      group.users.empty?.should be true
      group.name.should == "testgroup"
    end

    it "should create a new group with a name containing #{Gitolite::Config::Group::PREPEND_CHAR}" do
      name = "#{Gitolite::Config::Group::PREPEND_CHAR}testgroup"
      group = Gitolite::Config::Group.new(name)
      group.name.should == "testgroup"
    end
  end

  describe "users" do
    before :each do
      @group = Gitolite::Config::Group.new('testgroup')
    end

    describe "#add_user" do
      it "should allow adding one user with a string" do
        @group.add_user("bob")
        @group.size.should == 1
        @group.users.first.should == "bob"
      end

      it "should allow adding one user with a symbol" do
        @group.add_user(:bob)
        @group.size.should == 1
        @group.users.first.should == "bob"
      end

      it "should not add the same user twice" do
        @group.add_user("bob")
        @group.size.should == 1
        @group.add_user(:bob)
        @group.size.should == 1
        @group.users.first.should == "bob"
      end

      it "should maintain users in sorted order" do
        @group.add_user("susan")
        @group.add_user("peyton")
        @group.add_user("bob")
        @group.users.first.should == "bob"
        @group.users.last.should == "susan"
      end
    end

    describe "#add_users" do
      it "should allow adding multiple users at once" do
        @group.add_users("bob", "joe", "sue", "sam", "dan")
        @group.size.should == 5
      end

      it "should allow adding multiple users in nested arrays" do
        @group.add_users(["bob", "joe", ["sam", "sue", "dan"]], "bill")
        @group.size.should == 6
      end

      it "should allow adding users of symbols and strings" do
        @group.add_users("bob", :joe, :sue, "sam")
        @group.size.should == 4
      end

      it "should not add the same user twice" do
        @group.add_users("bob", :bob, "bob", "sam")
        @group.size.should == 2
      end
    end

    describe "#rm_user" do
      before :each do
        @group.add_users("bob", "joe", "susan", "sam", "alex")
      end

      it "should support removing a user via a String" do
        @group.rm_user("bob")
        @group.size.should == 4
      end

      it "should support removing a user via a Symbol" do
        @group.rm_user(:bob)
        @group.size.should == 4
      end
    end

    describe "#empty!" do
      it "should clear all users from the group" do
        @group.add_users("bob", "joe", "sue", "jim")
        @group.size.should == 4
        @group.empty!
        @group.size.should == 0
      end
    end

    describe "#size" do
      it "should reflect how many users are in the group" do
        @group.add_users("bob", "joe", "sue", "jim")
        @group.users.length.should == @group.size
      end
    end

    describe "#has_user?" do
      it "should search for a user via a String" do
        @group.add_user("bob")
        @group.has_user?("bob").should be true
      end

      it "should search for a user via a Symbol" do
        @group.add_user(:bob)
        @group.has_user?(:bob).should be true
      end
    end
  end

  describe "#to_s" do
    group = Gitolite::Config::Group.new("testgroup")
    group.add_users("bob", "joe", "sam", "sue")
    group.to_s.should == "@testgroup          = bob joe sam sue\n" #10 spaces after @testgroup
  end
end
