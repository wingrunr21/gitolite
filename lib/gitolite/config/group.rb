module Gitolite
  class Config
    # Represents a group inside the gitolite configuration.  The name and users
    # options are all encapsulated in this class.  All users are stored as
    # Strings!
    class Group
      attr_accessor :name, :users

      PREPEND_CHAR = '@'

      def initialize(name)
        # naively remove the prepend char
        # I don't think you can have two of them in a group name
        @name = name.gsub(PREPEND_CHAR, '')
        @users = []
      end

      def empty!
        @users.clear
      end

      def add_user(user)
        return if has_user?(user)
        @users.push(user.to_s).sort!
      end

      def add_users(*users)
        fixed_users = users.flatten.map{ |u| u.to_s }
        @users.concat(fixed_users).sort!.uniq!
      end

      def rm_user(user)
        @users.delete(user.to_s)
      end

      def has_user?(user)
        @users.include? user.to_s
      end

      def size
        @users.length
      end

      def to_s
        members = @users.join(' ')
        name = "#{PREPEND_CHAR}#{@name}"
        "#{name.ljust(20)}= #{members}\n"
      end
    end
  end
end
