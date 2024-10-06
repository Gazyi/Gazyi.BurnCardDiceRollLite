# Gazyi.BurnCardDiceRollLite
Server-side* Northstar mod that adds more effects for Dice Roll boost.

* Some HUD-related stuff ( icons, cooldown ) can be out of sync without client installation. Clients can either install and enable this mod, or servers can disable boosts that have this problem.

## Requirements
- [**MultiLanguageStrings**](https://github.com/Gazyi/Gazyi.MultiLanguageStrings)

## List of custom boosts
* TF1 Burn Cards - Stealth
* - Active Camo - Replaces Pilot Tactical Ability with longer lasting Cloak.
* - Ghost Squad - Permanently cloaked as a Pilot, in addition to having your Pilot Tactical Ability.
* TF1 Burn Cards - Speed
* - Smuggled Stimulant - Replaces Pilot Tactical Ability with longer lasting Stim.
* - Adrenaline Transfusion - Permanently stimmed as a Pilot, in addition to having your Pilot Tactical Ability.
* - Prosthetic Legs - Faster Pilot movement speed.
* TF1 Burn Cards - Intel
* - Packet Sniffer - You automatically generate Sonar Pulses periodically.
* - Satellite Uplink - Reveal all enemies on the minimap every 10 seconds.
* - Spider Sense - There is an audible warning when enemy players are nearby.
* - Double Agent - Grunts, Spectres, Auto-Titans, and Turrets ignore you.
* - Conscription - Nearby friendly Grunts fight for you - their kills count toward your score.
* - WI-FI Virus - Automatically hack nearby enemy Spectres.
* - Spectre Camo - You are a Spectre.
* TF1 Burn Cards - Misc
* - Rematch - Respawn where you died.
* TF1 Burn Cards - Bonus
* - Decisive Action - Adds 15% to Titan Meter or Titan Core Charge.
* - Pull Rank - Adds 30% to Titan Meter or Titan Core Charge.
* - Thin the Ranks - Titan Meter earned from killing Grunts is increased by 100%.
* - Urban Renewal - Titan Meter earned from killing Spectres is increased by 100%.
* - Most Wanted List - Titan Meter earned from killing Pilots is increased by 100%.
* - Titan Salvage - Titan Meter earned from damaging Titans is increased by 10%.
* - Outsource - Titan Meter earned during combat is increased by 100%.
* TF1 Burn Cards - Titan related
* - Turbo Engine - Your Titan will have increased Dash Capacity.
* - Super Charger - Your Titan has a pre-charged Titan Core ability.
* - Massive Payload - Your Titan Eject causes an extended nuclear explosion.
* - Titan Amped Weapons - Permanent Amped Titan weapons and abilities.
* Custom - Weapons
* - Amped Smart Pistol - Replaces Primary Weapon with Smart Pistol MK6. Limited Ammo.
* - TWIN-B Shotgun - Replaces Primary Weapon with short Double-Barreled Shotgun.
* - Carpet Bomb - Permanent Amped Pilot Ordnance.
* - Arc Trap - Replaces Ordnance Weapon with infinite Arc Traps.
* Custom - Pilot Abilities
* - Amped Pulse Blade - Replaces Pilot Tactical Ability with longer lasting Pulse Blade.
* - Pulse Blade Jammer - Replaces Pilot Tactical Ability with Pulse Blade with radar jammer.
* - Holoshift - Replaces Pilot Tactical Ability with special Holo Pilot. Pilot can swap position with your decoy.
* - Holomimic - Replaces Pilot Tactical Ability with special Holo Pilot. Decoys mimic your movement.
* - Amped Phase Shift - Replaces Pilot Tactical Ability with longer lasting Phase Shift.
* - Long Grapple - Replaces Pilot Tactical Ability with longer Grapple.
* - Attack on Titanfall - Replaces Pilot Tactical Ability with Grapple with more charges.
* - Phase Lifesaver - Activate Phase Rewind when Pilot is on the verge of death.
* - Phase Lifesaver - Activate Phase Shift when Pilot is on the verge of death.
* - Mobile Hard Cover - Creates mobile Hard Cover in front of Pilot.
* - Mobile A-Wall - Creates mobile Amped Wall in front of Pilot.
* Custom - Titan related
* - Regen Booster - Your Titan is able to regenerate its bodyshield at a faster rate than normal.
* - Emergency Titan - Summon your Emergency Titan with Warpfall kit. Titan has halved health and no core.
* - Rodeo Express - Friendly Pilots riding your Titan will have Amped Weapons.
* - Arc Field - Your Titan generates an electrical field capable of draining shields.
* Custom - Support NPCs
* - Support Squad - Summon a Grunt squad to fight on your behalf.
* - Support Squad - Summon a Spectre squad to fight on your behalf.
* - Support Squad - Summon a Stalker squad to fight on your behalf.
* - Reaperfall - Summon a Reaper to fight on your behalf.
* - Cloak Drone - Summon a Cloak Drone follower.

## Server ConVars
```
sv_bc_add_vanilla_boosts (Default value: 1) - Add vanilla boosts to random boost table. ConVar changes will be applied on next map.
sv_bc_replace_tactical_abilities (Default value: 1) - Add boosted Pilot tactical abilities to random boost table. They'll replace current Pilot ability. ConVar changes will be applied on next map. Note: Some abilities can show up incorrectly without installing mod on client side!
sv_bc_replace_pilot_weapons (Default value: 0) - Add custom Pilot weapons to random boost table. They'll replace current Pilot primary. ConVar changes will be applied on next map.
sv_bc_replace_titan_weapons (Default value: 0) - Add Amped Titan weapons to random boost table. ConVar changes will be applied on next map. Note: Many Titan weapons don't have burn mods and will not be Amped!
sv_bc_force_rtd_boost (Default value: 1) - All boosts will be converted to Dice Roll.
sv_bc_use_weights (Default value: 0) - Use weights when calculating random boost. Default weights are 1 for all boosts, you need to modify script to change them.
sv_bc_announce_boost (Default value: 1) - Create server announcements for rolled boosts.
sv_bc_autouse_deployable (Default value: 1) - Automatically throw ordinance and place turrets on boost use.
sv_bc_npc_drone_cloak_self (Default value: 1) - Cloak drones will cloak itself.
sv_bc_npc_drone_cloak_with_targets (Default value: 0) - Drone self-cloak behavior. 0 = Cloak itself when no cloak targets. 1 = Cloak itself when have cloak targets.
```