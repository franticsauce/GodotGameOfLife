extends Node2D

var tile_map
var tile_map2
var storage_dict = {}
var storage_dict2 = {}
var iterations = 0
var total_iterations = 0
var iteration_label
var mouse_on_button = false
var step_timer
var ips = 0 
var ips_timer
var ips_label
var thread : Thread
var clear_thread : Thread
var world_y = Global.world_y
var world_x = Global.world_x
var mean_snag = 0
var mean_snag_count = 0

func _ready():
	var path = ProjectSettings.globalize_path("user://")
	randomize()
	var center_tile = Vector2i(Global.world_x / 2, Global.world_y / 2)
	var center_coord = $TileMap.map_to_local(center_tile)
	$Camera2D.position = center_coord
	ips_label = $CanvasLayer/FPSLabel
	ips_timer = $IPSTimer
	tile_map = $TileMap
	tile_map2 = $TileMap
	iteration_label = $CanvasLayer/IterationLabel
	step_timer = $StepTimer
	var setup_cursor = Vector2i.ZERO
	$CanvasLayer/SizeField.text = str(Global.world_x)
	var cursor = Vector2i.ZERO
	if Global.start_with_cool_border == true:
		draw_cool_border()

func _on_step_timer_timeout():
#	check_cells() #first version, unthreaded, slightly slower
	check_cells_threaded() #best method so far.
#	check_cells_crispy() # the well written check loop that runs at half speed compared to the shitty one
	clear_cells()

func check_cells_threaded():
	iterations += 1
	total_iterations += 1
	iteration_label.text = "Iteration # " + str(total_iterations)
	#start thread to check bottom half
	thread_tester()
	#check top half
	var step_cursor = Vector2i.ZERO
	for y in Global.world_y / 2:
		for x in Global.world_x:
			#temp neighbor count for this cell. gets set at the end
			var neighbor_count : int = 0
			#check top left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, -1), false) != -1:
				neighbor_count += 1
			#check top
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(0, -1), false) != -1:
				neighbor_count += 1
			#check top right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, -1), false) != -1:
				neighbor_count += 1
			#check right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, 0), false) != -1:
				neighbor_count += 1
			#check bottom right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, 1), false) != -1:
				neighbor_count += 1
			#check bottom
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(0, 1), false) != -1:
				neighbor_count += 1
			#check bottom left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, 1), false) != -1:
				neighbor_count += 1
			#check left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, 0), false) != -1:
				neighbor_count += 1
			storage_dict[step_cursor] = {"neighbors":neighbor_count}
			step_cursor.x += 1
		step_cursor.x = 0
		step_cursor.y += 1
	
	
func thread_tester():
	thread = Thread.new()
	if thread.is_alive():
		return
	thread.start(thread_activity.bind("userdata"), 1)

func thread_activity(userdata):
	var CODETIME = Time.get_ticks_msec()
	var thread_cursor = Vector2i(0,(world_y/2))
	for y in (world_y / 2):
		for x in world_x:
			#temp neighbor count for this cell. gets set at the end
			var neighbor_count2 : int = 0
			#check top left
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(-1, -1), false) != -1:
				neighbor_count2 += 1
			#check top
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(0, -1), false) != -1:
				neighbor_count2 += 1
			#check top right
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(1, -1), false) != -1:
				neighbor_count2 += 1
			#check right
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(1, 0), false) != -1:
				neighbor_count2 += 1
			#check bottom right
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(1, 1), false) != -1:
				neighbor_count2 += 1
			#check bottom
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(0, 1), false) != -1:
				neighbor_count2 += 1
			#check bottom left
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(-1, 1), false) != -1:
				neighbor_count2 += 1
			#check left
			if tile_map2.get_cell_source_id(0, thread_cursor + Vector2i(-1, 0), false) != -1:
				neighbor_count2 += 1
			storage_dict2[thread_cursor] = {"neighbors":neighbor_count2}
			thread_cursor.x += 1
		thread_cursor.x = 0
		thread_cursor.y += 1
	mean_snag = mean_snag + Time.get_ticks_msec()-CODETIME
	mean_snag_count += 1
	if mean_snag_count >= 100:
		var new_mean = mean_snag / 100
		print("Bottom half thread averaging " + str(new_mean) + "ms")
		mean_snag = 0
		mean_snag_count = 0

