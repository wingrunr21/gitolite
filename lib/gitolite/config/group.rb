module Gitolite
  class Config
    #Represents a group inside the gitolite configuration.  The name and users
    #options are all encapsulated in this class
    class Group

      attr_accessor :name, :users

      def initialize(name)
        @name = name
        @users = []
      end

      def clean_users
        @users = []
      end

      def add_users(*users)
        users.flatten.sort.uniq.each do |user|
          @users << user
        end
      end

      def remove_user(user)
        @users.delete(user)
      end

    end
  end
end
