require 'yaml'
require './components.rb'
require './renderer.rb'

class Effect
	def initialize(default_activation_duration, &on_finish_proc)
		@default_activation_duration = default_activation_duration
		@duration = 0.0
		@on_finish = on_finish_proc	
		#@on_update = nil
		@component = nil
	end
	
	def active?
		@duration > 0.0
	end
	
	def link_component=(c)
		@component = c
	end
	
	# def set_on_update_func(f)
		# @on_update = f
	# end
	
	def activate(dur = nil)		
		# picking up multiple copies of a spell doesn't extend the timer
		@duration = dur ? dur : @default_activation_duration
	end
	
	def clear
		@duration = 0.0
	end
	
	def update(dt)
		if active?		
			@duration -= dt			
			if @duration < 0.0
				@duration = 0.0 
				@on_finish.call(self) if @on_finish
			end
		end		
	end	
	
	def update_component(dt)
		@component.update(dt) if @component and @component.active
	end
end


class KrozGame
	HINTS = {
		gem: "Gems give you both points and strength.",
		slow: 'You activated a Slow Creature spell.',
		ewall: 'An Electrified Wall blocks your way.'
	}
	
	attr_reader :board_x, :board_y, :player
	attr_reader :episode, :mission
	attr_reader :effects, :blocking_effects
	attr_reader :paused
	attr_reader :render_state
	attr_reader :gem_color, :border_color

	DIRS = [[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]]
	PLAYER_TICK = 0.1
	GAME_TICK = 0.3
	GROWTH_TICK = 0.8
	
	
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
		
		@episode = :kingdom # kingdom of kroz (remake?)
		@mission = 1 # level 1
		
		@player = nil # level loader will create the player when there's somewhere to place it
		@player_action = :none
		
		@render_state = RenderState.new()
		
		
		# game effects 
		@effects = {
			slow_monster: Effect.new(10.0),
			freeze_monster: Effect.new(10.0),
			speed_monster: Effect.new(10.0),
			invisible_player: Effect.new(8.0)			
		}
		
		@blocking_effects = {
			flash: Effect.new(9999)
		}
		

		@hints_found = Set.new()
		
		load_level()		

		@next_player_update = PLAYER_TICK
		@next_game_update = GAME_TICK
		
	end
	
	def give_hint(key)
		return if @hints_found.include? key
		message = KrozGame::HINTS[key]
		flash(message) if message
		@hints_found << key
	end
	
	# yikes
	def effects
		@effects
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
		raise "component already here #{comp} -  #{c}" if c and c.active
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
		@blocking_effects[:flash].activate if not @blocking_effects[:flash].active?
	end
	
	def slow_monster
		@effects[:slow_monster].activate
		@next_game_update = GAME_TICK * 6
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
	
	
	def pause
		@paused = true
	end 
	
	def unpause
		@paused = false
		@last_update = Time.now() if not @paused
	end
		
	def handle_action(action, *args)
		if action == :pause
			pause
		elsif action == :unpause
			unpause
		elsif action == :next_level and @player.status == :alive
			next_level
		elsif action == :prev_level and @player.status == :alive		
			prev_level # debugging only
		elsif action == :save_game and @player.status == :alive
			save_game
		elsif action == :restore_game
			restore_game
		elsif action == :restart_level						
			game_data = @game_data_at_start
			load_level
		elsif action == :set_location #debugging only 
			c = component_at(*args)
			@player.set_location(*args) unless (c and not c.can_player_walk?) or (args.first == @player.x and args.last == @player.y)
		elsif @player.status == :alive
			@next_player_action = action 
		end
	end
	
	def shutdown
	end
	
	def game_data
		{
			version: 1,
			episode: @episode, 
			mission: @mission, 
			score: @player.score, 
			gems: @player.gems, 
			whips: @player.whips, 
			rings: @player.rings, 
			teleports: @player.teleports, 
			keys: @player.keys, 
			difficulty: @player.difficulty_mod, 
			hints: @hints_found
		}.to_yaml
	end
	
	def game_data=(vals)
		if vals[:version] == 1
			@episode = data[:episode]
			@mission = data[:mission]
			@score = data[:score]
			@gems = data[:gems]
			@whips = data[:whips]
			@rings = data[:rings]
			@teleports = data[:teleports]
			@keys = data[:keys]
			@hints_found = data[:hints]
		else
			raise "unsupported version: #{vals[:version]}"
		end
	end
	
	def save_game
		# kroz just stores what you had at the beginning of the level...		
		File.write("save.yml", @game_data_at_start)
		flash("Game saved!  Press any key to continue playing.")
	end
	
	def restore_game
		# reload level...
		
		if not File.exists?("save.yml")
			flash("No save file found")
			return
		end
		
		data = YAML::load_file("save.yml")
		
		@game_data_at_start = data # now when loading this level 
		game_data = data
		
		
		load_level
	end
	
	# main game engine.. update all entities		
	def update(dt)
		@blocking_effects.each do |name,effect|
			effect.update(dt)
		end
		
		# update blocking components only if we are blocked
		if @blocking_effects.values.any? do |e| e.active? end
			@blocking_effects.each do |name,e| e.update_component(dt) end
			return
		end
		
		return if @paused or @player.status == :dead	
		
		@effects.each do |name,effect|
			# puts effect if effect.class != Effect
			effect.update(dt)
		end
			
		@components.each do |c| c.update(dt) end
		
		@next_game_update -= dt
		if @next_game_update < 0.0
			game_tick()
			@next_game_update = GAME_TICK
			@next_game_update *= 6 if @effects[:slow_monster].active?
			@next_game_update /= 2 if @effects[:speed_monster].active?
		end
	
		@next_player_update -= dt
		if @next_player_update < 0.0			
			player_tick(@next_player_action) if @next_player_action
			@next_player_update = PLAYER_TICK # try not adding, so if we are behind just leave it
			@next_player_action = nil		
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
					play("walk")
					@player.move(x,y) 
				
					# 'replace a rope we just stepped on and are now leaving behind
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
		
		if [:move_up, :move_upleft, :move_upright].include?(action) and @effects[:gravity]			
			
			if not location_supported?(x,y)
				x,y = @player.x, @player.y # reset movement
			end
		end
		
		player_move(x,y)

		
		if action == :whip 
			if @player.whips > 0
				@player.add_whips(-1)				
				DIRS.each do |dir|
					c = component_at(@player.x + dir.first, @player.y + dir.last)
					c.on_whip() if c
				end	
				anim = CompWhipAnimation.new(self, x, y)
				add_component(anim)
				@blocking_effects[:whip] = Effect.new(9999)
				@blocking_effects[:whip].link_component = (anim)
				@blocking_effects[:whip].activate
				# do the effect?				
				play("swing#{rand(3) + 1}")
				
				
			end
		elsif action == :teleport
			if @player.teleports > 0
				@player.add_teleports(-1)
				teleport_player
				play("spell")
				
			end
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
	
	def play(name)
		@render_state.play(name)
	end
		
	def generate_random_level(level_data)
	
		def place_random(data, char)
			while true
				px, py = rand(@board_x), rand(@board_y)
				if data[px + py * @board_x] == " "
					data[px + py * @board_x] = char		
					return				
				end
			end
		end	
	
		data = " " * 1472
		
		level_data[:data].each do |line|		
			glyph,cnt = line.strip.split(",")
			cnt.to_i.times do
				place_random(data, glyph)
			end
		end
		
		place_random(data, "P") # set player
				
		level_data[:data] = data
	end
	
	def add_component(c)
		# place_on_board(c,c.x,c.y) if c.layer == :space		
		@components << c
		c
	end
	
	def location_supported?(x,y)
		c = component_at(x,y)
		return true if c.class == CompRope
		c = component_at(x,y+1)
		return true if c and c.support_against_gravity?
		return true if c and c.class == CompPlayer and @player.rope_under?		
		return false
	end
	
	def place_multiple(num, comp, *args)
		num.times do
			attempts = 200
			found = false
			while not found
				
				loc = random_board_location
				c = component_at(loc.first,loc.last)
				if not c or [CompStop].include? c.class # place on stops too
					c.inactivate if c
					add_component(comp.new(self,loc.first,loc.last,*args))
					found = true
				end
				
				attempts -= 1
				return if attempts == 0  # we tried 200 times, lets just abort
			end
		end
	end
	
	
	def victory!
		flash("Oh no, something strange is happening!")
		flash("You are magically transported from Kroz!")
		flash("Your Gems are worth 100 points each...")
		@player.add_score(@player.gems * 100)
		flash("Your Whips are worth 100 points each...")
		@player.add_score(@player.whips * 100)
		flash("Your Teleport Scrolls are worth 100 points each...")
		@player.add_score(@player.teleports * 100)
		flash("Your Keys are worth 10,000 points each...")
		@player.add_score(@player.keys * 100)
		flash("Back at your hut")
		flash("For years you've waited for such a wonderful archaeological")
		flash("discovery. And now you possess one of the greatest finds ever!")
		flash("The Magical Amulet will bring you great fame, and even more")
		flash("so if you ever learn how to harness the Amulet's magical")
		flash("abilities.  For now it must wait, though, for Kroz is a huge")
		flash("place, and still mostly unexplored.")
		flash("Even with the many dangers that await, you feel another")
		flash("expedition is in order.  You must leave no puzzle unsolved, no")
		flash("treasure unfound--to quit now would leave the job unfinished.")
		flash("So you plan for a good night's rest, and think ahead to")
		flash("tomorrow's new journey.  What does the mysterious kingdom of")
		flash("Kroz have waiting for you, what type of new creatures will")
		flash("try for your blood, and what kind of brilliant treasure does")
		flash("Kroz protect.  Tomorrow will tell...")
	end
	
	def randomize_colors
		@gem_color = [Gosu::Color::RED,Gosu::Color::BLUE,Gosu::Color::GREEN,Gosu::Color::WHITE].sample
		@border_color = [Gosu::Color::RED,Gosu::Color::BLUE,Gosu::Color::GREEN,Gosu::Color::WHITE].sample
	end
	
	# interestingly lava and forests only spread orthogonal and not diagonal
	def is_orthogonal_to?(cx, cy, comp_classes)
		[[1,0],[-1,0],[0,1],[0,-1]].each do |dir|			
			comp = component_at(cx + dir.first, cy + dir.last)			
			return true if comp and comp_classes.include?(comp.class)
		end
		return false
	end
	
	def load_level()
		unload_level		
		flash("Press any key to begin this level")
		
		level_data = YAML::load_file("levels/#{@episode.to_s}_#{@mission}.yml")
		generate_random_level(level_data) if level_data[:mode] == :random
		
		level_data[:data] = level_data[:data].gsub(10.chr,"").gsub(13.chr,"")		

		randomize_colors

		if level_data[:flags][:gravity]
			@effects[:gravity] = Effect.new(0.25) do |e|							
				if not location_supported?(@player.x, @player.y) and not @player.rope_under?			
					player_move(@player.x,@player.y+1)		
				end
				e.activate
			end
			@effects[:gravity].activate
		else 
			@effects.delete(:gravity)
		end	

		if level_data[:flags][:lava_rate]					
			@effects[:lava] = Effect.new(GROWTH_TICK) do |e|				
				level_data[:flags][:lava_rate].to_i.times do
					pos = random_board_location						
					comp = component_at(pos.first, pos.last)
					if (not(comp) or comp.can_lava_spread?) and is_orthogonal_to?(pos.first,pos.last,[CompLava])
						comp.on_lava_spread if comp							
						add_component(CompLava.new(self, pos.first, pos.last))
					end
				end
				e.activate
			end
			@effects[:lava].activate
		else
			@effects.delete(:lava)
		end
		
		if level_data[:flags][:tree_rate]			
			@effects[:trees] = Effect.new(GROWTH_TICK) do |e|
				level_data[:flags][:tree_rate].to_i.times do
					pos = random_board_location		
					comp = component_at(pos.first, pos.last)					
					if (not(comp) or comp.can_tree_spread?) and is_orthogonal_to?(pos.first,pos.last,[CompTree,CompForest])									
						comp.on_tree_spread if comp
						if rand(4) == 0
							add_component(CompTree.new(self, pos.first, pos.last))
						else
							add_component(CompForest.new(self, pos.first, pos.last))
						end
					end
				end
				e.activate
			end
			@effects[:trees].activate
		else
			@effects.delete(:trees)
		end		
		
		raise "invalid map #{@episode.to_s}_#{@mission}.yml - #{level_data[:data].size} <> 1472" unless level_data[:data].size == 1472 # plus newlines?
				
		# borders
		(0...@board_x).each do |x|
			add_component(CompBorder.new(self, x, 0))			
			add_component(CompBorder.new(self, x, @board_y-1))
		end
		(1...@board_y-1).each do |y|
			add_component(CompBorder.new(self, 0, y))
			add_component(CompBorder.new(self, @board_x-1, y))
		end
		
		(1...@board_y-1).each do |y|
			(1...@board_x-1).each do |x|
				glyph = level_data[:data][(x-1) + (y-1) * (@board_x-2)]
				case glyph
					when "]" # {35} Create
						add_component(CompTrapMonsterCreate.new(self,x,y,not(level_data[:flags][:hide_create])))
					when "E" # {28} Quake
						add_component(CompQuakeTrap.new(self,x,y))
					when "R" # {17} River
						add_component(CompWater.new(self, x, y))
					when "-" # {32} Stop - blocks mobs until removed etc
						add_component(CompStop.new(self, x, y))
					when "G" # {36} Generator - generates mobs. score 50 
						add_component(CompGenerator.new(self,x,y))
					when "Z" # {26} Freeze - spell to freeze all enemies
						add_component(CompFreezeSpell.new(self, x, y))
					when "!" # {42} Tablet - pop up some text.
						add_component(CompTablet.new(self,x,y))
					when "B" # {21} Bomb - destroy mobs within 4 cells.  leave other things alone
						add_component(CompBomb.new(self,x,y))						
					when "V" # {22} Lava - lost 10 gems to walk on.  multiplies on some levels
						add_component(CompLava.new(self,x,y))
					when "=" # {23} Pit - fall in and die.  
						add_component(CompPit.new(self,x,y))					
					when "ü" # {252} Message - displays a secret message on lv18
						add_component(CompSecretMessage.new(self,x,y))
					
					# when player hits any of these, all with the same value go away
					# mobs can't touch them until then
					# {33,37,39,67,224-231}
					# trap 2,3,4,5,6,7,8,9,10,11,12,13
					when "@",")","(","$","à","á","â","ã","ä","å","æ","ç" 
						add_component(CompTrapCage.new(self,x,y,"("))
					when "?" # {45} chance - gem pouch
						add_component(CompGemPouch.new(self,x,y))
					when "N" # {47} wallvanish
						# wall vanish lv 16
						add_component(CompWallVanishTrap.new(self,x,y))
					when "&" # #{41} show gems - generate some gems
						add_component(CompSpellShowGems.new(self,x,y))
					when "*" # {27} Nugget
						add_component(CompNugget.new(self,x,y))		
					when "0" # #{65} Rock
						add_component(CompRock.new(self,x,y))
					when "S" # {8} slow time spell
						add_component(CompSlowSpell.new(self, x, y))
					when "F" # {15} speed-up curse
						add_component(CompFastSpell.new(self, x, y))
					when "¯" # {82} Shoot right
						add_component(CompShoot.new(self, x, y, :right))
					when "®" # {83} Shoot left
						add_component(CompShoot.new(self, x, y, :left))
					when "/" # {19} Forest - whip always clears
						add_component(CompForest.new(self, x, y))					
					when "\\" # {20} Tree
						add_component(CompTree.new(self, x, y))
					when ";" # {29} IBlock - weak wall that has to be bumped first to see
						add_component(CompWeakWallInvisible.new(self, x, y))
					when "U" # {25} Tunnel
						add_component(CompTunnel.new(self,x,y))						
					when "³" # {75} Rope
						add_component(CompRope.new(self,x,y))
					# {76,77,78,79,80} DropRope - cause a matching droprope to turn into a rope
					# and generate ropes downward to a surface
					when "¹","º","»","¼","½"
						add_component(CompDropRope.new(self,x,y,glyph))										
					when "P"					
						if not @player
							@player = add_component(CompPlayer.new(self,x,y))
						else			
							place_on_board(@player,x,y)
							@player.x, @player.y = x,y
						end
					when "1" # {1} slow monster
						add_component(CompMob1.new(self, x, y))
					when "2" # {2} medium monster
						add_component(CompMob2.new(self, x, y))
					when "3" # {3} fast monster
						add_component(CompMob3.new(self, x, y))
						
					# trigger trap removes corresponding trigger wall blocks
					# ñ>4, ò>5, ó>6, H>O, ô>7, õ>8, ö>9
					when "ñ" # {58} OSpell1
						add_component(CompTriggerTrap.new(self,x,y,4,nil, not(level_data[:flags][:hide_open_wall])))
					when "ò" # {59} OSpell2
						add_component(CompTriggerTrap.new(self,x,y,5,nil))
					when "ó" # {60} OSpell3
						add_component(CompTriggerTrap.new(self,x,y,6,nil))
					when "H" # {44} BlockSpell
						add_component(CompTriggerTrap.new(self,x,y,"O",nil))
					when "ô" # {61} CSpell1
						add_component(CompTriggerTrap.new(self,x,y,7,CompWall))
					when "õ" # {62} CSpell2
						add_component(CompTriggerTrap.new(self,x,y,8,CompWall))
					when "ö" # {63} CSpell3
						add_component(CompTriggerTrap.new(self,x,y,9,CompWall))					
					when "4" # {52} OWall1
						add_component(CompTriggerWallBlock.new(self,x,y,4))
					when "5" # {53} OWall2
						add_component(CompTriggerWallBlock.new(self,x,y,5))
					when "6" # {54} OWall3
						add_component(CompTriggerWallBlock.new(self,x,y,6))	
					when "O" # {43} ZBlock
						add_component(CompTriggerWeakWallBlock.new(self,x,y,"O"))	
					when "7" # {55} CWall1
						add_component(CompTriggerInvisBlock.new(self,x,y,7))
					when "8" # {56} CWall2
						add_component(CompTriggerInvisBlock.new(self,x,y,8))
					when "9" # {57} CWall3
						add_component(CompTriggerInvisBlock.new(self,x,y,9))
					when "%" # {34} zap spell - kills some enemies
						add_component(CompAltar.new(self,x,y))												
					when "W" # {5} Whip pickup
						add_component(CompWhip.new(self, x, y))
					when "+" # {9} gem
						add_component(CompGem.new(self, x, y, not(level_data[:flags][:hide_gems])))
					when "." # {16} teleport trap
						add_component(CompTrapTeleport.new(self, x, y))
					when ">" # {46} Statue - passively does damage
						add_component(CompStatue.new(self, x, y))					
					when "<" # {48} K - bonus points if you get all 4 in order
						add_component(CompKROZ.new(self,x,y, "k"))
					when "[" # {49} R - bonus points if you get all 4 in order
						add_component(CompKROZ.new(self,x,y, "r"))
					when "|" # {50} O - bonus points if you get all 4 in order
						add_component(CompKROZ.new(self,x,y, "o"))						
					when "\"" # {51} Z - bonus points if you get all 4 in order
						add_component(CompKROZ.new(self,x,y, "z"))					
					when "#" # #{14} solid wall, can't be destroyed						
						add_component(CompWall.new(self, x, y))
					when "Y" # gblock - same as weak wall but different color
						add_component(CompWeakWallAlt.new(self, x, y)) # just a different color? lv 4
					when "X" # {4} - Block - wall that can be whipped down or eaten by enemies
						add_component(CompWeakWall.new(self, x, y))
					when "C" #{7} chest
						add_component(CompChest.new(self, x, y))
					when "Q" #{18} Power - ring to increase whip strength
						add_component(CompRing.new(self, x, y))
					when "I" #{10} invisible curse
						add_component(CompInvisibility.new(self,x,y))
					when "L" #{6} stairs
						add_component(CompExit.new(self, x, y, not(level_data[:flags][:hide_exit])))
					when "D" #{13} door - must be unlocked with a key to progress
						add_component(CompDoor.new(self, x, y))
					when "`" #{31} IDoor - invisible door - bump to reveal
						add_component(CompDoorInvis.new(self, x, y))
					when "K" # {12} Key pickup
						add_component(CompKey.new(self, x, y))
					when "T" # {11} Teleport pickup
						add_component(CompTeleport.new(self, x, y))
					when "A" # {24} Tome
						add_component(CompTome.new(self,x,y))
					when "’" #{69}TRock
						add_component(CompTrapSurround.new(self, x, y, CompRock))
					when '‘' #{68}TBlock						
						add_component(CompTrapSurround.new(self, x, y, CompWeakWall))
					when "“" #{70}TGem
						add_component(CompTrapSurround.new(self, x, y, CompGem))
					when "”" #{71}TBlind
						add_component(CompTrapSurround.new(self, x, y, CompInvisibility))
					when "•" #{72}TWhip
						add_component(CompTrapSurround.new(self, x, y, CompWhip))
					when "–" #{73}TGold
						add_component(CompTrapSurround.new(self, x, y, CompNugget))
					when "—" #{74}TTree
						add_component(CompTrapSurround.new(self, x, y, CompTree))
					when ":" # {30} IWall - invisible wall - bump to reveal
						add_component(CompWallInvis.new(self, x, y))
					when "@" # {33} what glyph should this actually be??
						add_component(CompMovingBlockTrap.new(self,x,y))
					when "M" # {38} magic blocks - can start alive or come alive after hitting movingblocktrap
						add_component(CompMovingBlock.new(self,x,y, not(level_data[:flags][:hide_level_mblock])))
					when "~" # {66} ewall - electrified wall
						add_component(CompEWall.new(self,x,y))
					when "a".."z" # literal letters, otherwise walls
						add_component(CompLetter.new(self, x, y, glyph))
					when "Ã" # literal exclamation mark
						add_component(CompLetter.new(self, x, y, "!"))

					#when "ƒ" # {81} not implemented - just says "ERROR!!!" in original
					when " "
					else
						raise "unknown #{mission} #{glyph}"
						add_component(CompUnknown.new(self, x, y))
						#Tile.new("floor1", Gosu::Color.argb(0xff_202020))
				end				
			end
		end
		
		@game_data_at_start = game_data
	end
	
	def clear_all
		@components = []
		@board.select! do nil end
	end
	
	def unload_level
		@render_state.clear_all
		@blocking_effects.each do |name,e| e.clear end
		@effects.each do |name,e| e.clear end
		@floor = Array.new(@board_x * @board_y, TileFloor)
		@board = Array.new(@board_x * @board_y, nil)
		@components = []
		@components << @player if @player
		@player.clear_kroz if @player
	end
	
	def next_level		
		@mission += 1
		@mission = 25 if @mission > 25		
		load_level()
	end
	
	def prev_level
		@mission -= 1
		@mission = 1 if @mission <= 0			
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
		# super("wall", Gosu::Color::GRAY)
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
		#Gosu::Color.argb(0xff_104010)
		Gosu::Color::WHITE
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

