module StackFu
  module ApiHooks
    class Server < ActiveResource::Base; end
    class User < ActiveResource::Base; end
    class Stack < ActiveResource::Base; end
    class Provider < ActiveResource::Base; end
    class Deployment < ActiveResource::Base; end
  
    def initialize_api(config)
      [Server, User, Stack, Provider, Deployment].each do |model_class|
        model_class.format = :json
        model_class.site = StackFu::API.gsub(/api/, "#{config[:login]}:#{$config[:token]}@api") + "/"
      end
    end
  end
end