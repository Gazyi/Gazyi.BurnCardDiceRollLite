untyped
global function OnWeaponPrimaryAttack_holopilot
global function PlayerCanUseDecoy

global const int DECOY_FADE_DISTANCE = 16000 //Really just an arbitrarily large number
global const float DECOY_DURATION = 10.0
global const float DECOY_MIMIC_DURATION = 20.0 // HoloMimic mod
global const vector HOLOPILOT_ANGLE_SEGMENT = < 0, 25, 0 >

#if SERVER
global function CodeCallback_PlayerDecoyDie
global function CodeCallback_PlayerDecoyDissolve
global function CodeCallback_PlayerDecoyRemove
global function CodeCallback_PlayerDecoyStateChange
global function CreateHoloPilotDecoys
global function SetupDecoy_Common

global function Decoy_Init

#if MP
global function GetDecoyActiveCountForPlayer
#endif //if MP
#endif //if server

struct
{
	table< entity, int > playerToDecoysActiveTable //Mainly used to track stat for holopilot unlock
	table< entity > playerDecoyList //CUSTOM used to track the decoy the user will be teleported to
	table< entity, float > playerDecoyActiveFrom //CUSTOM used to set decoy ability discharge
}
file

#if SERVER
void function Decoy_Init()
{
	#if MP
		RegisterSignal( "CleanupFXAndSoundsForDecoy" )
	#endif

	RegisterSignal( "StopAllRecordings" )
}

void function CleanupExistingDecoy( entity decoy )
{
	if ( IsValid( decoy ) ) //This cleanup function is called from multiple places, so check that decoy is still valid before we try to clean it up again
	{
		decoy.Decoy_Dissolve()
		CleanupFXAndSoundsForDecoy( decoy )
	}
}

void function CleanupFXAndSoundsForDecoy( entity decoy )
{
	if ( !IsValid( decoy ) )
		return

	decoy.Signal( "CleanupFXAndSoundsForDecoy" )

	if ( decoy.IsNPC() )
	{
		if ( "fxHandle" in decoy.s )
		{
			var fx = decoy.s.fxHandle
			expect entity( fx )
			
			if ( IsValid( fx ) )
			{
				fx.ClearParent()
				EffectStop( fx )
			}
		}

		decoy.s.fxHandle <- null

		StopSoundOnEntity( decoy, "holopilot_loop" )
		StopSoundOnEntity( decoy, "holopilot_loop_enemy" )
	}
	else
	{
		if ( "spectreProxy" in decoy.s )
		{
			if ( decoy.s.spectreProxy != null )
			{
				entity spectreProxy = expect entity( decoy.s.spectreProxy )
				if ( IsValid( spectreProxy ) )
				{
					spectreProxy.Dissolve( ENTITY_DISSOLVE_CHAR, Vector( 0, 0, 0 ), 500 )
				}
			}
		}
		
		foreach( fx in decoy.decoy.fxHandles )
		{
			if ( IsValid( fx ) )
			{
				fx.ClearParent()
				EffectStop( fx )
			}
		}

		decoy.decoy.fxHandles.clear() //probably not necessary since decoy is already being cleaned up, just for throughness.

		foreach ( loopingSound in decoy.decoy.loopingSounds )
		{
			StopSoundOnEntity( decoy, loopingSound )
		}

		decoy.decoy.loopingSounds.clear()
	}
}

void function OnHoloPilotDestroyed( entity decoy )
{
	EmitSoundAtPosition( TEAM_ANY, decoy.GetOrigin(), "holopilot_end_3P" )

	entity bossPlayer = decoy.GetBossPlayer()
	if ( IsValid( bossPlayer ) )
	{
		if (bossPlayer in file.playerDecoyList)
		{
			if ( decoy == file.playerDecoyList[ bossPlayer ] )
				delete file.playerDecoyList[ bossPlayer ]
		}

		if ( bossPlayer in file.playerDecoyActiveFrom )
			delete file.playerDecoyActiveFrom[ bossPlayer ]

		EmitSoundOnEntityOnlyToPlayer( bossPlayer, bossPlayer, "holopilot_end_1P" )
	}

	CleanupFXAndSoundsForDecoy( decoy )
}

