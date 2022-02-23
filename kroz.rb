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
require_relative 'sound_manager.rb'

module MainMenuLayer
	def do_update(dt)
	end
	
	def draw
		@font.draw_text_rel("PRESS ANY KEY TO BEGIN YOUR DESCENT INTO KROZ", width / 2.0, height * 0.40, 1.0, 0.5, 0.5, 1.5, 1.5)
	end
	
	def button_down(id)
		if id == Gosu::KB_ESCAPE
			close				
		else
			include GameLayer
		end		
	end
	
	def button_up(id)
	end
	
	def needs_cursor?
		false
	end
end

module MenuLayer
	def do_update(dt)
	end
	
	def draw
	end
	
	def button_down(id)
		if id == Gosu::KB_ESCAPE
			@game.shutdown
			close				
		else
			
			set_action()			
			super
		end		
	end
	
	def button_up(id)
	end
	
	def needs_cursor?
		false
	end
end

module GameLayer
	def do_update(dt)		
		@game.update(dt)		
	end
	
	def draw()
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
			begin
				SpriteManager.image(c.sprite_name).draw(x * @tile_width * @tile_scale, y * @tile_height * @tile_scale, 0, @tile_scale, @tile_scale, c.color)
			rescue
				puts c
			end
		end
		
		# draw ui		
		@font.draw_text("Score: #{@game.player.score.to_s.rjust(9," ")}  Level: #{@game.mission.to_s.rjust(2, " ")}  Gems: #{@game.player.gems.to_s.rjust(3, " ")}  Whips: #{(@game.player.whips.to_s.rjust(3, " ") + (@game.player.rings == 0 ? "  " : ("+" + @game.player.rings.to_s)))}  Teleports: #{@game.player.teleports.to_s.rjust(3, " ")}  Keys: #{@game.player.keys.to_s.rjust(2, " ")}", 30.0, height - 30, 1.0)
		
		# @font.draw_text("PAUSED", 420, 530, 1.0, 2.0, 2.0) if @game.paused
		@font.draw_text_rel("PAUSED", width / 2.0, height * 0.90, 1.0, 0.5, 0.5, 2.0, 2.0) if @game.paused
		
		# center flash text?
		@font.draw_text_rel(@game.render_state.current_flash, width / 2.0, height * 0.80, 1.0, 0.5, 0.5, 1.5, 1.5) if @game.render_state.current_flash
		#draw_text(text, x, y, z, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
	end
	
	def set_action()
	
		if Gosu.button_down? Gosu::KB_SPACE
			@game.handle_action(@game.paused ? :unpause : :pause)
			@last_update = Time.now()
		else
			if @game.paused
				@game.unpause 
				@last_update = Time.now()
			end
	
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
			end
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
		else
			
			set_action()			
			super
		end		
	end
	
	def button_up(id)
	end

end

class GameWindow < Gosu::Window	

	def initialize
		super 1056, 768		
		self.caption = "Kroz"		
		@game = KrozGame.new()
		
		@tile_width = 16
		@tile_height = 24
		
		@tile_scale = 1.0
		# @tile_scale = [(width * 0.90) / (@game.board_x * @tile_width.to_f), (height * 0.90) / (@game.board_y * @tile_height.to_f)].min		
	
		@last_update = Time.now()
		
		@font = Gosu::Font.new(24)
		
		@action = nil
				
		include MainMenuLayer
	end	
	
	def update
		current = Time.now()
		do_update(current - @last_update)
		@last_update = current
	end
	
end

GameWindow.new.show()