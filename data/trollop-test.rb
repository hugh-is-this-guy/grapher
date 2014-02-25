require 'rubygems'
require 'trollop'

opts = Trollop::options do
  opt :local, 'Add data to local database - localhost:7474.'
end

puts opts
