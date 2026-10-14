## Reads GameBackend.ending_result (set by GameBackend._end_game()) to decide which text/music to show.
##
## The ending plays like a film's closing credits:
##  * behind everything, a camera drifts over your town, past each place you
##    spent the year (home, school, the canteen, the exam hall, work, the dairy)
##  * the title holds for a few seconds, then everything rolls up slowly —
##    your year, photos from it, your results, where everyone ended up, and the
##    credits — timed so the roll finishes as the ending song does
##  * hold Space (or the mouse) to speed it up, scroll to look back
extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

const COL_GOOD := Color(0.42, 0.82, 0.55)
const COL_WARN := Color(0.95, 0.74, 0.32)
const COL_BAD := Color(0.90, 0.42, 0.42)
const COL_TEXT := Color(0.94, 0.94, 0.96)
const COL_DIM := Color(0.70, 0.72, 0.78)

const TOWN_SCENE := "res://Main_Game/Assets/JPCandsurroundingssprint1.glb"
const COLUMN_WIDTH: float = 820.0
const TITLE_HOLD: float = 4.5
const FALLBACK_SONG_SECONDS: float = 95.0

## Camera stops for the flyover: [camera position, what it looks at]. The
## first and last are high wide shots of the whole town; the rest are the
## places from the year (door positions from MainMap.tscn).
const FLYOVER := [
	[Vector3(31.5, 95.0, 70.0), Vector3(31.5, 0.0, -32.7)],
	[Vector3(0.0, 23.0, -8.0), Vector3(-22.8, 2.0, -35.8)],       # home
	[Vector3(13.0, 25.0, -42.0), Vector3(-13.9, 3.0, -65.8)],     # school
	[Vector3(-53.0, 20.0, -38.0), Vector3(-26.0, 2.0, -59.7)],    # canteen
	[Vector3(-35.0, 22.0, 10.0), Vector3(-59.5, 3.0, -16.9)],     # exam hall
	[Vector3(80.0, 23.0, 45.0), Vector3(107.0, 3.0, 16.5)],       # work
	[Vector3(74.0, 20.0, -50.0), Vector3(101.5, 2.0, -82.0)],     # the dairy
	[Vector3(31.5, 130.0, 50.0), Vector3(31.5, 0.0, -32.7)],
]

var _epilogue_label: RichTextLabel
var _accent: Color = COL_BAD
var _good_ending: bool = false

var _roll_area: Control
var _column: VBoxContainer
var _roll_y: float = 0.0
var _start_y: float = 0.0
## Seconds into the roll (title hold included), from the real clock so the
## roll keeps time with the song however slowly the 3D renders. Holding Space
## or the mouse adds extra time on top (_boost), and scrolling moves it.
var _roll_time: float = 0.0
var _boost: float = 0.0
var _clock_start: int = 0
var _last_tick: int = 0
var _fade: ColorRect
var _rolling: bool = false
var _finished: bool = false
var _hint: Label

var _cam: Camera3D
var _song_seconds: float = FALLBACK_SONG_SECONDS
var _elapsed: float = 0.0


