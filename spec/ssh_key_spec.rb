require 'spec_helper'
require 'gitolite/ssh_key'
include Gitolite

describe Gitolite::SSHKey do
  key_dir = File.join(File.dirname(__FILE__),'keys')
  
  describe '#owner' do
    it 'owner should be bob for bob.pub' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob'
    end

    it 'owner should be bob for bob@desktop.pub' do
      key = File.join(key_dir, 'bob@desktop.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob'
    end

    it 'owner should be bob@zilla.com for bob@zilla.com.pub' do
      key = File.join(key_dir, 'bob@zilla.com.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob@zilla.com'
    end

    it "owner should be bob-ins@zilla-site.com for bob-ins@zilla-site.com@desktop.pub" do
      key = File.join(key_dir, 'bob-ins@zilla-site.com@desktop.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob-ins@zilla-site.com'
    end

    it 'owner should be bob@zilla.com for bob@zilla.com@desktop.pub' do
      key = File.join(key_dir, 'bob@zilla.com@desktop.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'bob@zilla.com'
    end

    it 'owner should be jakub123 for jakub123.pub' do
      key = File.join(key_dir, 'jakub123.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'jakub123'
    end

    it 'owner should be jakub123@foo.net for jakub123@foo.net.pub' do
      key = File.join(key_dir, 'jakub123@foo.net.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'jakub123@foo.net'
    end

    it 'owner should be joe@sch.ool.edu for joe@sch.ool.edu' do
      key = File.join(key_dir, 'joe@sch.ool.edu.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'joe@sch.ool.edu'
    end

    it 'owner should be joe@sch.ool.edu for joe@sch.ool.edu@desktop.pub' do
      key = File.join(key_dir, 'joe@sch.ool.edu@desktop.pub')
      s = SSHKey.from_file(key)
      s.owner.should == 'joe@sch.ool.edu'
    end
  end

  describe '#location' do
    it 'location should be "" for bob.pub' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for bob@desktop.pub' do
      key = File.join(key_dir, 'bob@desktop.pub')
      s = SSHKey.from_file(key)
      s.location.should == 'desktop'
    end

    it 'location should be "" for bob@zilla.com.pub' do
      key = File.join(key_dir, 'bob@zilla.com.pub')
      s = SSHKey.from_file(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for bob@zilla.com@desktop.pub' do
      key = File.join(key_dir, 'bob@zilla.com@desktop.pub')
      s = SSHKey.from_file(key)
      s.location.should == 'desktop'
    end

    it 'location should be "" for jakub123.pub' do
      key = File.join(key_dir, 'jakub123.pub')
      s = SSHKey.from_file(key)
      s.location.should == ''
    end

    it 'location should be "" for jakub123@foo.net.pub' do
      key = File.join(key_dir, 'jakub123@foo.net.pub')
      s = SSHKey.from_file(key)
      s.location.should == ''
    end

    it 'location should be "" for joe@sch.ool.edu' do
      key = File.join(key_dir, 'joe@sch.ool.edu.pub')
      s = SSHKey.from_file(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for joe@sch.ool.edu@desktop.pub' do
      key = File.join(key_dir, 'joe@sch.ool.edu@desktop.pub')
      s = SSHKey.from_file(key)
      s.location.should == 'desktop'
    end
  end

  describe '#keys' do
    it 'should load ssh key properly' do
      key = File.join(key_dir, 'bob.pub')
      s = SSHKey.from_file(key)
      parts = File.read(key).split #should get type, blob, email

      s.type.should == parts[0]
      s.blob.should == parts[1]
      s.email.should == parts[2]
    end
  end

  describe '#email' do
    it 'should use owner if email is missing' do
      key = File.join(key_dir, 'jakub123@foo.net.pub')
      s = SSHKey.from_file(key)
      s.owner.should == s.email
    end
  end
  
  describe '#new' do
    it 'should create a valid ssh key' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      
      s = SSHKey.new(type, blob, email)
      
      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == email
    end
    
    it 'should create a valid ssh key while specifying an owner' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      
      s = SSHKey.new(type, blob, email, owner)
      
      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == owner
    end
    
    it 'should create a valid ssh key while specifying an owner and location' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Name.location
      
      s = SSHKey.new(type, blob, email, owner, location)
      
      s.to_s.should == [type, blob, email].join(' ')
      s.owner.should == owner
      s.location.should == location
    end
  end
  
  describe '#filename' do
    it 'should create a filename that is the <email>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      
      s = SSHKey.new(type, blob, email)
      
      s.filename.should == "#{email}.pub"
    end
    
    it 'should create a filename that is the <owner>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      
      s = SSHKey.new(type, blob, email, owner)
      
      s.filename.should == "#{owner}.pub"
    end
    
    it 'should create a filename that is the <email>@<location>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)
      
      s = SSHKey.new(type, blob, email, nil, location)
      
      s.filename.should == "#{email}@#{location}.pub"
    end
    
    it 'should create a filename that is the <owner>@<location>.pub' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)
      
      s = SSHKey.new(type, blob, email, owner, location)
      
      s.filename.should == "#{owner}@#{location}.pub"
    end
  end
  
  describe '#to_file' do
    it 'should write a "valid" SSH public key to the file system' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)
      
      s = SSHKey.new(type, blob, email, owner, location)
      
      tmpdir = Dir.tmpdir
      s.to_file(tmpdir)
      
      s.to_s.should == File.read(File.join(tmpdir, s.filename))
    end
    
    it 'should return the filename written' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      owner = Forgery::Name.first_name
      location = Forgery::Basic.text(:at_least => 8, :at_most => 15)
      
      s = SSHKey.new(type, blob, email, owner, location)
      
      tmpdir = Dir.tmpdir
      
      
      s.to_file(tmpdir).should == File.join(tmpdir, s.filename)
    end
  end
  
  describe '==' do
    it 'should have two keys equalling one another' do
      type = "ssh-rsa"
      blob = Forgery::Basic.text(:at_least => 372, :at_most => 372)
      email = Forgery::Internet.email_address
      
      s1 = SSHKey.new(type, blob, email)
      s2 = SSHKey.new(type, blob, email)
      
      s1.should == s2
    end
  end
end
