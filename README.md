# Fast's ULX Custom Commands
[ULX](https://github.com/TeamUlysses/ulx) is an admin mod for [Garry's Mod](http://garrysmod.com/).
This is a command expansion pack for ULX.

## Requirements
[ULX](https://github.com/TeamUlysses/ulx) is obviously needed to run these commands, along with its main dependency [ULib](https://github.com/TeamUlysses/ulib).<br>
Also, the command for rating players requires [SUI Scoreboard](https://github.com/ZionDevelopers/sui-scoreboard) to have visible effects.

## Installation

### Just put this repository in your server's addons folder—simple and easy. &nbsp;After you have all the dependencies, restart the server and it should be good to go!

## Commands & Usage
### Meta Commands
- <b>ulx purge</b> ("!purge")<br>
&ensp;Purges command echo backlog. &ensp;Useful for cleaning up administrating gone-wrong.<br>
&ensp;All will still be visible in `data/ulx_logs`.

- <b>ulx serialize</b> ("!serialize") `<command>`<br>
&ensp;Lets you target multiple players with commands that only accept one, eg `!return *`.<br>
&ensp;While this *should* work with most commands, I can't guarantee it will work for *all*. &nbsp;Please be careful.<br>
&ensp;Commands ran through serialize are ran as the caller to prevent privilege escalation.
&ensp;<table><tr><td>**WARNING: People can do things like `!serialize !ban * 0 I am a serial killer!` with this!**<br>*Be very careful granting this to people with ban access!*</td></tr></table>

- <b>ulx swepify</b> ("!swepify") `<command>`<br>
&ensp;Packages ULX commands into SWEPs. &nbsp;It works best with the `@` selector, which targets players under your crosshair.<br>
&ensp;The SWEPs can be dropped with right mouse and will self-destruct if their creator leaves the server.
&ensp;<table><tr><td>**WARNING: Swepify guns execute with the same permissions as the person who created them!**<br>*Don't give your `!ban @ 0` gun to little timmy, or he can ban people with it!*</td></tr></table>

### Everything Else
- <b>ulx scare</b> ("!scare") `<players>` `<damage: default 0>`<br>
&ensp;Slaps target(s) with the stalker scream sound and inflicts damage.

- <b>ulx desync, ulx resync</b> ("!desync","!resync") `<players>`<br>
&ensp;Desynchronizes target(s) from their body, causing many strange effects.

- <b>ulx void</b> ("!void") `<players>`<br>
&ensp;Sends target(s) to the void. &nbsp;Returning to the map from the void is very difficult, but theoretically possible.

- <b>ulx rate</b> ("!rate") `<player>` `<rating>` `<amount: default 1>`<br>
&ensp;Modifies a player's SUI Scoreboard ratings. &nbsp;Negative amounts take away ratings.

- <b>ulx lag</b> ("!lag") `<players>`<br>
&ensp;Causes target(s) to rubberband before dying spectacularly.

- <b>ulx maxphyspeed</b> ("!maxphyspeed") `<speed: default = dynamic*>`<br>
&ensp;Sets the engine's max speed for physics objects.<br>
&ensp;*The default value of `speed` will change whenever something other than this command modifies it

- <b>ulx maxangspeed</b> ("!maxangspeed") `<speed: default = dynamic*>`<br>
&ensp;Sets the engine's max rotational speed for physics objects.<br>
&ensp;*The default value of `speed` will change whenever something other than this command modifies it

- <b>ulx setspot</b> ("!setspot") `<name>`<br>
&ensp;Sets a restart-persistent, map-specific spot players can teleport to.<br>

- <b>ulx removespot</b> ("!removespot") `<name>`<br>
&ensp;Removes a previously set spot.<br>

- <b>ulx spots</b> ("!spots") `<search term: default = "">`<br>
&ensp;Lists the names of all spots that include the give search term. &nbsp;Provide nothing to list them all.<br>

- <b>ulx spot</b> ("!spot") `<name: default = random>` `<player, defaults to self>`<br>
&ensp;Teleports the target to the previously set spot. &nbsp;Use the 'random' spot to choose randomly from all spots.<br>

- <b>ulx websound</b> ("!websound") `<url>`<br>
&ensp;Plays the sound at the provided URL to all players.<br>
&ensp;URL must link directly to a file! &nbsp;YouTube, Spotify, and SoundCloud links will not work!<br>
&ensp;Due to technical reasons, this is also rather difficult to use from console.

- <b>ulx shitaim</b> ("!shitaim","!unshitaim") `<players>`<br>
&ensp;Causes all bullets fired by target(s) to stray about 15 degrees away from their crosshair in random directions.<br>
&ensp;Good for shutting down aimbots.<br>

- <b>ulx ripears</b> ("!ripears","!asmr") `<players>`<br>
&ensp;Exposes target(s) to very loud sound until stopped with !asmr.<br>
&ensp;Prolonged exposure should really be avoided; this may actually harm players at full volume.<br>

- <b>ulx botbomb</b> ("!botbomb") `<player>`<br>
&ensp;Airstrikes the target with a bot. &nbsp;The bot explodes when it lands and will kill the target if it lands on them.<br>
&ensp;The bot has <i>some</i> airstrafing capabilities but will probably miss if dropped on a moving target.

- <b>ulx fakedc</b> ("!fakedc") `<target, defaults to self>`<br>
&ensp;Calls disconnect hook logic for the target to fake them leaving the server.<br>
&ensp;Use on yourself to juke minges and make them think you left the server!

- <b>ulx fakeban</b> ("!fakeban") `<player>` `[<minutes, 0 for perma: 0<=x, default 0>]` `[{reason}]`<br>
&ensp;An improved fake ban that also fakes the victim disconnecting.<br>
&ensp;Best used with '0' minutes and a petty ban reason.<br>

- <b>ulx ragmaul</b> ("!ragmaul") `<target>` `<attacker, defaults to self>`<br>
&ensp;Mauls the target with the attacker's ragdoll.<br>
&ensp;Will automatically ragdoll and unragdoll the attacker if they aren't already.<br>

- <b>ulx prop</b> ("!prop") `<players>` `<string>`<br>
&ensp;Turns target(s) into inanimate objects.<br>
&ensp;Destructable props make this command more fun.<br>

- <b>ulx blocktool</b> ("!blocktool") `<players>` `<tool class>`<br>
&ensp;Blocks a tool for the target(s).
&ensp;Written by StyledStrike.

## Bonus Improvements
- Deaths now set your "previous location" so you can `ulx return` to it.
- Ragdolls created by `ulx ragdoll` now inherit player colors correctly.

## Workshop Links to Dependencies
 - [ULX](http://steamcommunity.com/sharedfiles/filedetails/?id=557962280) | `557962280`
 - [ULib](http://steamcommunity.com/sharedfiles/filedetails/?id=557962238) | `557962238`
 - [SUI Scoreboard v2 w/UTime](https://steamcommunity.com/sharedfiles/filedetails/?id=160121673) | `160121673` (other versions of SUI scoreboard can also be used)
 
## Credits
ULX is brought to you by...

* Brett "Megiddo" Smith - Contact: <mailto:megiddo@ulyssesmod.net>
* JamminR - Contact: <mailto:jamminr@ulyssesmod.net>
* Stickly Man! - Contact: <mailto:sticklyman@ulyssesmod.net>
* MrPresident - Contact: <mailto:mrpresident@ulyssesmod.net>
