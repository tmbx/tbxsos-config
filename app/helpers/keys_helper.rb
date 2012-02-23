module KeysHelper

  # Word wrap which doesn't care about whitespaces.
  def forcibly_word_wrap(text, width = 80)
    t = text
    n = ''
    i = 0
    while (true)
      t2 = t[i, width]
      if not t2
        break
      end
      n = n + t2 + "<br />"
      i = i + width
    end

    return n
  end

end
