##
## data caching classes
##

# does not work when you using over several classes/modules... I think it does not work like python modules
# will investigate later
module ReqCache
  def ReqCache.init(force=false)
    if @cachedict.nil? or force == true
      @cachedict = {}
	end
  end

  def ReqCache.get(key)
    ReqCache.init()
    if @cachedict.has_key?(key)
      return @cachedict[key]
    end
    return nil
  end

  def ReqCache.set(key, value)
    ReqCache.init()
    @cachedict[key] = value
	return value
  end
end


