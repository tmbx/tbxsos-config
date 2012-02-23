class Menus

  attr_accessor :menus_items, :menus_order

  private

  def initialize
    @menus_items = {}
    @menus_order = {}

    @menus_order["topright"] = [ "dashboard", "logout" ]
    @menus_items["topright"] = {
                      "dashboard" => { "label" => "menu.label.dashboard",
                                       "linkparams" => {:action => 'list', :controller => 'info'},
                                       "linktagparams" => {} },

                      "logout" => { "label" => "menu.label.logout",
                                    "linkparams" => {:action => 'logout', :controller => 'login'},
                                    "linktagparams" => {} }
                   }

    @menus_order["left1"] = [ "basic_setup", "teambox", "organizations", "userman", "ldap" ]
    #if Reseller.is_reseller?()
    #  @menus_order["left1"] = [ "basic_setup", "teambox", "organizations", "ldap" ]
    #else
    #  @menus_order["left1"] = [ "basic_setup", "teambox", "userman", "ldap" ]
    #end
    @menus_items["left1"] = {
      "basic_setup" => { 
        "label" => "menu.label.basic_setup",
        "linkparams" => {:action => 'list', :controller => 'basic_options'},
        "linktagparams" => {:style => 'action'} 
      },
      "teambox" => { 
        "label" => "menu.label.teambox_identity",
        "linkparams" => {:action => 'list', :controller => 'licenses'},
        "linktagparams" => {:style => 'action'} 
      },
      "organizations" => { 
        "label" => "menu.label.organizations",
        "linkparams" => {:action => 'list', :controller => 'organizations'},
        "linktagparams" => {:style => 'action'} 
      },
      "userman" => { 
        "label" => "menu.label.user_management",
        "linkparams" => {:action => 'list', :controller => 'users'},
        "linktagparams" => {:style => 'action'} 
      },
      "ldap" => { 
        "label" => "menu.label.ldap_setup",
        "linkparams" => {:action => 'list', :controller => 'ldap_config'},
        "linktagparams" => {:style => 'action'} 
      }
    }

    @menus_order["left2"] = [ "updates", "logs" ] # "tests"
    @menus_items["left2"] = {
                      "updates" => { "label" => "menu.label.updates",
                                     "linkparams" => {:action => 'list', :controller => 'updates'},
                                     "linktagparams" => {:style => 'action'} },
                      #"tests" => { "label" => "menu.label.tests",
                      #             "linkparams" => {:action => 'list', :controller => 'tests'},
                      #             "linktagparams" => {:style => 'action'} },
                      "logs" => { "label" => "menu.label.logs",
                                  "linkparams" => {:action => 'list', :controller => 'logs'},
                                  "linktagparams" => {:style => 'action'} }
 
                  }

    @menus_order["left3"] = [ "legal", "about" ] # [ "kpsmanual", "about" ]
    @menus_items["left3"] = {
                      "about" => { "label" => "menu.label.about",
                                   "linkparams" => {:action => 'list', :controller => 'about'},
                                   "linktagparams" => {:style => 'action'} },

                   }

    @menus_order["left2"] = [ "updates", "logs" ] # "tests"
    @menus_items["left2"] = {
                      "updates" => { "label" => "menu.label.updates",
                                     "linkparams" => {:action => 'list', :controller => 'updates'},
                                     "linktagparams" => {:style => 'action'} },
                      #"tests" => { "label" => "menu.label.tests",
                      #             "linkparams" => {:action => 'list', :controller => 'tests'},
                      #             "linktagparams" => {:style => 'action'} },
                      "logs" => { "label" => "menu.label.logs",
                                  "linkparams" => {:action => 'list', :controller => 'logs'},
                                  "linktagparams" => {:style => 'action'} }
 
                  }

    @menus_order["left3"] = [ "legal", "about" ] # [ "kpsmanual", "about" ]
    @menus_items["left3"] = {
                      "about" => { "label" => "menu.label.about",
                                   "linkparams" => {:action => 'list', :controller => 'about'},
                                   "linktagparams" => {:style => 'action'} },
                      #"kpsmanual" => { "label" => "menu.label.manual",
                      #                  "linkparams" => {:action => 'list', :controller => 'about'},
                      #                  "linktagparams" => {:style => 'action'} },
                      "legal" => { "label" => "menu.label.legal",
                                   "linkparams" => {:action => 'list', :controller => 'legal'},
                                   "linktagparams" => {:style => 'action'} },
 

                  }
    #if Reseller.is_reseller?()
    #  @menus_order["pagetop_ldap"] = [ "ldap_config" ]
    #else
    #  @menus_order["pagetop_ldap"] = [ "ldap_config", "divisions" ]
    #end
    @menus_order["pagetop_ldap"] = [ "ldap_config", "divisions" ]
    @menus_items["pagetop_ldap"] = {
                      "ldap_config" => { "label" => "menu.label.ldap_config",
                                       "linkparams" => {:action => 'list', :controller => 'ldap_config'},
                                       "linktagparams" => {} },

                      "divisions" => { "label" => "menu.label.divisions",
                                    "linkparams" => {:action => 'list', :controller => 'groups'},
                                    "linktagparams" => {} }
                   }

    @menus_order["pagetop_teambox"] = [ "licenses", "teambox_identity" ]
    @menus_items["pagetop_teambox"] = {
                      "teambox_identity" => { "label" => "menu.label.identity",
                                       "linkparams" => {:action => 'list', :controller => 'teambox_options'},
                                       "linktagparams" => {} },

                      "licenses" => { "label" => "menu.label.licensed_seats",
                                    "linkparams" => {:action => 'list', :controller => 'licenses'},
                                    "linktagparams" => {} }
                   }


  end

  public

  # when this is the current page
  def set_selected(menuident)
    @menus_items.each do |key, menus|
      if ! menus[menuident].nil?
        menus[menuident]["selected"] = true
      end
    end
  end

  # when we want to disable a menu
  def set_disabled(menuident)
    @menus_items.each do |key, menus|
      if ! menus[menuident].nil?
        menus[menuident]["disabled"] = true
      end
    end
  end
end

