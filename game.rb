require 'yaml'
require './components.rb'
require './renderer.rb'

class Effect
	def initialize(default_activation_duration)
		@default_activation_duration = default_activation_duration
		@duration = 0.0
	end
	
	def active?
		@duration > 0.0
	end
	
	def activate(dur = nil)		
		@duration += dur ? dur : @default_activation_duration # extend effect if already active
	end
	
	def clear
		@duration = 0.0
	end
	
	def update(dx)
		if active?
			@duration -= dx
			@duration = 0.0 if @duration < 0.0
		end
	end
end

class KrozGame
	attr_reader :board_x, :board_y, :player
	attr_reader :episode, :mission
	attr_reader :effects
	attr_reader :paused
	attr_reader :render_state

	DIRS = [[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
	PLAYER_TICK = 0.1
	GAME_TICK = 0.2
	def initialize()
		@board_x = 64 + 2
		@board_y = 23 + 2
		@board = Array.new(@board_x * @board_y)
		@components = []
		
		load_sprites()
		
		@episode = :kingdom # kingdom of kroz (remake?)
		@mission = 1 # level 1
		
		@player = nil
		@player_action = :none
		
		# game effects 
		@effects = {
			slow_monster: Effect.new(10.0),
			freeze_monster: Effect.new(10.0),
			speed_monster: Effect.new(10.0),
			invisible_player: Effect.new(8.0),
			flash: Effect.new(2.0)
		}
		
		load_level()

		@paused = true				
		
		@next_player_update = PLAYER_TICK
		@next_game_update = GAME_TICK
		
		@render_state = RenderState.new()
		
		flash("welcome")
	end
	
	def flash(msg)
		@render_state.add_flash(msg)		
		@effects[:flash].activate unless @effects[:flash].active?		
	end
	
	def slow_monster
		
		@effects[:slow_monster].activate
		@next_game_update = GAME_TICK * 6
	end
	
	def toggle_pause
		@paused = @paused ? false : true
		@last_update = Time.now() if not @paused			
	end
		
	def blocking_animation_running?
		@components.select do |c| c.active and c.blocking_animation? end.size > 0
	end
	
	def next_level		
		@mission += 1
		@mission = 14 if @mission > 14
		
		load_level()
	end
	
	def teleport_player
		while true
			tx = 1 + rand(64)
			ty = 1 + rand(23)
			cs = components_at(tx,ty)		
			if not cs			
				@player.x, @player.y = tx, ty 
				break
			end			
		end
	end
	
	def components_at(x,y)
		result = @components.select do |c|
			c.x == x and c.y == y and c.active
		end
		raise "more than one component at location #{x},#{y}: #{result.collect do |c| c.to_s end.join(" | ")}" if result.size > 1
		return result.first
	end
	
	def handle_action(action, *args)
		if action == :pause
			toggle_pause
		elsif action == :set_location
			@player.set_location(*args) unless components_at(*args) and not components_at(*args).can_player_walk?
		else			
			@next_player_action = action
		end
	end
	
	def shutdown
	end
	
		# main game engine.. update all entities		
	def update(dx)
		return if @paused
		
		@effects.each do |name,effect|
			effect.update(dx)
		end
		
		if not @effects[:flash].active?			
			@render_state.clear_flash if @render_state.current_flash
			@effects[:flash].activate if @render_state.current_flash			
		end
			
		@components.each do |c| c.update(dx) end
		
		if not blocking_animation_running?		
			@next_game_update -= dx
			if @next_game_update < 0.0
				game_tick()
				@next_game_update = GAME_TICK
				@next_game_update *= 6 if @effects[:slow_monster].active?
				@next_game_update /= 2 if @effects[:speed_monster].active?
			end
		
			@next_player_update -= dx
			if @next_player_update < 0.0
				player_tick(@next_player_action) if @next_player_action
				@next_player_update = PLAYER_TICK # try not adding, so if we are behind just leave it
				@next_player_action = nil		
			end		
		end		
		
	end	
	
	def player_tick(action)	
			
		x = @player.x
		y = @player.y
	
		y = y - 1 if [:move_up, :move_upleft, :move_upright].include? action
		y = y + 1 if [:move_down, :move_downleft, :move_downright].include? action
		x = x - 1 if [:move_left, :move_upleft, :move_downleft].include? action
		x = x + 1 if [:move_right, :move_downright, :move_upright].include? action		
			
		if @player.x != x or @player.y != y
			# attempt move
			cs = components_at(x,y)			
			if cs and not cs.can_player_walk?()
				cs.on_player_walk_fail()
			else				
				@player.x = x
				@player.y = y
				cs.on_player_walk() if cs
				# puts cs.first.name if cs.first
				# player walk sound
			end
					
			# check for OnEnter on destination
		end
		
		if action == :whip 
			if @player.whips > 0
				@player.add_whips(-1)				
				DIRS.each do |dir|
					cs = components_at(@player.x + dir.first, @player.y + dir.last)
					cs.on_whip() if cs
				end	
				@components << CompWhipAnimation.new(self, x, y)
			end
		elsif action == :teleport
			if @player.teleports > 0
				@player.add_teleports(-1)
				teleport_player
			end
		elsif action == :next_level
			next_level
		elsif action == :prev_level		
			@mission -= 1
			@mission = 1 if @mission <= 0
			
			load_level()
			
		end
		
		cleanup_components() # remove inactive components 
	end
	
	def cleanup_components()
		@components.select! do |c| c.active end
	end
	
	def game_tick()
		@components.each do |c| 
			c.tick() if c.active
		end
		cleanup_components()
	end
	
	def visible_components
		@components.select do |c| c.active and c.visible? end
	end
	
	# def components
		# @components
	# end
	
	
	
	def load_sprites
		SpriteManager.load_sprite_from_sheet("floor1", "terrain_sprites.png", 0, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("wall1", "terrain_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("border", "terrain_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("water", "terrain_sprites.png", 2, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("tree", "terrain_sprites.png", 1, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("forest", "terrain_sprites.png", 14, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("tunnel", "terrain_sprites.png", 8, 0, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("trap1", "item_sprites.png", 3, 2, 16, 24)
		SpriteManager.load_sprite_from_sheet("shootright", "feature_sprites.png", 11, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("shootleft", "feature_sprites.png", 11, 0, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("freeze", "item_sprites.png", 4, 1 , 16, 24)
		SpriteManager.load_sprite_from_sheet("fast", "item_sprites.png", 7, 0 , 16, 24)
		SpriteManager.load_sprite_from_sheet("slow", "item_sprites.png", 6, 0 , 16, 24)
		# 6,7
		
		SpriteManager.load_sprite_from_sheet("gem", "item_sprites.png", 3, 1 , 16, 24)
		SpriteManager.load_sprite_from_sheet("whip", "item_sprites.png", 15, 1 , 16, 24)
		SpriteManager.load_sprite_from_sheet("ring", "item_sprites.png", 31, 0 , 16, 24)
		SpriteManager.load_sprite_from_sheet("key", "item_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("chest", "item_sprites.png", 31, 2, 16, 24)
		SpriteManager.load_sprite_from_sheet("door", "sys_sprites.png", 6, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("exit", "feature_sprites.png", 4, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("teleport", "feature_sprites.png", 6, 0, 16, 24)
		
		
		SpriteManager.load_sprite_from_sheet("invis", "feature_sprites.png", 7, 0, 16, 24)
		
		
		SpriteManager.load_sprite_from_sheet("sign", "feature_sprites.png", 12, 0, 16, 24)		
		
		SpriteManager.load_sprite_from_sheet("tablet", "feature_sprites.png", 16, 0, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("player", "creature_sprites.png", 23, 3, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob1", "creature_sprites.png", 19, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob2", "creature_sprites.png", 1, 6, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob3", "creature_sprites.png", 20, 10, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("unknown", "terrain_sprites.png", 21, 0, 16, 24)
		
		('a'..'z').each do |letter|			
			SpriteManager.load_sprite_from_sheet(letter, "letters.png", letter.ord - 97, 0, 16, 24)
		end
	end
	
	# def place_random(comp)
		# while true
			# px, py = 2 + rand(@board_x - 2), 2 + rand(@board_y - 2)
			# if not components_at(px,py)
				# c = comp.new(self,px,py)
				# add_component(c)
				# return c
			# end
		# end
	# end
	
	def place_random(data, char)
		while true
			px, py = rand(@board_x), rand(@board_y)
			if data[px + py * @board_x] == " "
				data[px + py * @board_x] = char		
				return				
			end
		end
	end	
	
	def generate_random_level
		data = " " * 1495
		
		60.times do 
			place_random(data, "1")
			place_random(data, "X")
			place_random(data, "#")			
		end
		
		place_random(data, "L")
		place_random(data, "P")
				
		data
	end
	
	def add_component(c)
		
		@components << c
	end
	
	def load_level()
	
		# clear existing game
		@effects.each do |name,e| e.clear end
		@components = []
	
		if @episode == :kingdom and [3,5,7,9,11].include? @mission
			data = generate_random_level()
		else
			data = File.read("levels/#{@episode.to_s}_#{@mission}.dat")
		end
		
		# puts data.size
		raise "invalid map #{episode.to_s}_#{MISSIONS[episode][mission]}.dat" unless data.size == 1495 # plus newlines?
		#puts data[0]		
		idx = 0
	

		
		@board = []
		@board_x.times do |x|
			@board[x] = Array.new(@board_y, nil)
		end
		
		# borders
		(0...@board_x).each do |x|
			# @board[x][0] = TileBorder
			# @board[x][@board_y-1] = TileBorder
			@components << CompBorder.new(self, x, 0)
			@components << CompBorder.new(self, x, @board_y-1)
		end
		(1...@board_y-1).each do |y|
			# @board[0][y] = TileBorder
			# @board[@board_x-1][y] = TileBorder
			@components << CompBorder.new(self, 0, y)
			@components << CompBorder.new(self, @board_x-1, y)
		end
				
		(@board_y-2).times do |y|
			(@board_x-2).times do |x|				
				@board[x+1][y+1] = TileFloor					
				case data[idx]
					when "R"
						@board[x+1][y+1] = TileFloorWater	
					when "-"						
						# open space "stop"
						@components << CompStop.new(self, x+1, y+1)
					
					when "Z"
						@components << CompFreezeSpell.new(self, x+1, y+1)
					when "@"
						# trap 2
					when "$"
						# trap 5
					when "à"
						# trap 6
					when "á"
						# trap 7
					when "â"
						# trap 8
					when "ã"
						# trap 9
					when "ä"
						# trap 10
					when "å"
						# trap 11
					when "æ"
						# trap 12
					when "ç"
						# trap 13
					
					when "S"
						@components << CompSlowSpell.new(self, x+1, y+1)	
					when "F"
						@components << CompFastSpell.new(self, x+1, y+1)	
					when "®"
						@components << CompShootLeft.new(self, x+1, y+1)	
						
					when "/"						
						@components << CompForest.new(self, x+1, y+1)						
					when "\\"						
						@components << CompTree.new(self, x+1, y+1)
					when ";"
						@components << CompWeakWallInvisible.new(self, x+1, y+1)
					when "U"
						@components << CompTunnel.new(self,x+1,y+1)
					when "P"
						@player = CompPlayer.new(self, x+1,y+1)						
						@components << @player
					when "1"
						@components << CompMob1.new(self, x+1, y+1)						
					when "2"
						@components << CompMob2.new(self, x+1, y+1)						
					when "3"
						@components << CompMob3.new(self, x+1, y+1)
					when "W"
						@components << CompWhip.new(self, x+1, y+1)						
					when "+"
						@components << CompGem.new(self, x+1, y+1)						
					when "."						
						@components << CompTrapTeleport.new(self, x+1, y+1)
					when ">"
						@components << CompShootRight.new(self, x+1, y+1)						
					when " "
					
					when "#"						
						@components << CompWall.new(self, x+1, y+1)
					when "X"
						@components << CompWeakWall.new(self, x+1, y+1)										
					when "C"
						@components << CompChest.new(self, x+1, y+1)
					when "Q"
						@components << CompRing.new(self, x+1, y+1)
					when "I"
						@components << CompInvisibility.new(self,x+1,y+1)
					when "L"
						@components << CompExit.new(self, x+1, y+1)
					when "D"
						@components << CompDoor.new(self, x+1, y+1)
					when "K"
						@components << CompKey.new(self, x+1, y+1)
					when "T"
						@components << CompTeleport.new(self, x+1, y+1)
					when '‘'						
						@components << CompTrapBlock.new(self, x+1, y+1)
					when "a".."z"
						@components << CompLetter.new(self, x+1, y+1, data[idx])
					else
						@components << CompUnknown.new(self, x+1, y+1)
						#Tile.new("floor1", Gosu::Color.argb(0xff_202020))
				end
					
				idx += 1	
				idx += 1 while [10.chr, 13.chr].include? data[idx] # skip newlines
				
			end
		end
		
		# puts @board.size
		# puts @board[0].size
	end
	
	def floor_tile(x,y)	
		return @board[x][y]
	end

end

#level manager
#tile

# class Tile

	# load tile specs from yaml		
	# def initialize(sprite_name, color)
	
		# @sprite_name = sprite_name
		# @color = color
		# @name = name
		# @file_symbol = "."
		
	# end
	
	# def sprite_name()
		# @sprite_name
	# end
	
	# def color()
		# @color
	# end
	
# end

# class TileWall < Tile
	# def initialize()
		# super("wall1", Gosu::Color::GRAY)
	# end
# end

# class TileBorder
	# def self.sprite_name
		# "border"
	# end
	
	# def self.color
		# Gosu::Color::YELLOW
	# end
# end


class TileFloor
	def self.sprite_name
		"floor1"
	end
	
	def self.color
		Gosu::Color.argb(0xff_104010)
	end
end

class TileFloorWater
	def self.sprite_name
		"water"
	end
	
	def self.color
		Gosu::Color::BLUE
	end
end

