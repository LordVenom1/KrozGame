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
	def self.update(gosu, dt)
		
	end
	
	def self.draw(gosu)
		#gosu.font.draw_text_rel("PRESS ANY KEY TO BEGIN YOUR DESCENT INTO KROZ", gosu.width / 2.0, gosu.height * 0.40, 1.0, 0.5, 0.5, 1.5, 1.5)
		img = SpriteManager.image("title")
		img.draw(0,0,0, gosu.width.to_f / img.width.to_f, gosu.height.to_f / img.height.to_f)
	end
	
	def self.button_down(gosu, id)
		if id == Gosu::KB_ESCAPE
			gosu.close				
		else
			gosu.set_layer(GameLayer)
		end		
	end
	
	def self.button_up(id)
	end
end

module MenuLayer
	def self.update(gosu, dt)
	end
	
	def self.draw(gosu)
		top_margin = gosu.height * 0.20
		row = 0
		row_height = 32
				
		gosu.font.draw_text_rel("Level: #{gosu.game.mission.to_s.rjust(2, " ")}", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		row += row_height
		
		gosu.font.draw_text_rel("ESC - Return to KROZ", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'Q' - Quit the game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'X' - Restart this level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'S' - Save your game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'R' - Restore your game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'[' - Return to previous level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("']' - Skip to the next level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
	end
	
	def self.button_down(gosu, id)
		if id == Gosu::KB_ESCAPE
			gosu.set_layer(GameLayer)			
		elsif id == Gosu::KB_Q
			gosu.close
		elsif id == Gosu::KB_X
			gosu.game.handle_action(:restart_level)
			gosu.set_layer(GameLayer)	
		elsif id == Gosu::KB_S
			gosu.game.handle_action(:save_game)
			gosu.set_layer(GameLayer)			
		elsif id == Gosu::KB_R
			gosu.game.handle_action(:restore_game)
			gosu.set_layer(GameLayer)
		elsif id == Gosu::KB_RIGHT_BRACKET					
			gosu.game.handle_action(:next_level)
			gosu.set_layer(GameLayer)	
		elsif id == Gosu::KB_LEFT_BRACKET
			gosu.game.handle_action(:prev_level)
			gosu.set_layer(GameLayer)	
		end		
	end
end

module GameLayer
	def self.update(gosu,dt)		
		gosu.game.update(dt)		
	end
	
	def self.draw(gosu)
		# draw background
		(0...gosu.game.board_x).each do |x|
			(0...gosu.game.board_y).each do |y|
				t = gosu.game.floor_tile(x,y)				
				#raise "tile not found #{x}, #{y}" unless t
				#puts t.sprite_name
				if t #opaque tiles don't need to have anything under them...
					SpriteManager.image(t.sprite_name).draw(x * GameWindow::TILE_WIDTH * GameWindow::TILE_SCALE, y * GameWindow::TILE_HEIGHT * GameWindow::TILE_SCALE, 0, GameWindow::TILE_SCALE, GameWindow::TILE_SCALE, t.color)
				end
			end
		end
		
		# draw foreground
		gosu.game.visible_components.each do |c|
			x = c.x
			y = c.y
			begin
				SpriteManager.image(c.sprite_name).draw(x * GameWindow::TILE_WIDTH * GameWindow::TILE_SCALE, y * GameWindow::TILE_HEIGHT * GameWindow::TILE_SCALE, 0, GameWindow::TILE_SCALE, GameWindow::TILE_SCALE, c.color)
			rescue
				puts c
			end
		end
		
		# draw ui		
		gosu.font.draw_text("Score: #{gosu.game.player.score.to_s.rjust(9," ")}  Level: #{gosu.game.mission.to_s.rjust(2, " ")}  Gems: #{gosu.game.player.gems.to_s.rjust(3, " ")}  Whips: #{(gosu.game.player.whips.to_s.rjust(3, " ") + (gosu.game.player.rings == 0 ? "  " : ("+" + gosu.game.player.rings.to_s)))}  Teleports: #{gosu.game.player.teleports.to_s.rjust(3, " ")}  Keys: #{gosu.game.player.keys.to_s.rjust(2, " ")}", 30.0, gosu.height - 30, 1.0)
		
		# @font.draw_text("PAUSED", 420, 530, 1.0, 2.0, 2.0) if @game.paused
		gosu.font.draw_text_rel("PAUSED", gosu.width / 2.0, gosu.height * 0.90, 1.0, 0.5, 0.5, 2.0, 2.0) if gosu.game.paused
		
		gosu.font.draw_text_rel("GAME OVER", gosu.width / 2.0, gosu.height * 0.40, 1.0, 0.5, 0.5, 4.0, 4.0, Gosu::Color::RED) if gosu.game.player.status == :dead
		
		# center flash text?
		gosu.font.draw_text_rel(gosu.game.render_state.current_flash, gosu.width / 2.0, gosu.height * 0.80, 1.0, 0.5, 0.5, 1.5, 1.5) if gosu.game.render_state.current_flash
		#draw_text(text, x, y, z, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
	end
	
	def self.set_action(gosu)
		if Gosu.button_down? Gosu::KB_SPACE
			gosu.game.handle_action(gosu.game.paused ? :unpause : :pause)
			gosu.reset_last_update
		else
			# if @game.paused
				# @game.unpause 
				# @last_update = Time.now()
			# end
			if gosu.game.render_state.current_flash
				gosu.game.render_state.clear_flash
				gosu.game.blocking_effects[:flash].clear if not gosu.game.render_state.current_flash
			end
	
			if Gosu.button_down? Gosu::KB_NUMPAD_8 or Gosu.button_down? Gosu::KB_UP				
				gosu.game.handle_action(:move_up)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_7
				gosu.game.handle_action(:move_upleft)			
			elsif Gosu.button_down? Gosu::KB_NUMPAD_9
				gosu.game.handle_action(:move_upright)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_4 or Gosu.button_down? Gosu::KB_LEFT
				gosu.game.handle_action(:move_left)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_6 or Gosu.button_down? Gosu::KB_RIGHT
				gosu.game.handle_action(:move_right)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_1
				gosu.game.handle_action(:move_downleft)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_2 or Gosu.button_down? Gosu::KB_DOWN
				gosu.game.handle_action(:move_down)
			elsif Gosu.button_down? Gosu::KB_NUMPAD_3
				gosu.game.handle_action(:move_downright)
			elsif Gosu.button_down? Gosu::KB_W
				gosu.game.handle_action(:whip)
			elsif Gosu.button_down? Gosu::KB_T
				gosu.game.handle_action(:teleport)

			# elsif Gosu.button_down? Gosu::MS_LEFT
				# mx, my = mouse_x, mouse_y
				# mx = (mx / GameWindow::TILE_WIDTH / GameWindow::TILE_SCALE).to_i
				# my = (my / GameWindow::TILE_HEIGHT / GameWindow::TILE_SCALE).to_i							
				# @game.handle_action(:set_location, mx, my)
			end
		end
	end	
	
	def self.button_down(gosu,id)
		if id == Gosu::KB_ESCAPE
			gosu.set_layer(MenuLayer)		
		else			
			set_action(gosu)
		end		
	end
end

class GameWindow < Gosu::Window	

	TILE_WIDTH = 16
	TILE_HEIGHT = 24		
	TILE_SCALE = 1.0

	attr_reader :game
	attr_reader :font

	def initialize
		super 1056, 768		
		self.caption = "Kroz"		
		@game = KrozGame.new()
		

		# GameWindow::TILE_SCALE = [(width * 0.90) / (@game.board_x * GameWindow::TILE_WIDTH.to_f), (height * 0.90) / (@game.board_y * GameWindow::TILE_HEIGHT.to_f)].min		
	
		reset_last_update		
		@font = Gosu::Font.new(24)		
		@action = nil				
		@layer = MainMenuLayer
	end	
	
	
	def reset_last_update
		@last_update = Time.now()
	end
	
	def set_layer(layer)
		@layer = layer
	end
	
	def update
		current = Time.now()
		@layer.update(self, current - @last_update)
		@last_update = current
	end
	
	def draw
		@layer.draw(self)
	end
	
	def button_down(id)
		@layer.button_down(self,id)
	end
	
end

GameWindow.new.show()