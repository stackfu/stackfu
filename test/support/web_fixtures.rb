module WebFixtures
  def stub_file(*path)
    File.join(File.dirname(__FILE__), "../stubs", path)
  end

  def stub_file_contents(*path)
    File.open(File.join(File.dirname(__FILE__), "../stubs", path), "r").readlines.join("")
  end

  def fake_webby_os(os)
    yaml_api = "https://manager.webbynode.com/api/yaml"

    response = stub_file_contents("webbynode", "fcoury@me.com", "webbies")
    response.gsub! ":os_template: 32", ":os_template: #{os}"

    FakeWeb.clean_registry
    FakeWeb.register_uri(:post, "#{yaml_api}/webbies", :response => response)
  end

  def fake_webbynode
    FakeWeb.clean_registry
    yaml_api = "https://manager.webbynode.com/api/yaml"

    users = {
      "fcoury@me.com" => "1da75b299084548ccd84990e463d4266e96abc5a",
      "ctab@me.com"   => "2da127cbffd4266e96abc5a8bbc671e1c2bb3bac",
    }

    fakes = {
      "webbies" => "webbies",
      "client"  => "client"
    }

    users.each_pair do |email, token|
      fakes.each_pair do |key, value|
        FakeWeb.register_uri(:post, "#{yaml_api}/#{key}", :email => email, :response => stub_file("webbynode", email, value))
      end
    end
  end
  
  SlicehostUsers = {
    "felipe.coury@gmail.com" => "6ed05e7521dfb6a19c98a84f2d0a28fdffc1bf00e050fe7114a66d3049e9715e"
  }

  def fake_slicehost
    FakeWeb.clean_registry

    SlicehostUsers.each_pair do |email, token|
      slicehost_register(:get, "/slices.xml", "slices")
    end
  end
  
  def fake_slicehost_no_slice
    FakeWeb.clean_registry

    SlicehostUsers.each_pair do |email, token|
      slicehost_register(:get, "/slices.xml", "slices_none")
    end
  end

  def fake_slicehost_os(os)
    user = SlicehostUsers.keys.first
    token = SlicehostUsers.values.first

    xml_api = "https://#{token}@api.slicehost.com"

    response = stub_file_contents("slicehost", user, "slices")
    response.gsub! "Content-Length: 554", "Content-Length: 553" if os.to_s.size < 2
    response.gsub! '<image-id type="integer">10</image-id>', "<image-id type=\"integer\">#{os}</image-id>"

    FakeWeb.clean_registry
    FakeWeb.register_uri(:get, "#{xml_api}/slices.xml", :response => response)
  end

  def fake_slice_creation(success=true)
    slicehost_register :post, "/slices.xml", "create_slice"
  end

  def fake_slice_deletion(slice_id, error="")
    slicehost_register :delete, "/slices/#{slice_id}.xml", "delete_slice#{error.present? ? "_#{error}" : ""}"
  end
  
  def slicehost_register(method, uri, file, user=SlicehostUsers.keys.first)
    token = SlicehostUsers[user]
    
    file = stub_file("slicehost", user, file)
    prefix = "https://#{token}@api.slicehost.com"
    
    FakeWeb.register_uri(method, "#{prefix}#{uri}", :response => file)
  end
end