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
	end
		
	def on_player_walk_fail()
	end
	
	def can_player_walk?()
		true
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
	
	def on_whip() # str is 1-7		
	end
	
	def blocking_animation?
		false
	end
	
	def to_s
		[@name, @active].join(",")
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
	end
	
	def whip_power
		2 + @rings
	end
	
	def update(dx)
	end
	
	def set_location(px,py)		
		return if @x == px and @y == py
		c = @game.components_at(px, py)		
		c.on_player_walk() if c	
		@x = px
		@y = py
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
		@active = false
		@game.player.add_score(10)
		@game.effects[:invisible_player].activate
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
			cs = @game.components_at(tx, ty)
			# if cs.size > 1
				# puts cs
				# puts "#{x},#{y}"
			# end
			# raise 'multiple comps' if cs.size > 1
			if not cs or cs.can_mob_walk?
				@x, @y = tx, ty
				if cs
					@active = false if cs.on_mob_walk()					 
				end
			end
		end
		
		@next_tick = @speed if @active
	end
	
	def on_whip()
		@active = false
		@game.player.add_score(@power)
	end
	
	def on_player_walk()
		@active = false
		@game.player.add_gems(-1)
		@game.player.add_score(@power)
	end
	
	def can_mob_walk?()
		false
	end 
	
	def on_arrow_hit()
		@active = false
		false
	end
	
end

class CompMob1 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob1",1)
		@color = Gosu::Color::WHITE
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
		@color = Gosu::Color::YELLOW
	end
end

class CompWhip < Component
	def initialize(game,x,y)
		super(game,x,y,"whip")
		@color = Gosu::Color::YELLOW
	end 
	
	def on_player_walk()
		@active = false
		@game.player.add_whips(1)
		@game.player.add_score(1)
	end
	
	def on_mob_walk()
		@active = false
		false
	end 
	
	def on_whip()
		@active = false		
	end		
end	

class CompWhipAnimation < Component
	WHIP_TIME = 0.03
	def initialize(game,x,y,:anim)
		super(game,x,y,"whip")
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
				@active = false
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
		@active = false
	end
	
	def on_whip
		@active = false
	end
end

class CompChest < Component
	def initialize(game,x,y)
		super(game,x,y,"chest")
		#@color = Gosu::Color.argb(0xff_A52A2A)
		@color = Gosu::Color::YELLOW
	end
	
	def on_player_walk()		
		@active = false
		g = 3 + rand(3) * 2
		w = 1 + rand(3)
		@game.player.add_gems(g)
		@game.player.add_whips(w)
		@game.player.add_score(5)
		@game.flash("you found #{g} gems and #{w} whips!")
	end
	
	def on_mob_walk()
		@active = false
		false
	end 
	
	def on_arrow_hit()
		@active = false
		false
	end

end	

class CompGem < Component
	def initialize(game,x,y)
		super(game,x,y,"gem")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk()		
		@active = false
		@game.player.add_gems(1)
		@game.player.add_score(1)
	end

	def on_mob_walk()
		@active = false
		false
	end 
	
	def on_arrow_hit()
		@active = false
		false
	end
end	

class CompKey < Component
	def initialize(game,x,y)
		super(game,x,y,"key")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk()		
		@active = false
		@game.player.add_keys(1)
		@game.player.add_score(1)
	end

	def on_mob_walk()
		@active = false
		false
	end 
	
	def on_arrow_hit()
		@active = false
		false
	end
end	

class CompTrapTeleport < Component
	def initialize(game,x,y)
		super(game,x,y,"trap1")
		@color = Gosu::Color::RED
	end 
	
	def on_whip()
		@active = false
	end
	
	def on_player_walk
		@active = false
		@game.teleport_player
		@game.player.add_score(-5)
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
		c = @game.components_at(x,y)
		c.active = false if c and [CompStop].include? c.class
		raise "something already there #{c.class.to_s}" if c and c.active		
		@game.add_component(CompWeakWall.new(@game, x,y))
	end
	
	def on_player_walk
		mission_num = 
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
					else
						raise KrozGame::MISSIONS[@game.episode][@game.mission].to_s
					
				end
			else
				raise @game.episode.to_s
		end
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

