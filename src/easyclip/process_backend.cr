module EasyClip
  abstract class ProcessBackend < Backend
    abstract def copy_commands : Array(Command)
    abstract def paste_commands : Array(Command)

    def copy(content : String) : Nil
      run_copy_command(copy_commands, content)
    end

    def paste : String
      run_paste_command(paste_commands)
    end

    private def run_copy_command(commands : Array(Command), content : String)
      raise CopyError.new("[EasyClip] Copy operation failed: no supported clipboard command found") if commands.empty?

      failures = [] of String
      commands.each do |command|
        error = run_copy_command(command, content)
        return unless error
        failures << error
      end

      raise CopyError.new("[EasyClip] Copy operation failed: #{failures.join("; ")}")
    end

    private def run_copy_command(command : Command, content : String) : String?
      stderr = IO::Memory.new
      status = Process.run(command[:command], command[:args], input: IO::Memory.new(content), error: stderr)
      return nil if status.success?

      process_error(command, status, stderr.to_s)
    rescue ex
      "#{command_line(command)}: #{ex.message}"
    end

    private def run_paste_command(commands : Array(Command))
      raise PasteError.new("[EasyClip] Paste operation failed: no supported clipboard command found") if commands.empty?

      failures = [] of String
      commands.each do |command|
        content, error = run_paste_command(command)
        return content unless error
        failures << error
      end

      raise PasteError.new("[EasyClip] Paste operation failed: #{failures.join("; ")}")
    end

    private def run_paste_command(command : Command) : {String, String?}
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = Process.run(command[:command], command[:args], output: stdout, error: stderr)
      return {stdout.to_s, nil} if status.success?

      {"", process_error(command, status, stderr.to_s)}
    rescue ex
      {"", "#{command_line(command)}: #{ex.message}"}
    end

    private def process_error(command : Command, status : Process::Status, stderr : String) : String
      message = "#{command_line(command)} exited with #{status.exit_code}"
      stderr = stderr.strip
      stderr.empty? ? message : "#{message}: #{stderr}"
    end

    private def available_commands(*commands : Command) : Array(Command)
      available_commands(commands.to_a)
    end

    private def available_commands(commands : Array(Command)) : Array(Command)
      commands.select { |command| executable?(command[:command]) }
    end

    private def executable?(command : String) : Bool
      !!Process.find_executable(command)
    end

    private def command_line(command : Command) : String
      if command[:args].empty?
        command[:command]
      else
        "#{command[:command]} #{command[:args].join(" ")}"
      end
    end
  end
end
