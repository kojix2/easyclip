module EasyClip
  abstract class Backend
    abstract def copy(content : String) : Nil
    abstract def paste : String
  end
end
