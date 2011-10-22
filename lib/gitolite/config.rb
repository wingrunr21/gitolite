require 'tempfile'
require File.join(File.dirname(__FILE__), 'config', 'repo')
require File.join(File.dirname(__FILE__), 'config', 'group')

module Gitolite
  class Config
    attr_accessor :repos, :groups, :filename

    def initialize(config)
      @repos = {}
      @groups = {}
      @filename = File.basename(config)
      process_config(config)
    end

    def self.init(filename = "gitolite.conf")
      file = Tempfile.new(filename)
      conf = self.new(file.path)
      conf.filename = filename #kill suffix added by Tempfile
      file.close(unlink_now = true)
      conf
    end

    #TODO: merge repo unless overwrite = true
    def add_repo(repo, overwrite = false)
      raise ArgumentError, "Repo must be of type Gitolite::Config::Repo!" unless repo.instance_of? Gitolite::Config::Repo
      @repos[repo.name] = repo
    end

    def rm_repo(repo)
      name = normalize_repo_name(repo)
      @repos.delete(name)
    end

    def has_repo?(repo)
      name = normalize_repo_name(repo)
      @repos.has_key?(name)
    end

    def get_repo(repo)
      name = normalize_repo_name(repo)
      @repos[name]
    end

    def add_group(group, overwrite = false)
      raise ArgumentError, "Group must be of type Gitolite::Config::Group!" unless group.instance_of? Gitolite::Config::Group
      @groups[group.name] = group
    end

    def rm_group(group)
      name = normalize_group_name(group)
      @groups.delete(name)
    end

    def has_group?(group)
      name = normalize_group_name(group)
      @groups.has_key?(name)
    end

    def get_group(group)
      name = normalize_group_name(group)
      @groups[name]
    end

    def to_file(path=".", filename=@filename)
      raise ArgumentError, "Path contains a filename or does not exist" unless File.directory?(path)

      new_conf = File.join(path, filename)
      File.open(new_conf, "w") do |f|
        #Output groups
        @groups.each_value {|group| f.write group.to_s }

        gitweb_descs = []
        @repos.each do |k, v|
          f.write v.to_s

          gwd = v.gitweb_description
          gitweb_descs.push(gwd) unless gwd.nil?
        end

        f.write gitweb_descs.join("\n")
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

                @repos[r] = Repo.new(r) unless has_repo?(r)
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
            when /^#{Group::PREPEND_CHAR}(\S+) = ?(.*)/
              group = $1
              users = $2.split

              @groups[group] = Group.new(group) unless has_group?(group)
              @groups[group].add_users(users)
            #gitweb definition
            when /^(\S+)(?: "(.*?)")? = "(.*)"$/
              repo = $1
              owner = $2
              description = $3

              #Check for missing description
              raise ParseError, "Missing Gitweb description for repo: #{repo}" if description.nil?

              #Check for groups
              raise ParseError, "Gitweb descriptions cannot be set for groups" if repo =~ /@.+/

              if has_repo? repo
                r = @repos[repo]
              else
                r = Repo.new(repo)
                add_repo(r)
              end

              r.owner = owner
              r.description = description
            when /^include "(.+)"/
              #TODO: implement includes
              #ignore includes for now
            else
              raise ParseError, "'#{line}' cannot be processed"
          end
        end
      end

      # Normalizes the various different input objects to Strings
      def normalize_name(context, constant = nil)
        case context
          when constant
            context.name
          when Symbol
            context.to_s
          else
            context
        end
      end

      def method_missing(meth, *args, &block)
        if meth.to_s =~ /normalize_(\w+)_name/
          #Could use Object.const_get to figure out the constant here
          #but for only two cases, this is more readable
          case $1
            when "repo"
              normalize_name(args[0], Gitolite::Config::Repo)
            when "group"
              normalize_name(args[0], Gitolite::Config::Group)
          end
        else
          super
        end
      end

      #Raised when something in a config fails to parse properly
      class ParseError < RuntimeError
      end
  end
end
