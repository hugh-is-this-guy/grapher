#!/usr/bin/ruby

require 'net/http'
#require 'rubygems'
#require 'trollop'

def process_lines(filename)
  count = 0
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      yield line.strip, count
      count += 1
    end
  end
end

def post_to_db(query, params='')
  uri = URI('http://localhost:7474/db/data/cypher')
  if params then
    res = Net::HTTP.post_form(uri, 'query' => query, 'params' => params)
  else
    res = Net::HTTP.post_form(uri, 'query' => query)
  end
  res.body
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
puts 'Remove database?'
query = 'MATCH (a), OPTIONAL MATCH (a)-[r]-() DELETE a, r'
puts query
if STDIN.gets == 'y\n' or 'Y\n' then 
  post_to_db query
  puts 'deleted'
  STDIN.gets
end

#for i in 1..1899 do
#  query = "CREATE (#{ids[i]}:Person {name: '#{names[i]}'});"
#  puts query
#  puts post_to_db(query)
#end


process_lines("relationships") do |line, count| 
  from, to, weight = line.split
  from_id = ids[Integer(from)]
  to_id = ids[Integer(to)]
  
  query = "MATCH (#{from_id}:Person), (#{to_id}:Person)
  WHERE #{from_id}.name = from_name AND #{to_id}.name = to_name
  CREATE (#{from_id}) - [r:Knows{weight: rel_weight}] -> (#{to_id});"

  params = {
    :from_name => names[Integer(from)],
    :to_name => names[Integer(to)],
    :rel_weight => weight
  }

  puts query
  puts params
  puts post_to_db(query, params)
  STDIN.gets
end

puts names

#File.open("query", 'w') { |output|
#  for i in 1..1899 do
#    post_to_db("CREATE (#{names[i]}:Person {name: '#{names[i]}'});")
#    #output.puts "CREATE (#{names[i]}:Person {name: '#{names[i]}'});"
#  end
# 
#  process_lines("relationships") { |line, count| 
#    from, to, weight = line.split
#    from = names[Integer(from)]
#    to = names[Integer(to)]
#    output.puts "MATCH (#{from}:Person), (#{to}:Person)
#    WHERE #{from}.name = '#{from}' AND #{to}.name = '#{to}'
#    CREATE (#{from}) - [r:Knows{weight: #{weight}}] -> (#{to});"
#  }
#}

