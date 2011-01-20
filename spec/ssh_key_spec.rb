require 'gitolite/ssh_key'
include Gitolite

describe Gitolite::SSHKey do
  describe '#owner' do
    it 'owner should be bob for bob.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob.pub')
      s = SSHKey.new(key)
      s.owner.should == 'bob'
    end

    it 'owner should be bob for bob@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@desktop.pub')
      s = SSHKey.new(key)
      s.owner.should == 'bob'
    end

    it 'owner should be bob@zilla.com for bob@zilla.com.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@zilla.com.pub')
      s = SSHKey.new(key)
      s.owner.should == 'bob@zilla.com'
    end

    it 'owner should be bob@zilla.com for bob@zilla.com@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@zilla.com@desktop.pub')
      s = SSHKey.new(key)
      s.owner.should == 'bob@zilla.com'
    end

    it 'owner should be jakub123 for jakub123.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'jakub123.pub')
      s = SSHKey.new(key)
      s.owner.should == 'jakub123'
    end

    it 'owner should be jakub123@foo.net for jakub123@foo.net.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'jakub123@foo.net.pub')
      s = SSHKey.new(key)
      s.owner.should == 'jakub123@foo.net'
    end

    it 'owner should be joe@sch.ool.edu for joe@sch.ool.edu' do
      key = File.join(File.dirname(__FILE__),'keys', 'joe@sch.ool.edu.pub')
      s = SSHKey.new(key)
      s.owner.should == 'joe@sch.ool.edu'
    end

    it 'owner should be joe@sch.ool.edu for joe@sch.ool.edu@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'joe@sch.ool.edu@desktop.pub')
      s = SSHKey.new(key)
      s.owner.should == 'joe@sch.ool.edu'
    end
  end

  describe '#location' do
    it 'location should be "" for bob.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob.pub')
      s = SSHKey.new(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for bob@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@desktop.pub')
      s = SSHKey.new(key)
      s.location.should == 'desktop'
    end

    it 'location should be "" for bob@zilla.com.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@zilla.com.pub')
      s = SSHKey.new(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for bob@zilla.com@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob@zilla.com@desktop.pub')
      s = SSHKey.new(key)
      s.location.should == 'desktop'
    end

    it 'location should be "" for jakub123.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'jakub123.pub')
      s = SSHKey.new(key)
      s.location.should == ''
    end

    it 'location should be "" for jakub123@foo.net.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'jakub123@foo.net.pub')
      s = SSHKey.new(key)
      s.location.should == ''
    end

    it 'location should be "" for joe@sch.ool.edu' do
      key = File.join(File.dirname(__FILE__),'keys', 'joe@sch.ool.edu.pub')
      s = SSHKey.new(key)
      s.location.should == ''
    end

    it 'location should be "desktop" for joe@sch.ool.edu@desktop.pub' do
      key = File.join(File.dirname(__FILE__),'keys', 'joe@sch.ool.edu@desktop.pub')
      s = SSHKey.new(key)
      s.location.should == 'desktop'
    end
  end

  describe '#keys' do
    it 'should load ssh key properly' do
      key = File.join(File.dirname(__FILE__),'keys', 'bob.pub')
      s = SSHKey.new(key)
      parts = File.read(key).split #should get type, blob, email

      s.type.should == parts[0]
      s.blob.should == parts[1]
      s.email.should == parts[2]
    end
  end

  describe '#email' do
    it 'should use owner if email is missing' do
      key = File.join(File.dirname(__FILE__),'keys', 'jakub123@foo.net.pub')
      s = SSHKey.new(key)
      s.owner.should == s.email
    end
  end
end