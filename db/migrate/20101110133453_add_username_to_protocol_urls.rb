class AddUsernameToProtocolUrls < ActiveRecord::Migration
  class Repository < ActiveRecord::Base
    def self.inheritance_column
      # disable single table inheritance
      nil
    end
    
    def scm_name
      self.type || 'Abstract'
    end
    
    serialize :checkout_settings, Hash
  end
  
  def self.up
    ## First migrate the individual repositories
    Repository.all.each do |r|
      if r.scm_name == "Subversion"
        display_login = r.checkout_settings.delete 'checkout_display_login'
        display_login = display_login.present? ? '1' : '0'
      else
        display_login = '0'
      end
      
      protocols = r.checkout_settings['checkout_protocols']
      protocols.each {|p| p["display_login"] = display_login} if protocols
      r.save!
    end
    
    ## Then the global settings
    settings = Setting.plugin_redmine_checkout
    settings.keys.grep(/^protocols_/).each do |protocols|
      if protocols == "protocols_Subversion"
        display_login = settings["display_login"].present? ? '1' : '0'
      else
        display_login = '0'
      end
      
      settings[protocols].each do |protocol|
        protocol["display_login"] = display_login
      end
    end
    settings.delete "display_login"
    Setting.plugin_redmine_checkout = settings
  end
  
  def self.down
    raise ActiveRecord::IrreversibleMigration.new "Sorry, there is no down migration yet. If you really need one, please create an issue on http://dev.holgerjust.de/projects/redmine-checkout"
  end
end