# Copyright (C) 2007-2012 Opersys inc., All rights reserved. 

require 'safeexec'

# doesn't fit here
# should be a function and not a class

# FD: It's fine being a class.  It should not be a model though.

class PipeExec
  def pipe_exec(comment="", exec_file="", cmd_params=[], send_stdin="")
    pipe_result = PipeResult.new

    # does not work when exec_file is made of seveval params
#    if not FileTest.exists?(exec_file) or not FileTest.readable?(exec_file) or not FileTest.executable?(exec_file)
#      pipe_result.comment = comment
#      pipe_result.status = 255
#      pipe_result.stdin = ""
#      pipe_result.stdout = ""
#      pipe_result.stderr = "Exec file does not exists: '#{exec_file}'"
#      pipe_result.cmd_params = cmd_params
#
#      return pipe_result
#    end

    #pid, stdin, stdout, stderr = Open4::popen4(exec_file + " " + cmd_params.join(" "))
    cmd_line = exec_file + " " + cmd_params.join(" ")
    print cmd_line + "\n"
    p = KPopen3.new(cmd_line)
    sin, sout, serr = p.pipes

    if ! send_stdin.nil? && send_stdin != ""
      begin
        sin.write(send_stdin)
      rescue  Errno::EPIPE
        pipe_result.comment = comment
        pipe_result.status = 255
        pipe_result.stdin = send_stdin
        pipe_result.stdout = ""
        pipe_result.stderr = "Broken PIPE"
        pipe_result.cmd_params = cmd_params

        return pipe_result
      end
    end
    begin
      sin.close
    rescue
      # nothing
    end

    out, err = SafeExec.empty_pipes([sout, serr]);
    p.close

    pipe_result.comment = comment
    pipe_result.status = $?.exitstatus
    pipe_result.stdin = send_stdin
    pipe_result.stdout = out
    pipe_result.stderr = err
    pipe_result.cmd_params = cmd_params

    return pipe_result
  end
end