func clear_cells():
	thread.wait_to_finish()
#	storage_dict.merge(storage_dict2) - checking everything in one fuction seems to be faster than merging?
#	clear_bottom_thread() #trying to add a thread to the clearing function would constantly crash after 5-20 iterations
	var kill_cursor = Vector2i.ZERO
	var kill_cursor2 = Vector2i(0, (world_y / 2))
	for y in world_y / 2:
		for x in world_x:
			var num_neighbors = storage_dict[kill_cursor].get('neighbors')
			if tile_map.get_cell_source_id(0, kill_cursor, false) != -1  && num_neighbors < 2:
				set_cell(false,kill_cursor)
			elif tile_map.get_cell_source_id(0, kill_cursor, false) != -1  && num_neighbors > 3:
				set_cell(false,kill_cursor)
			elif tile_map.get_cell_source_id(0, kill_cursor, false) == -1  && num_neighbors == 3:
				set_cell(true,kill_cursor)
			kill_cursor.x += 1
		kill_cursor.x = 0
		kill_cursor.y += 1
	for y in (world_y / 2):
		for x in world_x:
			var num_neighbors2 = storage_dict2[kill_cursor2].get('neighbors')
			if tile_map2.get_cell_source_id(0, kill_cursor2, false) != -1  && num_neighbors2 < 2:
				set_cell(false, kill_cursor2)
			elif tile_map2.get_cell_source_id(0, kill_cursor2, false) != -1  && num_neighbors2 > 3:
				set_cell(false, kill_cursor2)
			elif tile_map2.get_cell_source_id(0, kill_cursor2, false) == -1  && num_neighbors2 == 3:
				set_cell(true, kill_cursor2)
			kill_cursor2.x += 1
		kill_cursor2.x = 0
		kill_cursor2.y += 1	
#	clear_thread.wait_to_finish()

func set_cell(is_on, position):
	if position.x > world_x || position.y > world_y:
		return
	if is_on:
		tile_map.set_cell(0,position, 0, Vector2i.ZERO, 0)
	elif !is_on:
		tile_map.set_cell(0,position, -1, Vector2i.ZERO, 0)

func _on_ips_timer_timeout():
	ips = iterations
	ips_label.text = "IPS: " + str(ips)
	iterations = 0

func _physics_process(delta):
	if Input.is_action_pressed("click") && mouse_on_button == false:
		if step_timer.is_stopped():
			var global_mouse = get_global_mouse_position()
			var cell_mouse = tile_map.local_to_map(global_mouse)
			if tile_map.get_cell_tile_data(0,cell_mouse,false) == null:
				set_cell(true, cell_mouse)
				return
			if tile_map.get_cell_tile_data(0,cell_mouse, false) != null:
				set_cell(false, cell_mouse)
				return

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$Camera2D.zoom += Vector2(.1, .1)
				$Camera2D.position = get_global_mouse_position()
		# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$Camera2D.zoom -= Vector2(.1, .1)
				$Camera2D.position = get_global_mouse_position()
			# call the zoom function

# the unused old checking functions
func check_cells_crispy():
	#this much more well written check cells function runs at about half the speed as the crusty one
	iterations += 1
	total_iterations += 1
	iteration_label.text = "Iteration # " + str(total_iterations)
	var step_cursor = Vector2i.ZERO
	for i in Global.world_y:
		for o in Global.world_x:
			var neighbor_count = 0
			for x in range(-1, 2):
				for y in range(-1, 2):
					if not (x == 0 and y == 0):
						if tile_map.get_cell_source_id(0, step_cursor + Vector2i(x, y), false) != -1:
							neighbor_count += 1
					storage_dict[step_cursor] = {"neighbors":neighbor_count}
			step_cursor.x += 1
		step_cursor.x = 0
		step_cursor.y += 1

