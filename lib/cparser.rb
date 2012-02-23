#!/usr/bin/env ruby

###
### config parser (ini style but not standard)
### (no parser without using gem which we try to avoid)
###

# supports:
# [section]
# key1=value
# key2=
# # comments

class CParser
	protected

	# loads with empty values, parse a file or parse a string
	def initialize(file=nil, data=nil)
		re_init()
		if file != nil
			#p "file"
			load_file(file)
		elsif data != nil
			#p "data"
			load_data(data)
		end
	end

	# we're loading or reloading data... reinit values
	def re_init()
		@values = {}
		@section = nil
	end

	public

	def set_value(section, key, value)
		if @values[section].nil?
			@values[section] = {}
		end
		@values[section][key] = value
	end

	def get_value(section, key)
		if ! @values[section].nil? && ! @values[section][key].nil?
			return @values[section][key]
		end
		return nil
	end


	def load_file(file)
		f = open(file, "rb")
		data = f.read()
		f.close()

		load_data(data)
	end

	def load_data(data)
		re_init()
		i = 0
		for line in data.split("\n")
			i = i + 1
			if ! (line =~ /^\s*#/) && ! (line =~ /^\s*$/) # skip empty or comment lines
				if line =~ /^\[(\S*)\].*$/ && ! $1.nil?
					# got a section line
					@section = $1
					#p "Section " + @section
				elsif (line =~ /^(\S+)=(.*)$/) && ! $1.nil? && ! $2.nil?
					# got a key=value line
					key = $1
					value = $2
					#p "Key " + key + " has value " + value
					set_value(@section, key, value)
				else
					raise Exception.new("invalid config syntax at line " + i.to_s + ":'" + line + "'")
				end
			end
		end
    end          

end



### BEGIN_TESTS ###
def cparser_test()
	data = "
 # fsdgdf
### fgfdgd
lyly=
gg
	
	  		     
[lala]
#lala=lala
lili=lili
[lolo]
sdfsd=fgdfg
hgfh=fghfgh
"

	ini = CParser.new(nil, data)
	p ini.get_value(nil, "hhhh")
	p ini.get_value(nil, "lyly")
	p ini.get_value("lala", "lili")
	p ini.get_value("lala", "lflf")
end

#cparser_test()
### END_TESTS ###

