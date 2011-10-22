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

    def initialize(type, blob, email, owner = nil, location = "")
      @type = type
      @blob = blob
      @email = email

      @owner = owner || email
      @location = location
    end

    def self.from_file(key)

      raise "#{key} does not exist!" unless File.exists?(key)

      #Get our owner and location
      File.basename(key) =~ /^(\w+(?:@(?:\w+\.)+\D{2,4})?)(?:@(\w+))?.pub$/i
      owner = $1
      location = $2 || ""

      #Get parts of the key
      type, blob, email = File.read(key).split

      #If the key didn't have an email, just use the owner
      if email.nil?
        email = owner
      end

      self.new(type, blob, email, owner, location)
    end

    def to_s
      [@type, @blob, @email].join(' ')
    end

    def to_file(path)
      key_file = File.join(path, self.filename)
      File.open(key_file, "w") do |f|
        f.write(self.to_s)
      end
      key_file
    end

    def filename
      file = @owner
      file += "@#{@location}" unless @location.empty?
      file += ".pub"
    end

    def ==(key)
      @type == key.type &&
      @blob == key.blob &&
      @email == key.email &&
      @owner == key.owner &&
      @location == key.location
    end
  end
end
