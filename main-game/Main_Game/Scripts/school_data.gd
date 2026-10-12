## SchoolData.gd
## Autoload: "SchoolData"
## Every face-to-face conversation in the school scene.
## These used to be one opening line plus three canned replies, which is why
## they read like a menu rather than a conversation. They now use exactly the
## same shape as the phone threads: a list of steps, each with replies that
## can "goto" any other step. So a chat runs three, four, five exchanges
## deep, remembers what you said two lines ago by virtue of where it sent
## you, and can end on completely different notes.
## Conversation shape:
##   id         unique string
##   speaker    who's talking (a named classmate, or Mr Halloway)
##   role       "student" | "teacher"
##   condition  when this conversation is allowed to come up (see _condition_met)
##   steps      [{them, replies:[{text, sanity, temptation, goto}]}]
##
## {NAME} is replaced with the player's name.
extends Node

# Named classmates
# Students have names so conversations feel like people rather than a generic
# "student" prompt.
const STUDENT_NAMES := ["Mika", "Tane", "Priya", "Josh", "Ana", "Wiremu", "Chloe", "Sione"]
const TEACHER_NAME := "Mr Halloway"


static func random_student_name() -> String:
	return STUDENT_NAMES[randi() % STUDENT_NAMES.size()]

# WHEN A CONVERSATION IS ALLOWED TO COME UP
# The school reacts to the state you're actually in. Walk up to a classmate
# the day before an external and they talk about the external walk up to one
# when you're falling apart and someone notices.

func _condition_met(condition: String) -> bool:
	match condition:
		"", "always":
			return true
		"early_year":
			return GameBackend.get_elapsed_days() < 25
		"mid_year":
			return GameBackend.get_elapsed_days() >= 25 and GameBackend.get_elapsed_days() < 65
		"late_year":
			return GameBackend.get_elapsed_days() >= 65
		"exam_soon":
			var d: int = GameBackend.days_until_next_exam()
			return d >= 0 and d <= 3
		"low_sanity":
			return GameBackend.sanity < 40.0
		"very_low_sanity":
			return GameBackend.sanity < 22.0
		"high_temptation":
			return GameBackend.temptation > 60.0
		"behind":
			return GameBackend.get_overall_grade() < GameBackend.required_grade() - 8.0
		"ahead":
			return GameBackend.get_overall_grade() >= GameBackend.required_grade()
		"no_loan":
			return GameBackend.loan_status == "none" and GameBackend.loan_applications_open()
		"short_credits":
			return not GameBackend.has_university_entrance() and GameBackend.get_elapsed_days() > 40
	return true


## Picks a conversation from `pool` whose condition currently holds. Falls
## back to any unconditional one so there's always something to say.
func _pick(pool: Array) -> Dictionary:
	var eligible: Array = []
	for convo in pool:
		if _condition_met(str(convo.get("condition", "always"))):
			eligible.append(convo)
	if eligible.is_empty():
		eligible = pool
	return eligible[randi() % eligible.size()]


## Translates a conversation (the data holds localisation keys) and
## substitutes {NAME} throughout.
static func personalise(convo: Dictionary, player_name: String) -> Dictionary:
	var out: Dictionary = convo.duplicate(true)
	for step in out.steps:
		step.them = TranslationServer.translate(str(step.them)).replace("{NAME}", player_name)
		for reply in step.replies:
			reply.text = TranslationServer.translate(str(reply.text)).replace("{NAME}", player_name)
	return out


func get_student_conversation(player_name: String) -> Dictionary:
	return personalise(_pick(_student_conversations), player_name)


func get_teacher_conversation(player_name: String) -> Dictionary:
	return personalise(_pick(_teacher_conversations), player_name)


## Where a reply sends you. Same rule as the phone threads.
func next_step_for(reply: Dictionary, current_step: int) -> int:
	return int(reply.get("goto", current_step + 1))



# CLASSMATES