func check_cells():
	iterations += 1
	total_iterations += 1
	iteration_label.text = "Iteration # " + str(total_iterations)
	var step_cursor = Vector2i.ZERO
	for y in Global.world_y:
		for x in Global.world_x:
			#temp neighbor count for this cell. gets set at the end
			var neighbor_count : int = 0
			#check top left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, -1), false) != -1:
				neighbor_count += 1
			#check top
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(0, -1), false) != -1:
				neighbor_count += 1
			#check top right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, -1), false) != -1:
				neighbor_count += 1
			#check right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, 0), false) != -1:
				neighbor_count += 1
			#check bottom right
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(1, 1), false) != -1:
				neighbor_count += 1
			#check bottom
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(0, 1), false) != -1:
				neighbor_count += 1
			#check bottom left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, 1), false) != -1:
				neighbor_count += 1
			#check left
			if tile_map.get_cell_source_id(0, step_cursor + Vector2i(-1, 0), false) != -1:
				neighbor_count += 1
			storage_dict[step_cursor] = {"neighbors":neighbor_count}
			step_cursor.x += 1
		step_cursor.x = 0
		step_cursor.y += 1

func draw_cool_border():
	var border_cursor = Vector2i.ZERO
	#top border
	for x in Global.world_x:
		set_cell(true, Vector2i(x, 1))
#		tile_map.set_cell(0,Vector2i(x, 1), 0, Vector2i.ZERO, 0)
	#left border
	for y in Global.world_y:
		set_cell(true, Vector2i(1, y))
#		tile_map.set_cell(0,Vector2i(1, y), 0, Vector2i.ZERO, 0)
	#bottom border
	for x in Global.world_x:
		set_cell(true, Vector2i(x, Global.world_y-1))
#		tile_map.set_cell(0,Vector2i(x, Global.world_y-1), 0, Vector2i.ZERO, 0)
	#right border
	for y in Global.world_y:
		set_cell(true, Vector2i(Global.world_x-1, y))
#		tile_map.set_cell(0,Vector2i(Global.world_x-1, y), 0, Vector2i.ZERO, 0)

#--- these are the fuctions for the threading of the clearing method, didn't work.
func clear_bottom_thread():
	clear_thread = Thread.new()
	if clear_thread.is_alive():
		return
	clear_thread.start(clear_cells_bottom.bind("funky"), 1)

func clear_cells_bottom(userdata):
	var kill_cursor2 = Vector2i(0, (world_y / 2) + 1)
	for y in (world_y / 2):
		for x in world_x:
			var num_neighbors2 = storage_dict2[kill_cursor2].get('neighbors')
			if tile_map2.get_cell_source_id(0, kill_cursor2, false) != -1  && num_neighbors2 < 2:
				set_cell(false, kill_cursor2)
			elif tile_map2.get_cell_source_id(0, kill_cursor2, false) != -1  && num_neighbors2 > 3:
				set_cell(false, kill_cursor2)
			elif tile_map2.get_cell_source_id(0, kill_cursor2, false) == -1  && num_neighbors2 == 3:
				set_cell(true, kill_cursor2)
			kill_cursor2.x += 1
		kill_cursor2.x = 0
		kill_cursor2.y += 1	


# UI stuff
func _on_border_button_pressed():
	Global.start_with_cool_border = true
	get_tree().reload_current_scene()

func _on_empty_button_pressed():
	Global.start_with_cool_border = false
	get_tree().reload_current_scene()

func _on_run_button_pressed():
	if $StepTimer.is_stopped():
		$StepTimer.start()
		ips_timer.start()
		$CanvasLayer/RunButton.text = "Stop"
	elif !$StepTimer.is_stopped():
		$StepTimer.stop()
		ips_timer.stop()
		$CanvasLayer/RunButton.text = "Start"

func _on_h_slider_value_changed(value):
	$StepTimer.wait_time = value
	$CanvasLayer/SpeedLabel.text = "Speed: " + str($StepTimer.wait_time)

func _on_panel_mouse_entered():
	mouse_on_button = true

func _on_panel_mouse_exited():
	mouse_on_button = false

func _on_size_field_text_submitted(new_text):
	var new_size = new_text.to_int()
	Global.world_x = new_size
	Global.world_y = new_size
	get_tree().reload_current_scene()

func _on_cam_button_pressed():
	var image = get_viewport().get_texture().get_image()
	image.save_png("user://" + str(int(randf_range(1,500))) + ".png")

func _on_file_button_pressed():
	$CanvasLayer/CamPanel/FileDialog.visible = true

func _on_file_dialog_confirmed():
	OS.shell_open($CanvasLayer/CamPanel/FileDialog.current_path)
