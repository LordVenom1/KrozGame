def partial_sum(a, blk)
	sums = 0
	a.collect do |e|
		sums += e
		sums
	end
end



heights = [2,1,2,4,2,3,5,2,4,7]

left = partial_sum(heights)

puts left

right = partial_sum(heights.reverse)

result = left.zip(right).inject(0) do |total,e|
	puts e.min
	e.min
end

puts result

exit

max_so_far = 0
puts heights.inject(0, :+) do |total, e|
	total += e - max_so_far
	max_so_far = [max_so_far,e].max
end
exit

# heights = [0,1,0,2,1,0,1,3,2,1,2,1]
# the water level at a specific location is the min of the highest elevation seen to the left and the highest to the right.


left = heights.collect do |a,b| [a,b].max end # max so far
right = heights.reverse.collect do |a,b| [a,b].max end

puts left.zip(right).reduce() do |a| [a.first,a.last].max end