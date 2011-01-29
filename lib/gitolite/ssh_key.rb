module Gitolite
  #Models an SSH key within gitolite
  #provides support for multikeys
  #
  #Types of multi keys:
  #  bob.pub => username: bob
  #  bob@desktop.pub => username: bob, location: desktop
  #  bob@email.com.pub => username: bob@email.com
  #  bob@email.com@desktop.pub => username: bob@email.com, location: desktop

  class SSHKey
    attr_accessor :owner, :location, :type, :blob, :email

    def initialize(key)

      raise "#{key} does not exist!" unless File.exists?(key)

      #Get our owner and location
      File.basename(key) =~ /^(\w+(?:@(?:\w+\.)+\D{2,4})?)(?:@(\w+))?.pub$/i
      @owner = $1
      @location = $2 || ""

      #Get parts of the key
      @type, @blob, @email = File.read(key).split

      #If the key didn't have an email, just use the owner
      if @email.nil?
        @email = @owner
      end
    end
    
    def initialize(type, blob, email, owner = nil, location = "")
      @type = type
      @blob = blob
      @email = email
      
      @owner = owner || email
      @location = location
    end

    def to_s
      [@type, @blob, @email].join(' ')
    end
    
    def filename
      file = @owner
      file << "@#{@location}" unless @location.empty?
      file << ".pub"
    end
  end
end

