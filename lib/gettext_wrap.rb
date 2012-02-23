require 'gettext' # NOT gettext/rails - IT SUCKS (IMHO)

def gettext_change_language(locale="en")
	# RAILS_ROOT is provided by a patch in environment.rb
	# it would not be available yet in a normal setup
  GetText::bindtextdomain("kpswebconfig" , "#{RAILS_ROOT}/locale", locale)
end

# gets a "non-altered" string
def GT_(str,  nilifmissing=false)
  tmpstr = GetText::gettext(str)

  if str == tmpstr && nilifmissing == true
    return nil
  elsif str == tmpstr
    return "MISSING:"+tmpstr
  end

  return tmpstr
end

# gets an html escaped string
def GTEH_(str, nilifmissing=false)
  val = GT_(str, nilifmissing)
  return nil if val.nil?

  # escape basic forbidden html characters (not entities)
  val = CGI.escapeHTML(val)

  # unescape some html tags that we allow in strings
  # <p></p>, <b></b> and <i></i> are allowed righ now
  # special case: <nbsp> --> &lt;nbsp&gt; --> &nbsp;
  val = val.gsub(/&lt;(\/?)(p|b|i)&gt;/i, "<\\1\\2>")
  val = val.gsub(/&lt;nbsp&gt;/, "&nbsp;") # special case -- convert <nbsp> (does not exist) to &nbsp;

  return val
end


