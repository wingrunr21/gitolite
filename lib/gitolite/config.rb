module Gitolite
  class Config
    attr_accessor :repos, :groups, :filename

    def initialize(config)
      @repos = {}
      @groups = Hash.new { |k,v| k[v] = [] }
      @filename = File.basename(config)
      process_config(config)
    end

    def self.init(filename = "gitolite.conf")
      file = Tempfile.new(filename)
      conf = self.new(file)
      conf.filename = filename #kill suffix added by Tempfile
      file.close(unlink_now = true)
      conf
    end

    #Represents a repo inside the gitolite configuration.  The name, permissions, and git config
    #options are all encapsulated in this class
    class Repo
      ALLOWED_PERMISSIONS = ['C', 'R', 'RW', 'RW+', 'RWC', 'RW+C', 'RWD', 'RW+D', 'RWCD', 'RW+CD', '-']

      attr_accessor :permissions, :name, :config

      def initialize(name)
        @name = name
        @permissions = Hash.new {|k,v| k[v] = Hash.new{|k2, v2| k2[v2] = [] }}
        @config = {}
      end

      def add_permission(perm, refex = "", *users)
        if ALLOWED_PERMISSIONS.include? perm
          @permissions[perm][refex].concat users.flatten
          @permissions[perm][refex].uniq!
        else
          raise InvalidPermissionError, "#{perm} is not in the allowed list of permissions!"
        end
      end

      def set_git_config(key, value)
        @config[key] = value
      end

      def unset_git_config(key)
        @config.delete(key)
      end

      def to_s
        repo = "repo    #{@name}\n"

        @permissions.each do |perm, list|
          list.each do |refex, users|
            repo += "  " + perm.ljust(6) + refex.ljust(20) + "= " + users.join(' ') + "\n"
          end
        end

        repo
      end

      #Gets raised if a permission that isn't in the allowed
      #list is passed in
      class InvalidPermissionError < RuntimeError
      end
    end

    #TODO: merge repo unless overwrite = true
    def add_repo(repo, overwrite = false)
      raise "Repo must be of type Gitolite::Config::Repo!" unless repo.instance_of? Gitolite::Config::Repo
      @repos[repo.name] = repo
    end

    def rm_repo(repo)
      raise "Repo must be of type Gitolite::Config::Repo!" unless repo.instance_of? Gitolite::Config::Repo
      @repos.delete repo.name
    end

    def to_file(path)
      new_conf = File.join(path, @filename)
      File.open(new_conf, "w") do |f|
        @groups.each do |k,v|
          members = v.join(' ')
          f.write "#{k.ljust(20)}=  #{members}\n"
        end

        @repos.each do |k, v|
          f.write v.to_s
        end
      end

      new_conf
    end

    private
      #Based on
      #https://github.com/sitaramc/gitolite/blob/pu/src/gl-compile-conf#cleanup_conf_line
      def cleanup_config_line(line)
        #remove comments, even those that happen inline
        line.gsub!(/^((".*?"|[^#"])*)#.*/) {|m| m=$1}

        #fix whitespace
        line.gsub!('=', ' = ')
        line.gsub!(/\s+/, ' ')
        line.strip
      end

      def process_config(config)
        context = [] #will store our context for permissions or config declarations

        #Read each line of our config
        File.open(config, 'r').each do |l|

          line = cleanup_config_line(l)
          next if line.empty? #lines are empty if we killed a comment

          case line.strip
            #found a repo definition
            when /^repo (.*)/
              #Empty our current context
              context = []

              repos = $1.split
              repos.each do |r|
                context << r

                @repos[r] = Repo.new(r) unless @repos.has_key? r
              end
            #repo permissions
            when /^(-|C|R|RW\+?(?:C?D?|D?C?)) (.* )?= (.+)/
              perm = $1
              refex = $2 || ""
              users = $3.split

              context.each do |c|
                @repos[c].add_permission(perm, refex, users)
              end
            #repo git config
            when /^config (.+) = ?(.*)/
              key = $1
              value = $2

              context.each do |c|
                @repos[c].set_git_config(key, value)
              end
            #group definition
            when /^(@\S+) = ?(.*)/
              group = $1
              users = $2.split

              @groups[group].concat users
              @groups[group].uniq!
            #gitweb definition
            when /^(\S+)(?: "(.*?)")? = "(.*)"$/
              #ignore gitweb right now
              puts line
            when /^include "(.+)"/
              #ignore includes for now
            else
              puts "The following line cannot be processed:"
              puts "'#{line}'"
          end
        end
      end
  end
end
