extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	change_scene_to_file("res://scenes/boss_victory_portal.tscn")
	await process_frame
	await process_frame
	var scene := current_scene
	scene.set_process(false)
	var tape: Node3D = scene.get_node("TapeSource")
	var shadow: Node3D = scene.get_node("Shadow")
	var portal: Node3D = scene.get_node("Portal")
	assert(tape.visible and tape.get_node("Tape_Rig | pose Tape_Master").visible)
	assert(not tape.get_node("Player | Runner_Rig controls").visible)
	assert(shadow.visible and absf(shadow.rotation.x - PI / 2.0) < 0.01, "Shadow lies on the ground")
	assert(scene.get_node("Boombox").find_children("*", "MeshInstance3D", true, false).size() > 0)
	assert(root.get_node("MusicDirector").current_track == 3)
	scene._process(3.6)
	var rig: Skeleton3D = scene.player_actor.skeleton
	var hand := rig.find_bone("Hand.L")
	var hand_position: Vector3 = (rig.global_transform * rig.get_bone_global_pose(hand)).origin
	assert(hand_position.distance_to(tape.global_position) < 1.5, "Player reaches toward the repaired tape")
	scene._process(1.1)
	assert(not tape.visible, "The fixed tape goes into the boombox")
	scene._process(2.5)
	assert(portal.scale.x > 0.9, "The portal opens")
	scene._process(1.2)
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://scenes/final_ending.tscn", "Portal cutscene leads to final ending")
	print("BOSS VICTORY PORTAL: passed")
	quit()
