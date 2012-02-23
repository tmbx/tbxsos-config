require 'time'

class License
  attr_reader :raw_string, :limit, :max, :is_reseller, :best_before, :best_after

  def get_value(s, reg)
    if reg.match(s)
      return s.gsub(reg, "\\1")
    end
    return nil
  end

  def parse(s)
    @raw_string = s;
    s = s.gsub(/[\n\r]*/, "") # remove line endings
    @limit = get_value(s, /.*seat limit: (-?[0-9]+).*/)
    @max = get_value(s, /.*seat max: (-?[0-9]+).*/)
    @best_after = get_value(s, /.*best after \(GMT\): ([0-9]{4}\-[0-9]{2}\-[0-9]{2})/)
    @best_before = get_value(s, /.*best before \(GMT\): ([0-9]{4}\-[0-9]{2}\-[0-9]{2})/)
    @is_reseller = get_value(s, /.*is reseller: ([0-1]).*/)

    [@limit, @max, @best_after, @best_before, @is_reseller].each do |f|
      if f.nil?
        return false
      end
    end

    @limit = @limit.to_i
    @max = @max.to_i
    @is_reseller = @is_reseller.to_i
    @best_after = Time.parse(@best_after, "%Y-%m-%d")
    @best_before = Time.parse(@best_before, "%Y-%m-%d")

    return true
  end

  def License.from_org_id(org_id)
    org = Organization.find(org_id)
    return License.from_kdn(org.name)
  end

  def License.from_kdn(kdn)
    begin
      cmd = "kctl showlicense #{kdn}"
      out = SafeExec.exec(cmd, "", true)
    rescue Exception => ex
      #KLOGGER.info("could not get license for kdn '#{kdn}'")
      #KLOGGER.error("kctlbin error:")
      #KLOGGER.error(ex.stderr.to_s)
      return nil
    end
    license = License.new()
    if license.parse(out)
      return license
    end
    return nil
  end
end

