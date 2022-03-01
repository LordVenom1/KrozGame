class CompWhipAnimation < Component
	WHIP_TIME = 0.02
	def initialize(game,x,y)
		super(game,x,y,"whip",false)		
		@color = Gosu::Color::RED
		@duration = WHIP_TIME
		@rx, @ry = x,y
		@n = 0
	end
	
	def update(dt)
		@duration -= dt
		if @duration <= 0.0
			@n += 1
			@duration += WHIP_TIME
			if @n == KrozGame::DIRS.size
				inactivate		
				@game.blocking_effects[:whip].clear
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
	
	# def blocking_animation?
		# true
	# end
end

class CompArrowAnimation < Component
	ARROW_TIME = 0.03
	def initialize(game,x,y,dx)
		super(game,x,y,"arrow",false)		
		@color = Gosu::Color::WHITE	
		@duration = ARROW_TIME
		@dx = dx
	end 
	
	def update(dt)
		@duration -= dt
		if @duration <= 0.0
			if (c = @game.component_at(@x+@dx,@y)) then
				if c.on_arrow_hit() then
					@game.blocking_effects[:arrow].clear
					inactivate
					return
				end
			else
				@x = @x + @dx
			end
			@duration += ARROW_TIME
		end
	end
end	

class CompFallingAnimation < Component
	FALL_TIME = 0.05	
	def initialize(game,x,y)
		super(game,x,y,"player",false)
		@duration = FALL_TIME
		@loops = 3		
	end
	
	def update(dt)
		return if @loops == 0
		@duration -= dt
		if @duration <= 0.0
			@y += 1
			@duration += FALL_TIME
			
			if @y >= 24 and @loops > 1
				@y = 0
				@loops -= 1
				if @loops == 1
					(26...40).each do |x|
						@game.add_component(CompWall.new(@game,x,24))
					end
				end
			end			
			
			if @y >= 23 and @loops == 1					
				@name = "flatline" # splat
				@game.blocking_effects[:falling].clear
				@game.player.kill
				@game.flash("You fell into a pit and died.")
				@loops = 0
			end			
		end		
	end	
end