require 'Set'

class Component
	attr_accessor :x, :y, :active, :layer	
	def initialize(game, x = nil,y = nil, name = "", on_board = true)
		@game = game
		@on_board = on_board
		@x,@y = x,y		
		@name = name
		@color = Gosu::Color::WHITE
		@active = true				
		@game.place_on_board(self,x,y) if @on_board
	end
	
	def inactivate
		@active = false
		@game.remove_from_board(self, @x, @y) if @on_board
	end
	
	def move(ax,ay)
		c = @game.component_at(ax,ay)
		raise "#{self.to_s} - #{c} is already at #{ax},#{ay}" if c
		
		@game.move_on_board(self, @x, @y, ax, ay)
		@x,@y = ax,ay		
	end
	
	def visible?
		true
	end
	
	def update(dt)		
	end
	
	def tick()
	end
	
	def sprite_name()
		@name
	end
	
	def color()
		@color
	end
		
	def on_player_walk
		inactivate
		true
	end
		
	def on_player_walk_fail()
	end
	
	def on_player_walk_after()
	end
	
	def can_player_walk?()
		false
	end
	
	def can_push_rock?()
		false
	end
	
	def on_push_rock(rock)
		inactivate
	end
	
	def on_mob_walk()
		true
	end 
	
	def can_mob_walk?()
		true
	end 
	
	def on_arrow_hit()
		false
	end

	def on_bomb		
	end
	
	def on_whip()
	end
		
	def support_against_gravity?
		false
	end
	
	def to_s
		[self.class.to_s, @name, @active, "#{@x}, #{@y}"].join(",")
	end
	
	def stops_rope_drop?
		true
	end
	
	def can_lava_spread?
		false
	end
	
	def on_lava_spread
		inactivate
	end
	
	def can_tree_spread?
		false
	end
	
	def on_tree_spread
		inactivate
	end
	
	# small chance that some components get displayed as a question mark
	def chance_to_obscure(i)
		if rand(i) == 0
			@name = "question"
			@color = Gosu::Color::WHITE
		end
	end
end

class CompTypePowerup < Component
	def initialize(game,x,y,name)
		super
	end
	
	def can_player_walk?
		true
	end
	
	def can_mob_walk?
		true
	end
	
	def on_player_walk
		inactivate
	end
	
	def on_mob_walk
		inactivate
	end
	
	def on_whip
		inactivate
	end
	
	def can_lava_spread?
		true
	end
	
	def can_tree_spread?
		true
	end
	
	def can_tree_spread?
		true
	end
	
	def on_arrow_hit
		inactivate
		false
	end
	
	def can_push_rock?
		true
	end
end

require_relative 'animations.rb'

class CompPlayer < Component

	attr_reader :score, :gems, :whips, :teleports, :keys, :rings
	attr_reader :status

	def initialize(game,x,y)
		super(game,x,y,"player")
		@color = Gosu::Color::YELLOW
		
		@score = 0	
		@gems = 20
		
		@whips = 10
		
		@teleports = 0
		@keys = 0
		@rings = 0
		@status = :alive
		
		@keys = 99
			
		@rope = false
		
		@letters = Set.new()
	end
	
	def set_game_data(data)
		@status = data[:status]
		@score = data[:score]
		@gems = data[:gems]
		@whips = data[:whips]
		@rings = data[:rings]
		@teleports = data[:teleports]
		@keys = data[:keys]
		clear_kroz
		rope_under = nil
		
	end
	
	def kill
		@status = :dead
	end
	
	def victory!
		@status = :victory
	end
	
	def difficulty_mod
	    # 9:begin Gems:=250;Whips:=100;Teleports:=50;Keys:=1;WhipPower:=3; end;
		# 8:begin Gems:=20;Whips:=10;end;
		# 5:Gems:=15;
		# 2:Gems:=10
		8
	end
	
	# dunno about this...
	def add_kroz(letter)
		@letters << letter
		if @letters.size == 4 and letter == 'z'
			add_score(1000)
		end
	end
	
	def clear_kroz
		@letters = Set.new()
	end
	
	def rope_under=(val)
		@rope = val
	end
	
	def rope_under?
		@rope
	end
	
	def whip_power
		2 + @rings
	end
	
	def update(dt)
	end
	
	# used to change the player's location outside the normal game
	def set_location(px,py)
		@game.player_move(px,py)
	end
	
	def visible?
		!@game.effects[:invisible_player].active?		
	end
	
	# scores in the game are x10 what they are coded as?? or the victory is only 1/10th???
	def add_score(s)
		@score += s * 10
		s = 0 if s < 0
	end
	
	def add_gems(cnt)		
		@gems += cnt
		@score = cnt * 10 if cnt > 0
		if @gems < 0
			@status = :dead 
			@gems = 0
			@game.flash("You have died")
		end			
	end
	
	def add_whips(cnt)
		@whips += cnt		
	end
	
	def add_rings(cnt)
		@rings += cnt
	end
	
	def add_keys(cnt)
		@keys += cnt
	end
	
	def add_teleports(cnt)
		@teleports += cnt
	end
	
	def on_mob_walk()
		add_gems(-1)
		true
	end 
