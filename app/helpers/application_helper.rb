require 'workdir'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

private

public
  def get_countries
    cl = File.open("/usr/share/zoneinfo/iso3166.tab")
    lines = cl.readlines
    cl.close
    countries = {}

    lines.each do |e|
      if !e.match("^\s*#")
        data = e.split("\t")
        countries[data[0]] = data[1].strip
      end
    end

    return countries
  end

  def country_list
    pref_countries = ["US", "CA"]
    list = []
    countries = get_countries

    # put prefered countries first
    pref_countries.each do |key|
      list.push({"key" => key, "value" => countries[key]})
    end

    # append other countries - leave prefered countries where they are too (duplicates)
    # could avoid users searching
    #p countries
    countries.sort{|a,b| a[1]<=>b[1]}.each do |elem|
      list.push({"key" => elem[0], "value" => elem[1]})
    end

    return list
  end

end
