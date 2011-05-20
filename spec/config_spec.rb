require 'gitolite/config'
require 'spec_helper'

describe Gitolite::Config do
  conf_dir = File.join(File.dirname(__FILE__),'configs')

  describe "#new" do
    it 'should read a simple configuration' do
      c = Gitolite::Config.new(File.join(conf_dir, 'simple.conf'))
      c.repos.length.should == 2
      c.groups.length.should == 0
    end

    it 'should read a complex configuration' do
      c = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      c.groups.length.should == 5
      c.repos.length.should == 12
    end

    describe 'gitweb operations' do
      before :all do
        @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
      end

      it 'should correctly read gitweb options for an existing repo' do
        r = @config.get_repo('gitolite')
        r.owner.should == "Sitaram Chamarty"
        r.description.should == "fast, secure, access control for git in a corporate environment"
      end

      it 'should correctly read a gitweb option with no owner for an existing repo' do
        r = @config.get_repo('foo')
        r.owner.should be nil
        r.description.should == "Foo is a nice test repo"
      end

      it 'should correctly read gitweb options for a new repo' do
        r = @config.get_repo('foobar')
        r.owner.should == "Bob Zilla"
        r.description.should == "Foobar is top secret"
      end

      it 'should correctly read gitweb options with no owner for a new repo' do
        r = @config.get_repo('bar')
        r.owner.should be nil
        r.description.should == "A nice place to get drinks"
      end

      it 'should raise a ParseError when a description is not specified' do
        t = Tempfile.new('bad_conf.conf')
        t.write('gitolite "Bob Zilla"')
        t.close

        lambda { Gitolite::Config.new(t.path) }.should raise_error(Gitolite::Config::ParseError)

        t.unlink
      end

      it 'should raise a ParseError when a Gitweb description is specified for a group' do
        t = Tempfile.new('bad_conf.conf')
        t.write('@gitolite "Bob Zilla" = "Test description"')
        t.close

        lambda { Gitolite::Config.new(t.path) }.should raise_error(Gitolite::Config::ParseError)

        t.unlink
      end
    end
  end

  describe "#init" do
    it 'should create a valid, blank Gitolite::Config' do
      c = Gitolite::Config.init
      c.repos.should_not be nil
      c.repos.length.should be 0
      c.groups.should_not be nil
      c.groups.length.should be 0
    end
  end

  describe "repo management" do
    describe "#get_repo" do
    end

    describe "#has_repo?" do
    end

    describe "#add_repo" do
    end

    describe "#rm_repo" do
    end
  end

  describe "#to_file" do
  end

  describe "deny rules" do
    it 'should maintain the order of rules within a config file' do
    end
  end

  describe "#cleanup_config_line" do
    before(:each) do
      @config = Gitolite::Config.init
    end

    it 'should remove comments' do
      s = "#comment"
      @config.instance_eval { cleanup_config_line(s) }.empty?.should == true
    end

    it 'should remove inline comments, keeping content before the comment' do
      s = "blablabla #comment"
      @config.instance_eval { cleanup_config_line(s) }.should == "blablabla"
    end

    it 'should pad = with spaces on each side' do
      s = "bob=joe"
      @config.instance_eval { cleanup_config_line(s) }.should == "bob = joe"
    end

    it 'should replace multiple space characters with a single space' do
      s = "bob       =        joe"
      @config.instance_eval { cleanup_config_line(s) }.should == "bob = joe"
    end

    it 'should cleanup whitespace at the beginning and end of lines' do
      s = "            bob = joe            "
      @config.instance_eval { cleanup_config_line(s) }.should == "bob = joe"
    end

    it 'should cleanup whitespace and comments effectively' do
      s = "            bob     =     joe             #comment"
      @config.instance_eval { cleanup_config_line(s) }.should == "bob = joe"
    end
  end
end