end

###############################################################################
#  Powerups 
###############################################################################

class CompInvisibility < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"invis")
	end	
	
	def on_player_walk		
		super
		@game.flash("Oh no, a temporary Blindness Potion!")
		@game.player.add_score(10)
		@game.effects[:invisible_player].activate
		true
	end
end

class CompWhip < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"whip")
		@color = Gosu::Color::YELLOW
	end 
	
	def on_player_walk()
		super
		@game.player.add_whips(1)
		@game.player.add_score(1)
		true
	end
end	

class CompKROZ < CompTypePowerup
	def initialize(game,x,y,letter)
		super(game,x,y,letter)		
		@color = Gosu::Color::WHITE
	end
	
	def on_player_walk
		super
		@game.player.add_kroz(@name)
		true
	end
end

class CompChest < CompTypePowerup
	def initialize(game,x,y)	
		super(game,x,y,"chest")
		@color = Gosu::Color::YELLOW		
		chance_to_obscure(20)		
	end
	
	def on_player_walk()		
		super
		g = 3 + rand(3) * 2
		w = 1 + rand(3)
		@game.play("door")
		@game.player.add_gems(g)
		@game.player.add_whips(w)
		@game.player.add_score(5)
		@game.flash("you found #{g} gems and #{w} whips!")
		true
	end
end	

class CompGem < CompTypePowerup
	def initialize(game,x,y,visible = true)
		super(game,x,y,"gem")
		@visible = visible
	end 
		
	def color
		@game.gem_color || Gosu::Color.argb(0xff_FB00F2)
	end
	
	def visible?
		@visible
	end
	
	def on_player_walk()	
		super		
		@game.player.add_gems(1)
		@game.player.add_score(1)
		@game.give_hint(:gem)
		@game.play("gem")
		true
	end
end	

class CompGemPouch < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"question")
		@color = Gosu::Color::WHITE
	end
	
	def on_player_walk?
		super
		@game.play("pouch")
		g = rand(@player.difficulty_mod) + 13
		@player.add_score(100)
		@game.flash("You found a Pouch containing #{g} Gems!")
		@player.add_gems(g)
		true
	end
end

class CompKey < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"key")
		@color = Gosu::Color.argb(0xff_FB00F2)
		chance_to_obscure(25)
	end 
	
	def on_player_walk()		
		super
		@game.player.add_keys(1)
		@game.player.add_score(1)
		@game.give_hint(:key)
		@game.play("pouch")
		true
	end
end

class CompNugget < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"nugget")
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk
		super
		@game.give_hint(:nugget)
		@game.player.add_score(50)
		true
	end
end

class CompTeleport < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"teleport")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk
		super
		@game.give_hint(:teleport)
		@game.player.add_score(1)
		@game.player.add_teleports(1)
		true
	end
end	

class CompRing < Component
	def initialize(game,x,y)
		super(game,x,y,"ring")
		@game.give_hint(:ring)
		@color = Gosu::Color.argb(0xff_FB00F2)
		chance_to_obscure(10)
	end 
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		super
		@game.player.add_rings(1)
		@game.player.add_score(15)
		true
	end
end	

class CompSecretMessage < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"message")
	end 
	
	def visible? 
		false
	end
	
	def on_player_walk
		super
		@game.flash("You notice a secret message carved into the old tree...")
		@game.flash("\"Goodness of Heart Overcomes Adversity.\"")
	end
end

class CompTome < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"tome")
	end
	
	def on_player_walk
		super
		@game.player.add_score(5000)
		@game.flash("The Magical Amulet of Kroz is finally yours--50,000 points!")
		@game.flash("Congratualtions, Adventurer, you finally did it!!!")
		comp = @game.component_at(34,6)
		comp.inactivate if comp
		@game.add_component(CompExitFinal.new(@game,34,6))
	end
