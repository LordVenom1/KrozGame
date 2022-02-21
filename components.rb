class Component
	attr_accessor :x, :y, :active, :layer
	attr_reader :name # for debugging
	def initialize(game, x = nil,y = nil, name = "", layer = :space)
		@game = game
		@x,@y = x,y		
		@name = name
		@color = Gosu::Color::WHITE
		@active = true		
		@layer = layer
		@game.place_on_board(self,x,y) if layer == :space
	end
	
	def inactivate
		@active = false
		@game.remove_from_board(self, @x, @y) if @layer == :space
	end
	
	def move(ax,ay)	
		c = @game.component_at(ax,ay)
		raise "#{c} is already at #{ax},#{ay}" if c
		
		@game.move_on_board(self, @x, @y, ax, ay)
		@x,@y = ax,ay
		
	end
	
	def visible?
		true
	end
	
	def update(dx)		
	end
	
	def tick()
	end
	
	def sprite_name()
		@name
	end
	
	def color()
		@color
	end
		
	def on_player_walk()
		true
	end
		
	def on_player_walk_fail()
	end
	
	def on_player_walk_after()
	end
	
	def can_player_walk?()
		true
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
		# inactivate
	end
	
	def on_whip() # str is 1-7		
	end
	
	def blocking_animation?
		false
	end
	
	def to_s
		[self.class.to_s, @name, @active].join(",")
	end
end

class CompPlayer < Component

	attr_reader :score, :gems, :whips, :teleports, :keys, :rings
	attr_reader :state

	def initialize(game,x,y)
		super(game,x,y,"player")
		@color = Gosu::Color::YELLOW
		
		@score = 0	
		@gems = 20
		
		@whips = 10
		
		@teleports = 0
		@keys = 0
		@rings = 0
		@state = :alive
		
		# for debugging
		@gems = 999
		@whips = 999
		@teleports = 999
		
		@rope = false
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
	
	def update(dx)
	end
	
	# used to change the player's location outside the normal game
	def set_location(px,py)		
		# return if @x == px and @y == py
		# c = @game.component_at(px, py)		
		# still_move = c ? c.on_player_walk() : true		
		# move(px,py) if still_move
		# c.on_player_walk_after if still_move and c
		@game.player_move(px,py)
	end
	
	def visible?
		!@game.effects[:invisible_player].active?		
	end
	
	def add_score(s)
		@score += s
		s = 0 if s < 0
	end
	
	def add_gems(cnt)
		@gems += cnt
		@score = cnt * 10 if cnt > 0
		raise 'game over' if @gems < 0
	end
	
	def add_whips(cnt)
		@whips += cnt
		# @score += cnt * 5
	end
	
	def add_rings(cnt)
		@rings += 1
	end
	
	def add_keys(cnt)
		@keys += 1
	end
	
	def add_teleports(cnt)
		@teleports += cnt
	end
	
	def on_mob_walk()
		add_gems(-1)
		true
	end 

		
end

class CompInvisibility < Component
	def initialize(game,x,y)
		super(game,x,y,"invis")
	end
	
	def on_player_walk		
		inactivate()
		@game.flash("You have been cursed with invisibility.  Enemies can still see you!")
		@game.player.add_score(10)
		@game.effects[:invisible_player].activate
		true
	end
end

class CompBorder < Component
	def initialize(game,x,y)
		super(game,x,y,"border")
		@color = Gosu::Color::YELLOW
	end
	
	def update(dx)
	end
	
	def sprite_name
		@name
	end
	
	def can_player_walk?()
		false
	end
	
	def on_player_walk_fail()
		# subtract score, 
		# play noise
		@game.player.add_score(-20)
		@game.flash("An Electrified Wall blocks your way.")
	end
	
	def can_mob_walk?()
		false
	end 
	
end

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
		
		if @x != tx or @y != ty
			c = @game.component_at(tx, ty)
			if not c or c.can_mob_walk?				
				inactivate if c and c.on_mob_walk()
				move(tx,ty) if @active				
			end
		end
		
		@next_tick = @speed if @active
	end
	
	def on_bomb()
		inactivate
	end
	
	def on_whip()
		inactivate
		@game.player.add_score(@power)
	end
	
	def on_player_walk()
		inactivate
		@game.player.add_gems(-@power)
		@game.player.add_score(@power)
		true
	end
	
	def can_mob_walk?()
		false
	end 
	
	def on_arrow_hit()
		inactivate
		false
	end
	
end

class CompMob1 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob1",1)
		@color = Gosu::Color::RED
	end
end

class CompMob2 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob2",2)
		@color = Gosu::Color::GREEN
	end
end

