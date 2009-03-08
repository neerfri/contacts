current_dir = File.dirname(__FILE__)

puts "Copying contacts.yml file to config directory..."
FileUtils.cp File.join(current_dir,'config/contacts.yml'), File.join(RAILS_ROOT, 'config')
