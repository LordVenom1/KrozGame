# needs awareness of gosu

class SpriteManager
	@images = {}
	
	def self.load_background(name, filename)
		@images[name] = Gosu::Image.new("media/#{filename}", tileable: false)
	end
	
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

SpriteManager.load_background("title","title.png")
SpriteManager.load_background("title_new","title_new.png")


# SpriteManager.load_sprite_from_sheet("floor1", "terrain_sprites.png", 0, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("floor1", "custom.png", 2, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("wall", "terrain_sprites.png", 3, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("border", "terrain_sprites.png", 3, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("water", "terrain_sprites.png", 2, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("lava", "terrain_sprites.png", 16, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("tree", "terrain_sprites.png", 1, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("forest", "terrain_sprites.png", 14, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("tunnel", "terrain_sprites.png", 8, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("question", "feature_sprites.png", 1, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("pit", "item_sprites.png", 31, 1, 16, 24)
SpriteManager.load_sprite_from_sheet("statue", "feature_sprites.png", 18, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("tome", "item_sprites.png", 4, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("flatline", "custom.png", 3, 0, 16, 24)
		
SpriteManager.load_sprite_from_sheet("trap_monster_create", "creature_sprites.png", 17, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("altar", "creature_sprites.png", 17, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("trap_teleport", "item_sprites.png", 3, 2, 16, 24)
SpriteManager.load_sprite_from_sheet("shootright", "feature_sprites.png", 11, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("shootleft", "feature_sprites.png", 11, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("arrow", "custom.png", 1, 0, 16, 24)

SpriteManager.load_sprite_from_sheet("freeze", "item_sprites.png", 4, 1 , 16, 24)
SpriteManager.load_sprite_from_sheet("fast", "item_sprites.png", 7, 0 , 16, 24)
SpriteManager.load_sprite_from_sheet("slow", "item_sprites.png", 6, 0 , 16, 24)
# 6,7

SpriteManager.load_sprite_from_sheet("gem", "item_sprites.png", 3, 1 , 16, 24)
SpriteManager.load_sprite_from_sheet("whip", "item_sprites.png", 15, 1 , 16, 24)
SpriteManager.load_sprite_from_sheet("ring", "item_sprites.png", 31, 0 , 16, 24)
SpriteManager.load_sprite_from_sheet("key", "item_sprites.png", 3, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("chest", "item_sprites.png", 31, 2, 16, 24)
# SpriteManager.load_sprite_from_sheet("door", "sys_sprites.png", 5, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("door", "custom.png", 0, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("exit", "feature_sprites.png", 4, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("teleport", "feature_sprites.png", 6, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("bomb", "item_sprites.png", 21, 1, 16, 24)
		
SpriteManager.load_sprite_from_sheet("rock", "item_sprites.png", 24, 2, 16, 24)
SpriteManager.load_sprite_from_sheet("nugget", "item_sprites.png", 10, 1, 16, 24)
SpriteManager.load_sprite_from_sheet("rope", "creature_sprites.png", 26, 3, 16, 24)
SpriteManager.load_sprite_from_sheet("drop_rope", "feature_sprites.png", 11, 0, 16, 24)		

SpriteManager.load_sprite_from_sheet("invis", "feature_sprites.png", 7, 0, 16, 24)


SpriteManager.load_sprite_from_sheet("sign", "feature_sprites.png", 12, 0, 16, 24)		

SpriteManager.load_sprite_from_sheet("tablet", "feature_sprites.png", 16, 0, 16, 24)

SpriteManager.load_sprite_from_sheet("player", "creature_sprites.png", 23, 3, 16, 24)
SpriteManager.load_sprite_from_sheet("mob1", "creature_sprites.png", 19, 0, 16, 24)
SpriteManager.load_sprite_from_sheet("mob2", "creature_sprites.png", 1, 6, 16, 24)
SpriteManager.load_sprite_from_sheet("mob3", "creature_sprites.png", 20, 10, 16, 24)
SpriteManager.load_sprite_from_sheet("generator", "item_sprites.png", 24, 1, 16, 24)

SpriteManager.load_sprite_from_sheet("unknown", "terrain_sprites.png", 21, 0, 16, 24)

('a'..'z').each do |letter|			
	SpriteManager.load_sprite_from_sheet(letter, "letters.png", letter.ord - 97, 0, 16, 24)
end

SpriteManager.load_sprite_from_sheet("!", "letters.png", 26, 0, 16, 24)