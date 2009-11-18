require 'activeresource'

module ApiHooks
  class Server < ActiveResource::Base
    self.format = :json
  end

  class User < ActiveResource::Base
    self.format = :json
  end
  
  class Stack < ActiveResource::Base
    self.format = :json
  end
  
  def initialize_api(config)
    [Server, User, Stack].each do |model_class|
      model_class.site = StackFu::API.gsub(/api/, "#{config[:login]}:#{$config[:token]}@api") + "/"
    end
  end
end