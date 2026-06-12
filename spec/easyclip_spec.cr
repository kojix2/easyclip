require "./spec_helper"

describe EasyClip do
  it "can copy and paste text" do
    greetings = {
      "Hello"    => "English",
      "Olá"      => "Portuguese",
      "Hola"     => "Spanish",
      "Bonjour"  => "French",
      "Hallo"    => "German",
      "Ciao"     => "Italian",
      "Merhaba"  => "Turkish",
      "Привет"   => "Russian",
      "مرحبا"    => "Arabic",
      "नमस्ते"   => "Hindi",
      "হ্যালো"   => "Bengali",
      "Xin chào" => "Vietnamese",
      "Halo"     => "Indonesian",
      "你好"       => "Chinese",
      "안녕하세요"    => "Korean",
      "こんにちは"    => "Japanese",
      "Hello\n"  => "Trailing newline",
      "😀🎉🚀"      => "Emoji (surrogate pairs)",
      ""         => "Empty string",
    }

    greetings.each do |greeting, _|
      EasyClip.copy(greeting)
      pasted_text = EasyClip.paste
      pasted_text.should eq(greeting)
    end
  end

  # Linux clipboard tools and Windows CF_UNICODETEXT treat embedded nulls as a
  # terminator, so this is only guaranteed by the macOS NSPasteboard backend.
  {% if flag?(:darwin) %}
    it "preserves embedded null characters with native backends" do
      greeting = "A\0B"

      EasyClip.copy(greeting)
      pasted_text = EasyClip.paste

      pasted_text.should eq(greeting)
    end
  {% end %}
end
