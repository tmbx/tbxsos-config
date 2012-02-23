module Org

  def Org.status_pending_activation
    return 1
  end

  def Org.status_activated
    return 2
  end

  def Org.get_first_key_id(org_id)
    act = Activator.load_org(org_id)
    if not act.nil?
      return act.keys.get_keyid()
    end
    KLOGGER.info("could not load activation for org_id #{org_id}")
    return nil
  end

end


