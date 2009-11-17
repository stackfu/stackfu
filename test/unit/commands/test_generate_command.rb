require File.dirname(__FILE__) + '/../../test_helper.rb'

class TestGenerateCommand < Test::Unit::TestCase
  context "empty command" do
    should "present the options" do
      command "generate"
      stdout.should =~ /You have to tell what you want to generate/
      stdout.should =~ /stack/
      stdout.should =~ /plugin/
    end
  end
  
  context "command generate stack" do
    should "show the requirement parameter if none given" do
      command "generate stack"
      stdout.should =~ /STACK_NAME/
    end
    
    ## Normal behavior
    
    should "generate the manifest and script folder when only stack name is given" do
      prepare_stack
      command "generate stack test"
      stdout.should =~ /Manifest/
      stdout.should =~ /script/
    end
    
    should "generate the manifest and scripts one scripts is passed" do
      prepare_stack(:scripts => ["install_counterstrike_server"])
      command "generate stack test install_counterstrike_server:script"
      stdout.should =~ /Manifest/
      stdout.should =~ /script/
      stdout.should =~ /install_counterstrike_server.sh.erb/
    end
    
    should "generate the manifest with the controls" do
      GenerateCommand.any_instance.expects(:create).with do |dir, file, contents|
        dir == "test/scripts"
      end
      
      GenerateCommand.any_instance.expects(:create).with do |dir, file, contents|
        file == "install_counterstrike_server.sh.erb"
      end
      
      GenerateCommand.any_instance.expects(:create).with do |dir, file, contents|
        (dir == "test" && file == "Manifest.yml" && 
        contents =~ /Clan Name/       &&
        contents =~ /clan_name/       &&
        contents =~ /Textbox/         &&
        contents =~ /Clan Password/   &&
        contents =~ /clan_password/   &&
        contents =~ /Password/)
      end
      
      command "generate stack test clan_name:textbox clan_password:password install_counterstrike_server:script"
    end
    
    ## Error conditions

    should "raise a nice error when mkdir fails" do
      prepare_stack(:creating_folder => IOError)
      command "generate stack test"
      stdout.should =~ /There was an error creating your stack: Error description/
    end

    should "raise a nice error when fails to create the manifest" do
      prepare_stack(:creating_manifest => IOError)
      command "generate stack test"
      stdout.should =~ /There was an error creating your stack: Error description/
    end
    
    should "raise a nice error when mkdir fails because there is a file with same name" do
      prepare_stack(:creating_folder => Errno::EEXIST)
      command "generate stack test"
      stdout.should =~ /There was an error creating your stack: File exists - Error description/
    end
  end
  
  private
  
  def prepare_stack(opts={})
    manifest_input = mock("Manifest input")
    manifest_output = mock("Manifest output")
    template = File.dirname(__FILE__) + '/../../../templates/Manifest.yml.erb'
    
    script_template = IO.readlines(File.dirname(__FILE__) + '/../../../templates/script.sh.erb')
    contents = IO.readlines(template)

    File.expects(:open).with { |v1, v2| v1 =~ /Manifest.yml.erb/ && v2 == "r" }.returns(manifest_input)
    manifest_input.expects(:readlines).returns(contents)

    File.expects(:open).with("test/Manifest.yml", "w").yields(manifest_output)
    
    output = contents.clone.join("")
    output.gsub!("<%= stack_type %>", "stack")
    output.gsub!("<%= name %>", "test")
    output.gsub!("<%= description %>", "Enter a description for this stack here")
    output.gsub!("<%%", "<%")
    
    if (exc = opts[:creating_manifest])
      manifest_output.expects(:write).with do |s| 
        s =~ /type: stack/
        s =~ /name: "test"/
        s =~ /description: "Enter a description for this stack here"/
      end.raises(exc, "Error description")
      
      return
    end
    
    manifest_output.expects(:write).with do |s| 
      s =~ /type: stack/
      s =~ /name: "test"/
      s =~ /description: "Enter a description for this stack here"/
    end
  
    if (exc = opts[:creating_folder])
      FileUtils.expects(:mkdir_p).with("test/scripts").raises(exc, "Error description")
      return
    end

    FileUtils.expects(:mkdir_p).with("test/scripts")

    if (scripts = opts[:scripts])
      scripts.each do |s|
        FileUtils.expects(:mkdir_p).with("test/scripts")

        script_input = mock("Script input stream")
        
        File.expects(:open).with { |v1, v2| v1 =~ /script.sh.erb/ && v2 == "r"}.returns(script_input)
        script_input.expects(:readlines).returns(script_template)
        
        script_output = script_template.clone.join("")
        script_output.gsub("<%= filename %>", "#{s}.sh.erb")
        script_output.gsub("<%= description %>", "#{s.titleize}")
        output.gsub!("<%%", "<%")
        
        script = mock("Script #{s}")
        File.expects(:open).with("test/scripts/#{s}.sh.erb", "w").yields(script)
        script.expects(:write).with { |v| v =~ /Installing -- #{s.titleize}/ }
      end
    end
  end
end