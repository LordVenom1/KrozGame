# encoding: Windows-1252
require 'yaml'

re = /DF[\[]([0-9]+)[\]]:=/


levels = {}

lines = File.readlines("./krozfree/source/KROZTRLI/KINGDOM/KINGDOM1.INC")[600,99999].collect do |line| line.force_encoding("Windows-1251").strip end

idx = 0

# glyphs = File.read("random_glyphs.dat").force_encoding("ISO-8859-5").split("\n")
# puts glyphs

# puts glyphs[2][0]
# exit

while idx < lines.size
	if lines[idx] =~ re
		level_num = $1.to_i
		levels[level_num] = []
		
		idx += 1
		
		glyphs = lines[idx].gsub(/[\{\} ]/,"") ; idx += 1
		counts = lines[idx].gsub(/[^0-9 ]/,"").scan(/.../).to_a.collect do |c| c.to_i end
		counts.each_with_index do |c,i|
			levels[level_num] << "#{glyphs[i]},#{c}" if c > 0
		end
		idx += 1
		glyphs = lines[idx].gsub(/[\{\} ]/,"") ; idx += 1
		counts = lines[idx].gsub(/[^0-9 ]/,"").scan(/.../).to_a.collect do |c| c.to_i end
		counts.each_with_index do |c,i|
			levels[level_num] << "#{glyphs[i]},#{c}" if c > 0
		end
		idx += 1
		glyphs = lines[idx].gsub(/[\{\} ]/,"") ; idx += 1
		counts = lines[idx].gsub(/[^0-9 ]/,"").scan(/.../).to_a.collect do |c| c.to_i end
		counts.each_with_index do |c,i|
			levels[level_num] << "#{glyphs[i]},#{c}" if c > 0
		end		
	end
	idx = idx + 1
end

levels.each do |k,v|

	y = {}
	y[:mode] = :random
	y[:flags] = {}
	y[:data] = v

	File.open("./levels/kingdom_#{k}.yml","w") do |out|
		out.puts y.to_yaml
	end
end
