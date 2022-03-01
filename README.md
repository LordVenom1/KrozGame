=======
# Kingdom of Kroz - Ruby

This is a re-implementation of Kingdom of Kroz (the 1990 re-release), originally made by Scott Miller.
In 2009 the original games were released as freeware, while the PASCAL source code was released under a GPL license.

[Wikipedia](https://en.wikipedia.org/wiki/Kroz)
[Original Kroz Source](https://github.com/tangentforks/kroz)

To play:
	* Download this project to a local directory
	* Download and install 'ruby 2.6.6'.  It should include the dev-tools.
	* Run 'bundle install' in the extracted folder
	* Type "kroz.rb"


Utilizing public domain art and audio assets:
	* Graphics: [Shadow of the Wyrm Spritesheets by Julian Day](https://www.shadowofthewyrm.org/downloads.html)
	* Font sprites: [Three Little Bitmap Fonts by Buch](https://opengameart.org/content/three-little-bitmap-fonts)		
	* Audio: [RPG Sound Pack by artisticdude](https://opengameart.org/content/rpg-sound-pack)

Goals:
	* Make a complete game that's playable
	* Have decent graphics by incorporating free assets
	* Read and understand a project written by someone else, in this case very terse PASCAL code.
	* Organize code to the point where all game functionality can be implemented
	* Publish it in some fashion

Design notes:
	* Written in Ruby.  Graphic rendering and Audio are handled by [Gosu](https://www.libgosu.org/) library.  		
	* Levels are exactly taken from PASCAL source.  Specific pieces of game behavior were taken from the source to maintain accuracy.  Otherwise the game design and structure was written from scratch.

Outcome:
	* The goals of the project were met and I am very happy with the results.  
	* The game is playable, feels similar to playing the original, and the emergent gameplay is still fun