func _ready() -> void:
	# If the year ended while something had the game paused, the ending must
	# still play.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Inventory.get_node("UI").hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_button.pressed.connect(_on_menu_pressed)

	var degree: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major

	#Headline -----------------------------------------------------------
	_accent = COL_BAD
	match GameBackend.ending_result:
		"scholarship":
			title_label.text = tr("END_SCHOLARSHIP")
			subtitle_label.text = tr("END_SUB_SCHOLARSHIP") % GameBackend.university_full_name()
			_accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"good":
			title_label.text = tr("END_ACCEPTED")
			subtitle_label.text = tr("END_SUB_GOOD") % GameBackend.university_full_name()
			_accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"student_loan":
			title_label.text = tr("END_ACCEPTED_LOAN")
			subtitle_label.text = tr("END_SUB_STUDENT_LOAN") % GameBackend.university_full_name()
			_accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"unfunded":
			title_label.text = tr("END_UNFUNDED")
			subtitle_label.text = tr("END_SUB_UNFUNDED") % GameBackend.university_full_name()
			_accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"deferred":
			title_label.text = tr("END_DEFERRED")
			subtitle_label.text = tr("END_SUB_DEFERRED")
			_accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"foundation_year":
			title_label.text = tr("END_FOUNDATION")
			subtitle_label.text = tr("END_SUB_FOUNDATION") % GameBackend.university_full_name()
			_accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"second_choice":
			title_label.text = tr("END_SECOND_CHOICE")
			subtitle_label.text = tr("END_SUB_SECOND_CHOICE") % GameBackend.university_full_name()
			_accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"no_ue":
			title_label.text = tr("END_NO_UE")
			subtitle_label.text = tr("END_SUB_NO_UE")
			_accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_sanity":
			title_label.text = tr("END_BURNOUT")
			subtitle_label.text = tr("END_SUB_BURNOUT")
			_accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_deadline":
			title_label.text = tr("END_REJECTION")
			subtitle_label.text = tr("END_SUB_REJECTION") % GameBackend.university_full_name()
			_accent = COL_BAD
			MusicManager.play_track("bad_ending")
		_:
			title_label.text = tr("END_YEAR_OVER")
			subtitle_label.text = tr("END_SUB_DEFAULT")
			MusicManager.play_track("bad_ending")
	_good_ending = _accent == COL_GOOD

	# Upper-case the first letter: "the University of Auckland offered you..." can open a sentence.
	subtitle_label.text = subtitle_label.text.substr(0, 1).to_upper() + subtitle_label.text.substr(1)
	title_label.add_theme_color_override("font_color", _accent)
	title_label.add_theme_font_size_override("font_size", 64)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(COLUMN_WIDTH - 60.0, 0)
	_shadow(title_label)
	_shadow(subtitle_label)

	_song_seconds = _current_song_length()
	_build_flyover()
	_build_shading()
	_build_roll(degree)
	_build_corner()
	# Black over everything until the roll is laid out and in place, then fade
	# in — otherwise the first frame or two shows the text before it's centred.
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 10
	add_child(_fade)
	_start_roll.call_deferred()


# =============================================================================
# THE 3D BACKGROUND
# =============================================================================

func _build_flyover() -> void:
	var holder := SubViewportContainer.new()
	holder.name = "Flyover"
	holder.stretch = true
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	move_child(holder, 1)   # just above the plain background colour

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	holder.add_child(vp)

	var world := Node3D.new()
	vp.add_child(world)

	if ResourceLoader.exists(TOWN_SCENE):
		var town = load(TOWN_SCENE)
		if town is PackedScene:
			world.add_child(town.instantiate())

	# A big ground plane, so the edge of the map never shows on the horizon.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4000, 4000)
	ground.mesh = plane
	ground.position = Vector3(31.5, -0.15, -32.7)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.27, 0.40, 0.24) if _good_ending else Color(0.20, 0.27, 0.22)
	gmat.roughness = 1.0
	ground.material_override = gmat
	world.add_child(ground)

	# Golden hour for the good endings, a cold dusk for the rest.
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	if _good_ending:
		sun.rotation_degrees = Vector3(-18.0, -35.0, 0.0)
		sun.light_color = Color(1.0, 0.80, 0.58)
		sun.light_energy = 1.25
	else:
		sun.rotation_degrees = Vector3(-10.0, 140.0, 0.0)
		sun.light_color = Color(0.62, 0.70, 0.92)
		sun.light_energy = 0.55
	world.add_child(sun)

	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	if _good_ending:
		sky_mat.sky_top_color = Color(0.32, 0.48, 0.78)
		sky_mat.sky_horizon_color = Color(1.0, 0.72, 0.52)
		sky_mat.ground_horizon_color = Color(0.85, 0.66, 0.50)
		sky_mat.ground_bottom_color = Color(0.25, 0.30, 0.22)
	else:
		sky_mat.sky_top_color = Color(0.08, 0.10, 0.20)
		sky_mat.sky_horizon_color = Color(0.42, 0.40, 0.52)
		sky_mat.ground_horizon_color = Color(0.36, 0.36, 0.44)
		sky_mat.ground_bottom_color = Color(0.12, 0.14, 0.16)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9 if _good_ending else 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	# Just enough haze to soften the far edge of the map.
	env.fog_light_color = sky_mat.sky_horizon_color.lerp(Color(0.8, 0.82, 0.88), 0.55)
	env.fog_light_energy = 0.7
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	_cam = Camera3D.new()
	_cam.far = 1500.0
	_cam.fov = 60.0
	world.add_child(_cam)
	_place_camera(0.0)


