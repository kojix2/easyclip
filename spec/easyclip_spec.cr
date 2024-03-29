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
    }

    greetings.each do |greeting, language|
      EasyClip.copy(greeting)
      pasted_text = EasyClip.paste
      {% if flag?(:windows) %}
        pasted_text = pasted_text.chomp
      {% end %}
      pasted_text.should eq(greeting)
    end
  end
end
