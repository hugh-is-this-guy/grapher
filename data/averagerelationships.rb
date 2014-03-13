#!/usr/bin/ruby

def process_lines(filename)
  count = 0
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      yield line.strip, count
      count += 1
    end
  end
end

relationships = Hash.new {}

process_lines("relationships.orig") do |line, count| 
  from, to, weight = line.split
  from, to, weight = from.to_i, to.to_i, weight.to_i
  node_less = if from < to then from else to end
  node_more = if from > to then from else to end

  if relationships["#{node_less}-#{node_more}"] == nil
    relationships["#{node_less}-#{node_more}"] = []
  end
  relationships["#{node_less}-#{node_more}"].push weight
end

File.open("relationships  ", 'w') do |output|
  relationships.each do |key, value|
    from, to = key.split("-")
    weight = value.inject{ |sum, el| sum + el } / value.size
    output.puts "#{from} #{to} #{weight}"
  end
end
