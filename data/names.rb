names = Array.new

def process_lines(filename)
  count = 0
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      yield line.strip, count
      count += 1
    end
  end
end

process_lines("forenames") { |line, count| 14.times { |i| names.push line }}

process_lines("surnames")  do |line, count| 
  14.times do |i|
    names[(150 * i ) + count] += " #{line}" 
  end
end

puts names
puts names.length

for i in 1..1899 do
  puts "CREATE (n:Person {name: '#{names[i]}'})"  
end

process_lines("relationships") { |line, count| 
  from, to, weight = line.split
  puts "MATCH (a:Person), (b:Person)
  WHERE a.name = '#{names[Integer(from)]}' AND b.name = '#{names[Integer(to)]}'
  CREATE (a) -[r:Knows{weight: #{weight}}]->(b)"
}
