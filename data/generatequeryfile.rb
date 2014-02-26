#!/usr/bin/ruby

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

File.open("query.cypher", 'w') do |output|
  for i in 1..1899 do
    output.puts "CREATE (#{ids[i]}:Person {id: #{i}, name: '#{names[i]}'})"
  end

  output.puts "CREATE"
  process_lines("relationships") do |line, count| 
    from, to, weight  = line.split
    from_id           = ids[Integer(from)]
    to_id             = ids[Integer(to)]
    from_name         = names[Integer(from)]
    to_name           = names[Integer(to)]
    
    output.puts "  (#{from_id})-[:KNOWS{weight: #{weight}}]->(#{to_id}),"
  end
  #output.puts "RETURN #{ids[0]};"

end







