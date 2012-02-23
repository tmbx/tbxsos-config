require "syslog"

# !!! not a standard logger class !!!
# !!! not a standard logger class !!!
# !!! not a standard logger class !!!

# Logger was already taken
class Klogger
  def initialize(app="tbxsos-config")
    @app = app
    open
  end

  def open
    Syslog.open(@app, Syslog::LOG_NDELAY, Syslog::LOG_DAEMON) unless Syslog.opened?
  end

  def send(priority, message)
    messages = message.gsub(/\r/, "").split("\n")
    messages.each do |message|
      Syslog.send(priority, "%s", message)
    end
  end

  public

  def info(message)
    open
    send("info", message)
  end

  def error(message)
    open
    send("err", message)
  end

  def debug(message)
    open
    send("debug", message)
  end
end