## Moves the camera to point `t` (0..1) of the flyover: a smooth curve through
## every stop, easing its gaze from one place to the next.
func _place_camera(t: float) -> void:
	if _cam == null:
		return
	var segs: int = FLYOVER.size() - 1
	var f: float = clampf(t, 0.0, 1.0) * segs
	var i: int = mini(int(f), segs - 1)
	var u: float = f - i
	var p0: Vector3 = FLYOVER[maxi(i - 1, 0)][0]
	var p1: Vector3 = FLYOVER[i][0]
	var p2: Vector3 = FLYOVER[i + 1][0]
	var p3: Vector3 = FLYOVER[mini(i + 2, segs)][0]
	var pos: Vector3 = p1.cubic_interpolate(p2, p0, p3, u)
	var look: Vector3 = (FLYOVER[i][1] as Vector3).lerp(FLYOVER[i + 1][1], smoothstep(0.0, 1.0, u))
	_cam.position = pos
	if not pos.is_equal_approx(look):
		_cam.look_at(look, Vector3.UP)


func _current_song_length() -> float:
	if MusicManager.music_player != null and MusicManager.music_player.stream != null:
		var len: float = MusicManager.music_player.stream.get_length()
		if len > 20.0:
			return len
	return FALLBACK_SONG_SECONDS


# =============================================================================
# THE ROLL
# =============================================================================

