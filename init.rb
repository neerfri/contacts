def relative_require(path)
  current_dir = File.dirname(__FILE__)
  require File.join(current_dir,path)
end

relative_require 'lib/contacts'
relative_require 'lib/contacts/flickr'
relative_require 'lib/contacts/google'
relative_require 'lib/contacts/windows_live'
relative_require 'lib/contacts/yahoo'

#if RAILS_ROOT/config/contacts.yml exists load it, if not load the local config file
app_config = File.join(File.dirname(__FILE__), '../../../config/contacts.yml')
plugin_config = File.join(File.dirname(__FILE__), 'config/contacts.yml')
Contacts.load_config_from_file(File.exists?(app_config) ? app_config : plugin_config)