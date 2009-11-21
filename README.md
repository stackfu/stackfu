# stackfu

* http://github.com/fcoury/stackfu

## DESCRIPTION:

## Future ideas

    $ sudo gem install stackfu
    Password:
    Successfully installed stackfu-0.3.2
    1 gem installed
        
    $ cd ~/Hosting
    $ stackfu generate stack lamp install_apache:script install_mysql:script install_php:script
    $ cd lamp

Would generate

    lamp/
      stack.rb
      scripts/
        install_apache.sh.erb
        install_mysql.sh.erb
        install_php.sh.erb
        
stack.rb

    stack "lamp" do
      requirements do
        check_folder "/var", :error => "You need /var folder before installing"
      end
    
      script "Install Apache", "install_apache"
      script "Install MySQL", "install_mysql"
      script "Install PHP", "install_php"
      
      verifications do
        check_folder "/etc/apache2", :error => "Apache was not installed properly"
        check_file "/etc/init.d/mysql", :error => "MySQL start script was not found"
      end
    end

Then
    
    $ cat ~/.stackfu
    cat: /Users/fcoury/.stackfu: No such file or directory
    
    $ stackfu add lamp
    Sending stack lamp to StackFu...
    Enter your login: fcoury
    Enter your password: 
    Stack lamp successfully saved

    $ cat ~/.stackfu
    login: fcoury
    password: abcdef
    
    $ stackfu list
    Listing 1 stack and 1 plugin:
      
      type      name       version
      --------- ---------- ---------
      stack     lamp             1.0
      plugin    firewall       1.2.2
    
    $ stackfu remove lamp
    Are you sure (y/n)? y
    Stack lamp removed
    
    $ stackfu list
    Nothing to show
    
    $ stackfu --help
    StackFu Commander 0.1.1, a stackfu command line client.
     (c) 2009-2020 StackFu - http://stackfu.com

      Usage: 
        stackfu -h/--help
        stackfu command [arguments] [options]
        
      Commands:
        add [stack/plugin]    sends the stack or plugin described in the current
                              folder
        list                  lists all the stacks and plugins currently hosted
                              under your account
    
    $ stackfu servers
    You current have 2 servers under your account:
    
      name         host           ip
      ------------ -------------  -------------------
      webby2847    Webbynode      208.88.103.25
      slippery     Slicehost      75.125.67.12
    
    $ stackfu deploy stack lamp to slippery
    WARNING: All data in this server will be destroyed.
    Confirm deployment of stack "lamp" to your server "slippery"
    at Slicehost? (y/n) 
    
    Redeploying slippery with Ubuntu 8.10... Done.
    
    Installing lamp stack...
       - Installing Apache2... Done.
       - Installing MySQL... Done.
       - Installing PHP... Done.
    
    Verifying installation...
       - Checking Apache... OK!
       - Checking MySQL... OK!
    
    Done.
    
    $ stackfu add plugin firewall to slippery
    Open port 80 (http) (y/n)? y
    Open port 22 (ssh)  (y/n)? y
    Enter other ports you want to open, separated by a comma: 
    
    OK, we'll install the Firewall plugin with Open port 80 and
    Open port 22.
    Confirm (y/n)? y
    
    Installing ufw... Done.
    Configuring ufw... Done.
    Do
    
    $ ssh root@75.125.67.12
    root@75.125.67.12's password:
    [slippery] $ ufw status
    Status: loaded

    To                         Action  From
    --                         ------  ----
    80/tcp                     ALLOW   Anywhere
    80/udp                     ALLOW   Anywhere
    21/tcp                     DENY    Anywhere
    21/udp                     DENY    Anywhere
    22/tcp                     ALLOW   Anywhere
    22/udp                     ALLOW   Anywhere
    
    [slippery] $ exit
    Connection to 75.125.67.12 closed.
    
    $ stackfu search plugin rails mongodb
    1 plugin found:
    
      Ruby on Rails with MongoDB's MongoMapper
      Key: rails-mongomapper
      Author: ctaborda
      Description: deploys a full Ruby on Rails stack
      with support to MongoDB's MongoMapper.
    
    $ stackfu clone ctaborda rails-mongomapper
    You have successfully cloned rails-mongomapper from fcoury
    
    $ stackfu list 
    stack   lamp              (1.0)
    plugin  firewall          (1.2.2)
    plugin  rails-mongomapper (2.1)
    
    $ stackfu import rails-mongomapper
    Import stack rails-mongomapper to the current folder (y/n)? y
    Done.
    
    $ cd rails-mongomapper
    $ ls -la
    drwx------    3 fcoury  staff       102 Jun 29 15:02 rails-mongomapper
    
    $ cd rails-mongomapper
    $ ls -la
    -rw-r--r--@   1 fcoury  staff       743 Aug 11 13:21 plugin.rb
    drwxr-xr-x    3 fcoury  staff       102 Apr  6  2009 scripts
    
    (...)
    
    $ stackfu add rails-mongomapper
    Plugin rails-mongomapper successfully saved

## FEATURES/PROBLEMS:

* FIX (list of features or problems)

## SYNOPSIS:

  FIX (code sample of usage)

## REQUIREMENTS:

* FIX (list of requirements)

## INSTALL:

* FIX (sudo gem install, anything else)

## LICENSE:

(The MIT License)

Copyright (c) 2009 FIXME full name

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.