void function CodeCallback_PlayerDecoyDie( entity decoy, int currentState ) //All Die does is play the death animation. Eventually calls CodeCallback_PlayerDecoyDissolve too
{
	//PrintFunc()
	OnHoloPilotDestroyed( decoy )
}

void function CodeCallback_PlayerDecoyDissolve( entity decoy, int currentState )
{
	//PrintFunc()
	OnHoloPilotDestroyed( decoy )
}


void function CodeCallback_PlayerDecoyRemove( entity decoy, int currentState )
{
	//PrintFunc()
}


void function CodeCallback_PlayerDecoyStateChange( entity decoy, int previousState, int currentState )
{
	//PrintFunc()
}

#endif


var function OnWeaponPrimaryAttack_holopilot( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	Assert( weaponOwner.IsPlayer() )

	if ( !PlayerCanUseDecoy( weaponOwner ) )
		return 0

	#if SERVER
	array<string> mods = weapon.GetMods()
	// Holopilot Shift
	if ( weapon.HasMod( "bc_holoshift" ) )
	{
		if ( weaponOwner in file.playerDecoyList )
		{
			CreateHoloPilotDecoys( weaponOwner, 1, "bc_holoshift" )
			entity decoy = file.playerDecoyList[ weaponOwner ]
			weapon.SetWeaponPrimaryClipCount( 0 )
			PlayerUsesHoloRewind( weaponOwner, decoy )

			if ( weaponOwner in file.playerDecoyActiveFrom )
				delete file.playerDecoyActiveFrom[weaponOwner]

			if (GetCurrentPlaylistName() == "lts")
			{
				if ( PlayerHasBattery(weaponOwner) )
					Rodeo_TakeBatteryAwayFromPilot( weaponOwner )
			}
		}
		else
		{
			entity decoy = CreateHoloPilotDecoys( weaponOwner, 1, "bc_holoshift" )
			file.playerDecoyList[ weaponOwner ] <- decoy
			
			//COMMUNICATION WITH HOLOTRACKER
			int eHandle = decoy.GetEncodedEHandle()
			ServerToClientStringCommand( weaponOwner, "ActivateDecoyTracking " + eHandle.tostring())
			//END OF COMMUNICATION
		}
	}
	// Holopilot Mimic
	else if ( weapon.HasMod( "bc_holomimic" ) )
	{
		entity decoy = CreateHoloPilotDecoys( weaponOwner, 1, "bc_holomimic" )
		thread MimicOwner( weaponOwner, decoy )
	}
	// Normal Holopilot
	else
		CreateHoloPilotDecoys( weaponOwner, 1 )
	#else
	Rumble_Play( "rumble_holopilot_activate", {} )
	#endif

	PlayerUsedOffhand( weaponOwner, weapon )

	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_min_to_fire )
}

