class RenderState	
	def initialize() #(board_x, board_y)
		# @floor_layer = Array.new(board_x) do Array.new(board_y,nil) end
		# @tile_layer = Array.new(board_x) do Array.new(board_y,nil) end
		@flash = []
		@sound_events = []
	end
	
	def play(sound_name)
		@sound_events << sound_name
	end
	
	def get_sound_events
		events = @sound_events.uniq
		@sound_events = []
		events
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
	
	def clear_all
		@flash = []
		@sound_events = []
	end
end