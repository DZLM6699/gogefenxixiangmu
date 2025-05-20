extends Enemy

export (PackedScene) var enemy_to_spawn


func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)

	if args.cleaning_up:
		return

	var charmed_by = get_charmed_by_player_index()

	for i in 3:
		emit_signal("wanted_to_spawn_an_enemy", enemy_to_spawn, ZoneService.get_rand_pos_in_area(Vector2(global_position.x, global_position.y), 200), self, charmed_by)
