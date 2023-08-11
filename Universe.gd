extends Node2D

var world_x = 150	
var world_y = 150
var tile_map
var storage_dict = {}
var iterations = 0
var iteration_label
var mouse_on_button = false
# Called when the node enters the scene tree for the first time.
func _ready():
	var center_tile = Vector2i(world_x / 2, world_y / 2)
	var center_coord = $TileMap.map_to_local(center_tile)
	print(center_coord)
	$Camera2D.position = center_coord
	tile_map = $TileMap
	iteration_label = $CanvasLayer/IterationLabel
	var cursor = Vector2i.ZERO
	if Global.start_with_cool_border == true:
		draw_cool_border()

func draw_cool_border():
	#set the border
	var border_cursor = Vector2i.ZERO
	#top border
	for x in world_x:
		tile_map.set_cell(0,Vector2i(x, 1), 0, Vector2i.ZERO, 0)
	#left border
	for y in world_y:
		tile_map.set_cell(0,Vector2i(1, y), 0, Vector2i.ZERO, 0)
	#bottom border
	for x in world_x:
		tile_map.set_cell(0,Vector2i(x, world_y-1), 0, Vector2i.ZERO, 0)
	#right border
	for y in world_y:
		tile_map.set_cell(0,Vector2i(world_x-1, y), 0, Vector2i.ZERO, 0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if $StepTimer.is_stopped():
			$StepTimer.start()
#			check_cells()
#			clear_cells()
		elif !$StepTimer.is_stopped():
			$StepTimer.stop()
	if Input.is_action_just_pressed("click") && mouse_on_button == false:
		if $StepTimer.is_stopped():
			var global_mouse = get_global_mouse_position()
			var cell_mouse = tile_map.local_to_map(global_mouse)
			if tile_map.get_cell_tile_data(0,cell_mouse,false) == null:
				tile_map.set_cell(0,Vector2i(cell_mouse.x, cell_mouse.y), 0, Vector2i.ZERO, 0)
#				cell_check.set_custom_data("on", true)
				return
			if tile_map.get_cell_tile_data(0,cell_mouse, false) != null:
				tile_map.set_cell(0,Vector2i(cell_mouse.x, cell_mouse.y), -1, Vector2i.ZERO, 0)
#				cell_check.set_custom_data("on", false)
				return
	if Input.is_action_just_pressed("faster"):
		$StepTimer.wait_time -= .05
		$CanvasLayer/SpeedLabel.text = "Speed: "+ str($StepTimer.wait_time)
	if Input.is_action_just_pressed("slower"):
		$StepTimer.wait_time += .05
		$CanvasLayer/SpeedLabel.text = "Speed: "+ str($StepTimer.wait_time)

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
		
func check_cells():
	iterations += 1
	iteration_label.text = "Iteration # " + str(iterations)
	var step_cursor = Vector2i.ZERO
	for y in world_y:
		for x in world_x:
			#temp neighbor count for this cell. gets set at the end
			var neighbor_count : int = 0
			#check top left
			var search_cursor_tl =  step_cursor + Vector2i(-1, -1)
			if tile_map.get_cell_tile_data(0, search_cursor_tl, false) != null:
				neighbor_count += 1
			#check top
			var search_cursor_t =  step_cursor + Vector2i(0, -1)
			if tile_map.get_cell_tile_data(0, search_cursor_t, false) != null:
				neighbor_count += 1
			#check top right
			var search_cursor_tr =  step_cursor + Vector2i(1, -1)
			if tile_map.get_cell_tile_data(0, search_cursor_tr, false) != null:
				neighbor_count += 1
			#check right
			var search_cursor_r =  step_cursor + Vector2i(1, 0)
			if tile_map.get_cell_tile_data(0, search_cursor_r, false) != null:
				neighbor_count += 1
			#check bottom right
			var search_cursor_br =  step_cursor + Vector2i(1, 1)
			if tile_map.get_cell_tile_data(0, search_cursor_br, false) != null:
				neighbor_count += 1
			#check bottom
			var search_cursor_b =  step_cursor + Vector2i(0, 1)
			if tile_map.get_cell_tile_data(0, search_cursor_b, false) != null:
				neighbor_count += 1
			#check bottom left
			var search_cursor_bl =  step_cursor + Vector2i(-1, 1)
			if tile_map.get_cell_tile_data(0, search_cursor_bl, false) != null:
				neighbor_count += 1
			#check left
			var search_cursor_l =  step_cursor + Vector2i(-1, 0)
			if tile_map.get_cell_tile_data(0, search_cursor_l, false) != null:
				neighbor_count += 1
			storage_dict[step_cursor] = {"neighbors":neighbor_count}
			step_cursor.x += 1
		step_cursor.x = 0
		step_cursor.y += 1

func _on_step_timer_timeout():
	check_cells()
	clear_cells()

func clear_cells():
	var kill_cursor = Vector2i.ZERO
	for y in world_y:
		for x in world_x:
			var num_neighbors = storage_dict[kill_cursor].get('neighbors')
			if $TileMap.get_cell_tile_data(0,kill_cursor, false) != null  && num_neighbors < 2:
				tile_map.set_cell(0,kill_cursor, -1, Vector2i.ZERO,0)
			elif $TileMap.get_cell_tile_data(0,kill_cursor, false) != null  && num_neighbors > 3:
				tile_map.set_cell(0,kill_cursor, -1, Vector2i.ZERO,0)
			elif $TileMap.get_cell_tile_data(0,kill_cursor, false) == null  && num_neighbors == 3:
				tile_map.set_cell(0,kill_cursor, 0, Vector2i.ZERO,0)
			kill_cursor.x += 1
		kill_cursor.x = 0
		kill_cursor.y += 1	
	storage_dict.clear()



func _on_border_button_pressed():
	Global.start_with_cool_border = true
	get_tree().reload_current_scene()


func _on_empty_button_pressed():
	Global.start_with_cool_border = false
	get_tree().reload_current_scene()


func _on_run_button_pressed():
	if $StepTimer.is_stopped():
		$StepTimer.start()
		$CanvasLayer/RunButton.text = "Stop"
	elif !$StepTimer.is_stopped():
		$StepTimer.stop()
		$CanvasLayer/RunButton.text = "Start"

func _on_h_slider_value_changed(value):
	$StepTimer.wait_time = value
	$CanvasLayer/SpeedLabel.text = "Speed: " + str($StepTimer.wait_time)


func _on_panel_mouse_entered():
	mouse_on_button = true


func _on_panel_mouse_exited():
	mouse_on_button = false
