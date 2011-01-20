module Gitolite
  class Config
    attr_accessor :repos, :groups

    def initialize(config)
      @repos = {}
      @groups = {}
      process_config(config)
    end

    #Represents a repo inside the gitolite configuration.  The name, permissions, and git config
    #options are all encapsulated in this class
    class Repo
      ALLOWED_PERMISSIONS = ['C', 'R', 'RW', 'RW+', 'RWC', 'RW+C', 'RWD', 'RW+D', 'RWCD', 'RW+CD', '-']

      attr_accessor :permissions, :name, :config

      def initialize(name)
        @name = name
        @permissions = {}
        @config = {}
      end

      def add_permission(perm, refex, users)
        if ALLOWED_PERMISSIONS.include? perm
          @permissions[perm] ||= {}

          @permissions[perm][refex] ||= []
          @permissions[perm][refex].concat users
        else
          raise InvalidPermissionError, "#{perm} is not in the allowed list of permissions!"
        end
      end

      def set_git_config(key, value)
        @config[key] = value
      end

      def unset_git_config(key)
        value = @config[key]
        @config.delete(key)
        value
      end

      def to_s
        @name
      end

      #Gets raised if a permission that isn't in the allowed
      #list is passed in
      class InvalidPermissionError < RuntimeError
      end
    end

    private
      #Based on
      #https://github.com/sitaramc/gitolite/blob/pu/src/gl-compile-conf#cleanup_conf_line
      def cleanup_config_line(line)
        #remove comments, even those that happen inline
        line.gsub!(/^((".*?"|[^#"])*)#.*/) {|m| m=$1}

        #fix whitespace
        line.gsub!(/=/, ' = ')
        line.gsub!(/\s+/, ' ')
        line.strip!
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

              if @groups.has_key? group
                @groups[group].concat users
              else
                @groups[group] = users
              end

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