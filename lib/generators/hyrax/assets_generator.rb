# -*- encoding : utf-8 -*-
require 'rails/generators'

class Hyrax::AssetsGenerator < Rails::Generators::Base
  desc """
    This generator installs the hyrax CSS assets into your application
       """

  source_root File.expand_path('../templates', __FILE__)

  def remove_blacklight_css
    remove_file "app/assets/stylesheets/blacklight.scss"
  end

  def inject_css
    copy_file "hyrax.scss", "app/assets/stylesheets/hyrax.scss"
  end

  def inject_js
    return if hyrax_javascript_installed?
    insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
      <<-EOF.strip_heredoc

        //= require hyrax
      EOF
    end
  end

  private

    def hyrax_javascript_installed?
      IO.read("app/assets/javascripts/application.js").include?('hyrax')
    end
end
