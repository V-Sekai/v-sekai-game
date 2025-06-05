class_name SarGameMode
extends Node

## This class defines for a game mode to be used with the game session manager.
## A game mode is a set of rules which define the desired gameflow behaviour
## such as how players should be spawned at during a session. It can further
## be expanded with any abitrary game logic and rules since it can encompass
## a whole scene.

var _game_session_manager: SarGameSessionManager = null

###

## Returns the game session manager connected to this game mode.
func get_game_session_manager() -> SarGameSessionManager:
	return _game_session_manager
