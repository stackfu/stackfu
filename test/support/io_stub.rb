module IoStub
  def stdout
    $stdout.rewind
    $stdout.read
  end
  
  def debug(s)
    @orig_stdout.puts s
  end
end