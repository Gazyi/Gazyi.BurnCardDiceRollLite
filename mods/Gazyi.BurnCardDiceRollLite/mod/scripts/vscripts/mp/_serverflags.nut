untyped

globalize_all_functions

function GiveServerFlag( player, passive )
{
	if ( !( player.serverFlags & passive ) )
	{
		player.serverFlags = player.serverFlags | passive
	}

	// enter/exit functions for specific passives
	switch ( passive )
	{
	}
}

function GiveServerFlagLifeLong( player, passive )
{
	if ( PlayerHasServerFlag( player, passive ) )
		return

	if ( !( "bc_serverflags" in player.s ) )
	{
		player.s.bc_serverflags <- 0
	}

	GiveServerFlag( player, passive )
	player.s.bc_serverflags = player.s.bc_serverflags | passive
}

function TakeServerFlag( player, passive )
{
	if ( !PlayerHasServerFlag( player, passive ) )
		return

	player.serverFlags = player.serverFlags & ( ~passive )

	// enter/exit functions for specific passives
	switch ( passive )
	{
	}

}

bool function PlayerHasServerFlag( player, passive )
{
	return bool( player.serverFlags & passive )
}
