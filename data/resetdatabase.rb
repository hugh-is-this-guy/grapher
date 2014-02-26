#!/usr/bin/ruby

require 'net/http'
require 'rubygems'
require 'json'

#required for printing progress
$stdout.sync = true

def process_lines(filename)
  count = 0
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      yield line.strip, count
      count += 1
    end
  end
end

def post_to_db(query)
  uri = URI('http://localhost:7474/db/data/cypher')
  res = Net::HTTP.post_form(uri, :query => query)
end

names = Array.new
ids   = Array.new

#add forenames to names array
process_lines("forenames") do |line, count| 
  14.times do |i| 
    ids.push line 
    names.push line 
  end
end

#add surnames to names array
process_lines("surnames")  do |line, count| 
  14.times do |i|
    ids[(150 * i ) + count] += "#{line}"
    names[(150 * i ) + count] += " #{line}"
  end
end

#delete all data
puts 'Deleting data'
query = 'MATCH (a) OPTIONAL MATCH (a)-[r]-() DELETE a, r'
post_to_db query
puts 'Data deleted'


#add nodes
puts 'Adding nodes (this may take a while)'
progress = 1
for i in 1..1899 do
  query = "CREATE (#{ids[i]}:Person {id: #{i}, name: '#{names[i]}'});"
  post_to_db(query)
  print '=' if progress % 19 == 0
  progress += 1
end
puts
puts 'Nodes added'

process = 1
puts 'Adding relationships (this will take even longer)'
process_lines("relationships") do |line, count| 
  from, to, weight  = line.split
  from_id           = ids[Integer(from)]
  to_id             = ids[Integer(to)]
  from_name         = names[Integer(from)]
  to_name           = names[Integer(to)]
  
  query = "MATCH (#{from_id}:Person), (#{to_id}:Person)
  WHERE #{from_id}.name = '#{from_name}' AND #{to_id}.name = '#{to_name}'
  CREATE (#{from_id}) - [:Knows{weight: #{weight}}] -> (#{to_id});"

  post_to_db(query)
  print '=' if progress % 200 == 0
  progress += 1
end
puts
puts 'Relationships added'