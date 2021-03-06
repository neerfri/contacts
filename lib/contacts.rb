require 'contacts/version'

module Contacts
  
  module PROVIDER
    Google = "Google"
    Yahoo = "Yahoo"
    WindowsLive = "WindowsLive"
  end
  
  Identifier = 'Ruby Contacts v' + VERSION::STRING
  DEFAULT_CONFIG_FILE_PATH = File.join(File.dirname(__FILE__), '/../config/contacts.yml')
  
  # An object that represents a single contact
  class Contact
    attr_reader :name, :username, :emails
    
    def initialize(email, name = nil, username = nil)
      @emails = []
      @emails << email if email
      @name = name
      @username = username
    end
    
    def email
      @emails.first
    end
    
    def inspect
      %!#<Contacts::Contact "#{name}"#{email ? " (#{email})" : ''}>!
    end
  end
  
  def self.verbose?
    'irb' == $0
  end
  
  class Error < StandardError
  end
  
  class TooManyRedirects < Error
    attr_reader :response, :location
    
    MAX_REDIRECTS = 2
    
    def initialize(response)
      @response = response
      @location = @response['Location']
      super "exceeded maximum of #{MAX_REDIRECTS} redirects (Location: #{location})"
    end
  end
  
  
  def self.auth_redirect_url_for(provider, options={})
    case provider
      when Contacts::PROVIDER::Google
        Contacts::Google.authentication_url(options[:return_uri], :key=>options[:key])
      when Contacts::PROVIDER::WindowsLive
        Contacts::WindowsLive.new.get_authentication_url
      when Contacts::PROVIDER::Yahoo
        Contacts::Yahoo.new.get_authentication_url
    end
  end
  
  def self.get_contacts(provider, secret)
    case provider
      when Contacts::PROVIDER::WindowsLive
        wl = Contacts::WindowsLive.new
        contacts = wl.contacts(secret)
      when Contacts::PROVIDER::Google
        gmail = Contacts::Google.new(secret)
        contacts = gmail.contacts
      when Contacts::PROVIDER::Yahoo
        yahoo = Contacts::Yahoo.new
        contacts = yahoo.contacts(secret)
      when "Test"
        contacts = [Contacts::Contact.new("Test", "test@example.com")]
    end
  end
  
  def self.load_config_from_file(path)
    config_hash = YAML.load_file(path)
    @@config = config_hash[ENV['RAILS_ENV']] ? config_hash[ENV['RAILS_ENV']] : config_hash 
  end

  def self.config
    Thread.exclusive do
      load_config_from_file(DEFAULT_CONFIG_FILE_PATH) if !defined?(@@config)
    end
    @@config
  end
end
