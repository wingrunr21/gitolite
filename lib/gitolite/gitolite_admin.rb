module Gitolite
  class GitoliteAdmin
    attr_accessor :gl_admin, :ssh_keys, :config

    CONF = "conf/gitolite.conf"
    KEYDIR = "keydir"

    #Intialize with the path to
    #the gitolite-admin repository
    def initialize(path, options = {})
      @gl_admin = Grit::Repo.new(path)

      @path = path
      @conf = File.join(path, options[:conf] || CONF)
      @keydir = File.join(path, options[:keydir] || KEYDIR)

      @ssh_keys = load_keys(@keydir)
      @config = Config.new(@conf)
    end

    #Writes all aspects out to the file system
    #will also stage all changes
    def save
      #Process config file
      new_conf = @config.to_file(@conf.dirname)
      @gl_admin.add(new_conf)

      #Process ssh keys
      files = list_keys(@keydir).map{|f| File.basename f}
      keys = @ssh_keys.values.map{|f| f.map {|t| t.filename}}.flatten
      
      to_remove = (files - keys).map { |f| File.join(@keydir, f)}
      @gl_admin.remove(to_remove)
      
      keys.each do |key|
        new_key = key.to_file(@key_dir)
        @gl_admin.add(new_key)
      end
    end

    #commits all staged changes and pushes back
    #to origin
    def apply
      status = @gl_admin.status
    end

    #Calls save and apply in order
    def save_and_apply
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
        Dir.chdir(path)
        Dir.glob("**/*.pub")
      end
  end
end
