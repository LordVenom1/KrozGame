class SoundManager
	@sounds = {}	
	
	def self.load(name,filename)
		@sounds[name] = Gosu::Sample.new("media/audio/#{filename}")
	end
		
	def self.play(name)				
		raise "sound sample not found: #{name}" unless @sounds.has_key?(name)		
		@sounds[name].play
	end
end

SoundManager.load("door","door.wav")
SoundManager.load("spell","spell.wav")
SoundManager.load("badhit","badhit.wav")
SoundManager.load("swing1","swing1.wav")
SoundManager.load("swing2","swing2.wav")
SoundManager.load("swing3","swing3.wav")
SoundManager.load("metal","metal_trap.wav")
SoundManager.load("gem","coin.wav")
SoundManager.load("pouch","coin2.wav")		
SoundManager.load("squish1","squish1.wav")		
SoundManager.load("squish2","squish2.wav")		
SoundManager.load("squish3","squish3.wav")		
SoundManager.load("walk","walk.wav")	
SoundManager.load("trap","trap.wav")	
SoundManager.load("arrow_loose","arrow_loose.wav")
