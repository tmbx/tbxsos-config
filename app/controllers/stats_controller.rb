class StatsController < ApplicationController

  layout "standard"

  private

  def stats_week(date)
    wwwpath = "/var/cache/tbxsos-stats/www"
    file = "stats-weekly-#{date}.html"
    filepath = File.join(wwwpath, file)

    begin
      @nostatsyet = false
      @date = date
      @time_updated = Time.at(File.stat(filepath).mtime.to_i)
      File.open(filepath) do |f|
        @table = f.read()
        f.close()
      end
    rescue
      @nostatsyet = true
    end
    render :action => "week"
  end

  public

  def list
    redirect_to :action => "current_week"    
  end

  def current_week
    @page_title += " - current week"
    t = Time.new()
    date = Time.at(t.to_i - (t.wday() * 86400)).strftime("%Y-%m-%d")
    stats_week(date)
  end

  def last_week
    @page_title += " - last week"
    t = Time.new()
    date = Time.at(t.to_i - (t.wday() * 86400) - (7 * 86400)).strftime("%Y-%m-%d")
    stats_week(date)
  end

end
