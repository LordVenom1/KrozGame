# needs awareness of gosu

class SpriteManager
	@images = {}
	
	def self.load_sprite_from_sheet(name, parent_filename, x, y, width, height)
		left = x * width
		top = y * height
		p = Gosu::Image.new("media/#{parent_filename}", tileable: true)		
		@images[name] = p.subimage(left, top, width, height)
	end
	
	def self.image(name)
		#@images[name] = Gosu::Image.new("media/#{name}.png", tileable: true) unless @images[name]
		raise "sprite not found: #{name}" unless @images.has_key?(name)
		@images[name]
	end
	
end