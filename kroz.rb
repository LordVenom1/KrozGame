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
	
		@last_update = Time.now()
		
		@font = Gosu::Font.new(24)
		
		@action = nil
		
	end	
	
	
	def update		
		current = Time.now()		
		@game.update(current - @last_update)
		@last_update = current	
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
		@font.draw_text("Score: #{@game.player.score.to_s.rjust(9," ")}  Level: #{@game.mission.to_s.rjust(2, " ")}  Gems: #{@game.player.gems.to_s.rjust(3, " ")}  Whips: #{(@game.player.whips.to_s.rjust(3, " ") + (@game.player.rings == 0 ? "  " : ("+" + @game.player.rings.to_s)))}  Teleports: #{@game.player.teleports.to_s.rjust(3, " ")}  Keys: #{@game.player.keys.to_s.rjust(2, " ")}", 30.0, height - 30, 1.0)
		
		@font.draw_text("PAUSED", 420, 530, 1.0) if @game.paused
		
		@font.draw_text(@game.render_state.current_flash, 420, 550, 1.0)
		#draw_text(text, x, y, z, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
	end
	
	def set_action()
		if Gosu.button_down? Gosu::KB_NUMPAD_8 or Gosu.button_down? Gosu::KB_UP				
			@game.handle_action(:move_up)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_7
			@game.handle_action(:move_upleft)			
		elsif Gosu.button_down? Gosu::KB_NUMPAD_9
			@game.handle_action(:move_upright)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_4 or Gosu.button_down? Gosu::KB_LEFT
			@game.handle_action(:move_left)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_6 or Gosu.button_down? Gosu::KB_RIGHT
			@game.handle_action(:move_right)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_1
			@game.handle_action(:move_downleft)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_2 or Gosu.button_down? Gosu::KB_DOWN
			@game.handle_action(:move_down)
		elsif Gosu.button_down? Gosu::KB_NUMPAD_3
			@game.handle_action(:move_downright)
		elsif Gosu.button_down? Gosu::KB_W
			@game.handle_action(:whip)
		elsif Gosu.button_down? Gosu::KB_T
			@game.handle_action(:teleport)
		elsif Gosu.button_down? Gosu::KB_RIGHT_BRACKET
			@game.handle_action(:next_level)
		elsif Gosu.button_down? Gosu::KB_LEFT_BRACKET
			@game.handle_action(:prev_level)
		elsif Gosu.button_down? Gosu::MS_LEFT
			mx, my = mouse_x, mouse_y
			mx = (mx / @tile_width / @tile_scale).to_i
			my = (my / @tile_height / @tile_scale).to_i							
			@game.handle_action(:set_location, mx, my)
		elsif Gosu.button_down? Gosu::KB_SPACE
			@game.handle_action(:pause)
			@last_update = Time.now()
		end
	end	
	
	# debug
	def needs_cursor?
		true
	end
	
	def button_down(id)
		if id == Gosu::KB_ESCAPE
			@game.shutdown
			close				
		
			
			@paused = !@paused
			if not @paused
				# if unpaused, reset timers to allow time to act
				@action = nil
				current = Time.now
				@last_player_update = current
				@last_game_update = current
				@last_update = current
			end
		else
			set_action() 
			super
		end		
	end
	
	def button_up(id)
	end
end

GameWindow.new.show()