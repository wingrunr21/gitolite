module Gitolite
  # Very simple proxy object for checking if the proxied object was modified
  # since the last clean_up! method called. It works correctly only for objects
  # with proper hash method!

  class DirtyProxy < BasicObject

    def initialize(target)
      @target = target
      clean_up!
    end

    def method_missing(method, *args, &block)
      @target.send(method, *args, &block)
    end

    def respond_to?(symbol, include_private=false)
      super || [:dirty?, :clean_up!].include?(symbol.to_sym)
    end

    def dirty?
      @clean_hash != @target.hash
    end

    def clean_up!
      @clean_hash = @target.hash
    end
  end
end
