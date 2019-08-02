# MagicMenace
Final Project for CSCB58: Magic Menace


" Magic Menace! "

By: Husni Fareed, Mustafa Hafeez, and Azim Hirjani

Video Demonstration:
https://drive.google.com/open?id=1lbbOV2Gw0iVVwS6tGOfQNqNoMhYag0ge

------------------------------

Different States in the game:

Pre-Game:

The User can preload 4 letters which can be called during the game by using each switch from SW[10:7] 
through an input from SW[3:0], 4-bit (16 letter) mapping system where 0 maps to A, 1 maps to B, ... , 
all the way until 15 which maps to P. When the User has configured the letter that they want to load 
using SW[3:0], they can press KEY[3] to load the value into whichever SW[10:7] are high (so we need a
memory unit of 4 addresses where each address stores a 4 bit wide binary value and SW[10] points to 
the first, SW[9] points to the second, ... , and SW[7] points to the forth). Along with this the letter
values stored in the four addresses are shown on HEX3 (first value), HEX2, HEX1, and HEX0 (last value). 
(View Board Mapping image for the visual mapping). When the board starts the four HEX's should show A B C D

Before the Game Starts and after the game ends, HEX7 and HEX6 will show the two digit number 60.

HEX5 and HEX4 will show the score from the last game run (so it will show 00 when the board first configures)

------------------------------

Game State:

The game state is triggered by KEY[2] and the game runs in 60 seconds when SW[18] is low (easy mode) and 
in 30 seconds when SW[18] is high (hard mode).  In either mode, the HEX7 and HEX6 show the two digit time 
decreasing from 60, so when hard mode is on, 60 decreases twice as fast from 60 to 0 than in easy mode.
Once the game ends, the user is in the same state as before the game (the pre-game state is the same state 
as the end-game state)

When the Game  starts the user sees 16 random letters on the screen and will have to enter each letter 
(Including only letters from A to P, because of 4 bit input). They will use four switches SW[3:0] on
the board to load the letter, and hit KEY[3] to submit the input.  If any of SW[10:7] are high,
the SW[3:0] is ignored ( in other words, the preloaded value has higher precedence). For each 
letter that the user enters correctly (reading the words from left to right), the score will be 
reflected on HEX5 and HEX4 and at the end of the game the score will remain the same until the next game starts.

------------------------------

Add-on features:

SW[16:14] Control the colour shown and instead of the demonstration video, they will change to 8 completely different colours.

If the user needs to pause the game during the game state, they can hold down the Key[3] button which will stop the timer 
(due to a debounce module)

------------------------------

References:

VGA Reference: https://github.com/Derek-X-Wang/VGA-Text-Generator?files=1

FSR Reference: https://vlsicoding.blogspot.com/2014/07/verilog-code-for-4-bit-linear-feedback-shift-register.html