## Darkens the picture behind the text, and fades the top and bottom edges so
## lines drift in and out rather than being chopped off.
func _build_shading() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.40)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	move_child(shade, 2)
	# A soft darker band down the middle, behind the text column.
	var band_g := Gradient.new()
	band_g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	band_g.colors = PackedColorArray([Color(0.02, 0.03, 0.06, 0.0), Color(0.02, 0.03, 0.06, 0.38),
		Color(0.02, 0.03, 0.06, 0.38), Color(0.02, 0.03, 0.06, 0.0)])
	var band_tex := GradientTexture2D.new()
	band_tex.gradient = band_g
	band_tex.fill_from = Vector2(0.0, 0.5)
	band_tex.fill_to = Vector2(1.0, 0.5)
	var band := TextureRect.new()
	band.texture = band_tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_left = 0.5
	band.anchor_right = 0.5
	band.anchor_top = 0.0
	band.anchor_bottom = 1.0
	band.offset_left = -COLUMN_WIDTH * 0.85
	band.offset_right = COLUMN_WIDTH * 0.85
	add_child(band)
	move_child(band, 3)
	for top in [true, false]:
		var g := Gradient.new()
		g.set_color(0, Color(0.02, 0.03, 0.06, 0.92))
		g.set_color(1, Color(0.02, 0.03, 0.06, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill_from = Vector2(0.5, 0.0) if top else Vector2(0.5, 1.0)
		tex.fill_to = Vector2(0.5, 1.0) if top else Vector2(0.5, 0.0)
		var r := TextureRect.new()
		r.texture = tex
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_left = 0.0
		r.anchor_right = 1.0
		r.anchor_top = 0.0 if top else 0.82
		r.anchor_bottom = 0.18 if top else 1.0
		r.offset_left = 0
		r.offset_right = 0
		r.offset_top = 0
		r.offset_bottom = 0
		r.z_index = 1
		add_child(r)


func _build_roll(degree: String) -> void:
	_roll_area = Control.new()
	_roll_area.name = "Roll"
	_roll_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roll_area.clip_contents = true
	_roll_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_roll_area)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 14)
	_column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_area.add_child(_column)
	_column.modulate.a = 0.0

	# The headline from the scene file moves into the roll.
	var old_box: Control = $CenterContainer
	for l in [title_label, subtitle_label]:
		l.get_parent().remove_child(l)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_column.add_child(l)
	old_box.visible = false
	_gap(160)

	# 1. Your year
	_heading(tr("END_YOUR_YEAR"))
	_epilogue_label = _para(GameBackend.build_epilogue().replace("\n\n", "\n"))

	# 2. The year in pictures
	_add_memories()

	# 3. Why it went this way
	var reasons: Array = GameBackend.offer_reasons()
	if not reasons.is_empty():
		_heading(tr("END_WHY"))
		var lines: Array = []
		for r in reasons:
			lines.append("•  " + str(r))
		_para("\n".join(lines))

	# 4. Results
	_heading(tr("END_RESULTS"))
	var res: Array = []
	res.append("%s  —  %s" % [GameBackend.university_full_name(), GameBackend.major_name(degree) if degree != "" else tr("END_NO_PROGRAMME")])
	for subject in GameBackend.active_subjects:
		var d: Dictionary = GameBackend.subject_result_detail(subject)
		var band: String = tr("NCEA_NOT_YET_SAT")
		if not d.externals.is_empty():
			var e: Dictionary = d.externals[0]
			band = GameBackend.band_name(str(e.band)) if e.taken else tr("NCEA_ABSENT")
		res.append(tr("END_SUBJECT_LINE") % [GameBackend.subject_name(str(subject)), band, int(d.credits)])
	res.append(GameBackend.ue_status_text())
	var cert_e: String = GameBackend.certificate_endorsement()
	if cert_e != "":
		res.append(tr("END_CERT_ENDORSED") % GameBackend.band_name(cert_e).to_upper())
	var courses: Dictionary = GameBackend.endorsed_courses()
	if not courses.is_empty():
		var bits: Array = []
		for subj in courses:
			bits.append("%s (%s)" % [GameBackend.subject_name(str(subj)), GameBackend.band_name(str(courses[subj]))])
		res.append(tr("END_COURSE_ENDORSEMENTS") % ", ".join(bits))
	_para("\n".join(res))

	# 5. The numbers
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	_heading(tr("END_NUMBERS"))
	var nums: Array = []
	nums.append(tr("END_OVERALL") % [GameBackend.get_overall_grade(), GameBackend.required_grade()])
	nums.append(tr("END_MONEY") % [GameBackend.money, money_needed])
	if GameBackend.loan_debt > 0.0:
		nums.append(tr("END_BORROWED") % GameBackend.loan_debt)
	nums.append(tr("END_WELLBEING") % [GameBackend.sanity, GameBackend.stat_lowest_sanity])
	_para("\n".join(nums))

	# 6. How you spent it
	_heading(tr("END_HOW_SPENT"))
	var spent: Array = []
	spent.append((tr("END_STUDY_SESSIONS") + ": %d   ·   " + tr("END_HOURS_STUDYING") + ": %.0f") % [
		GameBackend.stat_study_sessions, GameBackend.stat_study_hours])
	spent.append((tr("END_SHIFTS_WORKED") + ": %d   ·   " + tr("END_EARNED") + ": $%.0f") % [
		GameBackend.stat_shifts, GameBackend.stat_earned])
	spent.append((tr("END_ASSESSMENTS_SAT") + ": %d   ·   " + tr("END_MISSED") + ": %d") % [
		GameBackend.stat_exams_sat, GameBackend.stat_exams_missed])
	spent.append((tr("END_NIGHTS_SLEPT") + ": %d   ·   " + tr("END_MEALS_COOKED") + ": %d") % [
		GameBackend.stat_nights_slept, GameBackend.stat_meals_cooked])
	spent.append((tr("END_CONVERSATIONS") + ": %d   ·   " + tr("END_TEXTS_REPLIED") + ": %d") % [
		GameBackend.stat_conversations, GameBackend.stat_messages_replied])
	spent.append((tr("END_GAMES_PLAYED") + ": %d   ·   " + tr("END_RAVI_VISITS") + ": %d") % [
		GameBackend.stat_games_played, GameBackend.ravi_visits])
	if not GameBackend.phone_best.is_empty():
		var pb: Dictionary = GameBackend.phone_best
		spent.append(tr("END_BEST_SCORES") % [int(pb.get("maths", 0)), int(pb.get("memory", 0)), int(pb.get("higher", 0)), int(pb.get("tap", 0))])
	_para("\n".join(spent))

	# 7. Key moments
	var notable: Array = GameBackend.notable_events(10)
	if not notable.is_empty():
		_heading(tr("END_MOMENTS"))
		var m: Array = []
		for entry in notable:
			m.append((tr("COMMON_DAY") + " — %s") % [entry.day, entry.text])
		_para("\n".join(m))

	# 8. Where are they now
	_gap(40)
	_heading(tr("END_PEOPLE"))
	for pair in GameBackend.where_are_they_now():
		var who := Label.new()
		who.text = GameBackend.contact_name(str(pair[0]))
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		who.add_theme_font_size_override("font_size", 20)
		who.add_theme_color_override("font_color", _accent)
		_shadow(who)
		_column.add_child(who)
		var line := _para(str(pair[1]), true)
		line.add_theme_color_override("default_color", COL_TEXT)
		_gap(6)

	# 9. Credits
	_gap(120)
	_center_text(tr("END_GAME_TITLE"), 40, _accent)
	_gap(30)
	_center_text(tr("END_CREDITS"), 22, COL_DIM)
	for pair in [["CREDITS_DEVELOPERS_TITLE", "CREDITS_DEVELOPERS_AUTHOR"],
			["CREDITS_MODELASSETS_TITLE", "CREDITS_MODELASSETS_AUTHOR"],
			["END_MUSIC_TITLE", "END_MUSIC_TEXT"],
			["CREDITS_SHADER_ENVIROMENT_TITLE", "CREDITS_SHADER_ENVIROMENT_COPYRIGHT"]]:
		_gap(18)
		_center_text(tr(str(pair[0])).to_upper(), 15, COL_DIM)
		_center_text(tr(str(pair[1])), 19, COL_TEXT)
	_gap(24)
	_center_text(tr("END_ENGINE"), 15, COL_DIM)
	_gap(260)
	_center_text(tr("END_THANKS"), 34, COL_TEXT)
	_gap(40)


