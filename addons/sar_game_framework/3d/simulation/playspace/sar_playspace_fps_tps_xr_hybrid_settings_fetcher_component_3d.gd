@tool
class_name SarPlayspaceFPSTPSHybridSettingsFetcherComponent3D
extends SarPlayspaceSettingsFetcherComponent3D

func _setting_updated(p_setting: String) -> bool:
	if not p_setting:
		return false
	
	match p_setting:
		# If we turn native physics interpolation on or off,
		# toggle our own custom XR physics interpolation for
		# playspace's camera base.
		"physics/common/physics_interpolation":
			if playspace is SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D:
				(playspace as SarPlayerSimulationFPSTPSXRHybridPlayspaceComponent3D).xr_use_physics_interpolation = ProjectSettings.get_setting(p_setting, false)
			return true
			
	return super._setting_updated(p_setting)
