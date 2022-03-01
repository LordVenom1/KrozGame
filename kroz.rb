require 'gosu'

require_relative 'game.rb'
require_relative 'sprite_manager.rb'
require_relative 'sound_manager.rb'

module MainMenuLayer
	def self.update(gosu, dt)		
		@@duration -= dt if @@duration > 0.0
		if @@duration <= 0.0
			@@bg = "title_new"			
		end		
	end
	
	def self.draw(gosu)		
		img = SpriteManager.image(@@bg)
		img.draw(0,0,0, gosu.width.to_f / img.width.to_f, gosu.height.to_f / img.height.to_f)
		gosu.font.draw_text_rel("PRESS ANY KEY TO BEGIN YOUR DESCENT INTO KROZ", gosu.width / 2.0, gosu.height * 0.94, 1.0, 0.5, 0.5, 1.5, 1.5) if @@bg == "title_new"
	end
	
	def self.button_down(gosu, id)
		return if @@bg == "title"
		gosu.set_layer(GameLayer)		
	end
	
	def self.reset	
		@@duration = 0.40
		@@bg = "title"		
		self
	end
end

module VictoryLayer
	def self.update(gosu, dt)		
	end
	
	def self.draw(gosu)	
		top_margin = gosu.height * 0.10
		row = 0
		row_height = 32
						
		gosu.font.draw_text_rel("Back at your hut", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("For years you've waited for such a wonderful archaeological", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("discovery. And now you possess one of the greatest finds ever!", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("The Magical Amulet will bring you great fame, and even more", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("so if you ever learn how to harness the Amulet's magical", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("abilities.  For now it must wait, though, for Kroz is a huge", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("place, and still mostly unexplored.", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("Even with the many dangers that await, you feel another", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("expedition is in order.  You must leave no puzzle unsolved, no", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("treasure unfound--to quit now would leave the job unfinished.", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("So you plan for a good night's rest, and think ahead to", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("tomorrow's new journey.  What does the mysterious kingdom of", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("Kroz have waiting for you, what type of new creatures will", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("try for your blood, and what kind of brilliant treasure does", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("Kroz protect.  Tomorrow will tell...", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		; row += row_height		
		gosu.font.draw_text_rel("Final Score: #{gosu.game.player.score}", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height		
	end
	
	def self.button_down(gosu, id)	
		if id == Gosu::KB_ESCAPE
			puts "Congratulations, you escaped the kingdom of kroz!  Final score: #{gosu.game.player.score}"
			gosu.close 
		end
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
		gosu.font.draw_text_rel("Sound: #{gosu.options[:sound] ? "Enabled" : "Disabled"}", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		row += row_height
		
		gosu.font.draw_text_rel("ESC - Return to KROZ", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'Q' - Quit the game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'R' - Restart this level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		gosu.font.draw_text_rel("'S' - Toggle Sound", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		# gosu.font.draw_text_rel("'S' - Save your game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		# gosu.font.draw_text_rel("'R' - Restore your game", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		#gosu.font.draw_text_rel("'[' - Return to previous level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
		#gosu.font.draw_text_rel("']' - Skip to the next level", gosu.width / 2.0, top_margin + row, 1.0, 0.5, 0.5, 1.5, 1.5) ; row += row_height
	end
	
	def self.button_down(gosu, id)
		if id == Gosu::KB_ESCAPE
			gosu.set_layer(GameLayer)			
		elsif id == Gosu::KB_Q
			gosu.close
		elsif id == Gosu::KB_S
			gosu.options[:sound] = not(gosu.options[:sound])
		elsif id == Gosu::KB_R
			gosu.game.handle_action(:restart_level)
			gosu.set_layer(GameLayer)	
		# elsif id == Gosu::KB_S
			# gosu.game.handle_action(:save_game)
			# gosu.set_layer(GameLayer)			
		# elsif id == Gosu::KB_R
			# gosu.game.handle_action(:restore_game)
			# gosu.set_layer(GameLayer)
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
		
		gosu.game.render_state.get_sound_events.each do |name|
			SoundManager.play(name) if gosu.options[:sound]
		end
		
		if gosu.game.player.status == :victory
			gosu.set_layer(VictoryLayer)
		end		
	end
	
	def self.draw(gosu)
		# draw background		
		SpriteManager.image("floor").draw(0, 0, 0, GameWindow::TILE_SCALE, GameWindow::TILE_SCALE)
		
		# draw foreground
		gosu.game.visible_components.each do |c|
			x = c.x
			y = c.y
			begin
				SpriteManager.image(c.sprite_name).draw(x * GameWindow::TILE_WIDTH * GameWindow::TILE_SCALE, y * GameWindow::TILE_HEIGHT * GameWindow::TILE_SCALE, 0, GameWindow::TILE_SCALE, GameWindow::TILE_SCALE, c.color)
			end
		end
		
		# draw ui		
		gosu.font.draw_text("Numpad to move   W)hip   T)eleport    ESC) Options         Sound: #{gosu.options[:sound] ? "Enabled" : "Disabled"}", 30.0, gosu.height - 60, 1.0)
		gosu.font.draw_text("Score: #{gosu.game.player.score.to_s.rjust(9," ")}  Level: #{gosu.game.mission.to_s.rjust(2, " ")}  Gems: #{gosu.game.player.gems.to_s.rjust(3, " ")}  Whips: #{(gosu.game.player.whips.to_s.rjust(3, " ") + (gosu.game.player.rings == 0 ? "  " : ("+" + gosu.game.player.rings.to_s)))}  Teleports: #{gosu.game.player.teleports.to_s.rjust(3, " ")}  Keys: #{gosu.game.player.keys.to_s.rjust(2, " ")}", 30.0, gosu.height - 30, 1.0)
		
		gosu.font.draw_text_rel("PAUSED", gosu.width / 2.0, gosu.height * 0.90, 1.0, 0.5, 0.5, 2.0, 2.0) if gosu.game.paused		
		gosu.font.draw_text_rel("GAME OVER", gosu.width / 2.0, gosu.height * 0.40, 1.0, 0.5, 0.5, 4.0, 4.0, Gosu::Color::RED) if gosu.game.player.status == :dead
		
		gosu.font.draw_text_rel(gosu.game.render_state.current_flash, gosu.width / 2.0, gosu.height * 0.80, 1.0, 0.5, 0.5, 1.5, 1.5) if gosu.game.render_state.current_flash
	end
	
	def self.set_action(gosu)
		if Gosu.button_down? Gosu::KB_SPACE
			gosu.game.handle_action(gosu.game.paused ? :unpause : :pause)
			gosu.reset_last_update
		else
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
	attr_reader :options

	def initialize
		super 1056, 768		
		self.caption = "Kroz"		
		@game = KrozGame.new()
		reset_last_update		
		@font = Gosu::Font.new(24)		
		@action = nil				
		@layer = MainMenuLayer.reset
		
		@options = {sound: false}		
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