end

class CompTablet < CompTypePowerup
	def initialize(game,x,y)
		super(game,x,y,"tablet")
		@color = Gosu::Color::YELLOW
	end
		
	def on_player_walk
		inactivate
		case @game.episode 
			when :kingdom
				case @game.mission
					when 1
						@game.flash("Once again you uncover the hidden tunnel leading to Kroz!")
					when 2
						@game.flash("Warning to all Adventurers:  No one returns from Kroz!")
					when 4
						@game.flash("Adventurer, try the top right corner if you desire.")
					when 6
						@game.flash("A strange magical gravity force is tugging you downward!")
					when 8
						@game.flash("You have choosen the greedy path Adventurer!")	
					when 9
						@game.flash("A magical forest grows out of control in this region of Kroz!")
					when 10
						@game.flash("Sometimes, Adventurer, Gems can be crystal clear.")
					when 12
						@game.flash("The lava will block a slow Adventurer''s path!")
					when 14
						@game.flash("Follow the sequence if you wish to be successful.")
					when 18
						@game.flash("On the Ancient Tablet is a short Mantra, a prayer...")
						@game.flash("You take a deep breath and speak the words aloud...")
						@game.flash("Barriers of water, like barriers in life, can always be...")
												
						@game.components.select do |c| c.class == CompWater and c.active end.each do |c|
							c.inactivate
							@game.add_component(CompTriggerWeakWallBlock.new(@game,c.x,c.y,"O"))
						end
						
						@game.flash("...Overcome!")
					when 20
						@game.flash("These walls will seek to entrap you!")
					when 22
						@game.flash("If goodness is in my heart, that which flows shall...")						
						
						@game.components.select do |c| c.class == CompWater and c.active end.each do |c|
							c.inactivate
							@game.add_component(CompNugget.new(@game,c.x,c.y))
						end
						
						@game.flash("...Turn to Gold!")
					else
						raise "no tablet defined for #{@game.episode.to_s} - #{@game.mission}"
					
				end
			else
				raise @game.episode.to_s
		end
	end
	
	def can_lava_spread?
		false
	end
end

class CompLetter < Component
	def initialize(game,x,y, letter)
		super(game,x,y,letter)
		@color = Gosu::Color::WHITE # font is red
	end
	
	def can_mob_walk?
		false
	end
	
	def can_player_walk?()
		false
	end
	
	def support_against_gravity?
		true
	end
end

###############################################################################
#  Base Terrain
###############################################################################

class CompBorder < Component
	def initialize(game,x,y)
		super(game,x,y,"border")
		# @color = Gosu::Color::YELLOW
	end
	
	def color
		@game.border_color || Gosu::Color::YELLOW
	end
		
	def can_player_walk?()
		false
	end
	
	def on_player_walk_fail()
		# subtract score, 
		# play noise
		@game.player.add_score(@game.mission * -2)
		@game.flash("An Electrified Wall blocks your way.")
	end
	
	def can_mob_walk?()
		false
	end 
	
	def support_against_gravity?
		true
	end
end

class CompStop < Component
	def initialize(game,x,y)
		super(game,x,y,"stop")
	end
	
	def visible?
		false
	end
	
	def can_mob_walk?
		false
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		inactivate
		true
	end
	
	def on_whip
		inactivate
	end
			
	def stops_rope_drop?
		false
	end
	
	def can_push_rock?
		true
	end
	
	def on_push_rock(rock)
		inactivate
	end
	
	def can_lava_spread?
		true
	end
	
	def can_tree_spread
		true
	end
end

class CompRock < Component
	def initialize(game,x,y)
		super(game,x,y,"rock")
		@color = Gosu::Color::GRAY
	end
	
	def can_mob_walk?
		false
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		# try to move boulder in same direction as player before player is allowed to move
		v = [@x - @game.player.x, @y - @game.player.y]
		nx = @x + (@x - @game.player.x)
		ny = @y + (@y - @game.player.y)
		c = @game.component_at(nx,ny)
		if (c and c.can_push_rock?) or not c
			c.on_push_rock(self) if c			
			move(@x + v.first, @y + v.last) if @active
			true
		else
			false
		end
	end
	
	def support_against_gravity?
		true
	end
	
	def on_player_walk_after
	end
	
	def on_whip
		if (rand(50)) < @game.player.whip_power
			inactivate
			@game.player.add_score(100)
		end
	end