func _shadow(l: Control) -> void:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if l is RichTextLabel:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))


func _gap(h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(c)


func _heading(text: String) -> void:
	_gap(26)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", _accent)
	_shadow(l)
	_column.add_child(l)


func _para(text: String, centred: bool = false) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	r.add_theme_font_size_override("normal_font_size", 17)
	r.add_theme_constant_override("line_separation", 6)
	r.add_theme_color_override("default_color", COL_TEXT)
	_shadow(r)
	r.text = ("[center]%s[/center]" % text) if centred else text
	_column.add_child(r)
	return r


func _center_text(text: String, size: int, colour: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	_shadow(l)
	_column.add_child(l)


## Photos taken during the year (GameBackend.capture_memory), laid out like
## polaroids two to a row, each with the day and what was happening.
func _add_memories() -> void:
	var mems: Array = GameBackend.memories
	if mems.is_empty():
		return
	_heading(tr("END_MEMORIES"))
	var row: HBoxContainer = null
	for i in mems.size():
		if i % 2 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 34)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_column.add_child(row)
			_gap(10)
		row.add_child(_polaroid(mems[i], i))


func _polaroid(mem: Dictionary, index: int) -> Control:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.97, 0.96, 0.92)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 10
	st.content_margin_bottom = 12
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_size = 8
	card.add_theme_stylebox_override("panel", st)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(340, 192)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mem.get("image") is Image:
		pic.texture = ImageTexture.create_from_image(mem.image)
	box.add_child(pic)
	var cap := Label.new()
	cap.text = (tr("COMMON_DAY") % int(mem.get("day", 0))) + "  ·  " + str(mem.get("caption", ""))
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size = Vector2(340, 0)
	cap.add_theme_font_size_override("font_size", 13)
	cap.add_theme_color_override("font_color", Color(0.18, 0.18, 0.22))
	box.add_child(cap)
	# A slight tilt, alternating, like they've been dropped on a table.
	card.rotation_degrees = -2.5 if index % 2 == 0 else 2.0
	card.resized.connect(func(): card.pivot_offset = card.size * 0.5)
	return card


func _build_corner() -> void:
	# The scene's button stays as a small "skip to the menu" in the corner,
	# and becomes the big button once the roll is over.
	menu_button.get_parent().remove_child(menu_button)
	add_child(menu_button)
	menu_button.custom_minimum_size = Vector2(170, 40)
	menu_button.anchor_left = 1.0
	menu_button.anchor_right = 1.0
	menu_button.anchor_top = 1.0
	menu_button.anchor_bottom = 1.0
	menu_button.offset_left = -194
	menu_button.offset_right = -24
	menu_button.offset_top = -64
	menu_button.offset_bottom = -24
	menu_button.z_index = 2
	menu_button.modulate.a = 0.75

	_hint = Label.new()
	_hint.text = tr("END_SPEED_HINT")
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = 24
	_hint.offset_top = -52
	_hint.offset_right = 900
	_hint.offset_bottom = -30
	_hint.z_index = 2
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


