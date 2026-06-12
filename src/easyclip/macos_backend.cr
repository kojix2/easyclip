module EasyClip
  {% if flag?(:darwin) %}
    @[Link("objc")]
    private lib LibObjC
      alias Id = Void*
      alias Sel = Void*

      fun objc_get_class = objc_getClass(name : UInt8*) : Id
      fun sel_register_name = sel_registerName(name : UInt8*) : Sel
      fun objc_msg_send = objc_msgSend(receiver : Id, selector : Sel, arg1 : Id, arg2 : Id) : UInt64
      fun autorelease_pool_push = objc_autoreleasePoolPush : Void*
      fun autorelease_pool_pop = objc_autoreleasePoolPop(pool : Void*) : Nil
    end

    @[Link(framework: "CoreFoundation")]
    private lib LibCoreFoundation
      K_CF_STRING_ENCODING_UTF8 = 0x08000100_u32

      struct Range
        location : Int64
        length : Int64
      end

      fun string_create_with_bytes = CFStringCreateWithBytes(allocator : Void*, bytes : UInt8*, num_bytes : Int64, encoding : UInt32, is_external_representation : Bool) : Void*
      fun string_get_length = CFStringGetLength(string : Void*) : Int64
      fun string_get_maximum_size_for_encoding = CFStringGetMaximumSizeForEncoding(length : Int64, encoding : UInt32) : Int64
      fun string_get_bytes = CFStringGetBytes(string : Void*, range : Range, encoding : UInt32, loss_byte : UInt8, is_external_representation : Bool, buffer : UInt8*, max_buf_len : Int64, used_buf_len : Int64*) : Int64
      fun release = CFRelease(object : Void*) : Nil
    end

    @[Link(framework: "AppKit")]
    lib LibAppKit
      fun ns_application_load = NSApplicationLoad : Bool
    end

    class MacOSBackend < Backend
      NS_PASTEBOARD_TYPE_STRING = "public.utf8-plain-text"

      def copy(content : String) : Nil
        with_autorelease_pool do
          pasteboard = general_pasteboard
          string = cf_string(content)
          type = cf_string(NS_PASTEBOARD_TYPE_STRING)

          begin
            msg_uinteger(pasteboard, "clearContents")
            success = msg_bool(pasteboard, "setString:forType:", string, type)
            unless success
              raise CopyError.new("[EasyClip] Copy operation failed: NSPasteboard#setString returned false")
            end
          ensure
            LibCoreFoundation.release(string) unless string.null?
            LibCoreFoundation.release(type) unless type.null?
          end
        end
      end

      def paste : String
        with_autorelease_pool do
          pasteboard = general_pasteboard
          type = cf_string(NS_PASTEBOARD_TYPE_STRING)

          begin
            string = msg_id(pasteboard, "stringForType:", type)
            return "" if string.null?
            cf_string_to_string(string)
          ensure
            LibCoreFoundation.release(type) unless type.null?
          end
        end
      end

      private def general_pasteboard : LibObjC::Id
        load_appkit
        pasteboard = msg_id(objc_class("NSPasteboard"), "generalPasteboard")
        if pasteboard.null?
          raise Error.new("[EasyClip] Clipboard operation failed: NSPasteboard.generalPasteboard returned null")
        end
        pasteboard
      end

      private def cf_string(content : String) : LibObjC::Id
        load_appkit
        string = LibCoreFoundation.string_create_with_bytes(Pointer(Void).null, content.to_slice.to_unsafe, content.bytesize, LibCoreFoundation::K_CF_STRING_ENCODING_UTF8, false)
        if string.null?
          raise Error.new("[EasyClip] Clipboard operation failed: CFStringCreateWithBytes returned null")
        end
        string
      end

      private def cf_string_to_string(string : LibObjC::Id) : String
        length = LibCoreFoundation.string_get_length(string)
        max_size = LibCoreFoundation.string_get_maximum_size_for_encoding(length, LibCoreFoundation::K_CF_STRING_ENCODING_UTF8) + 1
        bytes = Bytes.new(max_size)
        used_size = 0_i64

        converted = LibCoreFoundation.string_get_bytes(
          string,
          LibCoreFoundation::Range.new(location: 0_i64, length: length),
          LibCoreFoundation::K_CF_STRING_ENCODING_UTF8,
          0_u8,
          false,
          bytes.to_unsafe,
          max_size,
          pointerof(used_size)
        )
        unless converted == length
          raise PasteError.new("[EasyClip] Paste operation failed: CFStringGetBytes returned #{converted} of #{length} characters")
        end

        String.new(bytes[0, used_size])
      end

      private def objc_class(name : String) : LibObjC::Id
        klass = LibObjC.objc_get_class(name)
        if klass.null?
          raise Error.new("[EasyClip] Clipboard operation failed: Objective-C class #{name} not found")
        end
        klass
      end

      private def selector(name : String) : LibObjC::Sel
        LibObjC.sel_register_name(name)
      end

      private def with_autorelease_pool(&)
        pool = LibObjC.autorelease_pool_push
        begin
          yield
        ensure
          LibObjC.autorelease_pool_pop(pool)
        end
      end

      private def load_appkit : Nil
        LibAppKit.ns_application_load
      end

      private def msg_id(receiver : LibObjC::Id, name : String) : LibObjC::Id
        Pointer(Void).new(LibObjC.objc_msg_send(receiver, selector(name), Pointer(Void).null, Pointer(Void).null))
      end

      private def msg_id(receiver : LibObjC::Id, name : String, arg1 : LibObjC::Id) : LibObjC::Id
        Pointer(Void).new(LibObjC.objc_msg_send(receiver, selector(name), arg1, Pointer(Void).null))
      end

      private def msg_bool(receiver : LibObjC::Id, name : String, arg1 : LibObjC::Id, arg2 : LibObjC::Id) : Bool
        (LibObjC.objc_msg_send(receiver, selector(name), arg1, arg2) & 0xff) != 0
      end

      private def msg_uinteger(receiver : LibObjC::Id, name : String) : UInt64
        LibObjC.objc_msg_send(receiver, selector(name), Pointer(Void).null, Pointer(Void).null)
      end
    end
  {% end %}
end
