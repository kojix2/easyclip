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
  def copy(content : String)
    cmd = copy_command
    run_copy_command(cmd, content)
  end

  # Retrieves the content from the clipboard.
  def paste : String
    cmd = paste_command
    run_paste_command(cmd)
  end

  private def copy_command
    {% if flag?(:darwin) %}
      "pbcopy"
    {% elsif flag?(:unix) %}
      "xsel -ib"
    {% elsif flag?(:win32) %}
      "clip"
    {% end %}
  end

  private def paste_command
    {% if flag?(:darwin) %}
      "pbpaste"
    {% elsif flag?(:unix) %}
      "xsel -ob"
    {% elsif flag?(:win32) %}
      "powershell.exe -command Get-Clipboard"
    {% end %}
  end

  private def run_copy_command(cmd, content : String)
    ps = Process.new(cmd, shell: true, input: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    stdin = ps.input
    stdin.print(content)
    stdin.close
    handle_process_error(ps, "Copy")
  end

  private def run_paste_command(cmd)
    ps = Process.new(cmd, shell: true, output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    stdout = ps.output
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
