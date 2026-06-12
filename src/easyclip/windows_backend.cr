module EasyClip
  {% if flag?(:win32) %}
    CF_UNICODETEXT =     13_u32
    GMEM_MOVEABLE  = 0x0002_u32
    GMEM_ZEROINIT  = 0x0040_u32

    @[Link("user32")]
    private lib LibUser32
      fun open_clipboard = OpenClipboard(hwnd_new_owner : Void*) : Int32
      fun close_clipboard = CloseClipboard : Int32
      fun empty_clipboard = EmptyClipboard : Int32
      fun set_clipboard_data = SetClipboardData(format : UInt32, mem : Void*) : Void*
      fun get_clipboard_data = GetClipboardData(format : UInt32) : Void*
      fun is_clipboard_format_available = IsClipboardFormatAvailable(format : UInt32) : Int32
    end

    @[Link("kernel32")]
    private lib LibKernel32
      fun global_alloc = GlobalAlloc(flags : UInt32, bytes : LibC::SizeT) : Void*
      fun global_free = GlobalFree(mem : Void*) : Void*
      fun global_lock = GlobalLock(mem : Void*) : Void*
      fun global_unlock = GlobalUnlock(mem : Void*) : Int32
      fun get_last_error = GetLastError : UInt32
    end

    class WindowsBackend < Backend
      # Another process may briefly hold the clipboard (clipboard managers, RDP,
      # other apps), so OpenClipboard is retried a few times before giving up.
      OPEN_CLIPBOARD_ATTEMPTS = 10
      OPEN_CLIPBOARD_DELAY    = 20.milliseconds

      def copy(content : String) : Nil
        copy_windows(content)
      end

      def paste : String
        paste_windows
      end

      private def copy_windows(content : String) : Nil
        utf16 = content.to_utf16
        byte_size = LibC::SizeT.new((utf16.size + 1) * sizeof(UInt16))
        mem = Pointer(Void).null
        clipboard_open = false
        transferred = false

        begin
          open_clipboard_for_copy
          clipboard_open = true
          empty_clipboard

          mem = LibKernel32.global_alloc(GMEM_MOVEABLE | GMEM_ZEROINIT, byte_size)
          raise CopyError.new("[EasyClip] Copy operation failed: GlobalAlloc failed (#{last_windows_error})") if mem.null?

          locked = LibKernel32.global_lock(mem)
          raise CopyError.new("[EasyClip] Copy operation failed: GlobalLock failed (#{last_windows_error})") if locked.null?

          begin
            buffer = locked.as(UInt16*)
            utf16.each_with_index do |unit, index|
              buffer[index] = unit
            end
            buffer[utf16.size] = 0_u16
          ensure
            LibKernel32.global_unlock(mem)
          end

          unless LibUser32.set_clipboard_data(CF_UNICODETEXT, mem).null?
            transferred = true
            return
          end

          raise CopyError.new("[EasyClip] Copy operation failed: SetClipboardData failed (#{last_windows_error})")
        ensure
          LibKernel32.global_free(mem) unless mem.null? || transferred
          LibUser32.close_clipboard if clipboard_open
        end
      end

      private def paste_windows : String
        clipboard_open = false
        locked = Pointer(Void).null
        mem = Pointer(Void).null

        begin
          open_clipboard_for_paste
          clipboard_open = true

          # An empty or non-text clipboard is not an error; return an empty string
          # to match the behavior of the process-based backends.
          return "" if LibUser32.is_clipboard_format_available(CF_UNICODETEXT) == 0

          mem = LibUser32.get_clipboard_data(CF_UNICODETEXT)
          raise PasteError.new("[EasyClip] Paste operation failed: GetClipboardData failed (#{last_windows_error})") if mem.null?

          locked = LibKernel32.global_lock(mem)
          raise PasteError.new("[EasyClip] Paste operation failed: GlobalLock failed (#{last_windows_error})") if locked.null?

          buffer = locked.as(UInt16*)
          length = 0
          while buffer[length] != 0_u16
            length += 1
          end

          String.from_utf16(Slice.new(buffer, length))
        ensure
          LibKernel32.global_unlock(mem) unless locked.null?
          LibUser32.close_clipboard if clipboard_open
        end
      end

      private def open_clipboard_for_copy : Nil
        return if try_open_clipboard
        raise CopyError.new("[EasyClip] Copy operation failed: OpenClipboard failed (#{last_windows_error})")
      end

      private def open_clipboard_for_paste : Nil
        return if try_open_clipboard
        raise PasteError.new("[EasyClip] Paste operation failed: OpenClipboard failed (#{last_windows_error})")
      end

      private def try_open_clipboard : Bool
        OPEN_CLIPBOARD_ATTEMPTS.times do |attempt|
          return true unless LibUser32.open_clipboard(Pointer(Void).null) == 0
          sleep(OPEN_CLIPBOARD_DELAY) unless attempt == OPEN_CLIPBOARD_ATTEMPTS - 1
        end
        false
      end

      private def empty_clipboard : Nil
        if LibUser32.empty_clipboard == 0
          raise CopyError.new("[EasyClip] Copy operation failed: EmptyClipboard failed (#{last_windows_error})")
        end
      end

      private def last_windows_error : String
        "GetLastError=#{LibKernel32.get_last_error}"
      end
    end
  {% end %}
end
