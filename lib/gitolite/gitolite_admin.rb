module Gitolite
  class GitoliteAdmin
    attr_accessor :gl_admin, :ssh_keys, :config

    CONF = "/conf/gitolite.conf"
    KEYDIR = "/keydir"

    #Intialize with the path to
    #the gitolite-admin repository
    def initialize(path, options = {})
      @gl_admin = Grit::Repo.new(path)

      conf = options[:conf] || CONF
      keydir = options[:keydir] || KEYDIR

      @ssh_keys = load_keys(File.join(path, keydir))
      @config = Config.new(File.join(path, conf))
    end

    #Writes all aspects out to the file system
    #will also stage all changes
    def save
      #Process config file

      #Process ssh keys
    end

    #commits all staged changes and pushes back
    #to origin
    def apply
      status = @gl_admin.status
    end

    #Calls save and apply in order
    def save_and_apply
    end

    private
      #Loads all .pub files in the gitolite-admin
      #keydir directory
      def load_keys(path)
        keys = {}

        Dir.chdir(path)
        Dir.glob("**/*.pub").each do |key|
          new_key = SSHKey.new(File.join(path, key))
          owner = new_key.owner

          keys[owner] ||= []
          keys[owner] << new_key
        end

        keys
      end
  end
end