#if SERVER
entity function CreateHoloPilotDecoys( entity player, int numberOfDecoysToMake = 1, string weaponMod = "" )
{
	Assert( numberOfDecoysToMake > 0  )
	Assert( player )

	player.Signal( "StopAllRecordings" )

	float displacementDistance = 30.0

	bool setOriginAndAngles = numberOfDecoysToMake > 1

	float stickPercentToRun = 0.65
	if ( setOriginAndAngles )
		stickPercentToRun = 0.0

	entity decoy

	for( int i = 0; i < numberOfDecoysToMake; ++i )
	{
		if ( weaponMod == "bc_holomimic" )
		{
			// Spectre camo check
			if ( "bc_spectre_camo" in player.s )
			{
				if ( player.s.bc_spectre_camo == true )
				{
					decoy = CreateSpectre( player.GetTeam(), player.GetOrigin(), player.GetAngles() )
				}
				else
				{
					decoy = CreateElitePilot( player.GetTeam(), player.GetOrigin(), player.GetAngles() )
					decoy.SetTitle( player.GetPlayerName() )
				}
			}
			else
			{
				decoy = CreateElitePilot( player.GetTeam(), player.GetOrigin(), player.GetAngles() )
				decoy.SetTitle( player.GetPlayerName() )
			}
			#if DEV
			printt( "Decoy mimic: ", decoy )
			#endif
			SetSpawnflags( decoy, ( SF_NPC_NO_PLAYER_PUSHAWAY | SF_NPC_ALLOW_SPAWN_SOLID | SF_NPC_ALTCOLLISION | SF_NPC_START_EFFICIENT ) )
			SetSpawnOption_OwnerPlayer( decoy, player )
			SetSpawnOption_Alert( decoy )
			// Setup decoy weapons
			array<entity> plWeapons = player.GetMainWeapons()
			int inactiveWeaponIndex = -1
			foreach ( index, weapon in plWeapons )
			{
				// No sidearms
				if ( index != 2 )
				{
					if ( weapon == player.GetActiveWeapon() )
					{
						SetSpawnOption_Weapon( decoy, weapon.GetWeaponClassName() )
						#if DEV
						printt( "Mimic current weapon: " + weapon.GetWeaponClassName() )
						#endif
					}
					else
					{
						// save index to setup after spawn
						inactiveWeaponIndex = index
					}
				}
				else
				{
					SetSpawnOption_Sidearm( decoy, weapon.GetWeaponClassName() )
					#if DEV
					printt( "Mimic sidearm: " + weapon.GetWeaponClassName() )
					#endif
					if ( weapon == player.GetActiveWeapon() )
					{
						// Set player primary weapon as spawn option
						SetSpawnOption_Weapon( decoy, plWeapons[0].GetWeaponClassName() )
					}
				}
			}
			decoy.SetScriptName( player.GetPlayerName() + "_decoy" )
			DispatchSpawn( decoy )
			if ( "bc_spectre_camo" in player.s )
			{
				if ( player.s.bc_spectre_camo != true )
				{
					decoy.SetModel( player.GetModelName() ) // Some of player models don't have NPC animations.
					// Non-Titan NPCs can't use camo! It'll always use first camo!
					decoy.SetSkin( player.GetSkin() )
					decoy.SetCamo( player.GetCamo() )
					#if DEV
					printt( "Decoy Skin:", decoy.GetSkin(), "Decoy Camo:", decoy.GetCamo() )
					#endif
				}
			}
			else
			{
				decoy.SetModel( player.GetModelName() )
				// Non-Titan NPCs can't use camo! It'll always use first camo!
				decoy.SetSkin( player.GetSkin() )
				decoy.SetCamo( player.GetCamo() )
				#if DEV
				printt( "Decoy Skin:", decoy.GetSkin(), "Decoy Camo:", decoy.GetCamo() )
				#endif
			}
			decoy.kv.VisibilityFlags = ENTITY_VISIBLE_TO_NOBODY
			decoy.Minimap_Hide( TEAM_MILITIA, null )
			decoy.Minimap_Hide( TEAM_IMC, null )
			decoy.SetHologram()
			decoy.EnableNPCFlag( NPC_NO_PAIN | NPC_NO_GESTURE_PAIN | NPC_NO_WEAPON_DROP | NPC_IGNORE_ALL | NPC_DISABLE_SENSING )
			decoy.SetCapabilityFlag( bits_CAP_WEAPON_RANGE_ATTACK1 | bits_CAP_AIM_GUN, false )
			decoy.EnableNPCMoveFlag( NPCMF_PREFER_SPRINT )
			decoy.SetBehaviorSelector( "behavior_soldier" )
			decoy.GiveWeapon( plWeapons[inactiveWeaponIndex].GetWeaponClassName() )
			thread KillAfterTimeout( DECOY_MIMIC_DURATION, decoy, player )
		}		
		else
		{
			decoy = player.CreatePlayerDecoy( stickPercentToRun )
			decoy.EnableAttackableByAI( 50, 0, AI_AP_FLAG_NONE )
			decoy.SetTimeout( DECOY_DURATION )
		}

		decoy.SetMaxHealth( 50 )
		decoy.SetHealth( 50 )
		SetObjectCanBeMeleed( decoy, true )

		if ( weaponMod == "bc_holoshift" )
			file.playerDecoyActiveFrom[player] <- Time()

		if ( setOriginAndAngles )
		{
			vector angleToAdd = CalculateAngleSegmentForDecoy( i, HOLOPILOT_ANGLE_SEGMENT )
			vector normalizedAngle = player.GetAngles() +  angleToAdd
			normalizedAngle.y = AngleNormalize( normalizedAngle.y ) //Only care about changing the yaw
			decoy.SetAngles( normalizedAngle )

			vector forwardVector = AnglesToForward( normalizedAngle )
			forwardVector *= displacementDistance
			decoy.SetOrigin( player.GetOrigin() + forwardVector ) //Using player origin instead of decoy origin as defensive fix, see bug 223066
			PutEntityInSafeSpot( decoy, player, null, player.GetOrigin(), decoy.GetOrigin() )
		}

		SetupDecoy_Common( player, decoy )

		#if MP
		thread MonitorDecoyActiveForPlayer( decoy, player )
		#endif
	}

	#if BATTLECHATTER_ENABLED
		PlayBattleChatterLine( player, "bc_pHolo" )
	#endif

	return decoy
}

