module EasyClip
  # Base class for EasyClip errors
  class Error < Exception
  end

  # Raised when an error occurs during the copy operation
  class CopyError < Error
  end

  # Raised when an error occurs during the paste operation
  class PasteError < Error
  end
end