class CompTablet < Component
# procedure Tablet_Message(Level: integer);
 # begin
  # case Level of
   # 1: Flash(5,25,'Once again you uncover the hidden tunnel leading to Kroz!');
   # 2: Flash(7,25,'Warning to all Adventurers:  No one returns from Kroz!');
   # 4: Flash(8,25,'Adventurer, try the top right corner if you desire.');
   # 6: Flash(6,25,'A strange magical gravity force is tugging you downward!');
   # 8,24: Flash(12,25,'You have choosen the greedy path Adventurer!');
   # 9: Flash(3,25,'A magical forest grows out of control in this region of Kroz!');
   # 10:Flash(9,25,'Sometimes, Adventurer, Gems can be crystal clear.');
   # 12:Flash(11,25,'The lava will block a slow Adventurer''s path!');
   # 14:Flash(9,25,'Follow the sequence if you wish to be successful.');
   # 18:begin
       # Prayer;
       # Flash(4,25,'"Barriers of water, like barriers in life, can always be..."');
       # bak(0,0);
       # for x := XBot to XTop do
        # for y := YBot to YTop do
         # if PF[x,y] = 17 then
          # begin
           # sound(x*y);
           # PF[x,y] := 43;
           # gotoxy(x,y);
           # col(6,7);
           # write(Block);
           # delay(4);
          # end; nosound; 
       # Flash(26,25,'"...Overcome!"');
      # end;
   # 20:Flash(16,25,'These walls will seek to entrap you!');
   # 22:begin
       # Prayer;
       # Flash(6,25,'"If goodness is in my heart, that which flows shall..."');
       # bak(0,0);
       # for x := XBot to XTop do
        # for y := YBot to YTop do
         # if PF[x,y] = 17 then
          # begin
           # sound(x*y);
           # PF[x,y] := 27;
           # gotoxy(x,y);
           # col(14,7);
           # write(Nugget);
           # delay(1);
          # end; nosound;
       # Flash(25,25,'"...Turn to Gold!"');
      # end;
  # end;
 # end; { Tablet_Message }
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
		@active = false
		true
	end

	def on_whip()
		# raise 'invalid str' unless (1..7).include? str		
		@active = false if (rand(7)) < @game.player.whip_power
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
		@pair = @game.components.select do |c| c.class == CompTunnel and not(c === self) end.first if @pair == nil
		raise 'unable to find partner tunnel' unless @pair
		while true			
			dx, dy = *KrozGame::DIRS.sample
			if not @game.components_at(@pair.x + dx, @pair.y + dy)
				@game.player.set_location(@pair.x + dx, @pair.y + dy)
				break
			end
		end
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
		
	end
end	

class CompDoor < Component
	def initialize(game,x,y)
		super(game,x,y,"door")
		@color = Gosu::Color.argb(0xff_A52A2A)
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
		@active = false
		@game.player.add_teleports(1)
	end
	
	def on_mob_walk
		@active = false
		false
	end
end	

class CompShootRight < Component
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED
	end 
	
	def on_player_walk()
		@active = false
		@game.add_component(CompShootRightAnimation.new(@game, x + 1, y))
	end
end	

class CompShootLeft < Component
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED
	end 
	
	def on_player_walk()
		@active = false
		@game.add_component(CompShootLeftAnimation.new(@game, x - 1, y))
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
			if (c = @game.components_at(@x+@dx,@y)) then
				if c.on_arrow_hit() then
					@active = false
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
	def initialize(game,x,y,:anim)
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
		@active = false
		@game.effects[:freeze_monster].activate
	end
end

class CompSlowSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"slow")
		@color = Gosu::Color::CYAN
	end
	
	def on_player_walk
		@game.flash("Monsters are moving slower. Go now!")
		@active = false
		@game.effects[:slow_monster].activate
	end
end

class CompFastSpell < Component
	def initialize(game,x,y)
		super(game,x,y,"fast")
		@color = Gosu::Color::CYAN
	end
	
	def on_player_walk
		@game.flash("Monsters begin to move more quickly")
		@active = false
		@game.effects[:speed_monster].activate
	end
end

class CompRing < Component
	def initialize(game,x,y)
		super(game,x,y,"ring")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk
		@active = false
		@game.player.add_rings(1)
		@game.player.add_score(15)
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