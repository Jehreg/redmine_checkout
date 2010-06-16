require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Checkout::Protocol do
  fixtures :settings, :repositories, :projects, :enabled_modules
  
  before(:each) do
    u = User.new
    u.admin = true
    User.current = u
    @repo = repositories :svn

    @repo.url = "http://example.com/svn/testrepo"
  end
  
  it "should use the default protocols" do
    protocols = @repo.checkout_protocols
    protocols[0].protocol.should eql "Subversion"
    protocols[1].protocol.should eql "SVN+SSH"
    protocols[2].protocol.should eql "Root"
  end
  
  it "should use regexes for generated URL" do
    protocol = @repo.checkout_protocols.find{|r| r.protocol == "SVN+SSH"}
    protocol.url.should eql "svn+ssh://testrepo@svn.foo.bar/svn"
  end
  
  it "should resolve access properties" do
    protocol = @repo.checkout_protocols.find{|r| r.protocol == "Subversion"}
    protocol.access.should eql "permission"
    protocol.access_rw.should eql "read+write"
  end
end