var _student_conversations: Array = [

	{
		"id": "mika_chem", "speaker": "Mika", "role": "student", "condition": "early_year",
		"steps": [
			# 0
			{"them": "CONV_MIKA_CHEM_S0",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "CONV_MIKA_CHEM_S0_R1", "sanity": 5.0, "goto": 1},
				{"text": "CONV_MIKA_CHEM_S0_R2", "sanity": 8.0, "goto": 2}]},
			# 1
			{"them": "CONV_MIKA_CHEM_S1",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S1_R0", "sanity": 9.0, "goto": 3},
				{"text": "CONV_MIKA_CHEM_S1_R1", "sanity": 8.0, "goto": 3},
				{"text": "CONV_MIKA_CHEM_S1_R2", "sanity": 4.0, "temptation": 3.0, "goto": 4}]},
			# 2
			{"them": "CONV_MIKA_CHEM_S2",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S2_R0", "sanity": 10.0, "goto": 5},
				{"text": "CONV_MIKA_CHEM_S2_R1", "sanity": 8.0, "goto": 5}]},
			# 3
			{"them": "CONV_MIKA_CHEM_S3",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S3_R0", "sanity": 10.0, "temptation": -3.0, "goto": 6},
				{"text": "CONV_MIKA_CHEM_S3_R1", "sanity": 7.0, "goto": 6}]},
			# 4
			{"them": "CONV_MIKA_CHEM_S4",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S4_R0", "sanity": 7.0, "goto": 3},
				{"text": "CONV_MIKA_CHEM_S4_R1", "sanity": 10.0, "goto": 6}]},
			# 5
			{"them": "CONV_MIKA_CHEM_S5",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S5_R0", "sanity": 13.0, "goto": 6},
				{"text": "CONV_MIKA_CHEM_S5_R1", "sanity": 10.0, "goto": 6}]},
			# 6
			{"them": "CONV_MIKA_CHEM_S6",
			 "replies": [
				{"text": "CONV_MIKA_CHEM_S6_R0", "sanity": 6.0},
				{"text": "CONV_MIKA_CHEM_S6_R1", "sanity": 11.0, "temptation": -2.0}]},
		]},

	{
		"id": "priya_marks", "speaker": "Priya", "role": "student", "condition": "mid_year",
		"steps": [
			# 0
			{"them": "CONV_PRIYA_MARKS_S0",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "CONV_PRIYA_MARKS_S0_R1", "sanity": 6.0, "goto": 1}]},
			# 1
			{"them": "CONV_PRIYA_MARKS_S1",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S1_R0", "sanity": 6.0, "goto": 2},
				{"text": "CONV_PRIYA_MARKS_S1_R1", "sanity": 9.0, "goto": 3},
				{"text": "CONV_PRIYA_MARKS_S1_R2", "sanity": 3.0, "goto": 2}]},
			# 2
			{"them": "CONV_PRIYA_MARKS_S2",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S2_R0", "sanity": 12.0, "goto": 4},
				{"text": "CONV_PRIYA_MARKS_S2_R1", "sanity": 10.0, "goto": 5},
				{"text": "CONV_PRIYA_MARKS_S2_R2", "sanity": 2.0, "temptation": 2.0, "goto": 6}]},
			# 3
			{"them": "CONV_PRIYA_MARKS_S3",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S3_R0", "sanity": 14.0, "goto": 4},
				{"text": "CONV_PRIYA_MARKS_S3_R1", "sanity": 12.0, "goto": 4}]},
			# 4
			{"them": "CONV_PRIYA_MARKS_S4",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S4_R0", "sanity": 12.0, "goto": 7},
				{"text": "CONV_PRIYA_MARKS_S4_R1", "sanity": 13.0, "goto": 7}]},
			# 5
			{"them": "CONV_PRIYA_MARKS_S5",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S5_R0", "sanity": 13.0, "goto": 7},
				{"text": "CONV_PRIYA_MARKS_S5_R1", "sanity": 11.0, "goto": 7}]},
			# 6
			{"them": "CONV_PRIYA_MARKS_S6",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S6_R0", "sanity": 6.0, "goto": 4},
				{"text": "CONV_PRIYA_MARKS_S6_R1", "sanity": 7.0, "goto": 4}]},
			# 7
			{"them": "CONV_PRIYA_MARKS_S7",
			 "replies": [
				{"text": "CONV_PRIYA_MARKS_S7_R0", "sanity": 10.0},
				{"text": "CONV_PRIYA_MARKS_S7_R1", "sanity": 13.0}]},
		]},

	{
		"id": "ana_notices_you", "speaker": "Ana", "role": "student", "condition": "low_sanity",
		"steps": [
			# 0
			{"them": "CONV_ANA_NOTICES_YOU_S0",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "CONV_ANA_NOTICES_YOU_S0_R1", "sanity": 6.0, "goto": 2},
				{"text": "CONV_ANA_NOTICES_YOU_S0_R2", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "CONV_ANA_NOTICES_YOU_S1",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S1_R0", "sanity": 15.0, "goto": 4},
				{"text": "CONV_ANA_NOTICES_YOU_S1_R1", "sanity": 11.0, "goto": 5}]},
			# 2
			{"them": "CONV_ANA_NOTICES_YOU_S2",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S2_R0", "sanity": 9.0, "goto": 1},
				{"text": "CONV_ANA_NOTICES_YOU_S2_R1", "sanity": 6.0, "goto": 5}]},
			# 3
			{"them": "CONV_ANA_NOTICES_YOU_S3",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S3_R0", "sanity": 12.0, "goto": 1},
				{"text": "CONV_ANA_NOTICES_YOU_S3_R1", "sanity": 5.0, "goto": 6},
				{"text": "CONV_ANA_NOTICES_YOU_S3_R2", "sanity": 7.0, "goto": 7}]},
			# 4
			{"them": "CONV_ANA_NOTICES_YOU_S4",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S4_R0", "sanity": 18.0, "goto": 7},
				{"text": "CONV_ANA_NOTICES_YOU_S4_R1", "sanity": 16.0, "goto": 7}]},
			# 5
			{"them": "CONV_ANA_NOTICES_YOU_S5",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S5_R0", "sanity": 14.0, "goto": 7},
				{"text": "CONV_ANA_NOTICES_YOU_S5_R1", "sanity": 8.0, "goto": 8}]},
			# 6
			{"them": "CONV_ANA_NOTICES_YOU_S6",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S6_R0", "sanity": 13.0, "goto": 1},
				{"text": "CONV_ANA_NOTICES_YOU_S6_R1", "sanity": 9.0, "goto": 7}]},
			# 7
			{"them": "CONV_ANA_NOTICES_YOU_S7",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S7_R0", "sanity": 12.0},
				{"text": "CONV_ANA_NOTICES_YOU_S7_R1", "sanity": 9.0}]},
			# 8
			{"them": "CONV_ANA_NOTICES_YOU_S8",
			 "replies": [
				{"text": "CONV_ANA_NOTICES_YOU_S8_R0", "sanity": 13.0, "goto": 7},
				{"text": "CONV_ANA_NOTICES_YOU_S8_R1", "sanity": 11.0, "goto": 7}]},
		]},

	{
		"id": "tane_shifts", "speaker": "Tane", "role": "student", "condition": "always",
		"steps": [
			# 0
			{"them": "CONV_TANE_SHIFTS_S0",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S0_R0", "sanity": 9.0, "goto": 1},
				{"text": "CONV_TANE_SHIFTS_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "CONV_TANE_SHIFTS_S0_R2", "sanity": 7.0, "goto": 3}]},
			# 1
			{"them": "CONV_TANE_SHIFTS_S1",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S1_R0", "sanity": 10.0, "goto": 4},
				{"text": "CONV_TANE_SHIFTS_S1_R1", "sanity": 8.0, "goto": 4}]},
			# 2
			{"them": "CONV_TANE_SHIFTS_S2",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S2_R0", "sanity": 4.0, "goto": 5},
				{"text": "CONV_TANE_SHIFTS_S2_R1", "sanity": 9.0, "goto": 1}]},
			# 3
			{"them": "CONV_TANE_SHIFTS_S3",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S3_R0", "sanity": 11.0, "temptation": -3.0, "goto": 4},
				{"text": "CONV_TANE_SHIFTS_S3_R1", "sanity": 10.0, "goto": 4}]},
			# 4
			{"them": "CONV_TANE_SHIFTS_S4",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S4_R0", "sanity": 11.0, "goto": 6},
				{"text": "CONV_TANE_SHIFTS_S4_R1", "sanity": 9.0, "goto": 6}]},
			# 5
			{"them": "CONV_TANE_SHIFTS_S5",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S5_R0", "sanity": 6.0, "goto": 6},
				{"text": "CONV_TANE_SHIFTS_S5_R1", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "CONV_TANE_SHIFTS_S6",
			 "replies": [
				{"text": "CONV_TANE_SHIFTS_S6_R0", "sanity": 5.0},
				{"text": "CONV_TANE_SHIFTS_S6_R1", "sanity": 8.0}]},
		]},

	{
		"id": "wiremu_exam_nerves", "speaker": "Wiremu", "role": "student", "condition": "exam_soon",
		"steps": [
			# 0
			{"them": "CONV_WIREMU_EXAM_NERVES_S0",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "CONV_WIREMU_EXAM_NERVES_S0_R1", "sanity": 6.0, "goto": 2},
				{"text": "CONV_WIREMU_EXAM_NERVES_S0_R2", "sanity": 9.0, "goto": 3}]},
			# 1
			{"them": "CONV_WIREMU_EXAM_NERVES_S1",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S1_R0", "sanity": 11.0, "goto": 4},
				{"text": "CONV_WIREMU_EXAM_NERVES_S1_R1", "sanity": 13.0, "temptation": -4.0, "goto": 5}]},
			# 2
			{"them": "CONV_WIREMU_EXAM_NERVES_S2",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S2_R0", "sanity": 14.0, "temptation": -4.0, "goto": 5},
				{"text": "CONV_WIREMU_EXAM_NERVES_S2_R1", "sanity": 7.0, "goto": 4}]},
			# 3
			{"them": "CONV_WIREMU_EXAM_NERVES_S3",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S3_R0", "sanity": 11.0, "goto": 4},
				{"text": "CONV_WIREMU_EXAM_NERVES_S3_R1", "sanity": 13.0, "goto": 5},
				{"text": "CONV_WIREMU_EXAM_NERVES_S3_R2", "sanity": 10.0, "goto": 6}]},
			# 4
			{"them": "CONV_WIREMU_EXAM_NERVES_S4",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S4_R0", "sanity": 8.0},
				{"text": "CONV_WIREMU_EXAM_NERVES_S4_R1", "sanity": 10.0}]},
			# 5
			{"them": "CONV_WIREMU_EXAM_NERVES_S5",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S5_R0", "sanity": 12.0, "temptation": -3.0},
				{"text": "CONV_WIREMU_EXAM_NERVES_S5_R1", "sanity": 10.0}]},
			# 6
			{"them": "CONV_WIREMU_EXAM_NERVES_S6",
			 "replies": [
				{"text": "CONV_WIREMU_EXAM_NERVES_S6_R0", "sanity": 12.0, "goto": 4},
				{"text": "CONV_WIREMU_EXAM_NERVES_S6_R1", "sanity": 10.0, "goto": 4}]},
		]},

	{
		"id": "sione_balance", "speaker": "Sione", "role": "student", "condition": "high_temptation",
		"steps": [
			# 0
			{"them": "CONV_SIONE_BALANCE_S0",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S0_R0", "sanity": 7.0, "goto": 1},
				{"text": "CONV_SIONE_BALANCE_S0_R1", "sanity": 5.0, "goto": 2},
				{"text": "CONV_SIONE_BALANCE_S0_R2", "sanity": 6.0, "goto": 3}]},
			# 1
			{"them": "CONV_SIONE_BALANCE_S1",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S1_R0", "sanity": 11.0, "goto": 4},
				{"text": "CONV_SIONE_BALANCE_S1_R1", "sanity": 9.0, "goto": 4}]},
			# 2
			{"them": "CONV_SIONE_BALANCE_S2",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S2_R0", "sanity": 10.0, "goto": 4},
				{"text": "CONV_SIONE_BALANCE_S2_R1", "sanity": 5.0, "goto": 5}]},
			# 3
			{"them": "CONV_SIONE_BALANCE_S3",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S3_R0", "sanity": 10.0, "goto": 4},
				{"text": "CONV_SIONE_BALANCE_S3_R1", "sanity": 6.0, "goto": 4}]},
			# 4
			{"them": "CONV_SIONE_BALANCE_S4",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S4_R0", "sanity": 13.0, "temptation": -8.0},
				{"text": "CONV_SIONE_BALANCE_S4_R1", "sanity": 12.0, "temptation": -6.0}]},
			# 5
			{"them": "CONV_SIONE_BALANCE_S5",
			 "replies": [
				{"text": "CONV_SIONE_BALANCE_S5_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_SIONE_BALANCE_S5_R1", "sanity": 11.0, "temptation": -5.0, "goto": 4}]},
		]},

	{
		"id": "chloe_gossip", "speaker": "Chloe", "role": "student", "condition": "always",
		"steps": [
			# 0
			{"them": "CONV_CHLOE_GOSSIP_S0",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S0_R0", "sanity": 1.0, "goto": 1},
				{"text": "CONV_CHLOE_GOSSIP_S0_R1", "sanity": 6.0, "goto": 2},
				{"text": "CONV_CHLOE_GOSSIP_S0_R2", "sanity": 5.0, "goto": 3}]},
			# 1
			{"them": "CONV_CHLOE_GOSSIP_S1",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S1_R0", "sanity": 7.0, "goto": 4},
				{"text": "CONV_CHLOE_GOSSIP_S1_R1", "sanity": 6.0, "goto": 4}]},
			# 2
			{"them": "CONV_CHLOE_GOSSIP_S2",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S2_R0", "sanity": 8.0, "goto": 4},
				{"text": "CONV_CHLOE_GOSSIP_S2_R1", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "CONV_CHLOE_GOSSIP_S3",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S3_R0", "sanity": 8.0, "goto": 4},
				{"text": "CONV_CHLOE_GOSSIP_S3_R1", "sanity": 7.0, "goto": 4}]},
			# 4
			{"them": "CONV_CHLOE_GOSSIP_S4",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S4_R0", "sanity": 4.0, "goto": 5},
				{"text": "CONV_CHLOE_GOSSIP_S4_R1", "sanity": 8.0, "goto": 6},
				{"text": "CONV_CHLOE_GOSSIP_S4_R2", "sanity": 6.0, "goto": 6}]},
			# 5
			{"them": "CONV_CHLOE_GOSSIP_S5",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S5_R0", "sanity": 11.0},
				{"text": "CONV_CHLOE_GOSSIP_S5_R1", "sanity": 9.0}]},
			# 6
			{"them": "CONV_CHLOE_GOSSIP_S6",
			 "replies": [
				{"text": "CONV_CHLOE_GOSSIP_S6_R0", "sanity": 8.0},
				{"text": "CONV_CHLOE_GOSSIP_S6_R1", "sanity": 7.0}]},
		]},

	{
		"id": "josh_credits", "speaker": "Josh", "role": "student", "condition": "short_credits",
		"steps": [
			# 0
			{"them": "CONV_JOSH_CREDITS_S0",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "CONV_JOSH_CREDITS_S0_R1", "sanity": 4.0, "goto": 1}]},
			# 1
			{"them": "CONV_JOSH_CREDITS_S1",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S1_R0", "sanity": 11.0, "goto": 2},
				{"text": "CONV_JOSH_CREDITS_S1_R1", "sanity": 9.0, "goto": 3},
				{"text": "CONV_JOSH_CREDITS_S1_R2", "sanity": 4.0, "goto": 4}]},
			# 2
			{"them": "CONV_JOSH_CREDITS_S2",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S2_R0", "sanity": 10.0, "goto": 5},
				{"text": "CONV_JOSH_CREDITS_S2_R1", "sanity": 12.0, "goto": 5}]},
			# 3
			{"them": "CONV_JOSH_CREDITS_S3",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S3_R0", "sanity": 12.0, "goto": 2},
				{"text": "CONV_JOSH_CREDITS_S3_R1", "sanity": 10.0, "goto": 2}]},
			# 4
			{"them": "CONV_JOSH_CREDITS_S4",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S4_R0", "sanity": 11.0, "goto": 2},
				{"text": "CONV_JOSH_CREDITS_S4_R1", "sanity": 8.0, "goto": 5}]},
			# 5
			{"them": "CONV_JOSH_CREDITS_S5",
			 "replies": [
				{"text": "CONV_JOSH_CREDITS_S5_R0", "sanity": 12.0},
				{"text": "CONV_JOSH_CREDITS_S5_R1", "sanity": 9.0}]},
		]},

	{
		"id": "mika_after", "speaker": "Mika", "role": "student", "condition": "late_year",
		"steps": [
			# 0
			{"them": "CONV_MIKA_AFTER_S0",
			 "replies": [
				{"text": "CONV_MIKA_AFTER_S0_R0", "sanity": 11.0, "goto": 1},
				{"text": "CONV_MIKA_AFTER_S0_R1", "sanity": 6.0, "goto": 2},
				{"text": "CONV_MIKA_AFTER_S0_R2", "sanity": 8.0, "temptation": 3.0, "goto": 3}]},
			# 1
			{"them": "CONV_MIKA_AFTER_S1",
			 "replies": [
				{"text": "CONV_MIKA_AFTER_S1_R0", "sanity": 13.0, "goto": 4},
				{"text": "CONV_MIKA_AFTER_S1_R1", "sanity": 12.0, "goto": 4}]},
			# 2
			{"them": "CONV_MIKA_AFTER_S2",
			 "replies": [
				{"text": "CONV_MIKA_AFTER_S2_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_MIKA_AFTER_S2_R1", "sanity": 12.0, "goto": 4}]},
			# 3
			{"them": "CONV_MIKA_AFTER_S3",
			 "replies": [
				{"text": "CONV_MIKA_AFTER_S3_R0", "sanity": 8.0, "goto": 4},
				{"text": "CONV_MIKA_AFTER_S3_R1", "sanity": 9.0, "goto": 4}]},
			# 4
			{"them": "CONV_MIKA_AFTER_S4",
			 "replies": [
				{"text": "CONV_MIKA_AFTER_S4_R0", "sanity": 9.0},
				{"text": "CONV_MIKA_AFTER_S4_R1", "sanity": 11.0}]},
		]},

	{
		"id": "ana_burnout_warning", "speaker": "Ana", "role": "student", "condition": "very_low_sanity",
		"steps": [
			# 0
			{"them": "CONV_ANA_BURNOUT_WARNING_S0",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S0_R0", "sanity": 12.0, "goto": 1},
				{"text": "CONV_ANA_BURNOUT_WARNING_S0_R1", "sanity": 5.0, "goto": 2},
				{"text": "CONV_ANA_BURNOUT_WARNING_S0_R2", "sanity": 8.0, "goto": 3}]},
			# 1
			{"them": "CONV_ANA_BURNOUT_WARNING_S1",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S1_R0", "sanity": 10.0, "goto": 4},
				{"text": "CONV_ANA_BURNOUT_WARNING_S1_R1", "sanity": 11.0, "goto": 4}]},
			# 2
			{"them": "CONV_ANA_BURNOUT_WARNING_S2",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S2_R0", "sanity": 11.0, "goto": 1},
				{"text": "CONV_ANA_BURNOUT_WARNING_S2_R1", "sanity": 7.0, "goto": 3}]},
			# 3
			{"them": "CONV_ANA_BURNOUT_WARNING_S3",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S3_R0", "sanity": 12.0, "goto": 4},
				{"text": "CONV_ANA_BURNOUT_WARNING_S3_R1", "sanity": 9.0, "goto": 5}]},
			# 4
			{"them": "CONV_ANA_BURNOUT_WARNING_S4",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S4_R0", "sanity": 20.0, "goto": 6},
				{"text": "CONV_ANA_BURNOUT_WARNING_S4_R1", "sanity": 18.0, "goto": 6},
				{"text": "CONV_ANA_BURNOUT_WARNING_S4_R2", "sanity": 10.0, "goto": 6}]},
			# 5
			{"them": "CONV_ANA_BURNOUT_WARNING_S5",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S5_R0", "sanity": 16.0, "goto": 4},
				{"text": "CONV_ANA_BURNOUT_WARNING_S5_R1", "sanity": 8.0, "goto": 4}]},
			# 6
			{"them": "CONV_ANA_BURNOUT_WARNING_S6",
			 "replies": [
				{"text": "CONV_ANA_BURNOUT_WARNING_S6_R0", "sanity": 14.0},
				{"text": "CONV_ANA_BURNOUT_WARNING_S6_R1", "sanity": 12.0}]},
		]},

	{
		"id": "tane_ahead", "speaker": "Tane", "role": "student", "condition": "ahead",
		"steps": [
			# 0
			{"them": "CONV_TANE_AHEAD_S0",
			 "replies": [
				{"text": "CONV_TANE_AHEAD_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "CONV_TANE_AHEAD_S0_R1", "sanity": 9.0, "goto": 2},
				{"text": "CONV_TANE_AHEAD_S0_R2", "sanity": 10.0, "goto": 1}]},
			# 1
			{"them": "CONV_TANE_AHEAD_S1",
			 "replies": [
				{"text": "CONV_TANE_AHEAD_S1_R0", "sanity": 11.0, "goto": 3},
				{"text": "CONV_TANE_AHEAD_S1_R1", "sanity": 7.0, "goto": 3}]},
			# 2
			{"them": "CONV_TANE_AHEAD_S2",
			 "replies": [
				{"text": "CONV_TANE_AHEAD_S2_R0", "sanity": 9.0, "goto": 3},
				{"text": "CONV_TANE_AHEAD_S2_R1", "sanity": 8.0, "goto": 3}]},
			# 3
			{"them": "CONV_TANE_AHEAD_S3",
			 "replies": [
				{"text": "CONV_TANE_AHEAD_S3_R0", "sanity": 12.0, "temptation": -4.0},
				{"text": "CONV_TANE_AHEAD_S3_R1", "sanity": 14.0, "temptation": -4.0}]},
		]},

	{
		"id": "priya_loan_nag", "speaker": "Priya", "role": "student", "condition": "no_loan",
		"steps": [
			# 0
			{"them": "CONV_PRIYA_LOAN_NAG_S0",
			 "replies": [
				{"text": "CONV_PRIYA_LOAN_NAG_S0_R0", "goto": 1},
				{"text": "CONV_PRIYA_LOAN_NAG_S0_R1", "goto": 2},
				{"text": "CONV_PRIYA_LOAN_NAG_S0_R2", "sanity": 3.0, "goto": 1}]},
			# 1
			{"them": "CONV_PRIYA_LOAN_NAG_S1",
			 "replies": [
				{"text": "CONV_PRIYA_LOAN_NAG_S1_R0", "sanity": 5.0, "goto": 3},
				{"text": "CONV_PRIYA_LOAN_NAG_S1_R1", "sanity": 10.0, "goto": 4}]},
			# 2
			{"them": "CONV_PRIYA_LOAN_NAG_S2",
			 "replies": [
				{"text": "CONV_PRIYA_LOAN_NAG_S2_R0", "sanity": 6.0, "goto": 1},
				{"text": "CONV_PRIYA_LOAN_NAG_S2_R1", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "CONV_PRIYA_LOAN_NAG_S3",
			 "replies": [
				{"text": "CONV_PRIYA_LOAN_NAG_S3_R0", "sanity": 7.0, "goto": 4},
				{"text": "CONV_PRIYA_LOAN_NAG_S3_R1", "sanity": 12.0, "goto": 4}]},
			# 4
			{"them": "CONV_PRIYA_LOAN_NAG_S4",
			 "replies": [
				{"text": "CONV_PRIYA_LOAN_NAG_S4_R0", "sanity": 10.0},
				{"text": "CONV_PRIYA_LOAN_NAG_S4_R1", "sanity": 9.0}]},
		]},
]



# MR HALLOWAY

var _teacher_conversations: Array = [

	{
		"id": "halloway_uneven", "speaker": TEACHER_NAME, "role": "teacher", "condition": "mid_year",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_UNEVEN_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S0_R0", "sanity": 4.0, "goto": 1},
				{"text": "CONV_HALLOWAY_UNEVEN_S0_R1", "sanity": 8.0, "goto": 2},
				{"text": "CONV_HALLOWAY_UNEVEN_S0_R2", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "CONV_HALLOWAY_UNEVEN_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S1_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_HALLOWAY_UNEVEN_S1_R1", "sanity": 11.0, "goto": 5}]},
			# 2
			{"them": "CONV_HALLOWAY_UNEVEN_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S2_R0", "sanity": 15.0, "goto": 5},
				{"text": "CONV_HALLOWAY_UNEVEN_S2_R1", "sanity": 9.0, "goto": 5}]},
			# 3
			{"them": "CONV_HALLOWAY_UNEVEN_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S3_R0", "sanity": 5.0, "goto": 6},
				{"text": "CONV_HALLOWAY_UNEVEN_S3_R1", "sanity": 11.0, "goto": 5}]},
			# 4
			{"them": "CONV_HALLOWAY_UNEVEN_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S4_R0", "sanity": 10.0, "goto": 5}]},
			# 5
			{"them": "CONV_HALLOWAY_UNEVEN_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S5_R0", "sanity": 12.0, "temptation": -5.0, "goto": 7},
				{"text": "CONV_HALLOWAY_UNEVEN_S5_R1", "sanity": 14.0, "temptation": -6.0, "goto": 7}]},
			# 6
			{"them": "CONV_HALLOWAY_UNEVEN_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S6_R0", "sanity": 10.0, "goto": 5},
				{"text": "CONV_HALLOWAY_UNEVEN_S6_R1", "sanity": 6.0, "goto": 5}]},
			# 7
			{"them": "CONV_HALLOWAY_UNEVEN_S7",
			 "replies": [
				{"text": "CONV_HALLOWAY_UNEVEN_S7_R0", "sanity": 9.0},
				{"text": "CONV_HALLOWAY_UNEVEN_S7_R1", "sanity": 11.0, "temptation": -3.0}]},
		]},

	{
		"id": "halloway_credits", "speaker": TEACHER_NAME, "role": "teacher", "condition": "short_credits",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_CREDITS_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S0_R0", "goto": 1},
				{"text": "CONV_HALLOWAY_CREDITS_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "CONV_HALLOWAY_CREDITS_S0_R2", "goto": 1}]},
			# 1
			{"them": "CONV_HALLOWAY_CREDITS_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S1_R0", "sanity": 5.0, "goto": 3},
				{"text": "CONV_HALLOWAY_CREDITS_S1_R1", "sanity": 9.0, "goto": 3}]},
			# 2
			{"them": "CONV_HALLOWAY_CREDITS_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S2_R0", "sanity": 6.0, "goto": 3},
				{"text": "CONV_HALLOWAY_CREDITS_S2_R1", "sanity": 10.0, "goto": 3}]},
			# 3
			{"them": "CONV_HALLOWAY_CREDITS_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S3_R0", "sanity": 6.0, "goto": 4},
				{"text": "CONV_HALLOWAY_CREDITS_S3_R1", "sanity": 9.0, "goto": 5}]},
			# 4
			{"them": "CONV_HALLOWAY_CREDITS_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S4_R0", "sanity": 13.0, "temptation": -5.0, "goto": 6},
				{"text": "CONV_HALLOWAY_CREDITS_S4_R1", "sanity": 9.0, "goto": 5}]},
			# 5
			{"them": "CONV_HALLOWAY_CREDITS_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S5_R0", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "CONV_HALLOWAY_CREDITS_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_CREDITS_S6_R0", "sanity": 12.0},
				{"text": "CONV_HALLOWAY_CREDITS_S6_R1", "sanity": 10.0}]},
		]},

	{
		"id": "halloway_burnout", "speaker": TEACHER_NAME, "role": "teacher", "condition": "low_sanity",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_BURNOUT_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S0_R0", "sanity": 12.0, "goto": 1},
				{"text": "CONV_HALLOWAY_BURNOUT_S0_R1", "sanity": 7.0, "goto": 2},
				{"text": "CONV_HALLOWAY_BURNOUT_S0_R2", "sanity": 10.0, "goto": 3}]},
			# 1
			{"them": "CONV_HALLOWAY_BURNOUT_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S1_R0", "sanity": 12.0, "goto": 4},
				{"text": "CONV_HALLOWAY_BURNOUT_S1_R1", "sanity": 10.0, "goto": 5}]},
			# 2
			{"them": "CONV_HALLOWAY_BURNOUT_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S2_R0", "sanity": 13.0, "goto": 1},
				{"text": "CONV_HALLOWAY_BURNOUT_S2_R1", "sanity": 9.0, "goto": 6}]},
			# 3
			{"them": "CONV_HALLOWAY_BURNOUT_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S3_R0", "sanity": 16.0, "goto": 4},
				{"text": "CONV_HALLOWAY_BURNOUT_S3_R1", "sanity": 8.0, "goto": 6}]},
			# 4
			{"them": "CONV_HALLOWAY_BURNOUT_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S4_R0", "sanity": 14.0},
				{"text": "CONV_HALLOWAY_BURNOUT_S4_R1", "sanity": 12.0}]},
			# 5
			{"them": "CONV_HALLOWAY_BURNOUT_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S5_R0", "sanity": 14.0},
				{"text": "CONV_HALLOWAY_BURNOUT_S5_R1", "sanity": 12.0}]},
			# 6
			{"them": "CONV_HALLOWAY_BURNOUT_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_BURNOUT_S6_R0", "sanity": 13.0, "goto": 4},
				{"text": "CONV_HALLOWAY_BURNOUT_S6_R1", "sanity": 10.0, "goto": 4}]},
		]},

	{
		"id": "halloway_derived", "speaker": TEACHER_NAME, "role": "teacher", "condition": "exam_soon",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_DERIVED_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S0_R0", "goto": 1},
				{"text": "CONV_HALLOWAY_DERIVED_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "CONV_HALLOWAY_DERIVED_S0_R2", "sanity": 6.0, "goto": 3}]},
			# 1
			{"them": "CONV_HALLOWAY_DERIVED_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S1_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_HALLOWAY_DERIVED_S1_R1", "sanity": 8.0, "goto": 5}]},
			# 2
			{"them": "CONV_HALLOWAY_DERIVED_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S2_R0", "sanity": 8.0, "goto": 5},
				{"text": "CONV_HALLOWAY_DERIVED_S2_R1", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "CONV_HALLOWAY_DERIVED_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S3_R0", "sanity": 8.0, "goto": 4},
				{"text": "CONV_HALLOWAY_DERIVED_S3_R1", "sanity": 8.0, "goto": 5}]},
			# 4
			{"them": "CONV_HALLOWAY_DERIVED_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S4_R0", "sanity": 11.0, "goto": 6},
				{"text": "CONV_HALLOWAY_DERIVED_S4_R1", "sanity": 13.0, "temptation": -4.0, "goto": 6}]},
			# 5
			{"them": "CONV_HALLOWAY_DERIVED_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S5_R0", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "CONV_HALLOWAY_DERIVED_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_DERIVED_S6_R0", "sanity": 10.0},
				{"text": "CONV_HALLOWAY_DERIVED_S6_R1", "sanity": 9.0}]},
		]},

	{
		"id": "halloway_hours", "speaker": TEACHER_NAME, "role": "teacher", "condition": "always",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_HOURS_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S0_R0", "sanity": 9.0, "goto": 1},
				{"text": "CONV_HALLOWAY_HOURS_S0_R1", "sanity": 7.0, "goto": 2},
				{"text": "CONV_HALLOWAY_HOURS_S0_R2", "sanity": 5.0, "goto": 3}]},
			# 1
			{"them": "CONV_HALLOWAY_HOURS_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S1_R0", "sanity": 9.0, "goto": 4}]},
			# 2
			{"them": "CONV_HALLOWAY_HOURS_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S2_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_HALLOWAY_HOURS_S2_R1", "sanity": 10.0, "goto": 4}]},
			# 3
			{"them": "CONV_HALLOWAY_HOURS_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S3_R0", "sanity": 9.0, "goto": 4},
				{"text": "CONV_HALLOWAY_HOURS_S3_R1", "sanity": 8.0, "goto": 5}]},
			# 4
			{"them": "CONV_HALLOWAY_HOURS_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S4_R0", "sanity": 13.0, "goto": 5},
				{"text": "CONV_HALLOWAY_HOURS_S4_R1", "sanity": 10.0, "goto": 5}]},
			# 5
			{"them": "CONV_HALLOWAY_HOURS_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_HOURS_S5_R0", "sanity": 8.0},
				{"text": "CONV_HALLOWAY_HOURS_S5_R1", "sanity": 9.0}]},
		]},

	{
		"id": "halloway_behind", "speaker": TEACHER_NAME, "role": "teacher", "condition": "behind",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_BEHIND_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S0_R0", "sanity": 4.0, "goto": 1},
				{"text": "CONV_HALLOWAY_BEHIND_S0_R1", "sanity": 6.0, "goto": 2}]},
			# 1
			{"them": "CONV_HALLOWAY_BEHIND_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S1_R0", "sanity": 6.0, "goto": 3},
				{"text": "CONV_HALLOWAY_BEHIND_S1_R1", "sanity": 8.0, "goto": 4},
				{"text": "CONV_HALLOWAY_BEHIND_S1_R2", "sanity": 2.0, "goto": 5}]},
			# 2
			{"them": "CONV_HALLOWAY_BEHIND_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S2_R0", "sanity": 5.0, "goto": 1}]},
			# 3
			{"them": "CONV_HALLOWAY_BEHIND_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S3_R0", "sanity": 10.0, "goto": 6}]},
			# 4
			{"them": "CONV_HALLOWAY_BEHIND_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S4_R0", "sanity": 11.0, "goto": 6}]},
			# 5
			{"them": "CONV_HALLOWAY_BEHIND_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S5_R0", "sanity": 13.0, "goto": 6},
				{"text": "CONV_HALLOWAY_BEHIND_S5_R1", "sanity": 9.0, "goto": 6}]},
			# 6
			{"them": "CONV_HALLOWAY_BEHIND_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_BEHIND_S6_R0", "sanity": 15.0, "temptation": -6.0},
				{"text": "CONV_HALLOWAY_BEHIND_S6_R1", "sanity": 10.0}]},
		]},

	{
		"id": "halloway_loan", "speaker": TEACHER_NAME, "role": "teacher", "condition": "no_loan",
		"steps": [
			# 0
			{"them": "CONV_HALLOWAY_LOAN_S0",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S0_R0", "goto": 1},
				{"text": "CONV_HALLOWAY_LOAN_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "CONV_HALLOWAY_LOAN_S0_R2", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "CONV_HALLOWAY_LOAN_S1",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S1_R0", "sanity": 12.0, "goto": 4},
				{"text": "CONV_HALLOWAY_LOAN_S1_R1", "sanity": 9.0, "goto": 5}]},
			# 2
			{"them": "CONV_HALLOWAY_LOAN_S2",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S2_R0", "sanity": 9.0, "goto": 1},
				{"text": "CONV_HALLOWAY_LOAN_S2_R1", "sanity": 6.0, "goto": 1}]},
			# 3
			{"them": "CONV_HALLOWAY_LOAN_S3",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S3_R0", "sanity": 11.0, "goto": 4},
				{"text": "CONV_HALLOWAY_LOAN_S3_R1", "sanity": 10.0, "goto": 4}]},
			# 4
			{"them": "CONV_HALLOWAY_LOAN_S4",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S4_R0", "sanity": 10.0},
				{"text": "CONV_HALLOWAY_LOAN_S4_R1", "sanity": 11.0}]},
			# 5
			{"them": "CONV_HALLOWAY_LOAN_S5",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S5_R0", "sanity": 8.0, "goto": 6},
				{"text": "CONV_HALLOWAY_LOAN_S5_R1", "sanity": 11.0, "goto": 7},
				{"text": "CONV_HALLOWAY_LOAN_S5_R2", "sanity": 10.0, "goto": 7}]},
			# 6
			{"them": "CONV_HALLOWAY_LOAN_S6",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S6_R0", "sanity": 10.0, "goto": 7},
				{"text": "CONV_HALLOWAY_LOAN_S6_R1", "sanity": 9.0, "goto": 7}]},
			# 7
			{"them": "CONV_HALLOWAY_LOAN_S7",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S7_R0", "sanity": 9.0, "goto": 8},
				{"text": "CONV_HALLOWAY_LOAN_S7_R1", "sanity": 12.0, "goto": 4}]},
			# 8
			{"them": "CONV_HALLOWAY_LOAN_S8",
			 "replies": [
				{"text": "CONV_HALLOWAY_LOAN_S8_R0", "sanity": 13.0, "goto": 4},
				{"text": "CONV_HALLOWAY_LOAN_S8_R1", "sanity": 10.0, "goto": 4}]},
		]},
]


# Extra-credit lines

var _teacher_lines_intro: Array = [
	"TEACHER_INTRO_0",
	"TEACHER_INTRO_1",
	"TEACHER_INTRO_2",
	"TEACHER_INTRO_3",
]

var _teacher_lines_correct: Array = [
	"TEACHER_CORRECT_0",
	"TEACHER_CORRECT_1",
	"TEACHER_CORRECT_2",
]

var _teacher_lines_incorrect: Array = [
	"TEACHER_WRONG_0",
	"TEACHER_WRONG_1",
	"TEACHER_WRONG_2",
]


func get_teacher_intro_line() -> String:
	return tr(_teacher_lines_intro[randi() % _teacher_lines_intro.size()])


func get_teacher_result_line(is_correct: bool) -> String:
	var pool: Array = _teacher_lines_correct if is_correct else _teacher_lines_incorrect
	return tr(pool[randi() % pool.size()])
