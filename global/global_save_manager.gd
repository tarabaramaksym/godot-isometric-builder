extends Node

# Path for saving building data
const SAVE_DIR = "user://saves/"
const BUILDINGS_FILENAME = "buildings.save"

# Initialize save directory
func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# Save all buildings to disk
func save_buildings(buildings_data: Array):
	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	# Open the file
	var file = FileAccess.open(SAVE_DIR + BUILDINGS_FILENAME, FileAccess.WRITE)
	if file:
		file.store_var(buildings_data)
	else:
		print("Failed to save buildings data")

# Load buildings from disk
func load_buildings() -> Array:
	if not FileAccess.file_exists(SAVE_DIR + BUILDINGS_FILENAME):
		return []
	
	var file = FileAccess.open(SAVE_DIR + BUILDINGS_FILENAME, FileAccess.READ)
	if file:
		var data = file.get_var()
		if data is Array:
			return data
	
	return []

# Add a single building to the saved buildings
func add_building(building_data: Dictionary):
	var buildings = load_buildings()
	buildings.append(building_data)
	save_buildings(buildings)

# Clear all saved buildings
func clear_buildings():
	save_buildings([]) 