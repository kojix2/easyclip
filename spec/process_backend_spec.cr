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

private def crystal_command(args : Array(String)) : EasyClip::Command
  crystal = Process.find_executable("crystal") || raise "crystal executable not found"
  {command: crystal, args: args}
end

private def eval_command(code : String, *args : String) : EasyClip::Command
  crystal_command(["eval", code, "--"] + args.to_a)
end

private def eval_command(code : String) : EasyClip::Command
  crystal_command(["eval", code])
end

private def with_temp_dir(&)
  dir = File.tempname("easyclip-spec")
  Dir.mkdir(dir)
  begin
    yield dir
  ensure
    FileUtils.rm_rf(dir)
  end
end

describe EasyClip::ProcessBackend do
  it "falls back to the next copy command when a command fails" do
    with_temp_dir do |dir|
      capture = File.join(dir, "clipboard.txt")
      backend = SpecProcessBackend.new(
        [
          eval_command(%(STDERR.puts "copy failed"; exit 7)),
          eval_command(%(File.write(ARGV[0], STDIN.gets_to_end)), capture),
        ],
        [] of EasyClip::Command
      )

      backend.copy("hello\nworld")

      File.read(capture).should eq("hello\nworld")
    end
  end

  it "falls back to the next paste command when a command fails" do
    backend = SpecProcessBackend.new(
      [] of EasyClip::Command,
      [
        eval_command(%(STDERR.puts "paste failed"; exit 8)),
        eval_command(%(print "pasted-text")),
      ]
    )

    backend.paste.should eq("pasted-text")
  end

  it "raises a copy error when no copy command is available" do
    backend = SpecProcessBackend.new([] of EasyClip::Command, [] of EasyClip::Command)

    expect_raises(EasyClip::CopyError, /no supported clipboard command/) do
      backend.copy("text")
    end
  end

  it "raises a paste error when every paste command fails" do
    backend = SpecProcessBackend.new(
      [] of EasyClip::Command,
      [eval_command(%(STDERR.puts "paste failed"; exit 9))]
    )

    expect_raises(EasyClip::PasteError, /paste failed/) do
      backend.paste
    end
  end
end