class CompMob3 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob3",3)
		@color = Gosu::Color::CYAN
	end
end

class CompWhip < Component
	def initialize(game,x,y)
		super(game,x,y,"whip")
		@color = Gosu::Color::YELLOW
	end 
	
	def on_player_walk()
		inactivate
		@game.player.add_whips(1)
		@game.player.add_score(1)
		true
	end
	
	def on_mob_walk()
		inactivate
		false
	end 
	
	def on_whip()
		inactivate	
	end		
end	

class CompWhipAnimation < Component
	WHIP_TIME = 0.02
	def initialize(game,x,y)
		super(game,x,y,"whip",:anim)
		@color = Gosu::Color::RED
		@duration = WHIP_TIME
		@rx, @ry = x,y
		@n = 0
	end
	
	def update(dx)
	
		@duration -= dx
		if @duration <= 0.0
			@n += 1
			@duration += WHIP_TIME
			if @n == KrozGame::DIRS.size
				inactivate
				@n = 0
			end
		end
	end	
	
	def x
		@rx + KrozGame::DIRS[@n].first
	end
		
	def y
		@ry + KrozGame::DIRS[@n].last
	end
	
	def blocking_animation?
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
	
	def on_player_walk
		inactivate
		true
	end
	
	def on_whip
		inactivate
	end
end

class CompChest < Component
	def initialize(game,x,y)
		super(game,x,y,"chest")
		#@color = Gosu::Color.argb(0xff_A52A2A)
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk()		
		inactivate
		g = 3 + rand(3) * 2
		w = 1 + rand(3)
		@game.player.add_gems(g)
		@game.player.add_whips(w)
		@game.player.add_score(5)
		@game.flash("you found #{g} gems and #{w} whips!")
		true
	end
	
	def on_mob_walk()
		inactivate
		false
	end 
	
	def on_arrow_hit()
		inactivate
		false
	end

end	

class CompGem < Component
	def initialize(game,x,y)
		super(game,x,y,"gem")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk()		
		inactivate
		@game.player.add_gems(1)
		@game.player.add_score(1)
		true
	end

	def on_mob_walk()
		inactivate
		false
	end 
	
	def on_arrow_hit()
		inactivate
		false
	end
end	

class CompKey < Component
	def initialize(game,x,y)
		super(game,x,y,"key")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk()		
		inactivate
		@game.player.add_keys(1)
		@game.player.add_score(1)
		true
	end

	def on_mob_walk()
		inactivate
		false
	end 
	
	def on_arrow_hit()
		inactivate
		false
	end
end	

class CompTrapTeleport < Component
	def initialize(game,x,y)
		super(game,x,y,"trap_teleport")
		@color = Gosu::Color::GREEN
	end 
	
	def can_push_rock?
		true
	end
	
	def on_whip()
		inactivate
	end
	
	def on_player_walk
		@game.flash "Teleport Trap!"
		inactivate
		@game.teleport_player
		@game.player.add_score(-5)
		false
	end
end	

class CompTrapBlock < Component
	def initialize(game, x, y)
		super(game,x,y,"trap1") # invis
		@color = Gosu::Color::WHITE
	end
	
	def visible?
		false
	end
	
	def place_weak_wall(x,y)
		c = @game.component_at(x,y)
		c.active = false if c and [CompStop].include? c.class
		raise "something already there #{c.class.to_s}" if c and c.active		
		@game.add_component(CompWeakWall.new(@game, x,y))
	end
	
	def on_player_walk
		inactivate		
		true
	end
	
	def on_player_walk_after
		case @game.episode 
			when :kingdom
				case @game.mission
					when 2
						place_weak_wall(7,3)
					when 4
						place_weak_wall(53,14)
						place_weak_wall(54,14)
						place_weak_wall(54,16)
						place_weak_wall(55,16) 
					when 8
						# wut
						place_weak_wall(10,55)
						place_weak_wall(10,56)
						place_weak_wall(11,56)
					else
						raise KrozGame::MISSIONS[@game.episode][@game.mission].to_s
					
				end
			else
				raise @game.episode.to_s
		end
	end
end