end


class CompWall < Component
	def initialize(game,x,y)
		super(game,x,y,"wall")
		@color = Gosu::Color::GRAY
	end 
	
	def can_player_walk?()
		false
	end
	
	def on_player_walk_fail		
		@game.player.add_score(-2)
	end
	
	def support_against_gravity?
		true
	end
		
	def can_mob_walk?()
		false
	end 

	def on_arrow_hit()
		true
	end
end	

class CompWeakWall < Component
	WALL_RESIST = 4
	def initialize(game,x,y)
		super(game,x,y,"wall")
		@color = Gosu::Color.argb(0xff_A52A2A)
	end 
	
	def can_player_walk?()
		false
	end
	
	def on_player_walk_fail
		@game.player.add_score(-2)
	end

	def on_mob_walk()
		inactivate
		true
	end

	def on_whip()
		# raise 'invalid str' unless (1..7).include? str		
		inactivate if (rand(7)) < @game.player.whip_power
	end
	
	def on_arrow_hit()
		return true
	end
	
	def support_against_gravity?
		true
	end
end

class CompWeakWallAlt < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@color = Gosu::Color::WHITE
	end
end

class CompTree < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@name = "tree"
	end
	
	def can_mob_walk?()
		false
	end
end

class CompForest < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@name = "forest"
		@color = Gosu::Color::GREEN
	end
	
	def can_mob_walk?()
		false
	end	
	
	def on_whip
		inactivate
	end
end

class CompExit < Component
	def initialize(game,x,y,visible)
		super(game,x,y,"exit")
		@color = Gosu::Color::GREEN
		@visible = visible
	end 
	
	def visible?
		@visible
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk()		
		super
		@game.give_hint(:stairs)
		@game.player.add_score(@game.mission)		
		@game.next_level()
		false
	end
end

class CompExitFinal < CompExit
	def initialize(game,x,y)
		super(game,x,y,true)
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk()
		inactivate
		@game.victory!
	end
end

class CompPit < Component
	def initialize(game,x,y)
		super(game,x,y,"pit")
	end
	
	def can_mob_walk? 
		false
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		# fall to death!
		super
		
		@game.clear_all			
		
		# build a quick 'level'
		(0..24).each do |y|
			@game.add_component(CompWall.new(@game,25,y))
			@game.add_component(CompWall.new(@game,40,y))
		end		
		
		anim = CompFallingAnimation.new(@game,32,0)
		@game.add_component(anim)
		@game.blocking_effects[:falling] = Effect.new(Float::MAX)
		@game.blocking_effects[:falling].link_component = anim
		@game.blocking_effects[:falling].activate
		
		false
	end
	
	def can_push_rock?
		true
	end
	
	def on_push_rock(rock)
		rock.inactivate
		true
	end
end

class CompWater < Component
	def initialize(game,x,y)
		super(game,x,y,"water")
		@color = Gosu::Color::BLUE
	end
	
	def can_player_walk?
		false
	end
	
	def can_mob_walk?
		false
	end
	
	def on_player_walk_fail
		@game.player.add_score(-2)
	end
end

class CompDoor < Component
	def initialize(game,x,y)
		super(game,x,y,"door")		
		@color = Gosu::Color::GREEN
	end 
	
	def can_player_walk?()
		@game.player.keys > 0
	end
	
	def on_player_walk
		inactivate
		@game.player.add_keys(-1)
		@game.player.add_score(1)
		@game.play("door")
		@game.give_hint(:door)
		true
	end
	
	def on_player_walk_fail
		@game.flash("To pass the Door you need a Key.")
	end
end

class CompWallInvis < CompWall
	def initialize(game,x,y)
		super	
		@visible = false
	end
	def visible?
		@visible
	end
	def on_player_walk_fail()
		@visible = true
	end	
	def support_against_gravity?
		@visible
	end	
end

class CompWeakWallInvisible < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@color = Gosu::Color.argb(0xff_A52A2A)
		@visible = false
	end

	def can_mob_walk?
		@visible
	end
	
	def visible?
		@visible
	end
	
	def on_player_walk_fail()		
		@visible = true
	end
	
	def on_whip
		super if @visible
	end
	
	def support_against_gravity?
		@visible
	end
end	

