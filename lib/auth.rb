# Copyright (C) 2007-2012 Opersys inc., All rights reserved.


# use those functions to get ldap status and ldap type


AUTH_LOCAL_DATABASE = 0
AUTH_LDAP_EXCHANGE = 1
AUTH_LDAP_DOMINO = 2

LDAP_TYPES = [ AUTH_LDAP_EXCHANGE, AUTH_LDAP_DOMINO ]


module Auth
    #Auth.AUTH_LOCAL_DATABASE = 0
    #Auth.AUTH_LDAP_EXCHANGE = 1
    #Auth.AUTH_LDAP_DOMINO = 2
    
    #Auth.LDAP_TYPES = [ AUTH_LDAP_EXCHANGE, AUTH_LDAP_DOMINO ]



    # return true or false
    def Auth.ldap_enabled?()
        if Auth.ldap_type() != false
            return true
        end
    
        return false
    end


    # return false or one of LDAP_TYPES
    def Auth.ldap_type()
        co = ConfigOptions.new
        num_type = co.get("ldap.enabled")

        LDAP_TYPES.each do |tmp_type|
            if tmp_type.to_i == num_type.to_i
                return num_type.to_i
            end
        end

        return false
    end    
end

