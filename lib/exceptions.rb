###
### generic exceptions (yeah, could have used better names)
###

# should catch late as a last resort
class DefaultErr < StandardError
end

# should catch early to show an appropriate error message
class DetailedErr < DefaultErr
end

