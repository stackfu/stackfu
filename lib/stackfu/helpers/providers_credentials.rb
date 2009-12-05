module StackFu
  module ProvidersCredentials 
    def add_webbynode_credentials(user)
      while true
        puts ""
        puts "Enter your Webbynode API credentials below (or type 'help' for more information or 'abort' to abort)"

        login = ask("Webbynode Login:")
      
        unless login.try(:downcase) == "abort" or login.try(:downcase) == "help"
          token = ask("Webbynode Token:")
        end
      
        credentials = [login || "", token || ""].map(&:downcase)
      
        if credentials.include?('help')
          puts ""
          puts "== Webbynode StackFu integration ==".foreground(:green).bright
          puts ""
          puts "In order to allow StackFu to integrate itself with Webbynode, you need to provide the email address you use to login into Webbynode Manager and your API token."
          puts ""
          puts "This can be easily done by visiting your '#{"Account".foreground(:cyan)}' area in Webbynode Manager. On the box where your summary is presented, copy the 'API Token:' field content."
          puts ""
          puts "If you need further information, visit #{"http://stackfu.com/faq/webbynode-api-integration".underline} for a complete walkthrough of this process."

        elsif credentials.include?('abort')
        
          puts "Aborted adding server."
          return false

        else
          user.settings.webbynode_login = login
          user.settings.webbynode_token = token
        
          if user.save
            puts ""
            puts "Webbynode credentials saved."
          else
            puts "Error: #{user.errors.full_messages.to_s}"
          end
        
          return true          
        end
      end
    end
  
    def add_slicehost_credentials(user)
      while true
        puts ""
        puts "Enter your Slicehost API password (or type 'help' for more information or 'abort' to abort): "

        token = ask("")
  
        unless ['help', 'abort'].include? token.downcase
          user.settings.slicehost_token = token
          if user.save
            puts ""
            puts "Slicehost credentials saved."
          else
            puts "Error: #{user.errors.full_messages.to_s}"
          end
          return true
        end
    
        if token.downcase == 'abort'
          puts ""
          puts "Aborted adding server."
          return false
        else
          puts ""
          puts "== Slicehost StackFu integration ==".foreground(:green).bright
          puts ""
          puts "In order to allow StackFu to integrate itself with Slicehost, you need to enabled your API Access and provide us your API Password."
          puts ""
          puts "This can be easily done by visiting your '#{"Account > API Access".foreground(:cyan)}' area in Slicehost manager."
          puts ""
          puts "If you need further information, visit #{"http://stackfu.com/faq/slicehost-api-integration".underline} for a complete walkthrough of this process."
        end
      end
    end
  end
end