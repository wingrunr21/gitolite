describe Gitolite::Config do
  conf_dir = File.join(File.dirname(__FILE__),'configs')

  describe "Subconfig managment" do
    before :each do
      @root_config = Gitolite::Config.load_from(File.join(conf_dir, 'subconfs.conf'))
      @root_config.has_subconf?('bar.conf').should == true
      @bar_config =  @root_config.get_subconf 'bar.conf'
    end

    describe '#new' do
      it 'should has a sub-configuration' do
        @root_config.subconfs.length.should == 1
        @root_config.has_subconf?('bar.conf').should == true
        bar = @root_config.get_subconf 'bar.conf'
        bar.class.should == Gitolite::Config
        bar.groups.length.should == 1
        bar.parent.should be @root_config
        bar.subconfs.length.should == 0
      end

      it 'should has a repos in subconf' do
          r = @bar_config.get_repo('bar')
          r.owner.should == "Mkie LEE"
          r.description.should == "This is a cool bar."
      end


      it 'should raise error when subconfig recursive include' do
        expect{Gitolite::Config.load_from(File.join(conf_dir, 'sparent.conf'))}.to raise_error(Gitolite::Config::ParseError)
      end
    end

    describe "#get_relative_path" do
      it 'should get proper key from file' do
        f = File.join(conf_dir, 'bar.conf')
        @root_config.get_relative_path(f).should == 'bar.conf'
        @root_config.normalize_config_name('bar.conf').should == 'bar.conf'
        @root_config.subconfs.has_key?('bar.conf').should be true
        @root_config.subconfs.has_key?(@root_config.get_relative_path('bar.conf')).should be true
        @root_config.has_subconf?('bar.conf').should == true
        @root_config.has_subconf?(f).should == true
      end
    end

    describe '#get_subconf' do
      it 'should fetch a subconf by a string containing the relatived filename' do
        @root_config.get_subconf('bar.conf').should be_an_instance_of Gitolite::Config
      end

      it 'should fetch a subconf by a string containing the absoluted filename' do
        f = File.join(conf_dir, 'bar.conf')
        @root_config.get_subconf(f).should be_an_instance_of Gitolite::Config
      end

      it 'should fetch a subconf via a symbol representing the name' do
        @root_config.get_subconf(:'bar.conf').should be_an_instance_of Gitolite::Config
      end

      it 'should return nil for a subconf that does not exist' do
        @root_config.get_subconf(:none).should be nil
      end
    end

    describe "#has_subconf?" do
      it 'should return false for a subconf that does not exist' do
        @root_config.has_subconf?(:none).should be false
      end

      it 'should check for the existance of a subconf given a subconf object' do
        r = @root_config.get_subconf("bar.conf")
        @root_config.has_subconf?(r).should be true
      end

      it 'should check for the existance of a subconf given a string containing the name' do
        @root_config.has_subconf?('bar.conf').should be true
      end

      it 'should check for the existance of a subconf given a symbol representing the name' do
        @root_config.has_subconf?(:'bar.conf').should be true
      end
    end

    describe "#add_subconf" do
      it 'should throw an ArgumentError for non-Gitolite::Config objects passed in' do
        lambda{ @root_config.add_subconf("not-a-config") }.should raise_error(ArgumentError)
      end

      it 'should add a given conf to the list of subconfs' do
        r = Gitolite::Config.new('cool_config')
        n = @root_config.subconfs.size
        @root_config.add_subconf(r)

        @root_config.subconfs.size.should == n + 1
        @root_config.has_subconf?(:cool_config).should be true
      end
    end
    
    describe "#parent=" do
      it 'should raise a ConfigDependencyError if there is a cyclic dependency' do
        c = Gitolite::Config.init
        c.filename = "test_deptree.conf"
        s = Gitolite::Config.new "subconf1.conf", c
        expect{s.add_subconf c}.should raise_error(Gitolite::Config::ConfigDependencyError)
      end
    end

    describe "#rm_subconf" do
      it 'should remove a subconfig for the Gitolite::Config object given' do
        g = @root_config.get_subconf('bar.conf')
        g2 = @root_config.rm_subconf(g)
        g.should_not be nil
        g2.name.should == g.name
      end

      it 'should remove a subconf given a string containing the name' do
        g = @root_config.get_subconf('bar.conf')
        g2 = @root_config.rm_subconf('bar.conf')
        g2.name.should == g.name
      end

      it 'should remove a subconf given a symbol representing the name' do
        g = @root_config.get_subconf('bar.conf')
        g2 = @root_config.rm_subconf(:'bar.conf')
        g2.name.should == g.name
      end
    end

    describe "#to_file" do
      it 'should ensure save subconfs info' do
        c = Gitolite::Config.init
        c.filename = "test_subconfs.conf"

        # Build some groups out of order
        s = Gitolite::Config.new "subconf1.conf", c
        g = Gitolite::Config::Group.new "groupa"
        g.add_users "bob", "@all"
        s.add_group(g)

        # Write the config to a file
        file = c.to_file('/tmp')
        # Read the conf and make sure our order is correct
        f = File.read(file)
        lines = f.lines.map {|l| l.strip}
        # Compare the file lines.  Spacing is important here since we are doing a direct comparision
        lines[0].should == "include    \"subconf1.conf\""
        # Cleanup
        File.unlink(file)
        file = '/tmp/subconf1.conf'
        f = File.read(file)
        lines = f.lines.map {|l| l.strip}

        # Compare the file lines.  Spacing is important here since we are doing a direct comparision
        lines[0].should == "@groupa             = @all bob"

        # Cleanup
        File.unlink(file)

      end

      it 'should ensure save subconfs info and force to create the direcotory ' do
        c = Gitolite::Config.init
        c.filename = "test_subconfs.conf"

        # Build some groups out of order
        s = Gitolite::Config.new "mytest_subconf/subconf1.conf", c
        g = Gitolite::Config::Group.new "groupa"
        g.add_users "bob", "@all"
        s.add_group(g)

        # Write the config to a file
        file = c.to_file('/tmp', nil, true)
        # Read the conf and make sure our order is correct
        f = File.read(file)
        lines = f.lines.map {|l| l.strip}
        # Compare the file lines.  Spacing is important here since we are doing a direct comparision
        lines[0].should == "include    \"mytest_subconf/subconf1.conf\""
        # Cleanup
        File.unlink(file)

        file = '/tmp/mytest_subconf/subconf1.conf'
        f = File.read(file)
        lines = f.lines.map {|l| l.strip}

        # Compare the file lines.  Spacing is important here since we are doing a direct comparision
        lines[0].should == "@groupa             = @all bob"

        # Cleanup
        File.unlink(file)
        Dir.rmdir('/tmp/mytest_subconf')

      end
    end
  end
end