void function SetupDecoy_Common( entity player, entity decoy ) //functioned out mainly so holopilot execution can call this as well
{
	decoy.SetDeathNotifications( true )
	decoy.SetPassThroughThickness( 0 )
	decoy.SetNameVisibleToOwner( true )
	decoy.SetNameVisibleToFriendly( true )
	decoy.SetNameVisibleToEnemy( true )
	if ( !decoy.IsNPC() )
	{	
		decoy.SetDecoyRandomPulseRateMax( 0.5 ) //pulse amount per second
	}
	decoy.SetFadeDistance( DECOY_FADE_DISTANCE )

	int friendlyTeam = decoy.GetTeam()
	EmitSoundOnEntityToTeam( decoy, "holopilot_loop", friendlyTeam  ) //loopingSound
	EmitSoundOnEntityToEnemies( decoy, "holopilot_loop_enemy", friendlyTeam  ) ///loopingSound

	if ( !decoy.IsNPC() )
		decoy.decoy.loopingSounds = [ "holopilot_loop", "holopilot_loop_enemy" ]

	Highlight_SetFriendlyHighlight( decoy, "friendly_player_decoy" )
	Highlight_SetOwnedHighlight( decoy, "friendly_player_decoy" )
	decoy.e.hasDefaultEnemyHighlight = true
	SetDefaultMPEnemyHighlight( decoy )

	int attachID = decoy.LookupAttachment( "CHESTFOCUS" )

	#if MP
	var childEnt = player.FirstMoveChild()
	while ( childEnt != null )
	{
		expect entity( childEnt )

		bool isBattery = false
		bool createHologram = false
		switch( childEnt.GetClassName() )
		{
			case "item_titan_battery":
			{
				isBattery = true
				createHologram = true
				break
			}

			case "item_flag":
			{
				createHologram = true
				break
			}
		}

		// first launched holopilot will not have a battery in LTS 
		if ( GetCurrentPlaylistName() == "lts" )
		{
			if ( !( player in file.playerDecoyList ) )
			{
				if ( isBattery )
					createHologram = false;
			}
		}

		asset modelName = childEnt.GetModelName()
		if ( createHologram && modelName != $"" && childEnt.GetParentAttachment() != "" )
		{
			entity decoyChildEnt = CreatePropDynamic( modelName, <0, 0, 0>, <0, 0, 0>, 0 )
			decoyChildEnt.Highlight_SetInheritHighlight( true )
			decoyChildEnt.SetParent( decoy, childEnt.GetParentAttachment() )

			if ( isBattery )
				thread Decoy_BatteryFX( decoy, decoyChildEnt )
			else
				thread Decoy_FlagFX( decoy, decoyChildEnt )
		}

		childEnt = childEnt.NextMovePeer()
	}
	#endif // MP

	entity holoPilotTrailFX = StartParticleEffectOnEntity_ReturnEntity( decoy, HOLO_PILOT_TRAIL_FX, FX_PATTACH_POINT_FOLLOW, attachID )
	SetTeam( holoPilotTrailFX, friendlyTeam )
	holoPilotTrailFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_FRIENDLY

	if ( decoy.IsNPC() )
	{
		decoy.s.fxHandle <- holoPilotTrailFX
	}
	else
	{
		if ( "bc_spectre_camo" in player.s )
		{
			if ( player.s.bc_spectre_camo == true )
			{
				// Can't change model after decoy spawn - it doesn't play current animation.
				//decoy.SetModel( $"models/robots/spectre/imc_spectre.mdl" )
				entity follower = CreatePropDynamic( $"models/robots/spectre/imc_spectre.mdl", decoy.GetOrigin(), decoy.GetAngles() )
				follower.SetParent( decoy, "REF" )
				follower.SetBoneMerge( decoy )
				follower.MarkAsNonMovingAttachment()
				follower.RemoveFromSpatialPartition()
				follower.Highlight_SetInheritHighlight( true )
				#if DEV
				printt( "Decoy ID: ", decoy, " Dummy model ID: ", follower )
				#endif
				decoy.s.spectreProxy <- follower
				//decoy.SetTitle( "#NPC_SPECTRE" ) // Doesn't work.
				decoy.Hide()
			}
		}
		
		decoy.decoy.fxHandles.append( holoPilotTrailFX )
		decoy.SetFriendlyFire( false )
		decoy.SetKillOnCollision( false )
	}
}