class CompTrapRock < Component
	def initialize(game, x, y)
		super(game,x,y,"trap1") # invis
		@color = Gosu::Color::WHITE
	end
	
	def visible?
		false
	end
		
	def place_rock(x,y)
		c = @game.component_at(x,y)
		c.active = false if c and [CompStop].include? c.class
		raise "something already there #{c.class.to_s}" if c and c.active		
		@game.add_component(CompRock.new(@game, x,y))
	end
	
	def on_player_walk
		inactivate				
		true
	end
	
	def on_player_walk_after
		case @game.episode 
			when :kingdom
				case @game.mission
					when 2						
						place_rock(2,1)
						place_rock(2,2)
						place_rock(1,2)
					when 8
						place_rock(17,57)
					else
						raise KrozGame::MISSIONS[@game.episode][@game.mission].to_s
					
				end
			else
				raise @game.episode.to_s
		end
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
	
	def on_player_walk
		# try to move boulder in same direction as player before player is allowed to move
		v = [@x - @game.player.x, @y - @game.player.y]
		nx = @x + (@x - @game.player.x)
		ny = @y + (@y - @game.player.y)
		c = @game.component_at(nx,ny)
		if (c and c.can_push_rock?) or not c
			c.on_push_rock(self) if c
			move(@x + v.first, @y + v.last) # check if it can be pushed first...			
			true
		else
			false
		end
	end
	
	def on_player_walk_after
	end
	
	def on_whip
		inactivate if (rand(50)) < @game.player.whip_power
	end
end


class CompWall < Component
	def initialize(game,x,y)
		super(game,x,y,"wall1")
		@color = Gosu::Color::GRAY
	end 
	
	def can_player_walk?()
		false
	end
	
		
	def can_mob_walk?()
		false
	end 

	def on_arrow_hit()
		true # stop the arrow
	end
end	

class CompGenerator < Component
	def initialize(game,x,y)
		super(game,x,y,"generator")
		@color = Gosu::Color::YELLOW
		@game.effects[self] = Effect.new(3.0)
	end
	
	def update(dx)
		if not @game.effects[self].active?
			spawn_mob
			@game.effects[self].activate
		end
	end
	
	def spawn_mob
		KrozGame::DIRS.shuffle.each do |dir|
			c = @game.component_at(@x + dir.first, @y + dir.last)
			if not c or c.can_mob_walk? then
				@game.add_component(CompMob1.new(@game,@x + dir.first, @y + dir.last))
				return
			end
		end
		# do nothing, generator is completely surrounded.
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

class CompTablet < Component
	def initialize(game,x,y)
		super(game,x,y,"tablet")
		@color = Gosu::Color::YELLOW
	end
		
	def on_player_walk
		inactivate
		case @game.episode 
			when :kingdom
				case @game.mission
					when 8
						@game.flash("You have choosen the greedy path Adventurer!")
					when 4
						place_weak_wall(53,14)
						place_weak_wall(54,14)
						place_weak_wall(54,16)
						place_weak_wall(55,16) 
					else
						raise KrozGame::MISSIONS[@game.episode][@game.mission].to_s
					
				end
			else
				raise @game.episode.to_s
		end
	end
end

class CompWeakWall < Component
	WALL_RESIST = 4
	def initialize(game,x,y)
		super(game,x,y,"wall1")
		@color = Gosu::Color.argb(0xff_A52A2A)
	end 
	
	def can_player_walk?()
		false
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
end	

class CompWeakWallInvisible < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@color = Gosu::Color.argb(0xff_A52A2A)
		@visible = false
	end 
	
	def visible?
		@visible
	end
	
	def on_player_walk_fail()
		@visible = true
	end
end	

class CompTree < CompWeakWall
	def initialize(game,x,y)
		super(game,x,y)
		@name = "tree"
		# @color = Gosu::Color::GREEN
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
		
	def on_player_walk_fail
		@exit = @game.components.select do |c| c.class == CompTunnel and not(c === self) end.select(1)
		
		raise 'unable to find outgoing tunnel' unless @exit
		
		KrozGame::DIRS.shuffle.each do |dir|		
			dx, dy = *dir
			if not @game.component_at(@pair.x + dx, @pair.y + dy)
				@game.player.set_location(@pair.x + dx, @pair.y + dy)
				break
			end
		end
		
		raise "outgoing tunnel is blocked..." # do we care or just skip the jump?
		false
		# find other tunnel...
	end
end

class CompUnknown < Component
	def initialize(game,x,y)
		super(game,x,y,"unknown",:trigger)
		@color = Gosu::Color::YELLOW
	end 
end	

class CompExit < Component
	def initialize(game,x,y)
		super(game,x,y,"exit")
		@color = Gosu::Color::GREEN
	end 
	
	def on_player_walk()
		# change level...
		# reset flags...
		@game.player.add_score(6)
		
		@game.next_level()
		false
	end
end

class CompNugget < Component
	def initialize(game,x,y)
		super(game,x,y,"nugget")
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk
		inactivate
		@game.player.add_score(10)
	end
	
	def on_mob_walk
		inactivate
	end
end

# an invis block where a wall might appear if a trigger is hit
class CompTriggerInvisBlock < Component
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"trigger",:trigger)
		@code = code
	end
	
	def visible?
		false
	end
