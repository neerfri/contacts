current_dir = File.dirname(__FILE__)
def relative_require(path)
  require File.join(current_dir,path)
end

relative_require 'lib/contacts'
relative_require 'lib/contacts/flickr'
relative_require 'lib/contacts/google'
relative_require 'lib/contacts/windows_live'
relative_require 'lib/contacts/yahoo'