vector function CalculateAngleSegmentForDecoy( int loopIteration, vector angleSegment )
{
	if ( loopIteration == 0 )
		return < 0, 0, 0 >

	if ( loopIteration % 2 == 0  )
		return ( loopIteration / 2 ) * angleSegment * -1
	else
		return ( ( loopIteration / 2 ) + 1 ) * angleSegment

	unreachable
}

#if MP
void function Decoy_BatteryFX( entity decoy, entity decoyChildEnt )
{
	decoy.EndSignal( "OnDeath" )
	decoy.EndSignal( "CleanupFXAndSoundsForDecoy" )
	Battery_StartFX( decoyChildEnt )

	OnThreadEnd(
		function() : ( decoyChildEnt )
		{
			Battery_StopFX( decoyChildEnt )
			if ( IsValid( decoyChildEnt ) )
				decoyChildEnt.Destroy()
		}
	)

	WaitForever()
}

void function Decoy_FlagFX( entity decoy, entity decoyChildEnt )
{
	decoy.EndSignal( "OnDeath" )
	decoy.EndSignal( "CleanupFXAndSoundsForDecoy" )

	SetTeam( decoyChildEnt, decoy.GetTeam() )
	entity flagTrailFX = StartParticleEffectOnEntity_ReturnEntity( decoyChildEnt, GetParticleSystemIndex( FLAG_FX_ENEMY ), FX_PATTACH_POINT_FOLLOW, decoyChildEnt.LookupAttachment( "fx_end" ) )
	flagTrailFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY

	OnThreadEnd(
		function() : ( flagTrailFX, decoyChildEnt )
		{
			if ( IsValid( flagTrailFX ) )
				flagTrailFX.Destroy()

			if ( IsValid( decoyChildEnt ) )
				decoyChildEnt.Destroy()
		}
	)

	WaitForever()
}

void function MonitorDecoyActiveForPlayer( entity decoy, entity player )
{
	if ( player in file.playerToDecoysActiveTable )
		++file.playerToDecoysActiveTable[ player ]
	else
		file.playerToDecoysActiveTable[ player ] <- 1

	decoy.EndSignal( "OnDestroy" ) //Note that we do this OnDestroy instead of the inbuilt OnHoloPilotDestroyed() etc functions so there is a bit of leeway after the holopilot starts to die/is fully invisible before being destroyed
	player.EndSignal( "OnDestroy" )

	OnThreadEnd(
	function() : ( player )
		{
			if( IsValid( player ) )
			{
				Assert( player in file.playerToDecoysActiveTable )
				--file.playerToDecoysActiveTable[ player ]
			}
		}
	)

	WaitForever()
}