class CompTunnel < Component
	def initialize(game,x,y)
		super(game,x,y,"tunnel")
		@color = Gosu::Color::RED
		@pair = nil
	end
	
	def can_player_walk?
		false
	end
	
	def can_mob_walk?
		false
	end
		
	def on_player_walk_fail
		@game.components.select do |c| c.class == CompTunnel and not(c === self) end.shuffle.each do |exit|				
			KrozGame::DIRS.shuffle.each do |dir|		
				dx, dy = *dir
				c = @game.component_at(exit.x + dx, exit.y + dy)
				if not c or [CompStop,CompMob1,CompMob2,CompMob3].include? c.class
					@game.player.set_location(exit.x + dx, exit.y + dy)
					return
				end			
			end
		end 
	end
end

class CompEWall < Component
	def initialize(game,x,y)
		super(game,x,y,"wall")
		@color = Gosu::Color::YELLOW
	end
	
	def can_player_walk?
		false
	end
	
	def can_mob_walk?
		false
	end
	
	def can_push_rock?
		true
	end
	
	def on_player_walk_fail
		#shock!
		@game.player.add_score(@game.mission * -2)
		@game.player.add_gems(-1)
		@game.flash("You hit a Electrified Wall!  You lose one Gem.")
	end
	
	def on_push_rock(rock)
		inactivate
		rock.inactivate
	end
end

class CompDoorInvis < CompDoor
	def initialize(game,x,y)
		super
		@visible = false
	end
	
	def visible?
		@visible
	end
	
	def can_player_walk?
		@visible and super
	end
	
	def on_player_walk_fail
		@visible = true
	end
end

###############################################################################
#  Spells and Special Tiles
###############################################################################

class CompAltar < Component
	def initialize(game,x,y)
		super(game,x,y,"altar")
	end
	
	def on_player_walk
		inactivate
		
		@game.play("spell")
		@game.flash("A Creature Zap Spell!")
		
		mobs = @game.components.select do |c|
			c.class.ancestors.include? CompMob and c.active
		end
		
		mobs.sample(40).each do |m|
			m.inactivate
		end
		
		true
	end
end

class CompBomb < Component
	def initialize(game,x,y)		
		super(game,x,y,"bomb")
		@color = Gosu::Color::YELLOW
		chance_to_obscure(40)	
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		inactivate
		explode
	end
	
	def can_mob_walk?
		false
	end
	
	def explode
		(-4...4).each do |x|
			(-4...4).each do |y|				
				c = @game.component_at(@x + x, @y + y)
				c.on_bomb if c
			end
		end
	end 
end

class CompFreezeSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"freeze")
		@color = Gosu::Color::CYAN
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		@game.flash("You have activated a Freeze Creature spell!")
		@game.play("spell")
		@game.player.add_score(1)
		inactivate		
		@game.effects[:freeze_monster].activate
		true
	end
end

class CompSlowSpell < Component
	def initialize(game,x,y)		
		super(game,x,y,"slow")	
		@color = Gosu::Color::CYAN
		chance_to_obscure(35)		
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		@game.flash("You activated a Slow Creature spell.")
		@game.play("spell")
		inactivate
		@game.effects[:slow_monster].activate
		true
	end
end

class CompFastSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"fast")
		@color = Gosu::Color::CYAN
		chance_to_obscure(10)		
	end
	
	def can_player_walk?
		true
	end
	
	def on_whip
		inactivate
	end
	
	def on_player_walk
		super
		@game.player.add_score(2)
		@game.flash("You activated a Speed Creature spell.")		
		@game.play("spell")
		@game.effects[:speed_monster].activate
		true
	end
end

class CompSpellShowGems < Component
	def initialize(game,x,y)
		super(game,x,y,"trigger")
	end
	
	def visible?
		false
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		inactivate

		true
	end
	
	def on_player_walk_after
		@game.place_multiple(120, CompGem, true)
		@game.play("pouch")		
		@game.flash("Yah Hoo! You discovered a Reveal Gems Scroll!")
	end
end

class CompShoot < Component
	def initialize(game,x,y,dir)
		if dir == :left
			@dx = -1
			name = "shootleft"
		elsif dir == :right
			@dx = 1
			name = "shootright"
		else
			raise "bad direction #{dir}"
		end
		super(game,x,y,name)
		@color = Gosu::Color::RED		
	end 
	
	def can_player_walk?
		true
	end
	
	def on_player_walk()
		super
		@game.play("arrow_loose")
		@game.give_hint(:arrow)
		anim = CompArrowAnimation.new(@game, x + @dx, y, @dx)
		@game.add_component(anim)
		@game.blocking_effects[:arrow] = Effect.new(Float::MAX)
		@game.blocking_effects[:arrow].link_component = anim
		@game.blocking_effects[:arrow].activate
		true
	end
