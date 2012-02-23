class PipeResult
  attr_accessor :comment, :status, :stdin, :stdout, :stderr, :cmd_params

  @comment = ""
  @status = 1
  @stdin = ""
  @stdout = ""
  @stderr = ""
  @cmd_params = []

  def debug_interface_result(ir)
    ir.add_debug("params: " + cmd_params.join(" "))
    ir.add_debug("")

    stdin.each do |message|
      message = "stdin: " + message
      ir.add_debug(message)
    end
    ir.add_debug("")

    stdout.each do |message|
      message = "stdout: " + message
      ir.add_debug(message)
    end
    ir.add_debug("")

    stderr.each do |message|
      message = "stderr: " + message
      ir.add_debug(message)
    end
    ir.add_debug("")

    ir.add_debug("STATUS: " + status.to_s)
    ir.add_debug("")
  end
end

