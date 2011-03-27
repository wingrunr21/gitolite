module Gitolite
  class GitoliteAdmin
    attr_accessor :gl_admin, :ssh_keys, :config

    CONF = "gitolite.conf"
    CONFDIR = "conf"
    KEYDIR = "keydir"

    # Intialize with the path to
    # the gitolite-admin repository
    def initialize(path, options = {})
      @gl_admin = Grit::Repo.new(path)

      @conf = options[:conf] || CONF
      @confdir = options[:confdir] || CONFDIR
      @keydir = options[:keydir] || KEYDIR

      @ssh_keys = load_keys(File.join(path, @keydir))
      @config = Config.new(File.join(path, @confdir, @conf))
    end

    # This method will bootstrap a gitolite-admin repo
    # at the given path.  A typical gitolite-admin
    # repo will have the following tree:
    #
    # gitolite-admin
    #   conf
    #     gitolite.conf
    #   keydir
    #
    # TODO: Make this method detect an existing gitolite-admin repo
    def self.bootstrap(path, options = {})
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

    #commits all staged changes and pushes back
    #to origin
    #
    #TODO: generate a better commit message
    #TODO: add the ability to specify the message, remote, and branch
    #TODO: detect existance of origin instead of just dying
    def apply
      @gl_admin.commit_index("Commit by gitolite gem")
      @gl_admin.git.push({}, "origin", "master")
    end

    def save_and_apply
      self.save
      self.apply
    end

    def add_key(key)
      raise "Key must be of type Gitolite::SSHKey!" unless key.instance_of? Gitolite::SSHKey
      @ssh_keys[key.owner] << key
    end

    def rm_key(key)
      @ssh_keys[key.owner].delete key
    end

    private
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
