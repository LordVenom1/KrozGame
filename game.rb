require 'yaml'
require './components.rb'
require './renderer.rb'

class Effect
	def initialize(default_activation_duration, &on_finish_block)
		@default_activation_duration = default_activation_duration
		@duration = 0.0
		@on_finish = on_finish_block
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
			if @duration < 0.0
				@duration = 0.0 
				@on_finish.call(self) if @on_finish
			end
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
	
	def random_board_location
		# 2 smaller to avoid borders
		return 1 + rand(@board_x - 2), 1 + rand(@board_y - 2)
	end
	
	def initialize()
		@board_x = 64 + 2
		@board_y = 23 + 2
		
		@floor = Array.new(@board_x * @board_y, TileFloor)
		@board = Array.new(@board_x * @board_y, nil)
		@components = []
		
		load_sprites()
		
		@episode = :kingdom # kingdom of kroz (remake?)
		@mission = 1 # level 1
		
		@player = nil # level loader will create the player when there's somewhere to place it
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
		
	def component_at(x,y)
		c = @board[x + y * @board_x]		
		return nil if not c or not c.active
		c
	end
	
	def components
		@components
	end
	
	def place_on_board(comp,x,y)		
		c = component_at(x,y)
		raise "component already here #{c} - #{x},#{y}" if c and c.active
		@board[x + y * @board_x] = comp
	end
	
	def move_on_board(comp,bx,by,ax,ay)		
		return if bx == ax and by == ay		
		remove_from_board(comp, bx, by)
		place_on_board(comp, ax, ay)
	end
	
	def remove_from_board(c, x, y)
		raise "component not here #{c} #{x} #{y}" unless c === @board[x + y * @board_x]
		@board[x + y * @board_x] = nil
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
	
	def teleport_player
		while true
			tx,ty = random_board_location
			c = component_at(tx,ty)		
			if not c and tx != @player.x and ty != @player.y								
				@player.set_location(tx,ty)
				break
			end			
		end
	end
		
	def handle_action(action, *args)
		if action == :pause
			toggle_pause
		elsif action == :set_location
			c = component_at(*args)
			@player.set_location(*args) unless (c and not c.can_player_walk?) or (args.first == @player.x and args.last == @player.y)
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
			# puts effect if effect.class != Effect
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
			
				# do this as an effect instead?
				# "side-ways" level: move down if not on stable ground
				if @episode == :kingdom and @mission == 8
					
				end
					# c = component_at(@player.x,@player.y+1)
					# if not [CompWall,CompWeakWall,CompBorder].include? c.class
						# @next_player_action = :move_down
					# end
				# end
			
				player_tick(@next_player_action) if @next_player_action
				@next_player_update = PLAYER_TICK # try not adding, so if we are behind just leave it
				@next_player_action = nil		
			end		
		end		
		
	end	
	
	def player_move(x,y)
		if @player.x != x or @player.y != y			
			px,py = @player.x,@player.y
			c = component_at(x,y)
			if c and not c.can_player_walk?()
				c.on_player_walk_fail()
			else								
				still_move = c ? c.on_player_walk() : true
				if still_move
					@player.move(x,y) 
				
					if @player.rope_under?
						add_component(CompRope.new(self,px,py)) 
						@player.rope_under = false
					end
					
					c.on_player_walk_after if c	
				end
			end
		end
	end
	
	def player_tick(action)	
			


		x = @player.x
		y = @player.y
		
		px,py = x,y
	
		y = y - 1 if [:move_up, :move_upleft, :move_upright].include? action
		y = y + 1 if [:move_down, :move_downleft, :move_downright].include? action
		x = x - 1 if [:move_left, :move_upleft, :move_downleft].include? action
		x = x + 1 if [:move_right, :move_downright, :move_upright].include? action
		player_move(x,y)

		
		if action == :whip 
			if @player.whips > 0
				@player.add_whips(-1)				
				DIRS.each do |dir|
					c = component_at(@player.x + dir.first, @player.y + dir.last)
					c.on_whip() if c
				end	
				add_component(CompWhipAnimation.new(self, x, y))				
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
		
		SpriteManager.load_sprite_from_sheet("trap_teleport", "item_sprites.png", 3, 2, 16, 24)
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
		# SpriteManager.load_sprite_from_sheet("door", "sys_sprites.png", 5, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("door", "custom.png", 0, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("exit", "feature_sprites.png", 4, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("teleport", "feature_sprites.png", 6, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("bomb", "item_sprites.png", 21, 1, 16, 24)
				
		SpriteManager.load_sprite_from_sheet("rock", "item_sprites.png", 24, 2, 16, 24)
		SpriteManager.load_sprite_from_sheet("nugget", "item_sprites.png", 10, 1, 16, 24)
		SpriteManager.load_sprite_from_sheet("rope", "creature_sprites.png", 26, 3, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("invis", "feature_sprites.png", 7, 0, 16, 24)
		
		
		SpriteManager.load_sprite_from_sheet("sign", "feature_sprites.png", 12, 0, 16, 24)		
		
		SpriteManager.load_sprite_from_sheet("tablet", "feature_sprites.png", 16, 0, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("player", "creature_sprites.png", 23, 3, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob1", "creature_sprites.png", 19, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob2", "creature_sprites.png", 1, 6, 16, 24)
		SpriteManager.load_sprite_from_sheet("mob3", "creature_sprites.png", 20, 10, 16, 24)
		SpriteManager.load_sprite_from_sheet("generator", "item_sprites.png", 24, 1, 16, 24)
		
		SpriteManager.load_sprite_from_sheet("unknown", "terrain_sprites.png", 21, 0, 16, 24)
		
		('a'..'z').each do |letter|			
			SpriteManager.load_sprite_from_sheet(letter, "letters.png", letter.ord - 97, 0, 16, 24)
		end
	end
		
	def generate_random_level
	
		def place_random(data, char)
			while true
				px, py = rand(@board_x), rand(@board_y)
				if data[px + py * @board_x] == " "
					data[px + py * @board_x] = char		
					return				
				end
			end
		end	
	
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
		# place_on_board(c,c.x,c.y) if c.layer == :space		
		@components << c
		c
	end
	
	def load_level()
	
		# clear existing game
		unload_level
		
	
		if @episode == :kingdom and [3,5,7,9,11].include? @mission
			data = generate_random_level()
		else
			data = File.read("levels/#{@episode.to_s}_#{@mission}.dat")
		end
		
		# puts data.size
		raise "invalid map #{episode.to_s}_#{MISSIONS[episode][mission]}.dat" unless data.size == 1495 # plus newlines?
		#puts data[0]		
		
			
		# borders
		(0...@board_x).each do |x|
			# @board[x][0] = TileBorder
			# @board[x][@board_y-1] = TileBorder
			add_component(CompBorder.new(self, x, 0))			
			add_component(CompBorder.new(self, x, @board_y-1))
		end
		(1...@board_y-1).each do |y|
			# @board[0][y] = TileBorder
			# @board[@board_x-1][y] = TileBorder
			add_component(CompBorder.new(self, 0, y))
			add_component(CompBorder.new(self, @board_x-1, y))
		end
		
		idx = 0
		(1...@board_y-1).each do |y|
			(1...@board_x-1).each do |x|
				case data[idx]
					when "R"
						#@floor[x + y * @board_x] = TileFloorWater						
						add_component(CompWater.new(self, x, y))
					when "-"						
						# open space "stop"
						add_component(CompStop.new(self, x, y))
					when "G"
						add_component(CompGenerator.new(self,x,y))
					when "Z"
						add_component(CompFreezeSpell.new(self, x, y))
					when "!"
						add_component(CompTablet.new(self,x,y))
					when "B"
						add_component(CompBomb.new(self,x,y))
						#bomb
					when "V"
						#lava
					when "=" 
						#pit
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
					when ")"
						# trap 3
					when "•"
						# spawn a whip...?
					when "?"
						# hidden object...
						# gem pouch?
					when "*"	
						add_component(CompNugget.new(self,x,y))		
					when "0"
						add_component(CompRock.new(self,x,y))
					when "S"
						add_component(CompSlowSpell.new(self, x, y))
					when "F"
						add_component(CompFastSpell.new(self, x, y))
					when "®"
						add_component(CompShootLeft.new(self, x, y))
					when "/"						
						add_component(CompForest.new(self, x, y))					
					when "\\"						
						add_component(CompTree.new(self, x, y))
					when ";"
						add_component(CompWeakWallInvisible.new(self, x, y))
					when "U"
						add_component(CompTunnel.new(self,x,y))
						
					when "³"
						add_component(CompRope.new(self,x,y))
					when "¹","º","»","¼","½"
						add_component(CompDropRope.new(self,x,y))
	# {75} Rope      = #179; {ALT-179}
# {}  {76} DropRope  = #25;  {ALT-185}
# {}  {77}{DropRope}         {ALT-186}
# {}  {78}{DropRope}         {ALT-187}
# {}  {79}{DropRope}         {ALT-188}
# {}  {80}{DropRope}         {ALT-189}						
						
					when "P"					
						if not @player
							@player = add_component(CompPlayer.new(self,x,y))
						else			
							place_on_board(@player,x,y)
							@player.x, @player.y = x,y
						end
					when "1"
						add_component(CompMob1.new(self, x, y))
					when "2"
						add_component(CompMob2.new(self, x, y))
					when "3"
						add_component(CompMob3.new(self, x, y))
					when "ñ"
						add_component(CompTriggerTrap.new(self,x,y,4,nil))  # open spell
					when "ò"
						add_component(CompTriggerTrap.new(self,x,y,5,nil))
					when "ó"
						add_component(CompTriggerTrap.new(self,x,y,6,nil))
					when "H"
						add_component(CompTriggerTrap.new(self,x,y,"O",nil))
					when "ô"
						add_component(CompTriggerTrap.new(self,x,y,7,CompWall))
					when "õ"
						add_component(CompTriggerTrap.new(self,x,y,8,CompWall))
					when "ö"
						add_component(CompTriggerTrap.new(self,x,y,9,CompWall))					
					when "4"
						add_component(CompTriggerWallBlock.new(self,x,y,4))
					when "5"
						add_component(CompTriggerWallBlock.new(self,x,y,5))
					when "6"
						add_component(CompTriggerWallBlock.new(self,x,y,6))	
					when "O"
						add_component(CompTriggerWeakWallBlock.new(self,x,y,"O"))	
					when "7"
						add_component(CompTriggerInvisBlock.new(self,x,y,7))
					when "8"
						add_component(CompTriggerInvisBlock.new(self,x,y,8))
					when "9"
						add_component(CompTriggerInvisBlock.new(self,x,y,9))
					when "%"
						# destroy a handful of enemies?												
					when "W"
						add_component(CompWhip.new(self, x, y))
					when "+"
						add_component(CompGem.new(self, x, y))
					when "."						
						add_component(CompTrapTeleport.new(self, x, y))
					when ">"
						add_component(CompShootRight.new(self, x, y))
					when " "
					# {<}  {48}  { K }
					# {[}  {49}  { R }
					# {|}  {50}  { O }
					# {"}  {51}  { Z }
					when "#"						
						add_component(CompWall.new(self, x, y))
					when "Y"
						add_component(CompWeakWall.new(self, x, y)) # just a different color? lv 4
					when "X"
						add_component(CompWeakWall.new(self, x, y))
					when "C"
						add_component(CompChest.new(self, x, y))
					when "Q"
						add_component(CompRing.new(self, x, y))
					when "I"
						add_component(CompInvisibility.new(self,x,y))
					when "L"
						add_component(CompExit.new(self, x, y))
					when "D"
						add_component(CompDoor.new(self, x, y))
					when "K"
						add_component(CompKey.new(self, x, y))
					when "T"
						add_component(CompTeleport.new(self, x, y))
					when "’"
						add_component(CompTrapRock.new(self,x,y))
					when '‘'						
						add_component(CompTrapBlock.new(self, x, y))
					when "a".."z"
						add_component(CompLetter.new(self, x, y, data[idx]))
					else
						add_component(CompUnknown.new(self, x, y))
						#Tile.new("floor1", Gosu::Color.argb(0xff_202020))
				end
					
				idx += 1	
				idx += 1 while [10.chr, 13.chr].include? data[idx] # skip newlines
				
			end
		end
		
		
		# sideways level
		if @episode == :kingdom and @mission == 8
			flash("sideways!")
			@effects[:gravity] = Effect.new(0.25) do |e|
				# puts "falling"
				c = component_at(@player.x,@player.y+1)
				if not [CompWall,CompWeakWall,CompBorder].include? c.class					
					player_move(@player.x,@player.y+1)		
				end
				e.activate
			end
			@effects[:gravity].activate
		end
		
		# { NOTE: The lines below are special conditions }
		# if Level=9 then TreeRate:=40;
		# if Level=15 then begin LavaFlow:=true;LavaRate:=40;end;
				  
		# puts @board.size
		# puts @board[0].size
	end
	
	def unload_level
		@effects.each do |name,e| e.clear end
		@floor = Array.new(@board_x * @board_y, TileFloor)
		@board = Array.new(@board_x * @board_y, nil)
		@components = []
		@components << @player if @player
	end
	
	def next_level		
		@mission += 1
		@mission = 14 if @mission > 14
		
		load_level()
	end
	
	def floor_tile(x,y)	
		return @floor[x + y * @board_x]
	end
	
	def floor_tile=(val,x,y)
		@floor[x + y * @board_x] = val
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

