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

private def with_env(name : String, value : String?, &)
  old_value = ENV[name]?
  if value
    ENV[name] = value
  else
    ENV.delete(name)
  end
  yield
ensure
  if old_value
    ENV[name] = old_value
  else
    ENV.delete(name)
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

private def with_fake_commands(*names : String, &)
  dir = File.tempname("easyclip-spec")
  Dir.mkdir(dir)
  begin
    names.each do |name|
      path = File.join(dir, name)
      File.write(path, "#!/bin/sh\nexit 0\n")
      File.chmod(path, 0o755)
    end
    yield dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

describe EasyClip::UnixBackend do
  {% if flag?(:linux) %}
    it "uses xsel for X11 copy" do
      with_fake_commands("xsel", "xclip") do |dir|
        with_path(dir) do
          commands = EasyClip::UnixBackend.new.copy_commands

          commands.should eq([
            {command: "xsel", args: ["-ib"]},
          ])
        end
      end
    end

    it "detects Wayland copy support at runtime" do
      with_fake_commands("wl-copy", "xsel") do |dir|
        with_path(dir) do
          with_env("XDG_SESSION_TYPE", nil) do
            with_env("WAYLAND_DISPLAY", "wayland-0") do
              commands = EasyClip::UnixBackend.new.copy_commands

              commands.should eq([
                {command: "wl-copy", args: [] of String},
                {command: "xsel", args: ["-ib"]},
              ])
            end
          end
        end
      end
    end

    it "detects Wayland paste support at runtime" do
      with_fake_commands("wl-paste", "xclip", "xsel") do |dir|
        with_path(dir) do
          with_env("WAYLAND_DISPLAY", nil) do
            with_env("XDG_SESSION_TYPE", "wayland") do
              commands = EasyClip::UnixBackend.new.paste_commands

              commands.should eq([
                {command: "wl-paste", args: [] of String},
                {command: "xclip", args: ["-selection", "clipboard", "-out"]},
                {command: "xsel", args: ["-ob"]},
              ])
            end
          end
        end
      end
    end
  {% end %}
end