end

# a wall that might go away if a trigger is hit
class CompTriggerWallBlock < CompWall
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y)
		@code = code
	end
end

# a weak wall that might go away if a trigger is hit
class CompTriggerWeakWallBlock < CompWeakWall
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y)
		@code = code
	end
end

# when stepped on, inactivate all comptriggers that have the same 'code', then possible 
class CompTriggerTrap < Component
	def initialize(game,x,y,code,replacement)
		super(game,x,y,:trigger)
		@code = code
		@replacement = replacement
	end
	
	def visible?
		false
	end
	
	def on_player_walk
		inactivate
		true
	end 
	
	def on_player_walk_after
		@game.components.select do |c| c.class != CompTriggerTrap and c.class.to_s.start_with? "CompTrigger" and c.code == @code end.each do |c|
			c.inactivate
			@game.add_component(@replacement.new(@game,c.x,c.y)) if @replacement
		end
	end
end

# an open space where a wall will appear if a trigger is hit
class CompTriggerWall < Component
	attr_reader :code
	def initialize(game,x,y,code)
		super(game,x,y,"trigger",:trigger)
		@code = code
	end
	
	def visible?
		false
	end
	
	# def on_player_walk
		# inactivate
	# end
end


class CompBomb < Component
	def initialize(game,x,y)
		super(game,x,y,"bomb")
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk
		inactivate
		explode
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
		@game.player.add_score(-20)
	end
end

class CompDoor < Component
	def initialize(game,x,y)
		super(game,x,y,"door")
		# @color = Gosu::Color.argb(0xff_A52A2A)
		@color = Gosu::Color::GREEN
	end 
	
	def can_player_walk?()
		
		false # player has keys...
	end
end	

class CompTeleport < Component
	def initialize(game,x,y)
		super(game,x,y,"teleport")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk
		inactivate
		@game.player.add_teleports(1)
		true
	end
	
	def on_mob_walk
		inactivate
		false
	end
end	

class CompShootRight < Component
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED
	end 
	
	def on_player_walk()
		inactivate
		@game.add_component(CompShootRightAnimation.new(@game, x + 1, y))
		true
	end
end	

class CompShootLeft < Component
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED
	end 
	
	def on_player_walk()
		inactivate
		@game.add_component(CompShootLeftAnimation.new(@game, x - 1, y))
		true
	end
end	

class CompShootRightAnimation < Component
	ARROW_TIME = 0.03
	def initialize(game,x,y)
		super(game,x,y,"shootright",:anim)
		@color = Gosu::Color::RED	
		@duration = ARROW_TIME
		@dx = 1
	end 
	
	def update(dx)
		@duration -= dx
		if @duration < 0.0
			if (c = @game.component_at(@x+@dx,@y)) then
				if c.on_arrow_hit() then
					inactivate
					return
				end
			else
				@x = @x + @dx
			end
			@duration += ARROW_TIME
		end
	end
	
	def blocking_animation?
		true
	end
end	

class CompShootLeftAnimation < CompShootRightAnimation	
	def initialize(game,x,y)
		super
		@name = "shootleft"	
		@dx = -1
	end 
end	

class CompFreezeSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"freeze")
		@color = Gosu::Color::CYAN
	end
	
	def on_player_walk
		@game.flash("Monsters have been frozen in place")
		inactivate
		@game.effects[:freeze_monster].activate
		true
	end
end

class CompSlowSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"slow")
		@color = Gosu::Color::CYAN
	end
	
	def on_player_walk
		@game.flash("Monsters are moving slower. Go now!")
		inactivate
		@game.effects[:slow_monster].activate
		true
	end
end

class CompFastSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"fast")
		@color = Gosu::Color::CYAN
	end
	
	def on_player_walk
		@game.flash("Monsters begin to move more quickly")
		inactivate
		@game.effects[:speed_monster].activate
		true
	end
end

class CompRing < Component
	def initialize(game,x,y)
		super(game,x,y,"ring")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk
		inactivate
		@game.player.add_rings(1)
		@game.player.add_score(15)
		true
	end
end	

class CompRope < Component
	def initialize(game,x,y)
		super(game,x,y,"rope")
		@color = Gosu::Color::YELLOW
		# do we just track ropes in a hash of coords, 
		# or do we allow players to step on ropes...
	end
	
	def on_player_walk
		inactivate
		true
	end
	
	def on_player_walk_after
		@game.player.rope_under = true
	end
end

class CompDropRope < Component
	def initialize(game,x,y)
		super(game,x,y,"rope")
		@color = Gosu::Color::YELLOW
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
end