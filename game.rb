require 'yaml'

class Component
	attr_accessor :x, :y, :active
	attr_reader :name # for debugging
	def initialize(game, x = nil,y = nil, name = "")		
		@game = game
		@x,@y = x,y
		@name = name
		@color = Gosu::Color::WHITE
		@active = true
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
	
	def on_whip(str) # str is 1-7		
	end
	
	def physical() # takes up that slot
		true
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
		@whips = 999 # debugging
		@teleports = 0
		@keys = 0
		@rings = 0
		@state = :alive		
	end
	
	def update(dx)
	end
	
	def sprite_name
		@name
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
	def initialize(game,x,y,name)
		super(game,x,y,name)
		@state = :awake
	end
	
	def tick()
		#monster AI
		
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
					cs.on_mob_walk() 
					@active = false
				end
			end
		end
	end
	
	def on_whip(str)
		@active = false
	end
	
	def on_player_walk()
		@active = false
		@game.player.add_gems(-1)
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
		super(game,x,y,"mob1")
		@color = Gosu::Color::WHITE
	end
	
	def on_whip(str)
		super
		@game.player.add_score(1)
	end
end

class CompMob2 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob2")
		@color = Gosu::Color::GREEN
	end
	
	def on_whip(str)
		super
		@game.player.add_score(1)
	end
end

class CompMob3 < CompMob
	def initialize(game,x,y)
		super(game,x,y,"mob3")
		@color = Gosu::Color::YELLOW
	end
	
	def on_whip(str)
		super
		@game.player.add_score(3)
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
	end
	
	def on_mob_walk()
		@active = false
	end 
	
	def on_whip(str)
		@active = false		
	end		
end	

class CompWhipAnimation < Component
	WHIP_TIME = 0.03
	def initialize(game,x,y)
		super(game,x,y,"whip")
		@color = Gosu::Color::RED			
		@duration = WHIP_TIME
	end
	
	def update(dx)		
		@duration -= dx
		@active = false if @duration <= 0.0
	end
	
	def physical
		false
	end
end

class CompChest < Component
	def initialize(game,x,y)
		super(game,x,y,"chest")
		@color = Gosu::Color.argb(0xff_A52A2A)
	end
	
	def on_player_walk()		
		@active = false
		@game.player.add_gems(3 + rand(3) * 2)
		@game.player.add_whips(1 + rand(3))
		@game.player.add_score(5)
	end
	
	def on_mob_walk()
		@active = false
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
	end 
	
	def on_arrow_hit()
		@active = false
		false
	end
end	

class CompTrap < Component
	def initialize(game,x,y)
		super(game,x,y,"trap1")
		@color = Gosu::Color::RED
	end 
	
	def on_whip(str)
		@active = false
	end
end	

class CompTrapBlock < Component
	def initialize(game, x, y)
		super(game,x,y,"trap1") # invis
		@color = Gosu::Color::WHITE
	end
	
	def on_player_walk
		# do it
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
	def initialize(game,x,y)
		super(game,x,y,"wall1")
		@color = Gosu::Color.argb(0xff_A52A2A)
	end 
	
	def can_player_walk?()
		false
	end

	def on_mob_walk()
		@active = false
	end

	def on_whip(str)
		raise 'invalid str' unless (1..7).include? str		
		@active = false if (rand(7)) < str
	end
end	

class CompUnknown < Component
	def initialize(game,x,y)
		super(game,x,y,"unknown")
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
		@game.add_score(6)
		
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
		@game.player.add_teleports(1)
	end
end	

class CompShootRight < Component
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED
	end 
	
	def on_player_walk()
		@active = false
		@game.components << CompShootRightAnimation.new(@game, x + 1, y)
	end
end	

class CompShootRightAnimation < Component
	ARROW_TIME = 0.03
	def initialize(game,x,y)
		super(game,x,y,"shootright")
		@color = Gosu::Color::RED	
		@duration = ARROW_TIME
	end 
	
	def update(dx)
		@duration -= dx
		if @duration < 0.0
			if (c = @game.components_at(x+1,y)) then
				if c.on_arrow_hit() then
					@active = false
					return
				end
			else
				@x = @x + 1
			end
			@duration += ARROW_TIME
		end
	end
	
	def physical
		false
	end
end	

class CompRing < Component
	def initialize(game,x,y)
		super(game,x,y,"ring")
		@color = Gosu::Color.argb(0xff_FB00F2)
	end 
	
	def on_player_walk
		@game.player.add_ring(1)
		@game.player.add_score(15)
	end
end	