end	

class CompRope < Component
	def initialize(game,x,y)
		super(game,x,y,"rope")
		@color = Gosu::Color::YELLOW
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		inactivate
		true
	end
	
	def can_mob_walk?
		false
	end
	
	def on_player_walk_after
		@game.player.rope_under = true
	end
	
	def support_against_gravity?
		true
	end
end

class CompDropRope < Component
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"drop_rope")
		@code = code
		@color = Gosu::Color::YELLOW
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk			
		inactivate
		
		true
	end
	
	def on_player_walk_after
		@pair = @game.components.select do |c| c.class == CompDropRope and c.code == @code and c.active and c != self end.first		
		raise "unable to find pair" unless @pair
		@pair.drop
	end
	
	def drop
		inactivate
		x = @x
		y = @y + 1 # look ahead because we don't want to add a rope at the bottom
		while true
			c = @game.component_at(x,y)			
			break if c and c.stops_rope_drop?
			c.inactivate if c
			@game.add_component(CompRope.new(@game,x,y - 1))
			y = y + 1
		end		
	end
end

class CompLava < Component
	def initialize(game,x,y)
		super(game,x,y,"lava")
		@color = Gosu::Color::RED		
	end
	
	def update(dt)				
	end
		
	def can_player_walk?
		true
	end
	
	def on_bomb
		# inactivate
	end
	
	def on_whip
		# inactivate
	end
	
	def on_player_walk
		inactivate
		@game.player.add_score(25)
		@game.player.add_gems(-10)
		true
	end
	
	def can_lava_spread?
		false
	end
end

###############################################################################
#  Enemies
###############################################################################

class CompMob < Component
	def initialize(game,x,y,name,power)
		super(game,x,y,name)
		@state = :awake
		@power = power
		@speed = (4 - power)
		@next_tick = @speed
	end	
	
	def tick()
		@next_tick -= 1
		return unless @next_tick == 0		
		
		
		px, py = @game.player.x, @game.player.y
		tx, ty = @x, @y
		
		if px > @x and py > @y
			tx, ty = @x + 1, @y + 1  # up-right
		elsif px > @x and py < @y
			tx, ty = @x + 1, @y - 1  # down-right
		elsif px < @x and py > @y
			tx, ty = @x - 1, @y + 1  # up-left
		elsif px < @x and py < @y
			tx, ty = @x - 1, @y - 1  # down-left
		elsif px > @x
			tx = @x + 1
		elsif px < @x
			tx = @x - 1
		elsif py > @y
			ty = @y + 1
		elsif py < @y
			ty = @y - 1
		end 
		
		if @game.effects[:gravity]
			ty = @y # clear y differences
			if not @game.location_supported?(tx,ty)
				tx = @x # clear x difference, only walk on solid ground
			end
		end
		
		if @x != tx or @y != ty
			c = @game.component_at(tx, ty)
			if not c or c.can_mob_walk?				
				inactivate if c and c.on_mob_walk()
				move(tx,ty) if @active				
			end
		end
		
		@next_tick = @speed if @active
	end
	
	def can_player_walk?
		true
	end
	
	def can_lava_spread?
		true
	end
	
	def can_tree_spread?
		true
	end
	
	def on_bomb()
		inactivate
	end
	
	def on_whip()
		inactivate
	end
	
	def inactivate
		super
		@game.player.add_score(@power)
	end
	
	def on_player_walk()	
		inactivate
		@game.player.add_gems(-@power)		
		true
	end
	
	def can_mob_walk?()
		false
	end 
	
	def on_arrow_hit()
		inactivate
		false
	end
	
	def can_push_rock?
		true
	end
	
end

class CompMob1 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob1",1)
		@color = Gosu::Color::RED
	end
	
	def inactivate
		super
		@game.play("squish1")
	end
end

class CompMob2 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob2",2)
		@color = Gosu::Color::GREEN
	end
	
	def inactivate
		super
		@game.play("squish2")
	end	
end

class CompMob3 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob3",3)
		@color = Gosu::Color::CYAN
	end
	
	def inactivate
		super
		@game.play("squish3")
	end
end

