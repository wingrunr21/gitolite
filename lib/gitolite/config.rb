require 'tempfile'
require 'pathname'

require File.join(File.dirname(__FILE__), 'config', 'repo')
require File.join(File.dirname(__FILE__), 'config', 'group')

module Gitolite
  class Config
    attr_accessor :repos, :groups, :filename, :subconfs, :file, :parent

    def initialize(config='gitolite.conf', parent=nil)
      @repos = {}
      @groups = {}
      @subconfs = {}
      @file = config
      @parent = parent
      @root_config = nil
      @filename = File.basename(config)
      @parent.add_subconf(self) if @parent
    end

    def self.init(filename = "gitolite.conf")
      self.new(filename)
    end

    def self.load_from(filename, parent=nil)
      conf = self.new(filename, parent)
      conf.process_config(filename)
      conf
    end

    def name
      @file
    end

    def root_config
      return @root_config if @root_config
      root = self
      parent = @parent
      while parent do
        root = parent
        parent = parent.parent
      end
      @root_config = root
      root
    end

    def parent=(conf)
      raise ArgumentError, "Config must be of type Gitolite::Config!" unless conf.instance_of? Gitolite::Config
      if has_subconf? conf, 99
        raise ConfigDependencyError
      else
        @parent = conf
      end
    end

    def add_subconf(conf)
      raise ArgumentError, "Config must be of type Gitolite::Config!" unless conf.instance_of? Gitolite::Config
      conf.parent = self if conf.parent != self 
      key = get_relative_path(conf.file)
      @subconfs[key] = conf
    end

    def get_relative_path(file)
      path = Pathname.new(file)
      if path.relative?
        file
      else
        basedir = Pathname.new File.dirname(@file)
        result = path.relative_path_from(basedir)
        result.to_s
      end
    rescue
      file
    end

    def has_subconf?(aFile, level = 1)
      file = get_relative_path(normalize_config_name(aFile))
      result = @subconfs.has_key?(file)
      #file.should == '' if aFile == 'subconfs.conf'
      if !result and (level > 1)
        level -= 1
        @subconfs.each do |k, v|
          result = v.has_subconf?(file, level)
          break if result 
        end
      end
      result
    end

    def get_subconf(file)
      file = normalize_config_name(file)
      @subconfs[get_relative_path(file)]
    end

    def rm_subconf(file)
      file = normalize_config_name(file)
      @subconfs.delete(get_relative_path(file))
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

    def to_file(path=".", filename=@filename, force_dir=false)
      filename=@filename if !filename || filename == ''
      new_conf = File.join(path, filename)

      if force_dir
        vPath = Pathname.new File.dirname(new_conf)
        vPath.mkpath unless vPath.exist?
      else
        raise ArgumentError, "Path contains a filename or does not exist" unless File.directory?(path)
      end

      File.open(new_conf, "w") do |f|
        #Output groups
        dep_order = build_groups_depgraph
        dep_order.each {|group| f.write group.to_s }

        gitweb_descs = []
        @repos.each do |k, v|
          f.write v.to_s

          gwd = v.gitweb_description
          gitweb_descs.push(gwd) unless gwd.nil?
        end

        f.write gitweb_descs.join("\n")

        # write subconfs into file
        gitweb_descs = []
        @subconfs.each do |k ,v|
          k= get_relative_path k
          v.to_file(path, k, force_dir)
          gitweb_descs.push("include    \"#{k}\"")
        end

        f.write gitweb_descs.join("\n")
      end

      new_conf
    end

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

          case line
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
            when /^(-|C|R|RW\+?(?:C?D?|D?C?)M?) (.* )?= (.+)/
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
            when /^subconf (["'])(.+)\1/
              #TODO: implement subconfs
              dir = File.dirname(@file)
              file = $2
              path = Pathname.new file
              file = File.join(dir, file) unless path.absolute?
              path = Pathname.new file
              raise ParseError, "'#{line}' '#{file}' not exits!" unless path.file?
              if not root_config.has_subconf?($2, 99)
                conf = Gitolite::Config.load_from(file, self)
              else
                raise ParseError, "'#{line}' recursive reference!"
              end
            else
              raise ParseError, "'#{line}' cannot be processed"
          end
        end
      end

    private
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
            when 'config'
              normalize_name(args[0], Gitolite::Config)
          end
        else
          super
        end
      end

      # Builds a dependency tree from the groups in order to ensure all groups
      # are defined before they are used
      def build_groups_depgraph
        dp = ::Plexus::Digraph.new

        # Add each group to the graph
        @groups.each_value do |group|
          dp.add_vertex! group

          # Select group names from the users
          subgroups = group.users.select {|u| u =~ /^#{Group::PREPEND_CHAR}.*$/}
                                 .map{|g| get_group g.gsub(Group::PREPEND_CHAR, '') }

          subgroups.each do |subgroup|
            dp.add_edge! subgroup, group
          end
        end

        # Figure out if we have a good depedency graph
        dep_order = dp.topsort

        if dep_order.empty?
          raise GroupDependencyError unless @groups.empty?
        end

        dep_order
      end

      #Raised when something in a config fails to parse properly
      class ParseError < RuntimeError
      end

      # Raised when group dependencies cannot be suitably resolved for output
      class GroupDependencyError < RuntimeError
      end

      # Raised when config dependencies cannot be suitably resolved for output
      class ConfigDependencyError < RuntimeError
      end
  end
end
