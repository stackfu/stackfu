module StackFu
  module OperatingSystems
    OperatingSystems = [
      :arch_2009, :centos_52, :centos_53, :gentoo_2008, :debian_50, 
      :fedora_10, :ubuntu_804, :ubuntu_810, :ubuntu_904
    ]

    FriendlyNames = {
      "ArchLinux 2009" => :arch_2009,
      "Arch 2009" => :arch_2009,
      "Centos 5.2" => :centos_52,
      "Centos 5.3" => :centos_53,
      "Gentoo 2008" => :gentoo_2008,
      "Debian 5.0" => :debian_50,
      "Fedora 10" => :fedora_10,
      "Ubuntu 8.04" => :ubuntu_804,
      "Ubuntu 8.10" => :ubuntu_810,
      "Ubuntu 9.04" => :ubuntu_904
    }

    def convert_os(friendly)
      StackFu::OperatingSystems::FriendlyNames[friendly] or raise "Unknown OS: #{friendly}"
    end

    def os_name(os_key)
      os_key = os_key.try(:to_sym)
      StackFu::OperatingSystems::FriendlyNames.index(os_key) or raise "Unknown OS: #{os_key}"
    end
  end
end