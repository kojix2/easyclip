require "./easyclip/errors"
require "./easyclip/command"
require "./easyclip/backend"
require "./easyclip/process_backend"
require "./easyclip/unix_backend"
require "./easyclip/windows_backend"

module EasyClip
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  extend self

  # Copies the given content to the clipboard.
  def copy(content : String) : Nil
    backend.copy(content)
  end

  # Retrieves the content from the clipboard.
  def paste : String
    backend.paste
  end

  private def backend : Backend
    {% if flag?(:win32) %}
      WindowsBackend.new
    {% else %}
      UnixBackend.new
    {% end %}
  end
end
