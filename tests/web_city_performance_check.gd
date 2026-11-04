extends SceneTree

const Progress = preload("res://scripts/city_progress.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Progress.reset()
	var city := load(Progress.HUB).instantiate() as Node3D
	root.add_child(city)
	await process_frame
	await process_frame
	var facades := city.find_children("FacadeStrips", "MultiMeshInstance3D", true, false)
	var boundaries := city.find_children("CityBoundary*", "StaticBody3D", false, false)
	var lights := city.find_children("*", "OmniLight3D", false, false)
	var meshes := city.find_children("*", "MeshInstance3D", true, false)
	var strips := 0
	for facade in facades: strips += facade.multimesh.instance_count
	assert(facades.size() >= 40, "City facades stay batched by building")
	assert(strips > 400, "Batched facades retain the city windows")
	assert(boundaries.size() == 54, "City boundary collisions remain intact")
	assert(lights.size() <= 10, "Streetlights stay within the Web light budget")
	assert(city.cinematic.far <= 500, "Cinematic camera has bounded draw distance")
	var skyline := city.get_node("NeonWorld")
	assert(skyline._districts.size() >= 8, "Skyline still surrounds the route")
	assert(skyline.find_children("TowerCollision*", "StaticBody3D", true, false).size() > 30, "Skyscraper collisions remain intact")
	print("WEB CITY PERFORMANCE CHECK: %d strips in %d batches, %d boundary colliders, %d local lights, %d mesh nodes" % [strips, facades.size(), boundaries.size(), lights.size(), meshes.size()])
	quit()
