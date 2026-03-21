module EasyClip
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  extend self

  # Base class for EasyClip errors
  class Error < Exception
  end

  # Raised when an error occurs during the copy operation
  class CopyError < Error
  end

  # Raised when an error occurs during the paste operation
  class PasteError < Error
  end

  # Copies the given content to the clipboard.
  # Note for Windows: Trailing newline characters will be appended to the content when copied to the clipboard.
  def copy(content : String) : Nil
    cmd, args = copy_command
    run_copy_command(cmd, args, content)
  end

  # Retrieves the content from the clipboard.
  def paste : String
    cmd, args = paste_command
    run_paste_command(cmd, args)
  end

  private def copy_command
    {% if flag?(:darwin) %}
      {"pbcopy", [] of String}
    {% elsif flag?(:unix) %}
      {% if flag?(:wayland) %}
        {"wl-copy", [] of String}
      {% elsif flag?(:xsel) %}
        {"xsel", ["-ib"]}
      {% else %}
        {"xsel", ["-ib"]}
      {% end %}
    {% elsif flag?(:win32) %}
      {"clip", [] of String}
    {% end %}
  end

  private def paste_command
    {% if flag?(:darwin) %}
      {"pbpaste", [] of String}
    {% elsif flag?(:unix) %}
      {% if flag?(:wayland) %}
        {"wl-paste", [] of String}
      {% elsif flag?(:xsel) %}
        {"xsel", ["-ob"]}
      {% else %}
        {"xsel", ["-ob"]}
      {% end %}
    {% elsif flag?(:win32) %}
      {"powershell.exe", ["-command", "Get-Clipboard"]}
    {% end %}
  end

  private def run_copy_command(cmd : String, args : Array(String), content : String)
    ps = Process.new(cmd, args, shell: false, input: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    stdin = ps.input
    stdin.print(content)
    stdin.close
    handle_process_error(ps, "Copy")
  end

  private def run_paste_command(cmd : String, args : Array(String))
    ps = Process.new(cmd, args, shell: false, output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    content = ps.output.gets_to_end
    handle_process_error(ps, "Paste")
    content
  end

  private def handle_process_error(ps : Process, operation : String)
    error_msg = ps.error.not_nil!.gets_to_end
    status = ps.wait
    unless status.success?
      case operation
      when "Copy"
        raise CopyError.new("[EasyClip] #{operation} operation failed: #{error_msg}")
      when "Paste"
        raise PasteError.new("[EasyClip] #{operation} operation failed: #{error_msg}")
      else
        raise Error.new("[EasyClip] Unknown operation: #{operation}")
      end
    end
  end
end
