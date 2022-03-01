class Effect
	def initialize(default_activation_duration, &on_finish_proc)
		@default_activation_duration = default_activation_duration
		@duration = 0.0
		@on_finish = on_finish_proc			
		@component = nil
	end
	
	def active?
		@duration > 0.0
	end
	
	def link_component=(c)
		@component = c
	end	
	
	def activate(dur = nil)
		@duration = dur || @default_activation_duration
	end
	
	def clear
		@duration = 0.0
	end
	
	def update(dt)
		if active?		
			@duration -= dt			
			if @duration < 0.0
				@duration = 0.0 
				@on_finish.call(self) if @on_finish
			end
		end		
	end	
	
	def update_component(dt)
		@component.update(dt) if @component and @component.active
	end
end