module StackFu
  module ApiHooks
    class Resource < ActiveResource::Base
      self.format = :json
    end
    
    class Server < Resource; end
    class User < Resource; end
    class Stack < Resource; end
    class Script < Resource; end
    class Provider < Resource; end
    class Deployment < Resource; end
  
    def initialize_api(config)
      [Server, User, Stack, Script, Provider, Deployment].each do |model_class|
        model_class.user = $config[:token]
        model_class.password = "X"
        model_class.site = StackFu::API
      end
    end
  end
end