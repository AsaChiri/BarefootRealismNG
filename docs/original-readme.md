# Barefoot Realism

## Introduction

Prisoners and slaves are usually forced to go barefoot and this is true in the Elder Scrolls universe as well. Remember slaves in Morrowind or those prisoners dragged through Skyrim by the Thalmor?

I often start my roleplaying runs on the bottom of society, as a runaway slave/prisoner or a poor peasant and have always been upset at how it was way too unrealistic. Dressed in rags, barefoot and penniless, my character can run across Skyrim as fast as a shod one without any consequences and buy/sell items at normal prices without the merchants batting an eyelash. Whatever happened to no shoes, no service?

This mod tries to add a touch of realism to this experience. Feet now get dirtier (using SlaveTats) depending which surfaces the player has been walking on and can be washed by wading in a stream or using a spell. This isn't a cosmetic change, either: the player's speechcraft skill is affected by the dirtiness of their feet. There's also an option for merchants to refuse service to barefoot characters in cheap clothing or all barefoot characters.

A kidnapped noble girl with pampered feet now won't be able to run away from those bandits easily. Every surface has a different roughness level which influences the chances to step on something nasty and stagger, stopping the character for a bit and alerting everyone to their presence. Worse even, just walking barefoot slowly accumulates feet pain, slowing the player down. The pain heals slowly over time, but don't expect to be able to walk even from Riverwood to Whiterun without moderate pain by the end of the trip.

Luckily, the character's feet will get tougher over time and at higher levels the player will be able to even sprint across gravel without letting out so much as a whimper. Feet toughness decays over time, though, so it may well be back to square one after a year of shod life.

The only good side to this mod for now is that being barefoot adds 10 to the character's sneak skill.

Finally, ever wondered how those ZaZ/DD ankle irons managed to fit over your character's massive boots? There's also an option to unequip boots or shoes when the character's ankles are shackled. That barefoot fettered girl won't be able to just loot some boots off of a dead soldier to ease her ordeal.

All of this is powered by a highly customizable (via MCM) and slightly overengineered mess of exponential decay functions and thresholds.

This is a rather early version, so don't use it on saves that you value. I've been using it for a couple of years and decided to release it to the world since it mostly seems to work, but I've only added MCM customization recently, so it could be broken.

This mod isn't really gender-specific, but I've only tested the dirty feet SlaveTats textures on female feet.

## Installation and requirements

Requirements:

  * SKSE
  * SkyUI
  * SlaveTats

Installation:

Copy the files to your Skyrim/Data directory or use Mod Organizer. There's nothing really specific about the installation and there's no FNIS required for now.

Upgrading:

Likely requires a clean save. Note your player attributes (globals PlayerFeetDirtiness, PlayerFeetRoughness and PlayerFeetPain), uninstall the mod, load-save the game, install the new version and reapply the global values.

## Advanced details

This is the maths that powers the mod. I'll also describe the effect of the default settings. You don't really need to read this, unless you want to customize your experience.

Barefoot Realism adds 3 parameters/skills to the player, all ranging from 0 to 1: feet dirtiness, roughness and pain. They're stored in 3 globals: PlayerFeetDirtiness, PlayerFeetRoughness and PlayerFeetPain and are the only bits of player state. You can modify them with console commands to back them up if you are going to delete the mod, for example.

### Dirtiness

Barefoot Realism can detect the surface the player is walking/running on, which lets different surfaces have different dirtiness levels. In addition, BR also detects the location type the player's in. The reasoning behind this is that a stone floor in someone's house will be much cleaner than the stone floor in a random dungeon.

Here are the default surface dirtiness levels:

  * Stone: 0.2
  * Dirt: 0.4
  * Mud: 1.0
  * Wood: 0.2
  * Grass: 0.3
  * Snow: 0.1
  * Carpet: 0.05
  * Gravel: 0.2
  * Water: -5.0

The default location dirtiness multipliers are:

  * Home (any owned interior): 1.0
  * Mines/prisons (dungeons with "Mine"/"Prison" in the name): 1.5
  * City (exterior): 2.0
  * Other dungeons: 2.0
  * Wilderness: 2.5
  
The total surface dirtiness is

    surface dirtiness * location dirtiness multiplier
    
In addition, if it's raining, the dirtiness is multiplied by 2.

The feet dirtiness tends to the total surface dirtiness: it's logical that the player's feet won't get dirtier than the actual surface the character's walking on.

    Dirtiness per step = (total surface dirtiness - feet dirtiness) * multiplier

If the feet are dirtier than the ground, the multiplier is 0.0005 and if they're cleaner, the multiplier is 0.001 (so accumulating dirt is faster than cleaning it off by walking on a clean surface).

