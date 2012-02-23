#
# Reseller class
#
require 'activator'
require 'license'

class Reseller
  def Reseller.is_reseller?(org_id=nil)
    begin
      if org_id.nil?
        org_kdn = Activator.main_org_id()
        org_id = Organization.find(:first, {:condition => ["name = ?", org_kdn]}).org_id
      end
      if not org_id.nil?
        license = License.from_org_id(org_id)
        #KLOGGER.info("is reseller: #{license.is_reseller.to_s}")
        return license.is_reseller
      end
    rescue Exception => ex
      #
      #KLOGGER.info("unable to check if org '#{org_id.to_s}' is a reseller: '#{ex.to_s}'")
    end
    return false
  end
end

