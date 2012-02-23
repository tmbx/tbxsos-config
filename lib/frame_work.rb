# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

def check_upload_file(name)
  if not params[name].nil? \
      and params[name] != "" \
      and not params[name].original_filename.nil? \
      and params[name].original_filename != ""
    return true
  end
  return false
end

class FrameWork
  attr_accessor :forms, :forms_order

  def initialize
    @forms = {}
    @forms_order = []
  end

  def add_form(ident)
    @forms_order.push(ident)
    @forms[ident] = Form.new(ident)

    tmpstr = GTEH_("forms.#{@forms[ident].ident_str}.descr")
    if ! tmpstr.nil? && tmpstr.length > 0
      @forms[ident].descr = tmpstr
    end
 

    return @forms[ident]
  end

  # this function sucks and surely has some bugs
  # validate form values
  # temporily (should be moved to another method), modify form values
  def form_validate(ident, params)
    form = @forms[ident]
    form.fields.each do |idfield, field|
      if field.readonly
        next
      end
      if field.disabled == true
        next
      end

      if field.type == "datetime"
        var = {}
        valuesspecs = [ { "year" => { "min" => 2007, "max" => 9999 } },
                        { "month" => { "min" => 1, "max" => 12 } },
                        { "day" => { "min" => 1, "max" => 31 } },
                        { "hour" => { "min" => 0, "max" => 24 } },
                        { "min" => { "min" => 0, "max" => 59 } },
                        { "sec" => { "min" => 0, "max" => 59 } } ]
        valuesspecs.each do |specshash| # use array of hashes to keep order
          specshash.each do |name,specs|
            var[name] = 0
            tmpvalue = get_hash_var(params, [ idfield, name ])
            if tmpvalue.nil? || tmpvalue.to_s.length == 0
              form.error = true
              field.error_required = true
              field.errors.push(GTEH_("framework.field.error.must_be_filled_name") % name)
            else
              begin
                tmpvalue = var[name] = tmpvalue.to_i
                if tmpvalue < specs["min"] || tmpvalue > specs["max"]
                  form.error = true
                  field.errors.push(GTEH_("framework.field.error.invalid_value_name") % name)
                end
              rescue
                form.error = true
                field.errors.push(GTEH_("framework.field.error.invalid_value_name") % name)
              end
            end
          end
        end
        var["timezone"] = params['datetime']['timezone']
        field.value = var
        next # no more validation on this field
      else
        var = get_hash_var(params, idfield)
      end

      if field.type == "checkbox"
        if var.nil?
          field.value = false
        else
          field.value = true
        end
        next # no more validation on this field
      end

      # in filter function
      # should change all "form_validate" for "process_form_input"
      # and call infilter and validate from there
      # allows modifiying with a function before validation
      if ! field.infilterfunc.nil?
        var = field.infilterfunc.call(var)
      end

      field.value = var



      # any other kind of data
      if field.required && (var.nil? || var.length < 1)
        form.error = true
        field.error_required = true
        field.errors.push(GTEH_("framework.field.error.must_be_filled"))

        next # no more validation on this field
      end


      if field.realtype == "numeric"
        number = false
        begin
          if var.to_i != 0 || (var.to_i == 0 && var.to_s == "0")
          number = true
          end
        rescue
          # do nothing
        end
        if number == true
          if ! field.min_value.nil? && var.to_i < field.min_value
            form.error = true
            field.errors.push(GTEH_("framework.field.error.minimum_integer_value") % field.min_value.to_i)
          end
          if ! field.max_value.nil? && var.to_i > field.max_value
            form.error = true
            field.errors.push(GTEH_("framework.field.error.maximum_integer_value") % field.max_value.to_i)
          end
        else
          form.error = true
          field.errors.push(GTEH_("framework.field.error.must_be_a_number"))
        end

        next # no more validation on this field
      end

      if field.realtype == "domain"
        if (var =~ /^[a-z0-9\.-]+$/) == nil
          form.error = true
          field.errors.push(GTEH_("framework.field.error.invalid_internet_domain_name") % var.to_s)
        end
      end

      if field.realtype == "email"
        if (var =~ /^[^<>\s]+@[a-z0-9\.-]+$/) == nil
          form.error = true
          field.errors.push(GTEH_("framework.field.error.invalid_email_address"))
        end
      end


      if ! field.verification_field.nil? && field.verification_field.length > 0 && field.error_required == false
        if var != get_hash_var(params, field.verification_field)
          form.error = true
          field.errors.push(GTEH_("framework.field.error.verification_password_no_match"))
  
          next # no more validation on this field
        end
      end
 
      if ! field.min_length.nil? && var.length < field.min_length
        form.error = true
        field.errors.push(GTEH_("framework.field.error.minimum_length") % field.min_length.to_i)
      end

      if ! field.max_length.nil? && var.length > field.max_length
        form.error = true
        field.errors.push(GTEH_("framework.field.error.maximum_length") % field.max_length.to_i)
      end
  
      # not tested - could have to escape regexp in some way before 
      if ! field.regexp.nil?
        if (var =~ field.regexp) == nil
          form.error = true
          field.errors.push(GTEH_("framework.field.error.invalid_value"))
        end
      end

      if ! field.validfunc.nil?
        tmpvar = field.validfunc.call(var)
        if tmpvar.nil?
          form.error = true
          field.errors.push(GTEH_("framework.field.error.invalid_value"))
        else
          field.value = tmpvar
        end
      end
    end
  end

  def get_hash_var(params, idfield)
    var = params
    if idfield.is_a?(Array)
      idfield.each do |key|
        if var.has_key?(key)
          var = var[key]
        else
          return nil
        end
      end
      return var
    end
    return var[idfield]
  end
