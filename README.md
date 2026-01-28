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
