require 'spec_helper'
require 'contacts/google'
require 'uri'

describe Contacts::Google, '.authentication_url' do
  
  after :each do
    FakeWeb.clean_registry
  end
  
  it 'generates a URL for target with default parameters' do
    uri = parse_authentication_url('http://example.com/invite')
    
    uri.host.should == 'www.google.com'
    uri.scheme.should == 'https'
    uri.query.split('&').sort.should == [
      'next=http%3A%2F%2Fexample.com%2Finvite',
      'scope=http%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds%2Fcontacts%2F',
      'secure=0',
      'session=0'
      ]
  end

  it 'should handle boolean parameters' do
    pairs = parse_authentication_url(nil, :secure => true, :session => true).query.split('&')
    
    pairs.should include('secure=1')
    pairs.should include('session=1')
  end

  it 'should imply secure=true when the key parameter is set' do
    rsa = mock('OpenSSL::PKey::RSA', :private_encrypt => 'signature')
    digest = mock('OpenSSL::Digest::SHA1', :hexdigest => 'digest')
    OpenSSL::Digest::SHA1.expects(:new).returns(digest).at_least_once
    OpenSSL::PKey::RSA.expects(:new).with('secret-key').returns(rsa).at_least_once

    pairs = parse_authentication_url(nil, :key => 'secret-key').query.split('&')

    pairs.should include('secure=1')
    pairs.should include('sig=c2lnbmF0dXJl%0A') # ['signature'].pack('m')
    pairs.should_not include('key=secret-key')
  end

  it 'should accept File or IO key parameter' do
    rsa = mock('OpenSSL::PKey::RSA', :private_encrypt => 'signature')
    digest = mock('OpenSSL::Digest::SHA1', :hexdigest => 'digest')
    OpenSSL::Digest::SHA1.expects(:new).returns(digest).at_least_once
    OpenSSL::PKey::RSA.expects(:new).with(File.open(File.join(File.dirname(__FILE__), 'myrsakey.pem')).read).returns(rsa).at_least_once

    pairs = parse_authentication_url(nil, :key => File.open(File.join(File.dirname(__FILE__), 'myrsakey.pem'))).query.split('&')

    pairs.should include('secure=1')
    pairs.should include('sig=c2lnbmF0dXJl%0A') # ['signature'].pack('m')
    pairs.should_not include('key=secret-key')
  end

  it 'should accept OpenSSL::Pkey::RSA key parameter' do
    digest = mock('OpenSSL::Digest::SHA1', :hexdigest => 'digest')
    OpenSSL::Digest::SHA1.expects(:new).returns(digest).at_least_once

    pairs = parse_authentication_url(nil, :key => OpenSSL::PKey::RSA.new(File.open(File.join(File.dirname(__FILE__), 'myrsakey.pem')).read)).query.split('&')

    pairs.should include('secure=1')
    pairs.should include('sig=nhzzbfqHUOhN6iE%2BkyHQabRvtfc3pbxKQt4hHqlNtBZVliswTFfVIISFPo5Z%0Ads6YVeAKdqAAZuVFUwMDihA83ihIf8spWN%2BrKpeLxAhrUCM69oihD7csdedG%0AbN9TCToIp4q9tJj2o4SsAgxs3dK55Nc1vhCOlVB7mIbxM%2B8YGL4%3D%0A') # based on 'digest' data
    pairs.should_not include('key=secret-key')
  end

  it 'skips parameters that have nil value' do
    query = parse_authentication_url(nil, :secure => nil).query
    query.should_not include('next')
    query.should_not include('secure')
  end

  it 'should be able to exchange one-time for session token' do
    FakeWeb::register_uri(:get, 'https://www.google.com/accounts/AuthSubSessionToken',
      :string => "Token=G25aZ-v_8B\nExpiration=20061004T123456Z",
      :verify => lambda { |req|
        req['Authorization'].should == %(AuthSub token="dummytoken")
      }
    )

    Contacts::Google.session_token('dummytoken').should == 'G25aZ-v_8B'
  end
  
  it "should support client login" do
    FakeWeb::register_uri(:post, 'https://www.google.com/accounts/ClientLogin',
      :method => 'POST',
      :query => {
        'accountType' => 'GOOGLE', 'service' => 'cp', 'source' => 'Contacts-Ruby',
        'Email' => 'mislav@example.com', 'Passwd' => 'dummyPassword'
      },
      :string => "SID=klw4pHhL_ry4jl6\nLSID=Ij6k-7Ypnc1sxm\nAuth=EuoqMSjN5uo-3B"
    )
    
    Contacts::Google.client_login('mislav@example.com', 'dummyPassword').should == 'EuoqMSjN5uo-3B'
  end
  
  it "should support token authentication after client login" do
    @gmail = Contacts::Google.new('dummytoken', 'default', true)
    @gmail.headers['Authorization'].should == 'GoogleLogin auth="dummytoken"'
  end

  def parse_authentication_url(*args)
    URI.parse Contacts::Google.authentication_url(*args)
  end
  
end
