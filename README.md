# GGJ26
Repository for our Global Game Jam 26 game

# Ideas
## Bit Masking
The idea is obviously centred around the concept of bit masking.

Imagine that you have a "ground" at the bottom of the screen. It is initially made of of only zeros '0'. Above the ground is the "sky" and falling from the sky are ones '1'. When a one makes contact with a zero in the ground it replaces the zero.

Now the ground is made up of ones and zeros. It is now possible to see that the ground can be shifted left or right (with wrapping at the edges).

It can be noticed that if a falling one makes contact with a one on the ones on the ground, that is ok it has no effect. Shifting the *mask* left and right enables the player to manage the falling ones.

Falling zeros are added to the mix. If a falling zero hits a ground zero, then no problem. If it hits a one then it sits on top of the one and the ground is now higher in that slot. 

The level of difficulty increases as now combinations of ones and zeros are falling '01' or '10', then '001' or '010' etc.

Something, something, maybe some kind of mechanism for clearing higher ground, perhaps like tetris rows?

...

Profit?

DM: Could maybe have different modes where different bitwise operators apply to falling digits, AND/OR/XOR etc.?
    Could also require player to make matching 2x2 blocks or similar to clear them compared to making complete lines?

DP: I like the idea of the bit operators a lot. Also the suggestion that you have about the different combo blocks for clearing is neat too. That seems like the kind of thing that we could get the core in, and then playtest around with different mechanics to see which ones work and are fun.

I think it could work quite well as a phone game where you interact with it through thumb at bottom of screen tracking left and right. Perhaps the speed of the ground moving could be analog - faster at the screen edges than towards the middle. I imagine that it could be something that rewards mastery, which would be pretty cool.

## Paint stencils

More of a specific mechanic around painting which would build out into a little game/experience.

With a standard dual stick controller:
 - Right stick controls a spray can held in one hand
 - Left stick controls a stencil held in the other
 - Right trigger to spray

 Can move right stick up & down to shake can, then hold trigger to draw using use stencils.

 Not quite sure how that builds out into a fully featured game, but feels like could be quite a pleasing interaction. (Puzzles where you have to make a specific image with stencils? Just wandering around a space drawing things? Some light plot to tie things together?)

 DP: Interesting. I had a not dissimilar idea that was a mix of the spray paint and masking tape. Kind of like those videos you sometimes see on the internet from street artists. I saw it as a VR game/experience. I can see how the dual sticks could work - makes me think a little of the game Baby Steps in that it could be quite awkward but you get used to it kind of way.


