# Copyright (C) 2007-2012 Opersys inc., All rights reserved. 

#
# first goal: mixed up class for everything we need to communicate with the user
# current: temporary storage class for data, grouped by some key
#
class InterfaceResults
  @values = nil # strings

  # constructor
  def initialize()
    @values = {}
  end

  # SINGLE VALUE
  # ( get | set)  the value for an item identified by dest_array
  #   *dest_array takes a variable amount of strings parameters
  # ie: get_value("error", "formfield", name")
  # ie: set_value(GTEH_("misc.error.blabla"), "error", "formfield", "name")
  def get_value(*dest_array)
     if @values.member?(dest_array)
       return @values[dest_array]
     end
     return nil
  end
  def set_value(line, *dest_array)
    @values[dest_array] = line
  end

  # ARRAY OF VALUE
  # ( get values (array) from | add a value to )  an array of values for dest_array
  #   *dest_array takes a variable amount of string parameters
  # ie: get_values("error", "formfield", "name")
  # ie: add_value(GTEH_("misc.error.blabla"), "error", "formfield", "name")
  def get_values(*dest_array)
    if @values.member?(dest_array)
      return @values[dest_array]
    end
    return nil
  end
  def add_value(line, *dest_array)
    if ! @values.member?(dest_array)
      @values[dest_array] = [] # init as a list (array)
    end
    
    @values[dest_array].push(line) # add the line
  end



  #
  # GLOBAL MESSAGES (errors, notices, debug)
  # does not really belong here
  #

  def add_error(line)
      add_value(line, "error")
  end

  def add_notice(line)
      add_value(line, "notice")
  end

  def add_debug(line)
      add_value(line, "debug")
  end
end


