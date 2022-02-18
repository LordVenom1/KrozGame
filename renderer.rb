class RenderState	
	def initialize() #(board_x, board_y)
		# @floor_layer = Array.new(board_x) do Array.new(board_y,nil) end
		# @tile_layer = Array.new(board_x) do Array.new(board_y,nil) end
		@flash = []
	end
	
	def add_flash(message)		
		@flash << message
	end
	
	def current_flash		
		@flash.first
	end	
	
	def clear_flash
		# print "popping #{@flash.size} ->"
		@flash = @flash.drop(1)
		@flash
		# print @flash.size
		# @flash
	end
end