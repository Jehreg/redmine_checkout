require_dependency 'repositories_helper'

module RepositoriesHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :repository_field_tags, :checkout
    end
  end
  
  module InstanceMethods
    def repository_field_tags_with_checkout(form, repository)    
      tags = repository_field_tags_without_checkout(form, repository) || ""
      return tags if repository.class.name == "Repository"
      
      tags +
      content_tag('p',
        form.select(:checkout_url_type, [
            [l(:label_checkout_type_original), 'original'],
            [l(:label_checkout_type_none), 'none'],
            [l(:label_checkout_type_overwritten), 'overwritten']
          ],
          {},
          :onchange => <<-EOF
            if ($A(['original', 'none']).include(value)){
              $('checkout_url').hide();
            } else {
              var txt = $('repository_checkout_url');
              if (txt.value.empty()) {txt.value = $('repository_url').value;}
              $('checkout_url').show();
            }
            EOF
        )
      ) +
      content_tag('p',
        form.text_field(:checkout_url, :size => 60),
        :id => "checkout_url",
        :style => ("display:none" unless ['overwritten'].include? form.object.checkout_url_type)
      ) + 
      content_tag('p',
        form.select(:display_login, [
            [l(:label_display_login_none), 'none'],
            [l(:label_display_login_username), 'username'],
            [l(:label_display_login_password), 'password']
          ]
        )
      )
    end
  end
end

RepositoriesHelper.send(:include, RepositoriesHelperPatch)

