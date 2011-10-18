module Gitolite
  class Config
    # Represents a group inside the gitolite configuration.  The name and users
    # options are all encapsulated in this class.  All users are stored as
    # Strings!
    class Group
      attr_accessor :name, :users

      def initialize(name)
        @name = name
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
        "#{@name.ljust(20)}= #{members}\n"
      end
    end
  end
end
