##
##
##

# https://v3x3d.itch.io/ - Bountiful Bits

# Font sprites:
#  https://opengameart.org/content/three-little-bitmap-fonts
#  Buch and link back to http://blog-buch.rhcloud.com

require 'gosu'

require_relative 'game.rb'
require_relative 'sprite_manager.rb'

class GameWindow < Gosu::Window	

	def initialize
		super 1024, 768		
		self.caption = "Kroz"		
		@game = KrozGame.new()
		
		@tile_width = 16
		@tile_height = 24
		
		@tile_scale = 1.0
		@tile_scale = [(width * 0.90) / (@game.board_x * @tile_width.to_f), (height * 0.90) / (@game.board_y * @tile_height.to_f)].min		
	
		@paused = true		
		
		@last_update = Time.now()
		@last_player_update = Time.now()
		@last_game_update = Time.now()
		@player_tick_rate = 0.1
		@game_tick_rate = 2.0
		
		@font = Gosu::Font.new(24)
		
		@action = nil
		
	end	
	
	
	def update
		return if @paused		
						
		current = Time.now()		
		@game.update(current - @last_update)
		@last_update = current
		
		if current > @last_player_update + @player_tick_rate
		
			# lock in player action...
			# could just pass this directly into player_tick?
			
			if Gosu.button_down? Gosu::KB_NUMPAD_8 or Gosu.button_down? Gosu::KB_UP or @action == :move_up	
				@game.player_tick(:move_up)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_7 or @action == :move_upleft
				@game.player_tick(:move_upleft)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_9 or @action == :move_upright
				@game.player_tick(:move_upright)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_4 or Gosu.button_down? Gosu::KB_LEFT or @action == :move_left
				@game.player_tick(:move_left)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_6 or Gosu.button_down? Gosu::KB_RIGHT or @action == :move_right
				@game.player_tick(:move_right)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_1 or @action == :move_downleft
				@game.player_tick(:move_downleft)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_2 or Gosu.button_down? Gosu::KB_DOWN or @action == :move_down
				@game.player_tick(:move_down)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_3 or @action == :move_downright
				@game.player_tick(:move_downright)
			elsif Gosu.button_down? Gosu::KB_W or @action == :whip
				@game.player_tick(:whip)
			end
			
			@action = nil
		
			@last_player_update += @player_tick_rate # in case we get behind
			
		end
		
		if current > @last_game_update + @game_tick_rate
			@last_game_update += @game_tick_rate # in case we get behind
			@game.game_tick()
		end
	

		
		# every x ticks, allow player to move
		# every y ticks, tick() all components
		# not sure if any components need true updates.. maybe scrolls?  probalby not
		
		
	end
	
	def draw	
		# draw background
		(0...@game.board_x).each do |x|
			(0...@game.board_y).each do |y|
				t = @game.floor_tile(x,y)				
				#raise "tile not found #{x}, #{y}" unless t
				#puts t.sprite_name
				if t #opaque tiles don't need to have anything under them...
					SpriteManager.image(t.sprite_name).draw(x * @tile_width * @tile_scale, y * @tile_height * @tile_scale, 0, @tile_scale, @tile_scale, t.color)
				end
			end
		end
		
		# draw foreground
		@game.visible_components.each do |c|
			x = c.x
			y = c.y
			SpriteManager.image(c.sprite_name).draw(x * @tile_width * @tile_scale, y * @tile_height * @tile_scale, 0, @tile_scale, @tile_scale, c.color)
		end
		
		# draw ui		
		@font.draw_text("Score: #{@game.player.score.to_s.rjust(7," ")}  Level: #{@game.mission.to_s.rjust(2, " ")}  Gems: #{@game.player.gems.to_s.rjust(3, " ")}  Whips: #{@game.player.whips.to_s.rjust(3, " ")}  Teleports: #{@game.player.teleports.to_s.rjust(3, " ")}  Keys: #{@game.player.keys.to_s.rjust(2, " ")}", 30.0, height - 30, 1.0)
		
		@font.draw_text("PAUSED", 420, 530, 1.0) if @paused
		#draw_text(text, x, y, z, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
	end
	
	def button_down(id)
	
		return if @game.animation
	
		if id == Gosu::KB_ESCAPE
			close			
		elsif id == Gosu::KB_NUMPAD_8 or Gosu.button_down? Gosu::KB_UP				
			@action = :move_up
		elsif id == Gosu::KB_NUMPAD_7
			@action = :move_upleft
		elsif id == Gosu::KB_NUMPAD_9
			@action = :move_upright
		elsif id == Gosu::KB_NUMPAD_4 or Gosu.button_down? Gosu::KB_LEFT
			@action = :move_left
		elsif id == Gosu::KB_NUMPAD_6 or Gosu.button_down? Gosu::KB_RIGHT
			@action = :move_right
		elsif id == Gosu::KB_NUMPAD_1
			@action = :move_downleft
		elsif id == Gosu::KB_NUMPAD_2 or Gosu.button_down? Gosu::KB_DOWN
			@action = :move_down
		elsif id == Gosu::KB_NUMPAD_3
			@action = :move_downright
		elsif id == Gosu::KB_W
			@action = :whip						
		elsif id == Gosu::KB_SPACE
			@paused = !@paused
			if not @paused
				# if unpaused, reset timers to allow time to act
				current = Time.now
				@last_player_update = current
				@last_game_update = current
				@last_update = current
			end
		else
			super
		end
	end
	
	def button_up(id)
	end
end

GameWindow.new.show()