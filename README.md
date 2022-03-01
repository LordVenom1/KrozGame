=======
# Kingdom of Kroz ruby remake

This is a re-implementation of Kingdom of Kroz (the 1990 re-release), originally made by Scott Miller, who would go on to found Apogee Software.
In 2009 the original games were released as freeware, while the PASCAL source code was released under a GPL license.

https://en.wikipedia.org/wiki/Kroz
https://github.com/tangentforks/kroz

Kroz was one of the first interesting video games series I played.  It is also historically significant as it was one of the games
that demonstrated the potential of shareware - that is wide distribution of a games to encourage people to purchase the full version.
It was also the game that started Scott Miller's career, who would found apogee software which would later become 3D Realms.

Unlike "roguelike" games of the era, Kroz is a real-time game.  you still move a simple character on a grid while chased by numerous enemies,
while chased by 

To play:
	Download the project to a local directory
	Download and install 'ruby with dev-tools'
	Run 'bundle install'
	Type "kroz.rb"

Use the numpad to move around, "w" to swing a whip, "t" to utilize a teleport.
Hit escape for the menu.

As in the original, 

Sample gameplay:

This project takes the original game levels and presents them in a made-from-scratch engine.  
It is written as a personal project with no specific purpose beyond making it freely available here.
The levels were taken as-is.  Many game specifics were taken from the game in order to get similar behavior.  



Utilizing public domain art and audio assets:
	# https://v3x3d.itch.io/ - Bountiful Bits
	# Font sprites:
		#  https://opengameart.org/content/three-little-bitmap-fonts
		#  Buch and link back to http://blog-buch.rhcloud.com
	# Audio:

Goals:
	* Make a complete game that's playable, focusing on implementation and not design
	* Make a game with decent graphics by utilizing free assets
	* Read and understand a project written by someone else, in this case very terse PASCAL code.
	* Make it freely available

Design notes:
	* Written in Ruby
	* Graphic rendering and Audio are handled by "Gosu" library
	* All visual components in the actual game inherit from the Component class and form a shallow class hierarchy
	* Components are stored in an arbitrary list
	* Removal of old components is a 2-phase process of flagging and then removal, to avoid the common issue of logic referring to empty components
	* Most component interactions are handled as functions in the Component interface.  This is a low-tech approach that none-the-less meets the needs well without extra complexity.
	* Saving and Loading work as they do in the original game... saving takes a snapshot of your status at the beginning of the current level only.
	* The levels are taken directly from the original source.  The target of the project is to fully implement the features necessary to support the original levels.
	* Sprites and Sounds are handled simply in separate files using a class-level static approach.
	* Drawing is done in a brute-force approach, with the rendering code having direct access to the components.  Only the 'flash' messages are implemented through an intermediate "RenderState" object.
	* The menus are implemented using a simple layer approach, having the Gosu library pass the update, draw, and keyboard calls to the current active layer.
	* The game has multiple types of timing.  The game handles a delta_time in a single update call.  It then tracks the amount of time since ticks have happened (basically monster movement), as well as player movement.
	* There are also "effects" that track actual wall time, these are used to count down power-ups, as well as used to block the game from progressing while the user acknowledges a message, etc.  This gives lots of flexibility to stop the action while an animation plays out, etc, simulating the delays that happened natually in the original due to the non-trivial time it takes to write to the screen.
	* Since all game progress occurs through this single update, that puts me in a good position to do in-game recordings or automated tests since the simulation should be fully deterministic.
	* Current performance seems very solid and stable on my workstation.
	* Perhaps the most interesting levels are the 'sideways' levels.  They pull the player downwards at all times, limit you to walking onto 'supported' tiles.  They also feature the only case where you can step on top of a tile (a rope) and then it remains there when you move away.  

Challenges:
The primary challenges were that once the first couple of levels were working well, there was more additional work that needed to be done than I anticipated.  Kingdom of Kroz has 25 levels, and one of the key features of Kroz that makes it fun and interesting is the introduction of new mechanics, as well as putting the player in situations where they need to understand the existing mechanics well in order to proceed without expending excessive resources.
I initially implemented some of the features in a way that made sense, but as the project continued it became more of a priority to me to reproduce the original behavior.  I perhaps should've taken a different approach and done something closer to a "port" and then refactor of the original source.  However as it stands the structure and design of my version is completely original.
This was most evident with all the "traps", which were really a set of triggers that have a lot of simularity and some small differences.  
Understanding how the game worked actually required playing through the original.  Luckily they are freely available online via emulators.  I basically played through while recording so that I could refer back to interesting parts as needed to avoid wasting time replaying them.
One of the technical challenges

Future ideas:    
	* At the moment there are still a few outstanding issues
		* need to compare "monster" logic to original to make sure they move exactly the same
		* on sideways levels shouldn't be able to move upward unless to rope.
		* Add all of the original 'hints' to the game - messages you see the first time you encounter each new component
	* Add option to turn on and off sound
	* Add more sounds to the game	
	* Lots of ideas for code cleanup that could make the code more object-oriented: 
		* switch simple actions to actual command pattern style objects.  
		* move all graphics to the renderstate object
		* use a full ECS design: move game logic into events and keep components as state only
	* Add high score
	* Add instant save option; allow you to jump between saves for each level and only save the "best" ones?
	* Add all seven Kroz games.  It would be interesting to see how many new features are in the other games that would require additional work.
	* While I'm happy with the initial graphics I didn't spend any time tuning the graphics and overall look and feel.  Some work in this area could make for very different looks for the game.
	* Could add other neat background animations, like monsters shambling a bit in place (which was in the original), torches on the wall flickering, portals swirling, etc.
	* The portion of the KrozGame class that deals with loading levels should be organized separately.
	* Sprites and Sounds should load based on a config file.
	* use a position class instead of x,y parameters to things like component_at
	* change "add_component" to take a class and handle the association to game

Overall
I'm very satisfied with how this project turned out, and "future ideas" aside I'm pretty happy with its current state.  I found the game genuinely fun to actually play through, and it held plenty of interesting and emergent surprises even though I had programmed the game myself.
My overall design, while not taken to a logical conclusion in terms of object-oriented game design, was very satisfactory.  By the end it felt fun and natural to implement each new component with minimal need to revisit other systems, which is naturally the point.


# KrozGame

