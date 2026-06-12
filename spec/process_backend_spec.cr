require "./spec_helper"
require "file_utils"

private class SpecProcessBackend < EasyClip::ProcessBackend
  def initialize(@copy_commands : Array(EasyClip::Command), @paste_commands : Array(EasyClip::Command))
  end

  def copy_commands : Array(EasyClip::Command)
    @copy_commands
  end

  def paste_commands : Array(EasyClip::Command)
    @paste_commands
  end
end

private def with_temp_executable(name : String, body : String, &)
  dir = File.tempname("easyclip-spec")
  Dir.mkdir(dir)
  begin
    path = File.join(dir, name)
    File.write(path, body)
    File.chmod(path, 0o755)
    yield path, dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

describe EasyClip::ProcessBackend do
  it "falls back to the next copy command when a command fails" do
    with_temp_executable("fail-copy", "#!/bin/sh\necho copy failed >&2\nexit 7\n") do |fail_copy, dir|
      capture = File.join(dir, "clipboard.txt")
      with_temp_executable("copy", "#!/bin/sh\ncat > \"$1\"\n") do |copy, _|
        backend = SpecProcessBackend.new(
          [
            {command: fail_copy, args: [] of String},
            {command: copy, args: [capture]},
          ],
          [] of EasyClip::Command
        )

        backend.copy("hello\nworld")

        File.read(capture).should eq("hello\nworld")
      end
    end
  end

  it "falls back to the next paste command when a command fails" do
    with_temp_executable("fail-paste", "#!/bin/sh\necho paste failed >&2\nexit 8\n") do |fail_paste, _|
      with_temp_executable("paste", "#!/bin/sh\nprintf pasted-text\n") do |paste, _|
        backend = SpecProcessBackend.new(
          [] of EasyClip::Command,
          [
            {command: fail_paste, args: [] of String},
            {command: paste, args: [] of String},
          ]
        )

        backend.paste.should eq("pasted-text")
      end
    end
  end

  it "raises a copy error when no copy command is available" do
    backend = SpecProcessBackend.new([] of EasyClip::Command, [] of EasyClip::Command)

    expect_raises(EasyClip::CopyError, /no supported clipboard command/) do
      backend.copy("text")
    end
  end

  it "raises a paste error when every paste command fails" do
    with_temp_executable("fail-paste", "#!/bin/sh\necho paste failed >&2\nexit 9\n") do |fail_paste, _|
      backend = SpecProcessBackend.new(
        [] of EasyClip::Command,
        [{command: fail_paste, args: [] of String}]
      )

      expect_raises(EasyClip::PasteError, /paste failed/) do
        backend.paste
      end
    end
  end
end
