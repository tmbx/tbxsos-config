# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

# We don't use rails tasks
require 'tasks/rails'

# builds mo files (binary) with po files (text)
# type: rake makemo in repos
require 'gettext/utils'
desc "Create mo-files" 
task :makemo do
  GetText.create_mofiles(true, "po", "locale")
end

# I couldn't find a Rails way of integrating unit testing for our
# libraries, so I've made my own Rake rule here (F-D)
desc "Library unit testing"
task :libtest do
  Rake::TestTask.new(:libtest) do |t|
    t.libs << "lib"
    t.pattern = "libtest/test*"
    t.verbose = true
    t.warning = true
  end
end
