module EasyClip
  POWERSHELL_PASTE_COMMAND = "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::Out.Write((Get-Clipboard -Raw))"

  class UnixBackend < ProcessBackend
    def copy_commands : Array(Command)
      {% if flag?(:darwin) %}
        available_commands({command: "pbcopy", args: [] of String})
      {% elsif flag?(:unix) %}
        available_commands(linux_copy_candidates)
      {% else %}
        [] of Command
      {% end %}
    end

    def paste_commands : Array(Command)
      {% if flag?(:darwin) %}
        available_commands({command: "pbpaste", args: [] of String})
      {% elsif flag?(:unix) %}
        available_commands(linux_paste_candidates)
      {% else %}
        [] of Command
      {% end %}
    end

    private def linux_copy_candidates : Array(Command)
      wayland = {command: "wl-copy", args: [] of String}
      xsel = {command: "xsel", args: ["-ib"]}
      termux = {command: "termux-clipboard-set", args: [] of String}
      wsl = {command: "clip.exe", args: [] of String}

      return [termux] if termux?
      return [wsl] if wsl?
      # On a Wayland session, X11 tools may still work via XWayland, so keep them
      # as a fallback when wl-clipboard is not installed.
      return [wayland, xsel] if wayland_session?

      [xsel]
    end

    private def linux_paste_candidates : Array(Command)
      wayland = {command: "wl-paste", args: [] of String}
      xclip = {command: "xclip", args: ["-selection", "clipboard", "-out"]}
      xsel = {command: "xsel", args: ["-ob"]}
      termux = {command: "termux-clipboard-get", args: [] of String}

      return [termux] if termux?
      return wsl_paste_candidates if wsl?
      # On a Wayland session, X11 tools may still work via XWayland, so keep them
      # as a fallback when wl-clipboard is not installed.
      return [wayland, xclip, xsel] if wayland_session?

      [xclip, xsel]
    end

    # On WSL, paste goes through the Windows-side PowerShell. The `.exe` suffix is
    # required so we don't accidentally pick a Linux-side `pwsh`, which cannot read
    # the Windows clipboard.
    private def wsl_paste_candidates : Array(Command)
      [
        {command: "pwsh.exe", args: powershell_args(POWERSHELL_PASTE_COMMAND)},
        {command: "powershell.exe", args: powershell_args(POWERSHELL_PASTE_COMMAND)},
      ]
    end

    private def powershell_args(command : String) : Array(String)
      ["-NoProfile", "-NonInteractive", "-Command", command]
    end

    private def wayland_session? : Bool
      !!ENV["WAYLAND_DISPLAY"]? || ENV["XDG_SESSION_TYPE"]? == "wayland"
    end

    private def termux? : Bool
      !!ENV["TERMUX_VERSION"]? || (ENV["PREFIX"]?.try(&.includes?("com.termux")) || false)
    end

    private def wsl? : Bool
      !!ENV["WSL_DISTRO_NAME"]? || !!ENV["WSL_INTEROP"]? || linux_proc_version.includes?("microsoft")
    end

    private def linux_proc_version : String
      File.exists?("/proc/version") ? File.read("/proc/version").downcase : ""
    rescue
      ""
    end
  end
end