The water dirtiness level is negative: the player can run around in some water sources (like the streams in Whiterun's Cloud District that they can still get to very often) to decrease feet dirtiness or use the Wash Feet spell near/in a body of water (waterfalls etc, the bodies are the same as defined in iNeed) to clear the dirtiness completely.

There are 5 spells draining Speechcraft and SlaveTats tattoos applied to the player's feet at different dirtiness levels: 0.0 (Speechcraft -10), 0.03 (-20), 0.1 (-30), 0.3 (-40), and 0.9 (-50).

### Roughness and pain

Different surfaces and location also have different roughness levels and again, to get the total roughness level, both are multiplied:

  * Stone: 0.4
  * Dirt: 0.2
  * Mud: 0.1
  * Wood: 0.2
  * Grass: 0.1
  * Snow: 0.5
  * Carpet: 0.05
  * Gravel: 0.6
  * Water: 0.05
  * Home: 0.1
  * Mines/prisons: 1.2
  * City: 1.0
  * Other dungeons: 1.5
  * Wilderness: 1.5

Feet pain accumulates per step as well. The formula is:

    pain multiplier * (total surface roughness / (feet roughness + 1)) ^ pain exponent

The default pain multiplier is 0.01 and the exponent is 4.

This might be a bit overengineered, but the idea is that the pain increase dramatically decreases when feet roughness is greater than the total surface roughness. Let's say the feet roughness is 0 and the player is walking around Whiterun (location roughness 1.0, surface roughness 0.4 for a total of 0.4). Then, with the default settings, the pain increase is 0.01 * (0.4 / (0 + 1)) ^ 4 = 0.000256 per step or 0.256 per thousand steps. If the roughness is 0.4, we get 0.01 * (0.4 / 1.4)^4; 0.067 per thousand steps. If the roughness is 1, we get 0.016,

Feet pain decays constantly at a default rate of 0.25 per game day. So at a roughness level of 0, a thousand steps around Whiterun will take a whole game day to clear and at a roughness level of 1, it will take about 1.5 hours to clear, presumably faster than accumulating them.

The feet roughness increases every step by a roughness multiplier (default 0.1) * the pain increase incurred. So by default, it accumulates 10 times slower than the pain. The roughness also decays at a default rate of 0.005 per game day (50 times faster the pain), so it will take 200 game days for fully trained feet to return to the 0 level.

### Stagger chance

Staggering by stepping on a pebble or a twig is a way to immediately slow down the player. It also emits a detection event, alerting enemies to the player's location. The stagger chance per every step is:

    stagger multiplier * e ^ (stagger exponent * feet roughness) * movement modifier * total surface roughness

The default stagger exponent, -4.6052, and the multiplier, 0.1, have been calibrated so that at feet roughness of 0 the stagger chance (before applying movement/surface modifiers) is 10% and at the roughness of 1 the stagger chance is 0.1%.

The movement modifier depends on whether the player is running (1.0), walking (default 0.25), sneaking (default 0.1) or sprinting (default 2.0).

With these defaults, a player running on a stone road (roughness 0.4) in the wilderness (roughness 1.5) will have a 6% chance of staggering every step (about every 15 steps). If she's sprinting, the chance becomes 12% (about every 8 steps). If she decides to save her feet and step off from the road into the dirt instead (roughness 0.2), she has a 3% chance of staggering (about every 33 steps) if running and 6% if walking.

## Changelog

## 0.8

  * Basic soft (no hard dependency required) Bathing In Skyrim support. I couldn't find a good way to hook into the BIS washing process, so currently the mod resets feet dirtiness to 0 whenever the BIS dirtiness global decreases (which only happens when the player washes). So if the player is clean and washes again, this won't reset the feet dirtiness -- but if the BIS dirtiness is >20% and the player washes, then it will.

## 0.7

  * Added a SEQ file. Apparently they're needed.
  * Removed innkeeper dialogue altogether, was conflicting with other mods and causing silent voice issues
  * Changed default snow/gravel pain to 0.5/0.6 from 0.7/1.0, making it much more manageable.

## 0.6

  * Bugfix: speed/barter damage spells now synchronize with the player pain/dirtiness stat always instead of only when the tattoo is supposed to be updated.
  * Bugfix: the dirtiness increase rate wasn't showing correctly because MCM was treating part of it as an HTML tag
  * Added MCM options to disable speed/damage barter spells.

## 0.5

  * Bugfix: DD leg iron detection
  * Removed DD and ZaP hard dependencies
  * Changed pain voices (a selection of files copied from SexLab and ZaZ Extension Pack), different for males and females.
  * Added a configuration option for the stagger chance multiplier
  * Wash Feet spell now more lenient (allow surfaces that the mod detects as water + don't require the player to be barefoot)
  * Bugfix: werewolves not considered to be barefoot
  * SlaveTats synchronization is now silent (No more "Please wait while SlaveTats works" messages)

## 0.4

Bugfixes.

  * Dialogue cleaning for the innkeepers/vendors. Bumped the dirt limit at which the innkeepers don't rent to 0.3 (to be consistent with the Very Dirty Feet debuff).
  * Terrain detection now only runs when the player is not sitting/riding a horse and is barefoot to minimize conflicts.
  * Make sure to refresh SlaveTats after using the Wash Feet spell.

## 0.3

  * Added an option to restrict the player from changing footwear during combat (similar to Requiem, but just for footwear)

## 0.2

  * Added MCM options to enable/disable stagger sounds
  * A single piece of footwear (like the DDx slave heels) can be set as barefoot (Miscellaneous -> Exceptions)
  * Correct vendor reaction for innkeepers (at "Low Clothing Value" mode, don't rent if feet dirtiness > 0.25)

## 0.1a

Initial version.
