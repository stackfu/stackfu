# module StackFu
#   class ServerCommand < Command
#     include StackFu::ApiHooks
#     include StackFu::ProvidersCredentials
# 
#     aliases :servers
#   
#     alias_subcommand :list => :default
#     # subcommand :add, :required_parameters => [:provider, :server_name]
#     subcommand :delete, :required_parameters => [:server_name]
# 
#     def default(parameters, options)
#       servers = spinner {
#         Server.find(:all)
#       }
# 
#       params = {
#         :class => Server, 
#         :collection => servers, 
#         :display => [:hostname, :provider_class, :ip, :status],
#         :labels => { :hostname => "Name", :provider_class => "Provider", :ip => "IP", :status => "Status" },
#         :main_column => :hostname,
#         :empty => "You have no servers under your account. Try adding some with 'server add' command.",
#         :ansi => options[:plain].nil?
#       }
#     
#       puts table(params) { |item| [item.hostname, item.provider_class, item.ip, item.status ? item.status[0] : ""] }
#     end
#   
#     def delete(parameters, options)
#       # TODO more than one server with the same hostname
#       spinner {
#         server = Server.find(:all).select { |s| s.hostname == parameters[0] }.first
#         server.destroy
#       }
#     
#       puts "Server #{parameters[0]} deleted successfully"
#     end
# 
#     def add(parameters, options)
#       if params?
#         if parameters.size < 2
#           puts "The command #{"server add".to_s.foreground(:yellow)} requires 2 parameters.\nUsage: stackfu server add PROVIDER SERVER_NAME"
#           return false
#         end
#         provider = parameters[0]
#         server_name = parameters[1]
#                 
#         user = User.find(:all).first
#         return false unless send("check_#{provider.downcase}", user)
#       else
#         server_add_header
#       end
#     
#       unless params?
#         provider, server_name = *server_menu
#       end
#     
#       server = Server.new(:provider_class => provider, :hostname => server_name)
#       result = spinner {
#         server.save
#       }
#     
#       puts " "
#       if result
#         puts "Server #{server_name} added successfully."
#       else
#         puts " "
#         puts "Server #{server_name} couldn't be added. Here's the error we've got:\n#{server.errors.full_messages.to_s}"
#       end
#     end
#   
#     private
#     
#     def check_slicehost(user)
#       unless user.settings.respond_to?(:slicehost_token)
#         return false unless add_slicehost_credentials(user)
#       end
#       
#       return true
#     end
#   
#     def check_webbynode(user)
#       unless user.settings.respond_to?(:webbynode_login) and user.settings.respond_to?(:webbynode_token) 
#         return false unless add_webbynode_credentials(user)
#       end
#       
#       return true
#     end
#   
#     def server_add_header
#       puts "=== Add Server ===".foreground(:green).bright
#     end
#   
#     def server_menu
#       user = User.find(:all).first
# 
#       providers = spinner { Provider.find(:all) }
#       provider_id = menu_for("provider", providers, true)
#     
#       provider = providers.select { |p| p.id == provider_id }.first
#     
#       puts ""
#       puts "Provider: #{provider_id.foreground(:blue)}"
#       puts ""
#       
#       return false unless send("check_#{provider_id.downcase}", user)
# 
#       servers = spinner { provider.get(:servers).to_structs }
#       server = menu_for("server", servers)
#     
#       puts ""
#       puts "Adding server #{server.foreground(:blue)}..."
#     
#       [provider_id.titleize, server]
#     end
#   
#     def slicehost
#       spinner {
#         UserAccount.find(:conditions => { :provider => "Slicehost" }).servers
#       }
#     end
#   end
# end