require 'redmine'

require 'dispatcher'

# Patches
require 'checkout_repositories_helper_patch'

# Hooks
require 'checkout_repository_hooks'

Redmine::Plugin.register :redmine_checkout do
  name 'Redmine Checkout plugin'
  author 'Holger Just'
  author_url 'http://dev.holgerjust.de/projects/show/redmine-checkout'
  description 'Adds a link to the actual repository to the GUI.'
  version '0.1'
  
  requires_redmine :version_or_higher => '0.8'
end