class CompLetter < Component
	def initialize(game,x,y, letter)
		super(game,x,y,letter)
		@color = Gosu::Color::WHITE # font is red
	end
	
	def can_player_walk?()
		false
	end
end

class KrozGame
	attr_reader :board_x, :board_y
	attr_reader :episode, :mission

	def initialize()
		@board_x = 64 + 2
		@board_y = 23 + 2
		@components = []
		
		load_sprites()
		
		@episode = 1 # kingdom of kroz (remake?)
		@mission = 2 # level 1
		
		@player = nil
		@player_action = :none
		
		load_level(@episode, @mission)
		
		@current = Time.now()
		@animation = false
	end
	
	def player 
		@player
	end
	
	def components_at(x,y)
		result = components.select do |c|
			c.x == x and c.y == y and c.active and c.physical
		end
		raise "more than one component at location #{x},#{y}" if result.size > 1
		return result.first
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
		
		if action == :whip and 
			if @player.whips > 0
				@player.add_whips(-1)				
				[[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0]].each do |dir|
					cs = components_at(@player.x + dir.first, @player.y + dir.last)
					cs.on_whip(1 + @player.rings) if cs
					cs = components_at(@player.x + dir.first, @player.y + dir.last)
					components << CompWhipAnimation.new(self, @player.x + dir.first, @player.y + dir.last) if not cs					
				end
				
			end
		end
		
		cleanup_components() # remove inactive components 
	end
	
	def cleanup_components()
		components.select! do |c| c.active end
	end
	
	def game_tick()
		@components.each do |c| 
			c.tick() if c.active
		end
		cleanup_components()
	end
	
	def visible_components
		@components.select do |c| c.active end
	end
	
	def components
		@components
	end
	
	def load_sprites
		SpriteManager.load_sprite_from_sheet("floor1", "terrain_sprites.png", 0, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("wall1", "terrain_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("border", "terrain_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("trap1", "feature_sprites.png", 5, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("shootright", "feature_sprites.png", 11, 0, 16, 24)
		
		
		SpriteManager.load_sprite_from_sheet("gem", "item_sprites.png", 3, 1 , 16, 24)
		#SpriteManager.load_sprite_from_sheet("gem", "creature_sprites.png", 21, 4 , 16, 24)
		SpriteManager.load_sprite_from_sheet("whip", "item_sprites.png", 15, 1 , 16, 24)
		SpriteManager.load_sprite_from_sheet("ring", "item_sprites.png", 31, 0 , 16, 24)
		SpriteManager.load_sprite_from_sheet("key", "item_sprites.png", 3, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("chest", "item_sprites.png", 31, 2, 16, 24)
		SpriteManager.load_sprite_from_sheet("door", "sys_sprites.png", 6, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("exit", "feature_sprites.png", 4, 0, 16, 24)
		SpriteManager.load_sprite_from_sheet("teleport", "feature_sprites.png", 6, 0, 16, 24)
		
		
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
	
	def load_level(episode, mission)
	
		data = File.read("levels/#{episode}_#{mission}.dat")
		# puts data.size
		raise "invalid map #{episode}, #{mission}" unless data.size == 1495 # plus newlines?
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
					when "P"
						@player = CompPlayer.new(self, x+1,y+1)						
						@components << @player
					when "1"
						@components << CompMob1.new(self, x+1, y+1)						
					when "2"
						@components << CompMob2.new(self, x+1, y+1)						
					when "3"
						@components << CompMob3.new(self, x+1, y+1)						
						#Tile.new("mob3", Gosu::Color::YELLOW)
					when "W"
						@components << CompWhip.new(self, x+1, y+1)						
					when "+"
						@components << CompGem.new(self, x+1, y+1)						
					when "."						
						@components << CompTrap.new(self, x+1, y+1)
					when ">"
						@components << CompShootRight.new(self, x+1, y+1)						
					when " "						
					when "#"						
						@components << CompWall.new(self, x+1, y+1)
					when "X"
						@components << CompWeakWall.new(self, x+1, y+1)										
					when "C"
						@components << CompChest.new(self, x+1, y+1)
					when "L"
						@components << CompExit.new(self, x+1, y+1)
					when "D"
						@components << CompDoor.new(self, x+1, y+1)
					when "K"
						@components << CompKey.new(self, x+1, y+1)
					when "T"
						@components << CompTeleport.new(self, x+1, y+1)						
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
	
	# main game engine.. update all entities
	def update(dx)		
		@animation.update(dx) if @animation		
		# @components.each do |c| c.update(dx) end
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

