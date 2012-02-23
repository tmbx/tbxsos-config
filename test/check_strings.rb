#!/usr/bin/env ruby

# checks misc LSTRING.get calls in code to make sure there is no undefined string
# undefined string shows like "UNDEF:....."
# this does check hard-coded calls within the code but
# does not check dynamic calls (like for forms, menus?(eventually?), page titles, page main docs, ...)

LOCAL_STRINGS_CONFIG="../config/localstrings.conf"

require "../lib/local_strings.rb"

LSTRINGS=LocalStrings.new

require "open3"

stdin, stdout, stderr = Open3.popen3('./check_strings.sh')

stdout.read.split("\n").each do |line|
  print eval(line) + "\n"
end


