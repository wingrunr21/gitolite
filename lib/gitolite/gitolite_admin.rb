module Gitolite
  class GitoliteAdmin
    attr_accessor :gl_admin, :ssh_keys, :config

    CONF = "gitolite.conf"
    CONFDIR = "conf"
    KEYDIR = "keydir"

    #Gitolite gem's default git commit message
    DEFAULT_COMMIT_MSG = "Committed by the gitolite gem"

    # Intialize with the path to
    # the gitolite-admin repository
    def initialize(path, options = {})
      @path = path
      @gl_admin = Grit::Repo.new(path)

      @conf = options[:conf] || CONF
      @confdir = options[:confdir] || CONFDIR
      @keydir = options[:keydir] || KEYDIR

      # Load the ssh keys and the configuration
      load_data
    end

    # This method will bootstrap a gitolite-admin repo
    # at the given path.  A typical gitolite-admin
    # repo will have the following tree:
    #
    # gitolite-admin
    #   conf
    #     gitolite.conf
    #   keydir
    def self.bootstrap(path, options = {})
      if self.is_gitolite_admin_repo?(path)
        if options[:overwrite]
          FileUtils.rm_rf(File.join(path, '*'))
        else
          return self.new(path)
        end
      end

      FileUtils.mkdir_p([File.join(path,"conf"), File.join(path,"keydir")])

      options[:perm] ||= "RW+"
      options[:refex] ||= ""
      options[:user] ||= "git"

      c = Config.init
      r = Config::Repo.new(options[:repo] || "gitolite-admin")
      r.add_permission(options[:perm], options[:refex], options[:user])
      c.add_repo(r)
      config = c.to_file(File.join(path, "conf"))

      repo = Grit::Repo.init(path)
      Dir.chdir(path) do
        repo.add(config)
        repo.commit_index(options[:message] || "Config bootstrapped by the gitolite gem")
      end

      self.new(path)
    end

    #Writes all aspects out to the file system
    #will also stage all changes
    def save
      Dir.chdir(@gl_admin.working_dir) do
        #Process config file
        new_conf = @config.to_file(@confdir)
        @gl_admin.add(new_conf)

        #Process ssh keys
        files = list_keys(@keydir).map{|f| File.basename f}
        keys = @ssh_keys.values.map{|f| f.map {|t| t.filename}}.flatten

        to_remove = (files - keys).map { |f| File.join(@keydir, f)}
        @gl_admin.remove(to_remove)

        @ssh_keys.each_value do |key|
          key.each do |k|
            @gl_admin.add(k.to_file(@keydir))
          end
        end
      end
    end

    # This method will destroy all local tracked changes, resetting the local gitolite
    # git repo to HEAD and reloading the entire repository
    # Note that this will also delete all untracked files
    def reset!
      Dir.chdir(@gl_admin.working_dir) do
        @gl_admin.git.reset({:hard => true}, 'HEAD')
        @gl_admin.git.clean({:d => true, :q => true, :f => true})
      end
      reload!
    end

    # This method will destroy the in-memory data structures and reload everything
    # from the file system
    def reload!
      load_data
    end

    #commits all staged changes and pushes back
    #to origin
    #
    #TODO: generate a better commit message
    #TODO: add the ability to specify the remote and branch
    #TODO: detect existance of origin instead of just dying
    def apply(commit_message = DEFAULT_COMMIT_MSG)
      @gl_admin.commit_index(commit_message)
      @gl_admin.git.push({}, "origin", "master")
    end

    def save_and_apply(commit_message = DEFAULT_COMMIT_MSG)
      self.save
      self.apply(commit_message)
    end

    # Updates the repo with changes from remote master
    def update(*args)
      options = {:reset => true, :rebase => false}
      options.merge! args.first || {}

      reset! if options[:reset]

      Dir.chdir(@gl_admin.working_dir) do
        @gl_admin.git.pull({:rebase => options[:rebase]}, "origin", "master")
      end

      reload!
    end

    def add_key(key)
      raise "Key must be of type Gitolite::SSHKey!" unless key.instance_of? Gitolite::SSHKey
      @ssh_keys[key.owner] << key
    end

    def rm_key(key)
      raise "Key must be of type Gitolite::SSHKey!" unless key.instance_of? Gitolite::SSHKey
      @ssh_keys[key.owner].delete key
    end

    #Checks to see if the given path is a gitolite-admin repository
    #A valid repository contains a conf folder, keydir folder,
    #and a configuration file within the conf folder
    def self.is_gitolite_admin_repo?(dir)
      # First check if it is a git repository
      begin
        Grit::Repo.new(dir)
      rescue Grit::InvalidGitRepositoryError
        return false
      end

      # If we got here it is a valid git repo,
      # now check directory structure
      File.exists?(File.join(dir, 'conf')) &&
        File.exists?(File.join(dir, 'keydir')) &&
        !Dir.glob(File.join(dir, 'conf', '*.conf')).empty?
    end

    private
      def load_data
        @ssh_keys = load_keys(File.join(@path, @keydir))
        @config = Config.new(File.join(@path, @confdir, @conf))
      end

      #Loads all .pub files in the gitolite-admin
      #keydir directory
      def load_keys(path)
        keys = Hash.new {|k,v| k[v] = []}

        list_keys(path).each do |key|
          new_key = SSHKey.from_file(File.join(path, key))
          owner = new_key.owner

          keys[owner] << new_key
        end

        keys
      end

      def list_keys(path)
        Dir.chdir(path) do
          keys = Dir.glob("**/*.pub")
          keys
        end
      end
  end
end
