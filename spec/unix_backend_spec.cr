require "./spec_helper"
require "file_utils"

private def with_path(path : String, &)
  old_path = ENV["PATH"]?
  ENV["PATH"] = path
  yield
ensure
  if old_path
    ENV["PATH"] = old_path
  else
    ENV.delete("PATH")
  end
end

private def with_fake_command(name : String, &)
  dir = File.tempname("easyclip-spec")
  Dir.mkdir(dir)
  begin
    path = File.join(dir, name)
    File.write(path, "#!/bin/sh\nexit 0\n")
    File.chmod(path, 0o755)
    yield dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

describe EasyClip::UnixBackend do
  {% if flag?(:darwin) %}
    it "selects pbcopy for copy on macOS" do
      with_fake_command("pbcopy") do |dir|
        with_path(dir) do
          commands = EasyClip::UnixBackend.new.copy_commands

          commands.map(&.[:command]).should eq(["pbcopy"])
        end
      end
    end

    it "selects pbpaste for paste on macOS" do
      with_fake_command("pbpaste") do |dir|
        with_path(dir) do
          commands = EasyClip::UnixBackend.new.paste_commands

          commands.map(&.[:command]).should eq(["pbpaste"])
        end
      end
    end
  {% end %}
end