class CompGenerator < Component
	def initialize(game,x,y)
		super(game,x,y,"generator")
		@color = Gosu::Color::YELLOW
		@game.effects[self] = Effect.new(3.0)
	end
	
	def update(dt)
		if not @game.effects[self].active?
			spawn_mob
			@game.effects[self].activate
		end
	end
	
	def spawn_mob	
		while true
			pos = @game.random_board_location	
			c = @game.component_at(pos.first, pos.last)
			if not c then # any others?
				@game.add_component(CompMob1.new(@game, pos.first, pos.last))
				return
			end
		end
	end
	
	def can_mob_walk?
		false
	end
	
	def can_player_walk?
		false
	end
	
	def on_whip
		@game.effects[self].clear
		@game.effects.delete(self)
		@game.player.add_score(50)
		inactivate
	end
end

class CompStatue < Component
	def initialize(game,x,y)
		super(game,x,y,"statue")
		@color = Gosu::Color::YELLOW
		@game.effects[self] = Effect.new(2.0)
	end
	
	def update(dt)
		if not @game.effects[self].active?
			deal_damage
			@game.effects[self].activate
		end
	end
	
	def on_whip
		if rand(50) > @game.player.whip_power
			inactivate 
			@game.player.add_score(10)
			@game.flash("You've destroyed the Statue!  Your Gems are now safe.")
		end
	end
	
	def deal_damage
		@game.player.add_gems(-1)
	end
end

#mblock #magic block
class CompMovingBlock < CompWeakWall
	def initialize(game,x,y,visible)
		super(game,x,y)
		@visible = visible
		@game.effects[self] = Effect.new(1.0) do |e|
			move_block
			e.activate
		end
	end
	
	def wake_up	
		@visible = true #?
		@game.effects[self].activate
	end
	
	def visible?
		@visible
	end
	
	def on_whip
		if (rand(7)) < @game.player.whip_power
			inactivate		
			@game.player.add_score(1)
		end
	end
	
	def move_block
		px, py = @game.player.x, @game.player.y
		tx, ty = @x, @y
		
		if px > @x and py > @y
			tx, ty = @x + 1, @y + 1  # up-right
		elsif px > @x and py < @y
			tx, ty = @x + 1, @y - 1  # down-right
		elsif px < @x and py > @y
			tx, ty = @x - 1, @y + 1  # up-left
		elsif px < @x and py < @y
			tx, ty = @x - 1, @y - 1  # down-left
		elsif px > @x
			tx = @x + 1
		elsif px < @x
			tx = @x - 1
		elsif py > @y
			ty = @y + 1
		elsif py < @y
			ty = @y - 1
		end 
	
		if @x != tx or @y != ty
			c = @game.component_at(tx, ty)
			if not c			
				# inactivate if c and c.on_mob_walk()
				move(tx,ty) if @active				
			end
		end		
	end
end

###############################################################################
#  Traps and Triggers
###############################################################################

class CompTypeTrap < Component
	def initialize(game,x,y,name)
		super(game,x,y,name)
	end
	
	def can_player_walk?
		true
	end
	
	def can_mob_walk?
		true
	end
	
	def visible?
		false
	end
	
	def on_whip()
		inactivate
	end	
end

# mobs can't walk on these until the player steps on any one of them
class CompTrapCage < CompTypeTrap
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"trigger")
		@code = code
	end
		
	def can_mob_walk?
		false
	end
	
	def on_whip
	end
	
	def on_player_walk
		@game.components.select do |c| c.class == CompTrapCage and c.code == @code end.each do |c|
			c.inactivate
		end
	end
end
	
# send the player to a random location
class CompTrapTeleport < CompTypeTrap
	def initialize(game,x,y)
		super(game,x,y,"trap_teleport")
		@color = Gosu::Color::GREEN
	end 
	
	def visible?
		true
	end
	
	def can_push_rock?
		true
	end

	def can_player_walk?
		true
	end
	
	def on_player_walk
		super
		@game.flash "Teleport Trap!"		
		@game.teleport_player
		@game.play("spell")
		@game.player.add_score(-5)
		false
	end
end	