func _start_roll() -> void:
	# Let the column work out its real height first. (Nothing is visible yet —
	# the black fade covers the screen until everything is in place.)
	await get_tree().process_frame
	await get_tree().process_frame
	var vp: Vector2 = get_viewport_rect().size
	_column.position.x = (vp.x - COLUMN_WIDTH) * 0.5
	# Start with the headline sitting in the middle of the screen.
	var head_h: float = title_label.size.y + subtitle_label.size.y + 14.0
	_start_y = vp.y * 0.5 - head_h * 0.5
	_roll_y = _start_y
	_column.position.y = _roll_y
	_column.modulate.a = 1.0
	_clock_start = Time.get_ticks_msec()
	_last_tick = _clock_start
	_rolling = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.4)
	tw.tween_callback(_fade.hide)


## How far the roll has to travel: from the headline in the middle of the
## screen to the last line sitting just above the middle. Measured live every
## frame, so it's right even if some text finishes laying out late.
func _travel() -> float:
	var vp: Vector2 = get_viewport_rect().size
	return maxf(1.0, _start_y - (vp.y * 0.42 - _column.size.y))


## Seconds of scrolling after the title hold, so the last line arrives as the
## song ends.
func _roll_seconds() -> float:
	return maxf(30.0, _song_seconds - TITLE_HOLD - 5.0)


func _process(_delta: float) -> void:
	if not _rolling:
		return
	var now: int = Time.get_ticks_msec()
	var real_dt: float = (now - _last_tick) / 1000.0
	_last_tick = now
	_elapsed = (now - _clock_start) / 1000.0
	_place_camera(_elapsed / maxf(1.0, _song_seconds))
	if _finished:
		return
	var fast: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if fast:
		_boost += minf(real_dt, 0.25) * 4.0
	_roll_time = _elapsed + _boost
	_apply_roll()


## The roll's position is worked out from time, not nudged by a speed, so it
## can't stall: progress 0 -> 1 over the song, times the live distance.
func _apply_roll() -> void:
	_roll_time = maxf(_roll_time, 0.0)
	var progress: float = clampf((_roll_time - TITLE_HOLD) / _roll_seconds(), 0.0, 1.0)
	_roll_y = _start_y - progress * _travel()
	_column.position.y = _roll_y
	if progress >= 1.0:
		_finish_roll()


func _input(event: InputEvent) -> void:
	if not _rolling or _finished:
		return
	if event is InputEventMouseButton and event.pressed:
		# Scrolling moves through time, about 70 pixels a notch.
		var secs_per_px: float = _roll_seconds() / _travel()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Back, but never before the start of the roll.
			_boost = maxf(TITLE_HOLD - _elapsed, _boost - 70.0 * secs_per_px)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_boost = maxf(TITLE_HOLD - _elapsed, _boost) + 70.0 * secs_per_px
		_roll_time = _elapsed + _boost
		_apply_roll()


func _finish_roll() -> void:
	if _finished:
		return
	_finished = true
	_hint.visible = false
	# The menu button moves to the middle, under "Thanks for playing."
	var vp: Vector2 = get_viewport_rect().size
	menu_button.anchor_left = 0.5
	menu_button.anchor_right = 0.5
	menu_button.anchor_top = 0.0
	menu_button.anchor_bottom = 0.0
	menu_button.custom_minimum_size = Vector2(260, 52)
	menu_button.offset_left = -130
	menu_button.offset_right = 130
	menu_button.offset_top = vp.y * 0.42 + 30.0
	menu_button.offset_bottom = vp.y * 0.42 + 82.0
	var tw := create_tween()
	tw.tween_property(menu_button, "modulate:a", 1.0, 1.2)


## Kept for anything that still asks for the old text block (and for tests).
func _compose_text(degree: String, _accent_unused: Color = Color.WHITE) -> String:
	var out: Array = [GameBackend.build_epilogue()]
	for r in GameBackend.offer_reasons():
		out.append(str(r))
	for pair in GameBackend.where_are_they_now():
		out.append("%s: %s" % [GameBackend.contact_name(str(pair[0])), str(pair[1])])
	if degree != "":
		out.append(GameBackend.major_name(degree))
	return "\n".join(out)


func _on_menu_pressed() -> void:
	GameBackend.reset_run()
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
