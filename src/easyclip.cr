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
    run_command(cmd, content)
  end

  # Retrieves the content from the clipboard.
  def paste : String
    cmd = paste_command
    result = run_command(cmd)
    return result
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

  private def run_command(cmd, content = nil)
    if content
      ps = Process.new(cmd, shell: true, input: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    else
      ps = Process.new(cmd, shell: true, output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    end
    if content
      stdin = ps.input
      stdin.print(content)
      stdin.close
    else
      stdout = ps.output
      content = stdout.gets_to_end
    end
    error_msg = ps.error.not_nil!.gets_to_end
    status = ps.wait
    unless status.success?
      error = content ? CopyError.new("[EasyClip] Copy operation failed: #{error_msg}") : PasteError.new("[EasyClip] Paste operation failed: #{error_msg}")
      raise error
    end
    content
  end
end