# surround the square with the specified items, only on empty spaces
class CompTrapSurround < CompTypeTrap
	def initialize(game, x, y, comp)
		super(game,x,y,"trap") # invis
		@color = Gosu::Color::WHITE
		@comp = comp
	end
		
	def place_comp(x,y)
		c = @game.component_at(x,y)
		c.active = false if c and [CompStop].include? c.class		
		return if c and c.active
		@game.add_component(@comp.new(@game, x,y))
	end
	
	def on_player_walk
		super
	end
	
	def on_player_walk_after
		@game.play("trap") # if bad... play $ if good
		KrozGame::DIRS.each do |d|
			place_comp(@x + d.first, @y + d.last)
		end		
	end
end

# an invis block where a wall might appear if a trigger is hit
class CompTriggerInvisBlock < Component
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"trigger")
		@code = code
	end
	
	def can_player_walk?
		true
	end
	
	def visible?
		false
	end
end

# make some random tiles vanish
class CompWallVanishTrap < Component
	def initialize(game,x,y)
		super(game,x,y,"trigger")
		chance_to_obscure(20)
	end
	
	def visible?
		false
	end
	
	def can_player_walk?
		true
	end
	
	def on_player_walk
		super
		75.times do
			pos = @game.random_board_location
			c = @game.component_at(pos.first,pos.last)
			
			if c.class == CompWall
				c.inactivate
				@game.add_component(CompWallInvis.new(@game,pos.first,pos.last))
			elsif c.class == CompWeakWall
				c.inactivate
				@game.add_component(CompWeakWallInvisible.new(@game,pos.first,pos.last))
			end
		end
	end
end

# a wall that might go away if a trigger is hit
class CompTriggerWallBlock < CompWall
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y)
		@code = code
	end
	
	def support_against_gravity?
		true
	end
end

# a weak wall that might go away if a trigger is hit
class CompTriggerWeakWallBlock < CompWeakWall
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y)
		@code = code
	end	

	def support_against_gravity?
		true
	end
end

# when stepped on, inactivate all comptriggers that have the same 'code', then possibly replace with something else 
class CompTriggerTrap < Component
	def initialize(game,x,y,code,replacement,visible = false)
		super(game,x,y,"altar")
		@code = code
		@replacement = replacement
		@visible = visible
	end
	
	def can_player_walk?
		true
	end
	
	def visible?
		@visible
	end
	
	def on_player_walk
		inactivate
		true
	end 
	
	def on_whip
		@visible = true
	end
	
	def on_player_walk_after
		@game.components.select do |c| c.class != CompTriggerTrap and c.class.to_s.start_with? "CompTrigger" and c.code == @code end.each do |c|
			c.inactivate
			@game.add_component(@replacement.new(@game,c.x,c.y)) if @replacement
			@game.flash("You triggered Exploding Walls!") if @code == "O"
		end
	end
end

# an open space where a wall will appear if a trigger is hit
class CompTriggerWall < Component
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"altar",:trigger)
		@code = code
	end
	
	def visible?
		false
	end
end

class CompQuakeTrap < Component
	def initialize(game,x,y)
		super(game,x,y,"quake")
		@color = Gosu::Color::YELLOW
		chance_to_obscure(15)
	end
	
	def can_player_walk?
		true
	end
	
	def visible?
		false
	end
	
	def on_player_walk
		inactivate
		@game.flash("Oh no, you set off an Earthquake trap!")
		
		true
	end
	
	def on_player_walk_after
		@game.place_multiple(50, CompRock)
	end
end	

# monster trap, spawn a bunch of slow monsters
class CompTrapMonsterCreate < Component
	def initialize(game,x,y,visible)
		super(game,x,y,"trap_monster_create")
		@visible = visible
	end
	
	def visible?
		@visible
	end
	
		def can_player_walk?
		true
	end
	
	def on_player_walk
		inactivate
		true
	end
	
	def on_player_walk_after
		@game.player.add_score(@game.mission * 2)	
		
		if @game.effects[:gravity]
			if @game.player.gems >= 13
				@game.flash(["3 gems float away","3 gems disolve before your eyes"].sample(1))
				@game.player.add_gems(-3)
			else
				@game.flash("you find nothing here")
			end
		else		
			@game.flash("you set off a create monster trap")
			
			@game.place_multiple(120, CompMob1)	
		end
	end
end

class CompMovingBlockTrap < Component
	def initialize(game,x,y)
		super(game,x,y,"")
	end 
	
	def visible?
		false
	end
		
	def on_player_walk
		@game.components.select do |c| c.class == CompMovingBlockTrap end.each do |c|
			c.inactivate
		end
		@game.components.select do |c| c.class == CompMovingBlock end.each do |c|
			c.wake_up
		end		
	end
end