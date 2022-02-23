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
		if @duration < 0.0
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