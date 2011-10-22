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

      c.should be_an_instance_of Gitolite::Config
      c.repos.should_not be nil
      c.repos.length.should be 0
      c.groups.should_not be nil
      c.groups.length.should be 0
      c.filename.should == "gitolite.conf"
    end

    it 'should create a valid, blank Gitolite::Config with the given filename' do
      filename = "test.conf"
      c = Gitolite::Config.init(filename)

      c.should be_an_instance_of Gitolite::Config
      c.repos.should_not be nil
      c.repos.length.should be 0
      c.groups.should_not be nil
      c.groups.length.should be 0
      c.filename.should == filename
    end
  end

  describe "repo management" do
    before :each do
      @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
    end

    describe "#get_repo" do
      it 'should fetch a repo by a string containing the name' do
        @config.get_repo('gitolite').should be_an_instance_of Gitolite::Config::Repo
      end

      it 'should fetch a repo via a symbol representing the name' do
        @config.get_repo(:gitolite).should be_an_instance_of Gitolite::Config::Repo
      end

      it 'should return nil for a repo that does not exist' do
        @config.get_repo(:glite).should be nil
      end
    end

    describe "#has_repo?" do
      it 'should return false for a repo that does not exist' do
        @config.has_repo?(:glite).should be false
      end

      it 'should check for the existance of a repo given a repo object' do
        r = @config.repos["gitolite"]
        @config.has_repo?(r).should be true
      end

      it 'should check for the existance of a repo given a string containing the name' do
        @config.has_repo?('gitolite').should be true
      end

      it 'should check for the existance of a repo given a symbol representing the name' do
        @config.has_repo?(:gitolite).should be true
      end
    end

    describe "#add_repo" do
      it 'should throw an ArgumentError for non-Gitolite::Config::Repo objects passed in' do
        lambda{ @config.add_repo("not-a-repo") }.should raise_error(ArgumentError)
      end

      it 'should add a given repo to the list of repos' do
        r = Gitolite::Config::Repo.new('cool_repo')
        nrepos = @config.repos.size
        @config.add_repo(r)

        @config.repos.size.should == nrepos + 1
        @config.has_repo?(:cool_repo).should be true
      end

      it 'should merge a given repo with an existing repo' do
        #Make two new repos
        repo1 = Gitolite::Config::Repo.new('cool_repo')
        repo2 = Gitolite::Config::Repo.new('cool_repo')

        #Add some perms to those repos
        repo1.add_permission("RW+", "", "bob", "joe", "sam")
        repo1.add_permission("R", "", "sue", "jen", "greg")
        repo1.add_permission("-", "refs/tags/test[0-9]", "@students", "jessica")
        repo1.add_permission("RW", "refs/tags/test[0-9]", "@teachers", "bill", "todd")
        repo1.add_permission("R", "refs/tags/test[0-9]", "@profs")

        repo2.add_permission("RW+", "", "jim", "cynthia", "arnold")
        repo2.add_permission("R", "", "daniel", "mary", "ben")
        repo2.add_permission("-", "refs/tags/test[0-9]", "@more_students", "stephanie")
        repo2.add_permission("RW", "refs/tags/test[0-9]", "@student_teachers", "mike", "judy")
        repo2.add_permission("R", "refs/tags/test[0-9]", "@leaders")

        #Add the repos
        @config.add_repo(repo1)
        @config.add_repo(repo2)

        #Make sure perms were properly merged
      end

      it 'should overwrite an existing repo when overwrite = true' do
        #Make two new repos
        repo1 = Gitolite::Config::Repo.new('cool_repo')
        repo2 = Gitolite::Config::Repo.new('cool_repo')

        #Add some perms to those repos
        repo1.add_permission("RW+", "", "bob", "joe", "sam")
        repo1.add_permission("R", "", "sue", "jen", "greg")
        repo2.add_permission("RW+", "", "jim", "cynthia", "arnold")
        repo2.add_permission("R", "", "daniel", "mary", "ben")

        #Add the repos
        @config.add_repo(repo1)
        @config.add_repo(repo2, true)

        #Make sure repo2 overwrote repo1
      end
    end

    describe "#rm_repo" do
      it 'should remove a repo for the Gitolite::Config::Repo object given' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo(r)
        r2.name.should == r.name
        r2.permissions.length.should == r.permissions.length
        r2.owner.should == r.owner
        r2.description.should == r.description
      end

      it 'should remove a repo given a string containing the name' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo('gitolite')
        r2.name.should == r.name
        r2.permissions.length.should == r.permissions.length
        r2.owner.should == r.owner
        r2.description.should == r.description
      end

      it 'should remove a repo given a symbol representing the name' do
        r = @config.get_repo(:gitolite)
        r2 = @config.rm_repo(:gitolite)
        r2.name.should == r.name
        r2.permissions.length.should == r.permissions.length
        r2.owner.should == r.owner
        r2.description.should == r.description
      end
    end
  end

  describe "group management" do
    before :each do
      @config = Gitolite::Config.new(File.join(conf_dir, 'complicated.conf'))
    end

    describe "#has_group?" do
      it 'should find the staff group using a symbol' do
        @config.has_group?(:staff).should be true
      end

      it 'should find the staff group using a string' do
       @config.has_group?('staff').should be true
      end

      it 'should find the staff group using a Gitolite::Config::Group object' do
        g = Gitolite::Config::Group.new("staff")
        @config.has_group?(g).should be true
      end
    end

    describe "#get_group" do
      it 'should return the Gitolite::Config::Group object for the group name String' do
        g = @config.get_group("staff")
        g.is_a?(Gitolite::Config::Group).should be true
        g.size.should == 6
      end

      it 'should return the Gitolite::Config::Group object for the group name Symbol' do
        g = @config.get_group(:staff)
        g.is_a?(Gitolite::Config::Group).should be true
        g.size.should == 6
      end
    end

    describe "#add_group" do
      it 'should throw an ArgumentError for non-Gitolite::Config::Group objects passed in' do
        lambda{ @config.add_group("not-a-group") }.should raise_error(ArgumentError)
      end

      it 'should add a given group to the groups list' do
        g = Gitolite::Config::Group.new('cool_group')
        ngroups = @config.groups.size
        @config.add_group(g)
        @config.groups.size.should be ngroups + 1
        @config.has_group?(:cool_group).should be true
      end

    end

    describe "#rm_group" do
      it 'should remove a group for the Gitolite::Config::Group object given' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group(g)
        g.should_not be nil
        g2.name.should == g.name
      end

      it 'should remove a group given a string containing the name' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group('oss_repos')
        g2.name.should == g.name
      end

      it 'should remove a group given a symbol representing the name' do
        g = @config.get_group(:oss_repos)
        g2 = @config.rm_group(:oss_repos)
        g2.name.should == g.name
      end
    end

  end

  describe "#to_file" do
    it 'should create a file at the given path with the config\'s file name' do
      c = Gitolite::Config.init
      file = c.to_file('/tmp')
      File.file?(File.join('/tmp', c.filename)).should be true
      File.unlink(file)
    end

    it 'should create a file at the given path when a different filename is specified' do
      filename = "test.conf"
      c = Gitolite::Config.init
      c.filename = filename
      file = c.to_file('/tmp')
      File.file?(File.join('/tmp', filename)).should be true
      File.unlink(file)
    end

    it 'should raise an ArgumentError when an invalid path is specified' do
      c = Gitolite::Config.init
      lambda { c.to_file('/does/not/exist') }.should raise_error(ArgumentError)
    end

    it 'should raise an ArgumentError when a filename is specified in the path' do
      c = Gitolite::Config.init
      lambda{ c.to_file('/home/test.rb') }.should raise_error(ArgumentError)
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
