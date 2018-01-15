#  UnDecidedProgram

Simple test project for an online game, to explore and demonstrate the basic functionality:

- Networking using UDP (to avoid latency)
- User management
- server-side validation of all client-side actions
- multi-player

Not all of this is implemented yet.

## Things that are known to be incomplete at this time

- Our passwords list is a name/password list in plain text on the hard disk. Should be salted hashes instead.
- We don't encrypt the connection yet. Should probably have a public key on the server that the client encrypts the first request with, which contains a public key for the replies, and then include another key in the reply from the server. That way both the password in the first request as well as the session token in all subsequent requests can't easily be extracted and used to fake requests.
- We don't deal with dropped packets right now. We should include sequence numbers and at least detect when we missed something, and maybe at first just add the ability to re-send full game state in that case. Alternately, we could try to make messages more structured so we can re-send them with updated information (e.g. a "player's position" packet being re-sent should contain the new position, not a position from 2 seconds ago that may be outdated already)

## Things to work out

Data transmission is well and good, but as a good example, it would probably be worth it to implement mechanisms for other common features:

- Switching animations in response to actions. Some of these depend on server-side state. "Player dead" for example should override all other animations, or a shopkeeper NPC's action loop), but on the other hand, a "reach out for this object" animation should probably be done by the client, even if the server will indicate in its reply what animation to play. Similarly, when a player moves, we'd want the movement between position changes the server reports to be a transition including the walk animation appropriate for the speed and distance, but if the player is on a ladder, the server should be able to override the walk animation.
- Reliable message delivery: This is useful both for an in-game mail system and for mission rewards. Some way to keep a list of messages on the server for each user, and a way for the client to query what messages are available and to retrieve their table of contents and/or mark them as read. Should probably also allow "attachments" (also used for mission rewards) that the user can have moved to their inventory. These messages would have game-defined types (like e-mail, mission completion, crafting result), which the client can use to display them differently (e.g. in a "read mail" window, or in a crafting queue, or a mission rewards popup. They'd also have a delivery date, and optionally a display filter (so e.g. mission reward windows can insert the player name into lore, or mission follow-up e-mails can include different parts of a message depending on your story decisions/class).
 - Inventory for each player, split into public (i.e. weapons and clothes other players can see them wearing) as well as private.
 - File downloads/asset updates: The client should be able to get assets from the server and keep them up-to-date. Maybe even self-update. Could probably be done by the server sending a UDP message containing a URL and one of a number of predefined engine locations (e.g. assets folder, maps folder, codex folder), then downloading and extracting the files from there. Or we could just send chunks of such a file via our UDP protocol as well, that would save us from including libcurl or wrapping platform-specific download code.
 - Do we keep this in ObjC? Since part of this will run on a server, tempted to do a core in C++ and just do the UI, rendering and audio in ObjC.
 - I do want to actually make a game with this. So the code should probably consist of attachment points and plug-ins more than actual code so I can implement my game in a project that just uses this engine, while keeping this example simple enough for people to follow, and the engine suitable for various kinds of games. The core would be MMO-like as above, but any more complex interactions could be implemented with the basic mechanisms we already have (e.g. crafting could be "destroy the crafting ingredients and schedule a reliable message for delivery in 2 hours that has the crafted item attached")
 
 ## License
 
 Copyright 2018 by Uli Kusterer.
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 
 3. This notice may not be removed or altered from any source
 distribution.


 
