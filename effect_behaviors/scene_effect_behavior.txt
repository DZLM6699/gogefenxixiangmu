class_name SceneEffectBehavior
extends Node

var _entity_spawner_ref: EntitySpawner
var _wave_manager: WaveManager


func init(entity_spawner_ref: EntitySpawner, wave_manager: WaveManager) -> SceneEffectBehavior:
	_entity_spawner_ref = entity_spawner_ref
	_wave_manager = wave_manager
	return self