end

# right now, a form ident can be anything
# right now, a field ident has to be an array of two strings (group, name)
class Form
  attr_reader :ident
  attr_accessor :fields, :fields_order
  attr_accessor :error, :errors
  attr_accessor :descr
  attr_accessor :redirect_to
  attr_accessor :required_notice
  attr_accessor :per_field_action

  def initialize(ident)
    @ident = ident
    @fields = {}
    @fields_order = []
    @error = false
    @errors = []
    @redirect_to = nil
    @required_notice = true
    @per_field_action = nil
  end

  def add_field(ident, type, params={})
    @fields_order.push(ident)
    @fields[ident] = Field.new(ident, type, params)
    @fields[ident].form = self
    tmpstr = GTEH_("forms.#{@ident}.#{@fields[ident].ident_str}.info")
    if ! tmpstr.nil? && tmpstr.length > 0
      @fields[ident].info = tmpstr
    end
    tmpstr = GTEH_("forms.#{@ident}.#{@fields[ident].ident_str}.help")
    if ! tmpstr.nil? && tmpstr.length > 0
      @fields[ident].help = tmpstr
    end
    tmpstr = GTEH_("forms.#{@ident}.#{@fields[ident].ident_str}.pre_sep", true)
    if ! tmpstr.nil? && tmpstr.length > 0
      @fields[ident].pre_sep = tmpstr
    end
    tmpstr = GTEH_("forms.#{@ident}.#{@fields[ident].ident_str}.comment", true)
    if ! tmpstr.nil? && tmpstr.length > 0
      @fields[ident].comment = tmpstr
    end
    tmpstr = GTEH_("forms.#{@ident}.#{@fields[ident].ident_str}.action_name")
    if ! tmpstr.nil? && tmpstr.length > 0
      @fields[ident].action_name = tmpstr
    end
    return @fields[ident]
  end

  def each_field(type=nil)
    count = 0;

    # counts the number of matching fields
    max = 0
    fields.each do |fi|
      if type.nil? || type == fi.type
        max += 1;
      end
    end

    # yields fields with some infos added (relative to that call only)
    count = 0
    first = true
    fields_order.each do |ident|
      fi = fields[ident]
      if type.nil? || type == fi.type
        fi.index = count
        count += 1

        fi.first = first
        first = false

        fi.even = false
        if fi.index % 2 == 1 # (index starts at 0)
          fi.even = true
        end

        fi.odd = false
        if count % 2 == 0 # (index starts at 0)
          fi.odd = true
        end

        fi.last = false
        if fi.index == (max - 1)
          last = true
        end
        yield fields[ident]
      end
    end
  end

  def ident_str()
    ident = @ident
    if ident.is_a?(Array)
      str = ""
      ident.length.times do |i|
        if i == 0
          str += ident[i]
        else
          str += "_" + ident[i]
        end
      end
       return str
    end
    return ident
  end
end

