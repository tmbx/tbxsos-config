# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

class SafeExecException < Exception

  public

  attr_accessor :command, :stdin, :stdout, :stderr, :status

  def initialize(err, command, stdin, stdout, stderr, status)
    super(err)
    @command = command
    @stdin = stdin
    @stdout = stdout
    @stderr = stderr
    @status = status
  end
end


class KPopen3
  def initialize(*cmd)
    p_in = IO::pipe   # pipe[0] for read, pipe[1] for write
    p_out = IO::pipe
    p_err = IO::pipe

    @pid = fork do
      # Close write-side of pipe, reopen read-side to stdin
      p_in[1].close
      STDIN.reopen(p_in[0])
      p_in[0].close

      # Close read-side of pipe, reopen write-side to stdout
      p_out[0].close
      STDOUT.reopen(p_out[1])
      p_out[1].close
      
      # Close read-side of pipe, reopen write-side to stdout
      p_err[0].close
      STDERR.reopen(p_err[1])
      p_err[1].close
      
      exec(*cmd)
    end

    p_in[0].close
    p_out[1].close
    p_err[1].close

    @pi = [p_in[1], p_out[0], p_err[0]]
    p_in[1].sync = true
  end

  def pipes
    @pi
  end

  def close
    @pi.each do |p|
      p.close unless p.closed?
    end

    Process.waitpid(@pid)
  end
end

module SafeExec 
    
  # Call this function to read all data from a set of pipes until they
  # are all empty.  Returns the data read in as many strings.
  def SafeExec.empty_pipes(pipes)
    strings = []

    # Set empty strings for each pipes.
    for i in 0..pipes.length
      strings[i] = ""
    end

    active_pipes = pipes.clone
    while !active_pipes.empty?
      begin
        arr = select(active_pipes)
        
        # If there are as much pipes in error as there are in the
        # pipes array, we terminate the loop
        if arr[2].length == active_pipes.length
          break
        end

        # For each pipe ready to read.
        arr[0].each do |s|
          idx = pipes.index(s)
          begin          
            str = s.read_nonblock(1024)
            strings[idx] += str
          rescue IOError
            active_pipes.delete(s)
          end
        end
      end
    end

    return strings
  end

  # stdin not implemented yet
  def SafeExec.exec(cmd, stdin="", returnout=false)
    begin
      po = KPopen3.new(cmd)
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])
    ensure
      po.close
    end

    if $? != 0
      raise SafeExecException.new("", cmd, nil, out_str, err_str, $?)
    end

    if returnout
      return out_str
    end
  end
end

