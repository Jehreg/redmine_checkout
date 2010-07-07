class ApplySettingChanges < ActiveRecord::Migration
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
    default_commands = {
      'Bazaar' => 'bzr checkout',
      'Cvs' => 'cvs checkout',
      'Darcs' => 'darcs get',
      'Git' => 'git clone',
      'Mercurial' => 'hg clone',
      'Subversion' => 'svn checkout'
    }
    
    ## First migrate the individual repositories
    
    Repository.all.each do |r|
      allow_subtree_checkout = ['Cvs', 'Subversion'].include? r.scm_name
      
      protocol = case r.checkout_settings['checkout_url_type']
      when 'none', 'generated'
        nil
      when 'original', 'overwritten'
        { "0" => {
          :protocol => r.scm_name,
          :command => Setting.plugin_redmine_checkout["checkout_cmd_#{r.scm_name}"] || default_commands[r.scm_name],
          :regex => "",
          :regex_replacement => "",
          :fixed_url => (r.checkout_settings['checkout_url_type'] == 'original' ? (r.url || "") : r.checkout_setings["checkout_url"]),
          :access => 'permission',
          :append_path => (allow_subtree_checkout ? '1' : '0'),
          :is_default => '1'}
        }
      end
      
      r.checkout_settings = {
        'checkout_protocols' => protocol,
        'checkout_description' => "The data contained in this repository can be downloaded to your computer using one of several clients.
Please see the documentation of your version control software client for more information.

Please select the desired protocol below to get the URL.",
        'checkout_display_login' => (r.checkout_settings['display_login'] == 'none' ? '' : r.checkout_settings['display_login']),
        'checkout_overwrite' => (r.checkout_settings['checkout_url_overwrite'] == 'true') ? '1': '0',
        'checkout_display_command' => (r.checkout_settings["render_type"].to_s == 'cmd') ? '1' : '0'
      }
      r.save!
    end
    
    ## Then the global settings
    
    settings = {
      'display_login' => Setting.plugin_redmine_checkout['display_login'],
      'use_zero_clipboard' => '1',

      'display_checkout_info' => (Setting.plugin_redmine_checkout['checkout_url_type'] == 'none' ? '0' : '1'),
      'description_Abstract' => <<-EOF
The data contained in this repository can be downloaded to your computer using one of several clients.
Please see the documentation of your version control software client for more information.

Please select the desired protocol below to get the URL.
EOF
    }

    CheckoutHelper.supported_scm.each do |scm|
      settings["description_#{scm}"] = ''
      settings["overwrite_description_#{scm}"] = '0'
      
      display_command = (Setting.plugin_redmine_checkout["render_type"].to_s == 'cmd') ? '1' : '0'
      settings["display_command_#{scm}"] = display_command
      
      case Setting.plugin_redmine_checkout['checkout_url_type']
      when 'generated', 'none':
        regex = Setting.plugin_redmine_checkout["checkout_url_regex_#{scm}"]
        replacement = Setting.plugin_redmine_checkout["checkout_url_regex_replacement_#{scm}"]
      when 'original':
        regex = ''
        replacement = ''
      end
      
      settings["protocols_#{scm}"] = {
        # access can be one of
        #   read+write => this protocol always allows read/write access
        #   read-only => this protocol always allows read access only
        #   permission => Access depends on redmine permissions
        '0' => {:protocol => scm,
                :command => Setting.plugin_redmine_checkout["checkout_cmd_#{scm}"] || default_commands[scm],
                :regex => regex,
                :regex_replacement => replacement,
                :fixed_url => '',
                :access => 'permission',
                :append_path => (['Cvs', 'Subversion'].include?(scm) ? '1' : '0'),
                :is_default => '1'
               }
      }
    end
    Setting.plugin_redmine_checkout = settings
  end
  
  def self.down
  end
end