require "ricer4-auth"
module Ricer4
  module Plugins
    module Auth
      
      add_ricer_plugin_module(File.dirname(__FILE__)+'/ricer4/auth_email')
      
    end
  end
end