int function GetDecoyActiveCountForPlayer( entity player )
{
	if ( !(player in file.playerToDecoysActiveTable ))
		return 0

	return file.playerToDecoysActiveTable[player ]
}
#endif // MP
#endif // SERVER

bool function PlayerCanUseDecoy( entity ownerPlayer ) //For holopilot and HoloPilot Nova. No better place to put this for now
{
	if ( !ownerPlayer.IsZiplining() )
	{
		if ( ownerPlayer.IsTraversing() )
			return false

		if ( ownerPlayer.ContextAction_IsActive() ) //Stops every single context action from letting decoy happen, including rodeo, melee, embarking etc
			return false
	}

	//Do we need to check isPhaseShifted here? Re-examine when it's possible to get both Phase and Decoy (maybe through burn cards?)
	if ( ownerPlayer.IsPhaseShifted() )
		return false

	// Holoshift checks
	entity weapon = ownerPlayer.GetOffhandWeapon( OFFHAND_SPECIAL )
	if ( weapon.GetWeaponClassName() == "mp_ability_holopilot" && weapon.HasMod( "bc_holoshift" ) )
	{
		if ( !(ownerPlayer in file.playerDecoyList) && weapon.GetWeaponPrimaryClipCount() < weapon.GetWeaponPrimaryClipCountMax() )
			return false
	}

	return true
}

#if SERVER
void function PlayerUsesHoloRewind( entity player, entity decoy )
{
	thread PlayerUsesHoloRewindThreaded( player, decoy )
}

void function PlayerUsesHoloRewindThreaded( entity player, entity decoy )
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )

	decoy.EndSignal("OnDestroy")
	decoy.EndSignal("OnDeath")

	entity mover = CreateScriptMover( player.GetOrigin(), player.GetAngles() )
	player.SetParent( mover, "REF" )

	table decoyData = {}
	decoyData.forceCrouch <- TraceLine
								( decoy.GetOrigin(), 
								decoy.GetOrigin() + < 0,0,80 >, // 40 is crouched pilot height! add additional 40 for better check
								[ decoy ], 
								TRACE_MASK_SHOT, 
								TRACE_COLLISION_GROUP_NONE 
								).hitEnt != null // decoy will stuck, need to forceCrouch player
	OnThreadEnd
	(
		function() : ( player, mover, decoy, decoyData )
		{
			if ( IsValid( player ) )
			{
				player.SetOrigin(decoy.GetOrigin())
				player.SetAngles(decoy.GetAngles())
				player.SetVelocity(decoy.GetVelocity())
				CancelPhaseShift( player )
				player.DeployWeapon()
				player.SetPredictionEnabled( true )
				player.ClearParent()
				ViewConeFree( player )
				if( decoyData.forceCrouch )
					thread HoloRewindForceCrouch( player ) // this will handle "UnforceCrouch()"
			}

			if ( IsValid( mover ) )
				mover.Destroy()

			if ( IsValid( decoy ) )
				CleanupExistingDecoy(decoy)
		}
	)

	vector initial_origin = player.GetOrigin()
	vector initial_angle = player.GetAngles()

	ViewConeZero( player )
	player.HolsterWeapon()
	player.SetPredictionEnabled( false )
	if( decoyData.forceCrouch )
		player.ForceCrouch() // avoid stucking!
	PhaseShift( player, 0.0, PHASE_REWIND_MAX_SNAPSHOTS * PHASE_REWIND_PATH_SNAPSHOT_INTERVAL * 1.5 )
	//printt( "initial_angle:", initial_angle )

	for ( float i = PHASE_REWIND_MAX_SNAPSHOTS; i > 0; i-- )
	{
		initial_origin -= (initial_origin - decoy.GetOrigin())*(1/i)
		vector decoy_angles = decoy.GetAngles()	
		float yaw = decoy_angles.y
		yaw %= 360
		initial_angle -= (initial_angle - <decoy_angles.x, yaw, decoy_angles.z>)*(1/i)
		//initial_angle -= (initial_angle - decoy.GetAngles())*(1/i)
		//printt( "NEW initial_angle:", initial_angle )
		//printt( "Decoy angles:", decoy.GetAngles() )
		mover.NonPhysicsMoveTo( initial_origin, PHASE_REWIND_PATH_SNAPSHOT_INTERVAL, 0, 0 )
		mover.NonPhysicsRotateTo( initial_angle, PHASE_REWIND_PATH_SNAPSHOT_INTERVAL, 0, 0 )
		wait PHASE_REWIND_PATH_SNAPSHOT_INTERVAL
	}

	mover.NonPhysicsMoveTo( decoy.GetOrigin(), PHASE_REWIND_PATH_SNAPSHOT_INTERVAL, 0, 0 )
	mover.NonPhysicsRotateTo( decoy.GetAngles(), PHASE_REWIND_PATH_SNAPSHOT_INTERVAL, 0, 0 )
	player.SetVelocity( decoy.GetVelocity() )
}

