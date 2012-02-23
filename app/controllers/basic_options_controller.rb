# derived from OptionsController, where most of the code is
class BasicOptionsController < OptionsController
  layout "standard"

  def init_menu
    @menus.set_selected("basic_setup")
  end

  def set_optgroup
    @optgroup = "basic_options"
  end

  # language could not be set yet in ititialize so we use a filter
  def init_forms
    super

    ### DATE AND TIME ###
    fo = @fw.add_form("datetime")
    fo.required_notice = false

    fi = fo.add_field("datetime", "datetime", { "required" => true })
    
    @tm = Time.new
    @timezones = [["UTC/GMT", "Etc/UTC"]]
    tzs = `cat /usr/share/zoneinfo/zone.tab | grep -v ^# | cut -f 3 | sort`.split("\n")
    @timezones += tzs.zip(tzs)
    @fw.forms["datetime"].fields["datetime"].value = 
      { "year" => @tm.year, "month" => @tm.month, "day" => @tm.day,
        "hour" => @tm.hour, "min" => @tm.min, "sec" => @tm.sec,
        "timezone" => `cat /etc/timezone`.strip }
  end

  public

  def set_datetime

    # fill in basic options even if we're setting date/time
    @fw = @co.set_field_values_from_options(@fw, @optgroup)

    @fw.form_validate("datetime", params)    

    if @fw.forms["datetime"].error
      render :action => "list", :optgroup => optgroup
      return
    else
      begin
        kcd = TbxsosdConfigd.new
        form_values = @fw.forms["datetime"].fields["datetime"].value

        if kcd.set_date(form_values["year"], form_values["month"], form_values["day"])
          t=Time.now();
          flash[:notice] = GTEH_("datetime.change_date.success\n") \
                           % [ form_values["year"], form_values["month"], form_values["day"] ]


          if kcd.set_time(form_values["hour"], form_values["min"], form_values["sec"])
            flash[:notice] += GTEH_("datetime.change_time.success\n") \
            % [ form_values["hour"], form_values["min"], form_values["sec"] ]

            if kcd.set_timezone(form_values["timezone"])
              flash[:notice] += GTEH_("datetime.change_timezone.success\n") % form_values["timezone"]
            else
              flash[:error] = GTEH_("datetime.change_timezone.failed")
            end        
          else
            flash[:error] = GTEH_("datetime.change_time.failed")
          end
        else
          flash[:error] = GTEH_("datetime.change_date.failed")
        end 
      rescue NoDaemon, Exception => ex
        flash[:error] = GTEH_("datetime.change_date.failed")
        raise ex
      end
    end

    redirect_to :action => "list", :anchor => "start" # start is an undefined anchor
                                                      # if using nil or "", we're coming back to the same
                                                      # anchor ("datetime") (is it rails or the browser implementation?
                                                      # got this problem with firefox)
    #redirect_default
  end
end