# right now, a form ident can be anything
# right now, a field ident has to be an array of two strings (group, name)
class Field
  attr_reader :ident, :type
  attr_accessor :form
  attr_accessor :required, :default, :autofocus
  attr_accessor :choices  # :choices_help
  attr_accessor :realtype
  attr_accessor :info, :help, :comment
  attr_accessor :infilterfunc
  attr_accessor :validfunc
  attr_accessor :displayfunc
  attr_accessor :regexp
  attr_accessor :pre_sep
  attr_accessor :field_template, :field_input_template
  attr_accessor :errors, :error_required
  attr_accessor :size # for text fields
  attr_accessor :cols, :rows # for textareas
  attr_accessor :reference # misc : could be the option name used in a config file
  attr_accessor :verification_field # like a verification password
  attr_accessor :min_value, :max_value
  attr_accessor :min_length, :max_length
  attr_accessor :index, :first, :last, :odd, :even # when iterated through forms.each_field
  attr_accessor :action, :action_name
  attr_accessor :input_class
  attr_accessor :tags
  attr_accessor :readonly
  attr_accessor :disabled
  attr_accessor :force_value

  # read accessor
  def value
    # if present, force value to force_value instead of returning the real value
    if ! @force_value.nil?
      return @force_value
    end

    return @value
  end
  # write accessor
  def value=(value)
    @value = value
  end


  def initialize(ident, type, params={})
    @error_required = false
    @errors = []

    @form = nil

    @ident = ident
    @type = type

    @value = nil
    @choices = []
    @choices_help = nil
    @required = false
    @reference = nil
    @realtype = ""
    @info = nil
    @help = nil
    @comment = nil
    @infilterfunc = nil
    @validfunc = nil
    @displayfunc = nil
    @regexp = nil
    @pre_sep = ""
    @field_template = nil
    @field_input_template = nil
    @autofocus = false
    @size = nil
    @cols = 25
    @rows = 4
    @verification_field = nil
    @min_value = nil
    @max_value = nil
    @min_length = nil
    @max_length = nil
    @action = nil
    @action_name = nil
    @input_class = nil
    @tags = {}
    @readonly = false
    @disabled = false
    @force_value = nil

    #if type == "text" || type == "textarea"
    #  @value = ""
    #end
    if ! params["value"].nil?
      @value = params["value"]
    end
    if ! params["choices"].nil?
      @choices = params["choices"]
    end
    #if ! params["choices_help"].nil?
    #  @choices_help = params["choices_help"]
    #end
 
    if ! params["required"].nil? && params["required"] == true
      @required = true
    end
    if ! params["reference"].nil? && params["reference"].length > 0
    @reference = params["reference"]
    end
    if ! params["realtype"].nil? && params["realtype"].length > 0
      @realtype = params["realtype"]
    end
    if ! params["infilterfunc"].nil?
      @infilterfunc = params["infilterfunc"]
    end
    if ! params["validfunc"].nil?
      @validfunc = params["validfunc"]
    end
    if ! params["displayfunc"].nil?
      @displayfunc = params["displayfunc"]
    end
    if ! params["regexp"].nil?
      @regexp = params["regexp"]
    end
    if ! params["pre_sep"].nil?
      @pre_sep = params["pre_sep"]
    end
    if ! params["field_template"].nil?
      @field_template = params["field_template"]
    end
    if ! params["field_input_template"].nil?
      @field_input_template = params["field_input_template"]
    end

    if ! params["autofocus"].nil? && params["autofocus"] == true
      @autofocus = true
    end
     if ! params["size"].nil? && params["size"].to_s.length > 0
      @size = params["size"]
    end
    if ! params["cols"].nil? && params["cols"].to_s.length > 0
      @cols = params["cols"]
    end
    if ! params["rows"].nil? && params["rows"].to_s.length > 0
      @rows = params["rows"]
    end
    if ! params["verification_field"].nil? && params["verification_field"].length > 0
      @verification_field = params["verification_field"]
    end
    if ! params["min_value"].nil? && params["min_value"].to_i > 0
      @min_value = params["min_value"].to_i
    end
    if ! params["max_value"].nil? && params["max_value"].to_i > 0
      @max_value = params["max_value"].to_i
    end
    if ! params["min_length"].nil? && params["min_length"].to_i > 0
      @min_length = params["min_length"].to_i
    end
    if ! params["max_length"].nil? && params["max_length"].to_i > 0
      @max_length = params["max_length"].to_i
    end
    if ! params["action"].nil? && params["action"].length > 0
      @action = params["action"]
    end
    if ! params["action_name"].nil? && params["action_name"].length > 0
      @action_name = params["action_name"]
    end
    if ! params["input_class"].nil? && params["input_class"].length > 0
      @input_class = params["input_class"]
    end
    if ! params["tags"].nil? && params["tags"].length > 0
      @tags = params["tags"]
    end
    if ! params["readonly"].nil? && params["readonly"].length > 0
      @readonly = params["readonly"]
    end
    if ! params["disabled"].nil? && params["disabled"].length > 0
      @readonly = params["disabled"]
    end
    if ! params["force_value"].nil?
      @force_value = params["force_value"]
    end
  end

  def id()
    if @form.nil?
      return nil
    end

    return "fid_" + @form.ident_str + "_" + ident_tag
  end

  # works and tested with single strings and arrays of two strings only
  def ident_tag()
    ident = @ident
    if ident.is_a?(Array)
      str = ""
      ident.length.times do |i|
        if i == 0
          str += ident[i]
        else
          str += "[" + ident[i] + "]"
        end
      end
      return str
    end
    return ident
  end

  # works and tested with single strings and arrays of two strings only
  def ident_str()
    ident = @ident
    if ident.is_a?(Array)
      str = ""
      ident.length.times do |i|
        if i == 0
          str += ident[i]
        else
          str += "_" + ident[i]
        end
      end
      return str
    end
    return ident
  end
end