void function HoloRewindForceCrouch( entity player )
{
	// make player crouch
	player.ForceCrouch()
	wait 0.2 // magic number, player must be completely crouched to avoid auto-stand
	if( IsValid( player ) )
		player.UnforceCrouch()
}

void function MimicOwner( entity player, entity decoy )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "StopAllRecordings" )
	player.EndSignal( "PlayerEmbarkedTitan" )

	decoy.EndSignal("OnDestroy")
	decoy.EndSignal("OnDeath")
	
	entity ref = CreateScriptMover( player.GetOrigin() )

	OnThreadEnd
	(
		function() : ( ref, player, decoy )
		{
			if ( IsValid( decoy ) )
			{
				decoy.Freeze()
				TakeAllWeapons( decoy )
				decoy.Dissolve( ENTITY_DISSOLVE_CHAR, Vector( 0, 0, 0 ), 500 )
			}
				
			if ( IsValid( player ) )
				player.StopRecordingAnimation()

			ref.Destroy()

			if ( IsValid( player ) )
			{
				if( player in file.playerDecoyList )
				{
					if( decoy == file.playerDecoyList[player] )
						delete file.playerDecoyList[player]
				}
				EmitSoundOnEntityOnlyToPlayer( player, player, "holopilot_end_1P" )	
			}
		}
	)

	player.StartRecordingAnimation( ref.GetOrigin(), ref.GetAngles() )
	wait 0.5

	var rec = player.StopRecordingAnimation()
	decoy.PlayRecordedAnimation( rec, <0,0,0>, <0,0,0>, DEFAULT_SCRIPTED_ANIMATION_BLEND_TIME, ref )
	decoy.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE

	while( true )
	{		
		if ( IsPilot( player ) )
		{
			player.StartRecordingAnimation( ref.GetOrigin(), ref.GetAngles() )
			entity CurWeapon = player.GetActiveWeapon()
			wait 0.5

			var recording = player.StopRecordingAnimation()
			decoy.PlayRecordedAnimation( recording, <0,0,0>, <0,0,0>, DEFAULT_SCRIPTED_ANIMATION_BLEND_TIME, ref )

			if ( IsValid( CurWeapon ) )
			{
				if ( CurWeapon.GetWeaponClassName() != decoy.GetActiveWeapon().GetWeaponClassName() )
				{
					if ( HasWeapon( decoy, CurWeapon.GetWeaponClassName() ) )
					{
						decoy.SetActiveWeaponByName( CurWeapon.GetWeaponClassName() )
					}
					else
					{
						if ( !( CurWeapon.IsWeaponOffhand() ) && ( CurWeapon.GetWeaponClassName().find( "mp_titanweapon_" ) == null ) )
						{
							decoy.TakeWeaponNow( decoy.GetActiveWeapon().GetWeaponClassName() )
							decoy.GiveWeapon( CurWeapon.GetWeaponClassName() )
						}
					}
				}
			}
		}
		else
		{
			wait 0.5
		}
	}
}

void function KillAfterTimeout( float time, entity decoy, entity player )
{
	decoy.EndSignal("OnDestroy")
	decoy.EndSignal("OnDeath")
	
	wait time
	player.Signal( "StopAllRecordings" )
}
#endif