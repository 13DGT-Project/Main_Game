## MessageData.gd
## Autoload: "MessageData"
## Every conversation in the phone's Messages app. The STATE of each thread
## (arrived / read / how far through it you are / the saved transcript) lives
## on GameBackend, not here, so it survives scene changes. This file is pure
## content plus the delivery rules.
## Thread shape:
##   id        unique string, used as the key in GameBackend.message_state
##   sender    contact name shown in the inbox
##   avatar    two-letter initials for the inbox circle
##   arrives   in-game day it becomes eligible to land (0 = from the start)
##   steps     the conversation, in order
##
## Step shape:
##   them      what they say
##   from      OPTIONAL — for group chats, who specifically said it
##   replies   2-3 options; each has text, optional sanity / temptation,
##             and an optional "goto": <step index> to branch
##
## {NAME} anywhere is replaced with the player's name.
## {UNI} is replaced with the player's chosen university's full name.
##
## BRANCHING
## A reply may carry "goto": <step index> to jump elsewhere in the thread.
## Steps are zero-indexed. Where a reply has no "goto" it simply advances by
## one. A step with no "goto" on its last reply and no following step ends
## the conversation. This is what lets a conversation actually respond to
## what you said rather than railroading to the same next line.
extends Node

signal message_arrived(sender: String)


func _ready() -> void:
	reset_state()


## Nothing to clear locally any more — GameBackend owns thread state. Kept as
## a named function because reset_run() and the ending screen both call it.
func reset_state() -> void:
	pass


# THE CONVERSATIONS

var threads: Array = [

	# --- WEEK 1: the year starts -------------------------------------------
	{
		"id": "mum_check_in", "sender": "Mum", "avatar": "MU", "arrives": 0,
		"steps": [
			{"them": "MSG_MUM_CHECK_IN_S0",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_MUM_CHECK_IN_S0_R1", "sanity": 2.0, "goto": 3},
				{"text": "MSG_MUM_CHECK_IN_S0_R2", "sanity": 1.0, "goto": 5}]},
			{"them": "MSG_MUM_CHECK_IN_S1",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S1_R0", "sanity": 5.0, "goto": 2},
				{"text": "MSG_MUM_CHECK_IN_S1_R1", "sanity": 5.0, "goto": 2}]},
			{"them": "MSG_MUM_CHECK_IN_S2",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S2_R0", "sanity": 8.0, "goto": 6},
				{"text": "MSG_MUM_CHECK_IN_S2_R1", "sanity": 14.0, "goto": 6}]},
			{"them": "MSG_MUM_CHECK_IN_S3",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S3_R0", "sanity": 7.0, "goto": 1},
				{"text": "MSG_MUM_CHECK_IN_S3_R1", "sanity": 3.0, "goto": 4}]},
			{"them": "MSG_MUM_CHECK_IN_S4",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S4_R0", "sanity": 6.0, "goto": 6}]},
			{"them": "MSG_MUM_CHECK_IN_S5",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S5_R0", "sanity": 9.0, "goto": 6},
				{"text": "MSG_MUM_CHECK_IN_S5_R1", "sanity": 5.0, "goto": 6}]},
			{"them": "MSG_MUM_CHECK_IN_S6",
			 "replies": [
				{"text": "MSG_MUM_CHECK_IN_S6_R0", "sanity": 8.0},
				{"text": "MSG_MUM_CHECK_IN_S6_R1", "sanity": 5.0}]},
		]},
	{
		"id": "tane_where_are_you", "sender": "Tane", "avatar": "TA", "arrives": 0,
		"steps": [
			{"them": "MSG_TANE_WHERE_ARE_YOU_S0",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S0_R1", "sanity": 2.0, "goto": 3},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S0_R2", "temptation": 3.0, "goto": 4}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S1",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S1_R0", "sanity": 7.0, "goto": 2},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S1_R1", "sanity": 7.0, "goto": 2}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S2",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S2_R0", "sanity": 14.0, "temptation": 4.0, "goto": 6},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S2_R1", "sanity": 11.0, "temptation": 2.0, "goto": 6}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S3",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S3_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S3_R1", "temptation": 3.0, "goto": 4}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S4",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S4_R0", "sanity": 5.0, "goto": 5},
				{"text": "MSG_TANE_WHERE_ARE_YOU_S4_R1", "sanity": -3.0, "temptation": 4.0, "goto": 6}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S5",
			 "replies": [
				{"text": "MSG_TANE_WHERE_ARE_YOU_S5_R0", "sanity": 7.0, "goto": 6}]},
			{"them": "MSG_TANE_WHERE_ARE_YOU_S6",
			 "replies": [{"text": "MSG_TANE_WHERE_ARE_YOU_S6_R0", "sanity": 2.0}]},
		]},
	{
		"id": "year13_chat", "sender": "Year 13 groupchat", "avatar": "Y13", "arrives": 1,
		"steps": [
			{"from": "Chloe", "them": "MSG_YEAR13_CHAT_S0",
			 "replies": [
				{"text": "MSG_YEAR13_CHAT_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_YEAR13_CHAT_S0_R1", "sanity": 5.0, "goto": 1}]},
			{"from": "Sione", "them": "MSG_YEAR13_CHAT_S1",
			 "replies": [
				{"text": "MSG_YEAR13_CHAT_S1_R0", "sanity": 4.0, "goto": 2},
				{"text": "MSG_YEAR13_CHAT_S1_R1", "sanity": 5.0, "goto": 2}]},
			{"from": "Ana", "them": "MSG_YEAR13_CHAT_S2",
			 "replies": [
				{"text": "MSG_YEAR13_CHAT_S2_R0", "sanity": 10.0},
				{"text": "MSG_YEAR13_CHAT_S2_R1", "sanity": 4.0}]},
		]},
	{
		"id": "school_notices_1", "sender": "School Notices", "avatar": "SN", "arrives": 2,
		"steps": [
			{"them": "MSG_SCHOOL_NOTICES_1_S0",
			 "replies": [
				{"text": "MSG_SCHOOL_NOTICES_1_S0_R0", "goto": 1},
				{"text": "MSG_SCHOOL_NOTICES_1_S0_R1", "sanity": 2.0, "goto": 1}]},
			{"them": "MSG_SCHOOL_NOTICES_1_S1",
			 "replies": [
				{"text": "MSG_SCHOOL_NOTICES_1_S1_R0", "sanity": 2.0},
				{"text": "MSG_SCHOOL_NOTICES_1_S1_R1", "temptation": 3.0}]},
		]},
	{
		"id": "work_first_roster", "sender": "Deb (work)", "avatar": "DE", "arrives": 3,
		"requires": "still_employed",
		"steps": [
			{"them": "MSG_WORK_FIRST_ROSTER_S0",
			 "replies": [
				{"text": "MSG_WORK_FIRST_ROSTER_S0_R0", "goto": 1, "commit": {"kind": "work", "label": "COMMIT_SUPERMARKET_SHIFT", "in": 2}},
				{"text": "MSG_WORK_FIRST_ROSTER_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "MSG_WORK_FIRST_ROSTER_S0_R2", "sanity": 5.0, "goto": 3}]},
			{"them": "MSG_WORK_FIRST_ROSTER_S1",
			 "replies": [{"text": "MSG_WORK_FIRST_ROSTER_S1_R0", "sanity": 2.0}]},
			{"them": "MSG_WORK_FIRST_ROSTER_S2",
			 "replies": [
				{"text": "MSG_WORK_FIRST_ROSTER_S2_R0", "sanity": 5.0},
				{"text": "MSG_WORK_FIRST_ROSTER_S2_R1", "sanity": -2.0}]},
			{"them": "MSG_WORK_FIRST_ROSTER_S3",
			 "replies": [
				{"text": "MSG_WORK_FIRST_ROSTER_S3_R0", "sanity": 9.0},
				{"text": "MSG_WORK_FIRST_ROSTER_S3_R1", "sanity": 3.0}]},
		]},
	{
		"id": "study_group_forming", "sender": "Study group", "avatar": "SG", "arrives": 4,
		"steps": [
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FORMING_S0",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FORMING_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_STUDY_GROUP_FORMING_S0_R1", "sanity": 3.0, "goto": 2}]},
			{"from": "Mika", "them": "MSG_STUDY_GROUP_FORMING_S1",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FORMING_S1_R0", "sanity": 6.0, "goto": 3}]},
			{"from": "Mika", "them": "MSG_STUDY_GROUP_FORMING_S2",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FORMING_S2_R0", "sanity": 8.0, "temptation": -2.0, "goto": 3},
				{"text": "MSG_STUDY_GROUP_FORMING_S2_R1", "sanity": 2.0, "goto": 4}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FORMING_S3",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FORMING_S3_R0", "sanity": 10.0, "temptation": -4.0, "goto": 5, "commit": {"kind": "study_group", "label": "COMMIT_STUDY_GROUP_LIBRARY", "in": 3}},
				{"text": "MSG_STUDY_GROUP_FORMING_S3_R1", "sanity": 5.0, "goto": 5},
				{"text": "MSG_STUDY_GROUP_FORMING_S3_R2", "sanity": 2.0, "goto": 4}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FORMING_S4",
			 "replies": [{"text": "MSG_STUDY_GROUP_FORMING_S4_R0", "sanity": 3.0}]},
			{"from": "Mika", "them": "MSG_STUDY_GROUP_FORMING_S5",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FORMING_S5_R0", "sanity": 8.0},
				{"text": "MSG_STUDY_GROUP_FORMING_S5_R1", "sanity": 6.0}]},
		]},
	{
		"id": "nan_first_text", "sender": "Nan", "avatar": "NA", "arrives": 5,
		"steps": [
			{"them": "MSG_NAN_FIRST_TEXT_S0",
			 "replies": [
				{"text": "MSG_NAN_FIRST_TEXT_S0_R0", "sanity": 9.0, "goto": 1},
				{"text": "MSG_NAN_FIRST_TEXT_S0_R1", "sanity": 6.0, "goto": 2}]},
			{"them": "MSG_NAN_FIRST_TEXT_S1",
			 "replies": [
				{"text": "MSG_NAN_FIRST_TEXT_S1_R0", "sanity": 11.0, "goto": 3},
				{"text": "MSG_NAN_FIRST_TEXT_S1_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_NAN_FIRST_TEXT_S2",
			 "replies": [{"text": "MSG_NAN_FIRST_TEXT_S2_R0", "sanity": 10.0, "goto": 1}]},
			{"them": "MSG_NAN_FIRST_TEXT_S3",
			 "replies": [{"text": "MSG_NAN_FIRST_TEXT_S3_R0", "sanity": 13.0}]},
		]},

	# --- WEEKS 2-4: settling in-------------------------------
	{
		"id": "careers_confirm", "sender": "Careers Advisor", "avatar": "CA", "arrives": 8,
		"requires": "before_results",
		"steps": [
			{"them": "MSG_CAREERS_CONFIRM_S0",
			 "replies": [
				{"text": "MSG_CAREERS_CONFIRM_S0_R0", "sanity": 4.0, "goto": 1},
				{"text": "MSG_CAREERS_CONFIRM_S0_R1", "sanity": 6.0, "goto": 2}]},
			{"them": "MSG_CAREERS_CONFIRM_S1",
			 "replies": [
				{"text": "MSG_CAREERS_CONFIRM_S1_R0", "sanity": 6.0, "goto": 3},
				{"text": "MSG_CAREERS_CONFIRM_S1_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_CAREERS_CONFIRM_S2",
			 "replies": [
				{"text": "MSG_CAREERS_CONFIRM_S2_R0", "sanity": 11.0, "goto": 3},
				{"text": "MSG_CAREERS_CONFIRM_S2_R1", "sanity": 6.0, "goto": 3}]},
			{"them": "MSG_CAREERS_CONFIRM_S3",
			 "replies": [
				{"text": "MSG_CAREERS_CONFIRM_S3_R0", "sanity": 8.0},
				{"text": "MSG_CAREERS_CONFIRM_S3_R1", "temptation": 4.0}]},
		]},
	{
		"id": "priya_law_or_commerce", "sender": "Priya", "avatar": "PR", "arrives": 10,
		"steps": [
			{"them": "MSG_PRIYA_LAW_OR_COMMERCE_S0",
			 "replies": [
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S0_R1", "sanity": 5.0, "goto": 1}]},
			{"them": "MSG_PRIYA_LAW_OR_COMMERCE_S1",
			 "replies": [
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S1_R0", "sanity": 11.0, "goto": 2},
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S1_R1", "sanity": 10.0, "goto": 2},
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S1_R2", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_PRIYA_LAW_OR_COMMERCE_S2",
			 "replies": [
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S2_R0", "sanity": 8.0},
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S2_R1", "sanity": 10.0}]},
			{"them": "MSG_PRIYA_LAW_OR_COMMERCE_S3",
			 "replies": [
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S3_R0", "sanity": 12.0},
				{"text": "MSG_PRIYA_LAW_OR_COMMERCE_S3_R1", "sanity": 9.0}]},
		]},
	{
		"id": "sione_gym", "sender": "Sione", "avatar": "SI", "arrives": 11,
		"steps": [
			{"them": "MSG_SIONE_GYM_S0",
			 "replies": [
				{"text": "MSG_SIONE_GYM_S0_R0", "sanity": 11.0, "temptation": 3.0, "goto": 1},
				{"text": "MSG_SIONE_GYM_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "MSG_SIONE_GYM_S0_R2", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_SIONE_GYM_S1",
			 "replies": [{"text": "MSG_SIONE_GYM_S1_R0", "sanity": 5.0}]},
			{"them": "MSG_SIONE_GYM_S2",
			 "replies": [{"text": "MSG_SIONE_GYM_S2_R0", "sanity": 5.0}]},
			{"them": "MSG_SIONE_GYM_S3",
			 "replies": [
				{"text": "MSG_SIONE_GYM_S3_R0", "sanity": 12.0, "temptation": 2.0},
				{"text": "MSG_SIONE_GYM_S3_R1", "sanity": 5.0}]},
		]},
	{
		"id": "wrong_number", "sender": "Unknown number", "avatar": "??", "arrives": 12,
		"steps": [
			{"them": "MSG_WRONG_NUMBER_S0",
			 "replies": [
				{"text": "MSG_WRONG_NUMBER_S0_R0", "goto": 1},
				{"text": "MSG_WRONG_NUMBER_S0_R1", "temptation": 2.0, "goto": 2}]},
			{"them": "MSG_WRONG_NUMBER_S1",
			 "replies": [
				{"text": "MSG_WRONG_NUMBER_S1_R0", "sanity": 6.0, "goto": 3},
				{"text": "MSG_WRONG_NUMBER_S1_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_WRONG_NUMBER_S2",
			 "replies": [
				{"text": "MSG_WRONG_NUMBER_S2_R0", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_WRONG_NUMBER_S3",
			 "replies": [
				{"text": "MSG_WRONG_NUMBER_S3_R0", "sanity": 5.0}]},
		]},
	{
		"id": "mika_group_project", "sender": "Mika", "avatar": "MI", "arrives": 14,
		"steps": [
			{"them": "MSG_MIKA_GROUP_PROJECT_S0",
			 "replies": [
				{"text": "MSG_MIKA_GROUP_PROJECT_S0_R0", "sanity": 10.0, "temptation": -2.0, "goto": 1},
				{"text": "MSG_MIKA_GROUP_PROJECT_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_MIKA_GROUP_PROJECT_S0_R2", "sanity": 5.0, "goto": 3}]},
			{"them": "MSG_MIKA_GROUP_PROJECT_S1",
			 "replies": [
				{"text": "MSG_MIKA_GROUP_PROJECT_S1_R0", "sanity": 7.0},
				{"text": "MSG_MIKA_GROUP_PROJECT_S1_R1", "sanity": 8.0}]},
			{"them": "MSG_MIKA_GROUP_PROJECT_S2",
			 "replies": [
				{"text": "MSG_MIKA_GROUP_PROJECT_S2_R0", "sanity": 7.0},
				{"text": "MSG_MIKA_GROUP_PROJECT_S2_R1", "sanity": 5.0}]},
			{"them": "MSG_MIKA_GROUP_PROJECT_S3",
			 "replies": [
				{"text": "MSG_MIKA_GROUP_PROJECT_S3_R0", "sanity": 8.0},
				{"text": "MSG_MIKA_GROUP_PROJECT_S3_R1", "sanity": 9.0}]},
		]},
	{
		"id": "chloe_prank", "sender": "Chloe", "avatar": "CH", "arrives": 16,
		"steps": [
			{"them": "MSG_CHLOE_PRANK_S0",
			 "replies": [
				{"text": "MSG_CHLOE_PRANK_S0_R0", "sanity": 1.0, "goto": 1},
				{"text": "MSG_CHLOE_PRANK_S0_R1", "sanity": 5.0, "goto": 2}]},
			{"them": "MSG_CHLOE_PRANK_S1",
			 "replies": [
				{"text": "MSG_CHLOE_PRANK_S1_R0", "sanity": 6.0},
				{"text": "MSG_CHLOE_PRANK_S1_R1", "sanity": 5.0}]},
			{"them": "MSG_CHLOE_PRANK_S2",
			 "replies": [{"text": "MSG_CHLOE_PRANK_S2_R0", "sanity": 7.0}]},
		]},
	{
		"id": "dad_awkward", "sender": "Dad", "avatar": "DA", "arrives": 17,
		"steps": [
			{"them": "MSG_DAD_AWKWARD_S0",
			 "replies": [
				{"text": "MSG_DAD_AWKWARD_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_DAD_AWKWARD_S0_R1", "sanity": 2.0, "goto": 2},
				{"text": "MSG_DAD_AWKWARD_S0_R2", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_DAD_AWKWARD_S1",
			 "replies": [
				{"text": "MSG_DAD_AWKWARD_S1_R0", "sanity": 9.0, "goto": 4},
				{"text": "MSG_DAD_AWKWARD_S1_R1", "sanity": 8.0, "goto": 4}]},
			{"them": "MSG_DAD_AWKWARD_S2",
			 "replies": [
				{"text": "MSG_DAD_AWKWARD_S2_R0", "sanity": 7.0, "goto": 1},
				{"text": "MSG_DAD_AWKWARD_S2_R1", "sanity": 3.0, "goto": 4}]},
			{"them": "MSG_DAD_AWKWARD_S3",
			 "replies": [
				{"text": "MSG_DAD_AWKWARD_S3_R0", "sanity": 7.0, "goto": 4}]},
			{"them": "MSG_DAD_AWKWARD_S4",
			 "replies": [
				{"text": "MSG_DAD_AWKWARD_S4_R0", "sanity": 13.0},
				{"text": "MSG_DAD_AWKWARD_S4_R1", "sanity": 6.0}]},
		]},
	{
		"id": "manaia_at_uni", "sender": "Manaia (cousin)", "avatar": "MA", "arrives": 19,
		"steps": [
			{"them": "MSG_MANAIA_AT_UNI_S0",
			 "replies": [
				{"text": "MSG_MANAIA_AT_UNI_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_MANAIA_AT_UNI_S0_R1", "sanity": 3.0, "goto": 2}]},
			{"them": "MSG_MANAIA_AT_UNI_S1",
			 "replies": [
				{"text": "MSG_MANAIA_AT_UNI_S1_R0", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_MANAIA_AT_UNI_S2",
			 "replies": [
				{"text": "MSG_MANAIA_AT_UNI_S2_R0", "sanity": 3.0, "goto": 3}]},
			{"them": "MSG_MANAIA_AT_UNI_S3",
			 "replies": [
				{"text": "MSG_MANAIA_AT_UNI_S3_R0", "sanity": 12.0, "goto": 4},
				{"text": "MSG_MANAIA_AT_UNI_S3_R1", "sanity": 5.0, "goto": 4}]},
			{"them": "MSG_MANAIA_AT_UNI_S4",
			 "replies": [
				{"text": "MSG_MANAIA_AT_UNI_S4_R0", "sanity": 10.0},
				{"text": "MSG_MANAIA_AT_UNI_S4_R1", "sanity": 6.0}]},
		]},
	{
		"id": "josh_notes", "sender": "Josh (maths)", "avatar": "JO", "arrives": 21,
		"steps": [
			{"them": "MSG_JOSH_NOTES_S0",
			 "replies": [
				{"text": "MSG_JOSH_NOTES_S0_R0", "sanity": 7.0, "goto": 1},
				{"text": "MSG_JOSH_NOTES_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_JOSH_NOTES_S0_R2", "sanity": 3.0, "goto": 3}]},
			{"them": "MSG_JOSH_NOTES_S1",
			 "replies": [
				{"text": "MSG_JOSH_NOTES_S1_R0", "sanity": 8.0},
				{"text": "MSG_JOSH_NOTES_S1_R1", "sanity": 5.0}]},
			{"them": "MSG_JOSH_NOTES_S2",
			 "replies": [{"text": "MSG_JOSH_NOTES_S2_R0", "sanity": 6.0}]},
			{"them": "MSG_JOSH_NOTES_S3",
			 "replies": [
				{"text": "MSG_JOSH_NOTES_S3_R0", "sanity": 7.0},
				{"text": "MSG_JOSH_NOTES_S3_R1", "sanity": 8.0}]},
		]},

	# --- WEEKS 4-8: the middle, where it gets heavy -------------------------
	{
		"id": "work_extra_shift", "sender": "Deb (work)", "avatar": "DE", "arrives": 23,
		"requires": "still_employed",
		"steps": [
			{"them": "MSG_WORK_EXTRA_SHIFT_S0",
			 "replies": [
				{"text": "MSG_WORK_EXTRA_SHIFT_S0_R0", "sanity": -3.0, "goto": 1, "commit": {"kind": "work", "label": "COMMIT_EXTRA_THURSDAY", "in": 2}},
				{"text": "MSG_WORK_EXTRA_SHIFT_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_WORK_EXTRA_SHIFT_S0_R2", "sanity": 6.0, "goto": 3}]},
			{"them": "MSG_WORK_EXTRA_SHIFT_S1",
			 "replies": [{"text": "MSG_WORK_EXTRA_SHIFT_S1_R0", "sanity": 1.0}]},
			{"them": "MSG_WORK_EXTRA_SHIFT_S2",
			 "replies": [{"text": "MSG_WORK_EXTRA_SHIFT_S2_R0", "sanity": 5.0}]},
			{"them": "MSG_WORK_EXTRA_SHIFT_S3",
			 "replies": [
				{"text": "MSG_WORK_EXTRA_SHIFT_S3_R0", "sanity": 12.0},
				{"text": "MSG_WORK_EXTRA_SHIFT_S3_R1", "sanity": 4.0}]},
		]},
	{
		"id": "ana_noticed", "sender": "Ana", "avatar": "AN", "arrives": 25,
		"steps": [
			{"them": "MSG_ANA_NOTICED_S0",
			 "replies": [
				{"text": "MSG_ANA_NOTICED_S0_R0", "sanity": 10.0, "goto": 1},
				{"text": "MSG_ANA_NOTICED_S0_R1", "sanity": 7.0, "goto": 2},
				{"text": "MSG_ANA_NOTICED_S0_R2", "sanity": 3.0, "goto": 2}]},
			{"them": "MSG_ANA_NOTICED_S1",
			 "replies": [
				{"text": "MSG_ANA_NOTICED_S1_R0", "sanity": 13.0, "goto": 3},
				{"text": "MSG_ANA_NOTICED_S1_R1", "sanity": 10.0, "goto": 4}]},
			{"them": "MSG_ANA_NOTICED_S2",
			 "replies": [{"text": "MSG_ANA_NOTICED_S2_R0", "sanity": 8.0}]},
			{"them": "MSG_ANA_NOTICED_S3",
			 "replies": [
				{"text": "MSG_ANA_NOTICED_S3_R0", "sanity": 15.0},
				{"text": "MSG_ANA_NOTICED_S3_R1", "sanity": 12.0}]},
			{"them": "MSG_ANA_NOTICED_S4",
			 "replies": [
				{"text": "MSG_ANA_NOTICED_S4_R0", "sanity": 13.0},
				{"text": "MSG_ANA_NOTICED_S4_R1", "sanity": 8.0}]},
		]},
	{
		"id": "work_chat", "sender": "Store groupchat", "avatar": "WK", "arrives": 27,
		"requires": "still_employed",
		"steps": [
			{"from": "Reti", "them": "MSG_WORK_CHAT_S0",
			 "replies": [
				{"text": "MSG_WORK_CHAT_S0_R0", "sanity": 4.0, "goto": 1},
				{"text": "MSG_WORK_CHAT_S0_R1", "sanity": 3.0, "goto": 2}]},
			{"from": "Reti", "them": "MSG_WORK_CHAT_S1",
			 "replies": [
				{"text": "MSG_WORK_CHAT_S1_R0", "sanity": 6.0, "goto": 3}]},
			{"from": "Reti", "them": "MSG_WORK_CHAT_S2",
			 "replies": [
				{"text": "MSG_WORK_CHAT_S2_R0", "sanity": 5.0, "goto": 3},
				{"text": "MSG_WORK_CHAT_S2_R1", "sanity": 8.0, "goto": 3}]},
			{"from": "Deb", "them": "MSG_WORK_CHAT_S3",
			 "replies": [
				{"text": "MSG_WORK_CHAT_S3_R0", "sanity": 9.0},
				{"text": "MSG_WORK_CHAT_S3_R1", "sanity": 8.0}]},
		]},
	{
		"id": "tane_panic", "sender": "Tane", "avatar": "TA", "arrives": 29,
		"steps": [
			{"them": "MSG_TANE_PANIC_S0",
			 "replies": [
				{"text": "MSG_TANE_PANIC_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_TANE_PANIC_S0_R1", "sanity": 4.0, "goto": 1}]},
			{"them": "MSG_TANE_PANIC_S1",
			 "replies": [
				{"text": "MSG_TANE_PANIC_S1_R0", "sanity": 9.0, "goto": 2},
				{"text": "MSG_TANE_PANIC_S1_R1", "sanity": 11.0, "temptation": 3.0, "goto": 3},
				{"text": "MSG_TANE_PANIC_S1_R2", "sanity": 3.0, "goto": 4}]},
			{"them": "MSG_TANE_PANIC_S2",
			 "replies": [{"text": "MSG_TANE_PANIC_S2_R0", "sanity": 7.0}]},
			{"them": "MSG_TANE_PANIC_S3",
			 "replies": [{"text": "MSG_TANE_PANIC_S3_R0", "sanity": 9.0}]},
			{"them": "MSG_TANE_PANIC_S4",
			 "replies": [{"text": "MSG_TANE_PANIC_S4_R0", "sanity": 5.0}]},
		]},
	{
		"id": "scam_prize", "sender": "Unknown number", "avatar": "??", "arrives": 30,
		"steps": [
			{"them": "MSG_SCAM_PRIZE_S0",
			 "replies": [
				{"text": "MSG_SCAM_PRIZE_S0_R0", "sanity": 4.0, "goto": 2},
				{"text": "MSG_SCAM_PRIZE_S0_R1", "sanity": 1.0, "temptation": 3.0, "goto": 1}]},
			{"them": "MSG_SCAM_PRIZE_S1",
			 "replies": [{"text": "MSG_SCAM_PRIZE_S1_R0", "sanity": 5.0, "goto": 2}]},
			{"them": "MSG_SCAM_PRIZE_S2",
			 "replies": [{"text": "MSG_SCAM_PRIZE_S2_R0", "sanity": 2.0}]},
		]},
	{
		"id": "wiremu_last_game", "sender": "Wiremu", "avatar": "WI", "arrives": 32,
		"steps": [
			{"them": "MSG_WIREMU_LAST_GAME_S0",
			 "replies": [
				{"text": "MSG_WIREMU_LAST_GAME_S0_R0", "sanity": 12.0, "temptation": 5.0, "goto": 1},
				{"text": "MSG_WIREMU_LAST_GAME_S0_R1", "sanity": 8.0, "temptation": 2.0, "goto": 2},
				{"text": "MSG_WIREMU_LAST_GAME_S0_R2", "sanity": 3.0, "goto": 3}]},
			{"them": "MSG_WIREMU_LAST_GAME_S1",
			 "replies": [{"text": "MSG_WIREMU_LAST_GAME_S1_R0", "sanity": 8.0}]},
			{"them": "MSG_WIREMU_LAST_GAME_S2",
			 "replies": [{"text": "MSG_WIREMU_LAST_GAME_S2_R0", "sanity": 9.0}]},
			{"them": "MSG_WIREMU_LAST_GAME_S3",
			 "replies": [
				{"text": "MSG_WIREMU_LAST_GAME_S3_R0", "sanity": 9.0, "temptation": 3.0},
				{"text": "MSG_WIREMU_LAST_GAME_S3_R1", "sanity": 4.0}]},
		]},
	{
		"id": "nan_recipe", "sender": "Nan", "avatar": "NA", "arrives": 34,
		"steps": [
			{"them": "MSG_NAN_RECIPE_S0",
			 "replies": [
				{"text": "MSG_NAN_RECIPE_S0_R0", "sanity": 9.0, "goto": 1},
				{"text": "MSG_NAN_RECIPE_S0_R1", "sanity": 7.0, "goto": 2}]},
			{"them": "MSG_NAN_RECIPE_S1",
			 "replies": [
				{"text": "MSG_NAN_RECIPE_S1_R0", "sanity": 12.0, "goto": 3},
				{"text": "MSG_NAN_RECIPE_S1_R1", "sanity": 8.0, "goto": 3}]},
			{"them": "MSG_NAN_RECIPE_S2",
			 "replies": [
				{"text": "MSG_NAN_RECIPE_S2_R0", "sanity": 10.0, "goto": 1}]},
			{"them": "MSG_NAN_RECIPE_S3",
			 "replies": [
				{"text": "MSG_NAN_RECIPE_S3_R0", "sanity": 13.0},
				{"text": "MSG_NAN_RECIPE_S3_R1", "sanity": 11.0}]},
		]},
	{
		"id": "study_group_slipping", "sender": "Study group", "avatar": "SG", "arrives": 36,
		"steps": [
			{"from": "Priya", "them": "MSG_STUDY_GROUP_SLIPPING_S0",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_SLIPPING_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_STUDY_GROUP_SLIPPING_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "MSG_STUDY_GROUP_SLIPPING_S0_R2", "sanity": 4.0, "goto": 1}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_SLIPPING_S1",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_SLIPPING_S1_R0", "sanity": 12.0, "temptation": -4.0, "goto": 3, "commit": {"kind": "study_group", "label": "COMMIT_STUDY_GROUP_PRIYA", "in": 3}},
				{"text": "MSG_STUDY_GROUP_SLIPPING_S1_R1", "sanity": 11.0, "goto": 3}]},
			{"from": "Mika", "them": "MSG_STUDY_GROUP_SLIPPING_S2",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_SLIPPING_S2_R0", "sanity": 7.0, "goto": 3}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_SLIPPING_S3",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_SLIPPING_S3_R0", "sanity": 9.0},
				{"text": "MSG_STUDY_GROUP_SLIPPING_S3_R1", "sanity": 8.0}]},
		]},
	{
		"id": "neighbour_lawns", "sender": "Mrs Tuiloma", "avatar": "MT", "arrives": 38,
		"steps": [
			{"them": "MSG_NEIGHBOUR_LAWNS_S0",
			 "replies": [
				{"text": "MSG_NEIGHBOUR_LAWNS_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_NEIGHBOUR_LAWNS_S0_R1", "sanity": 2.0, "goto": 2},
				{"text": "MSG_NEIGHBOUR_LAWNS_S0_R2", "sanity": 9.0, "goto": 3}]},
			{"them": "MSG_NEIGHBOUR_LAWNS_S1",
			 "replies": [
				{"text": "MSG_NEIGHBOUR_LAWNS_S1_R0", "sanity": 8.0},
				{"text": "MSG_NEIGHBOUR_LAWNS_S1_R1", "sanity": 9.0}]},
			{"them": "MSG_NEIGHBOUR_LAWNS_S2",
			 "replies": [
				{"text": "MSG_NEIGHBOUR_LAWNS_S2_R0", "sanity": 7.0},
				{"text": "MSG_NEIGHBOUR_LAWNS_S2_R1", "sanity": 9.0}]},
			{"them": "MSG_NEIGHBOUR_LAWNS_S3",
			 "replies": [
				{"text": "MSG_NEIGHBOUR_LAWNS_S3_R0", "sanity": 10.0},
				{"text": "MSG_NEIGHBOUR_LAWNS_S3_R1", "sanity": 11.0}]},
		]},
	{
		"id": "school_notices_timetable", "sender": "School Notices", "avatar": "SN", "arrives": 40,
		"steps": [
			{"them": "MSG_SCHOOL_NOTICES_TIMETABLE_S0",
			 "replies": [
				{"text": "MSG_SCHOOL_NOTICES_TIMETABLE_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_SCHOOL_NOTICES_TIMETABLE_S0_R1", "sanity": 1.0, "goto": 1}]},
			{"them": "MSG_SCHOOL_NOTICES_TIMETABLE_S1",
			 "replies": [
				{"text": "MSG_SCHOOL_NOTICES_TIMETABLE_S1_R0", "sanity": 3.0},
				{"text": "MSG_SCHOOL_NOTICES_TIMETABLE_S1_R1", "sanity": 2.0}]},
		]},
	{
		"id": "mum_worried", "sender": "Mum", "avatar": "MU", "arrives": 42,
		"steps": [
			{"them": "MSG_MUM_WORRIED_S0",
			 "replies": [
				{"text": "MSG_MUM_WORRIED_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_MUM_WORRIED_S0_R1", "sanity": 8.0, "goto": 2},
				{"text": "MSG_MUM_WORRIED_S0_R2", "sanity": 2.0, "goto": 3}]},
			{"them": "MSG_MUM_WORRIED_S1",
			 "replies": [
				{"text": "MSG_MUM_WORRIED_S1_R0", "sanity": 9.0, "goto": 4},
				{"text": "MSG_MUM_WORRIED_S1_R1", "sanity": 4.0, "goto": 4}]},
			{"them": "MSG_MUM_WORRIED_S2",
			 "replies": [
				{"text": "MSG_MUM_WORRIED_S2_R0", "sanity": 10.0, "goto": 4},
				{"text": "MSG_MUM_WORRIED_S2_R1", "sanity": 7.0, "goto": 4}]},
			{"them": "MSG_MUM_WORRIED_S3",
			 "replies": [
				{"text": "MSG_MUM_WORRIED_S3_R0", "sanity": 6.0, "goto": 4}]},
			{"them": "MSG_MUM_WORRIED_S4",
			 "replies": [
				{"text": "MSG_MUM_WORRIED_S4_R0", "sanity": 14.0},
				{"text": "MSG_MUM_WORRIED_S4_R1", "sanity": 8.0}]},
		]},
	{
		"id": "ball_committee", "sender": "Ball committee", "avatar": "BC", "arrives": 44,
		"steps": [
			{"from": "Chloe", "them": "MSG_BALL_COMMITTEE_S0",
			 "replies": [
				{"text": "MSG_BALL_COMMITTEE_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_BALL_COMMITTEE_S0_R1", "sanity": 8.0, "temptation": 4.0, "goto": 2},
				{"text": "MSG_BALL_COMMITTEE_S0_R2", "sanity": 3.0, "goto": 3}]},
			{"from": "Chloe", "them": "MSG_BALL_COMMITTEE_S1",
			 "replies": [
				{"text": "MSG_BALL_COMMITTEE_S1_R0", "sanity": 9.0, "goto": 3},
				{"text": "MSG_BALL_COMMITTEE_S1_R1", "sanity": 7.0, "temptation": 4.0, "goto": 2}]},
			{"from": "Chloe", "them": "MSG_BALL_COMMITTEE_S2",
			 "replies": [
				{"text": "MSG_BALL_COMMITTEE_S2_R0", "sanity": 8.0},
				{"text": "MSG_BALL_COMMITTEE_S2_R1", "sanity": 7.0}]},
			{"from": "Ana", "them": "MSG_BALL_COMMITTEE_S3",
			 "replies": [
				{"text": "MSG_BALL_COMMITTEE_S3_R0", "sanity": 9.0},
				{"text": "MSG_BALL_COMMITTEE_S3_R1", "sanity": 5.0}]},
		]},
	{
		"id": "bank_alert", "sender": "Bank", "avatar": "$", "arrives": 46,
		"steps": [
			{"them": "MSG_BANK_ALERT_S0",
			 "replies": [
				{"text": "MSG_BANK_ALERT_S0_R0", "goto": 1},
				{"text": "MSG_BANK_ALERT_S0_R1", "temptation": 3.0, "goto": 2}]},
			{"them": "MSG_BANK_ALERT_S1",
			 "replies": [
				{"text": "MSG_BANK_ALERT_S1_R0", "sanity": 3.0, "goto": 3},
				{"text": "MSG_BANK_ALERT_S1_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_BANK_ALERT_S2",
			 "replies": [
				{"text": "MSG_BANK_ALERT_S2_R0", "sanity": 3.0, "goto": 1}]},
			{"them": "MSG_BANK_ALERT_S3",
			 "replies": [
				{"text": "MSG_BANK_ALERT_S3_R0", "sanity": 2.0},
				{"text": "MSG_BANK_ALERT_S3_R1", "sanity": 6.0}]},
		]},
	{
		"id": "tane_apology", "sender": "Tane", "avatar": "TA", "arrives": 48,
		"steps": [
			{"them": "MSG_TANE_APOLOGY_S0",
			 "replies": [
				{"text": "MSG_TANE_APOLOGY_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "MSG_TANE_APOLOGY_S0_R1", "sanity": 6.0, "goto": 2},
				{"text": "MSG_TANE_APOLOGY_S0_R2", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_TANE_APOLOGY_S1",
			 "replies": [
				{"text": "MSG_TANE_APOLOGY_S1_R0", "sanity": 11.0, "goto": 3},
				{"text": "MSG_TANE_APOLOGY_S1_R1", "sanity": 9.0, "goto": 3}]},
			{"them": "MSG_TANE_APOLOGY_S2",
			 "replies": [
				{"text": "MSG_TANE_APOLOGY_S2_R0", "sanity": 8.0, "goto": 3}]},
			{"them": "MSG_TANE_APOLOGY_S3",
			 "replies": [
				{"text": "MSG_TANE_APOLOGY_S3_R0", "sanity": 14.0, "temptation": 3.0},
				{"text": "MSG_TANE_APOLOGY_S3_R1", "sanity": 12.0, "temptation": 3.0}]},
		]},
	{
		"id": "dairy_owner", "sender": "Ravi (dairy)", "avatar": "RA", "arrives": 50,
		"steps": [
			{"them": "MSG_DAIRY_OWNER_S0",
			 "replies": [
				{"text": "MSG_DAIRY_OWNER_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_DAIRY_OWNER_S0_R1", "sanity": 4.0, "goto": 2}]},
			{"them": "MSG_DAIRY_OWNER_S1",
			 "replies": [
				{"text": "MSG_DAIRY_OWNER_S1_R0", "sanity": 6.0, "goto": 3},
				{"text": "MSG_DAIRY_OWNER_S1_R1", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_DAIRY_OWNER_S2",
			 "replies": [
				{"text": "MSG_DAIRY_OWNER_S2_R0", "sanity": 6.0, "goto": 1}]},
			{"them": "MSG_DAIRY_OWNER_S3",
			 "replies": [
				{"text": "MSG_DAIRY_OWNER_S3_R0", "sanity": 8.0},
				{"text": "MSG_DAIRY_OWNER_S3_R1", "sanity": 9.0}]},
		]},
	{
		"id": "mika_meltdown", "sender": "Mika", "avatar": "MI", "arrives": 52,
		"steps": [
			{"them": "MSG_MIKA_MELTDOWN_S0",
			 "replies": [
				{"text": "MSG_MIKA_MELTDOWN_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "MSG_MIKA_MELTDOWN_S0_R1", "sanity": 7.0, "goto": 2},
				{"text": "MSG_MIKA_MELTDOWN_S0_R2", "sanity": 5.0, "goto": 3}]},
			{"them": "MSG_MIKA_MELTDOWN_S1",
			 "replies": [
				{"text": "MSG_MIKA_MELTDOWN_S1_R0", "sanity": 9.0, "goto": 4},
				{"text": "MSG_MIKA_MELTDOWN_S1_R1", "sanity": 6.0, "goto": 4},
				{"text": "MSG_MIKA_MELTDOWN_S1_R2", "sanity": 10.0, "goto": 4}]},
			{"them": "MSG_MIKA_MELTDOWN_S2",
			 "replies": [
				{"text": "MSG_MIKA_MELTDOWN_S2_R0", "sanity": 8.0, "goto": 4}]},
			{"them": "MSG_MIKA_MELTDOWN_S3",
			 "replies": [
				{"text": "MSG_MIKA_MELTDOWN_S3_R0", "sanity": 9.0, "goto": 4}]},
			{"them": "MSG_MIKA_MELTDOWN_S4",
			 "replies": [
				{"text": "MSG_MIKA_MELTDOWN_S4_R0", "sanity": 11.0},
				{"text": "MSG_MIKA_MELTDOWN_S4_R1", "sanity": 9.0}]},
		]},

	# --- WEEKS 8-11: exam run-in --------------------------------------------
	{
		"id": "studylink_reminder", "sender": "StudyLink", "avatar": "SL", "arrives": 54,
		"requires": "no_loan_application",
		"steps": [
			{"them": "MSG_STUDYLINK_REMINDER_S0",
			 "replies": [
				{"text": "MSG_STUDYLINK_REMINDER_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_STUDYLINK_REMINDER_S0_R1", "sanity": 1.0, "goto": 2},
				{"text": "MSG_STUDYLINK_REMINDER_S0_R2", "goto": 3}]},
			{"them": "MSG_STUDYLINK_REMINDER_S1",
			 "replies": [
				{"text": "MSG_STUDYLINK_REMINDER_S1_R0", "sanity": 4.0, "goto": 4}]},
			{"them": "MSG_STUDYLINK_REMINDER_S2",
			 "replies": [
				{"text": "MSG_STUDYLINK_REMINDER_S2_R0", "sanity": 6.0, "goto": 4},
				{"text": "MSG_STUDYLINK_REMINDER_S2_R1", "sanity": 2.0, "goto": 4}]},
			{"them": "MSG_STUDYLINK_REMINDER_S3",
			 "replies": [
				{"text": "MSG_STUDYLINK_REMINDER_S3_R0", "sanity": 5.0, "goto": 4}]},
			{"them": "MSG_STUDYLINK_REMINDER_S4",
			 "replies": [
				{"text": "MSG_STUDYLINK_REMINDER_S4_R0", "sanity": 4.0},
				{"text": "MSG_STUDYLINK_REMINDER_S4_R1", "sanity": 7.0}]},
		]},
	{
		"id": "priya_wobble", "sender": "Priya", "avatar": "PR", "arrives": 56,
		"steps": [
			{"them": "MSG_PRIYA_WOBBLE_S0",
			 "replies": [
				{"text": "MSG_PRIYA_WOBBLE_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_PRIYA_WOBBLE_S0_R1", "sanity": 8.0, "goto": 2},
				{"text": "MSG_PRIYA_WOBBLE_S0_R2", "sanity": 4.0, "goto": 1}]},
			{"them": "MSG_PRIYA_WOBBLE_S1",
			 "replies": [
				{"text": "MSG_PRIYA_WOBBLE_S1_R0", "sanity": 11.0, "goto": 3},
				{"text": "MSG_PRIYA_WOBBLE_S1_R1", "sanity": 9.0, "goto": 3}]},
			{"them": "MSG_PRIYA_WOBBLE_S2",
			 "replies": [
				{"text": "MSG_PRIYA_WOBBLE_S2_R0", "sanity": 13.0, "goto": 3},
				{"text": "MSG_PRIYA_WOBBLE_S2_R1", "sanity": 8.0, "goto": 3}]},
			{"them": "MSG_PRIYA_WOBBLE_S3",
			 "replies": [
				{"text": "MSG_PRIYA_WOBBLE_S3_R0", "sanity": 9.0},
				{"text": "MSG_PRIYA_WOBBLE_S3_R1", "sanity": 13.0}]},
		]},
	{
		"id": "halls_accommodation", "sender": "Accommodation Office", "avatar": "AC", "arrives": 58,
		"requires": "no_accommodation",
		"steps": [
			{"them": "MSG_HALLS_ACCOMMODATION_S0",
			 "replies": [
				{"text": "MSG_HALLS_ACCOMMODATION_S0_R0", "goto": 1},
				{"text": "MSG_HALLS_ACCOMMODATION_S0_R1", "goto": 2},
				{"text": "MSG_HALLS_ACCOMMODATION_S0_R2", "goto": 3}]},
			{"them": "MSG_HALLS_ACCOMMODATION_S1",
			 "replies": [
				{"text": "MSG_HALLS_ACCOMMODATION_S1_R0", "sanity": 1.0, "goto": 4},
				{"text": "MSG_HALLS_ACCOMMODATION_S1_R1", "sanity": 5.0, "goto": 4}]},
			{"them": "MSG_HALLS_ACCOMMODATION_S2",
			 "replies": [
				{"text": "MSG_HALLS_ACCOMMODATION_S2_R0", "sanity": 3.0, "goto": 4}]},
			{"them": "MSG_HALLS_ACCOMMODATION_S3",
			 "replies": [
				{"text": "MSG_HALLS_ACCOMMODATION_S3_R0", "sanity": 6.0, "goto": 4}]},
			{"them": "MSG_HALLS_ACCOMMODATION_S4",
			 "replies": [
				{"text": "MSG_HALLS_ACCOMMODATION_S4_R0", "sanity": 7.0},
				{"text": "MSG_HALLS_ACCOMMODATION_S4_R1", "sanity": 4.0}]},
		]},
	{
		"id": "wiremu_after_season", "sender": "Wiremu", "avatar": "WI", "arrives": 60,
		"steps": [
			{"them": "MSG_WIREMU_AFTER_SEASON_S0",
			 "replies": [
				{"text": "MSG_WIREMU_AFTER_SEASON_S0_R0", "sanity": 8.0, "goto": 1},
				{"text": "MSG_WIREMU_AFTER_SEASON_S0_R1", "sanity": 3.0, "goto": 2}]},
			{"them": "MSG_WIREMU_AFTER_SEASON_S1",
			 "replies": [
				{"text": "MSG_WIREMU_AFTER_SEASON_S1_R0", "sanity": 13.0, "goto": 3},
				{"text": "MSG_WIREMU_AFTER_SEASON_S1_R1", "sanity": 12.0, "goto": 3},
				{"text": "MSG_WIREMU_AFTER_SEASON_S1_R2", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_WIREMU_AFTER_SEASON_S2",
			 "replies": [
				{"text": "MSG_WIREMU_AFTER_SEASON_S2_R0", "sanity": 6.0, "goto": 3}]},
			{"them": "MSG_WIREMU_AFTER_SEASON_S3",
			 "replies": [
				{"text": "MSG_WIREMU_AFTER_SEASON_S3_R0", "sanity": 12.0, "temptation": -3.0},
				{"text": "MSG_WIREMU_AFTER_SEASON_S3_R1", "sanity": 10.0, "temptation": -2.0}]},
		]},
	{
		"id": "teacher_email", "sender": "Mr Halloway", "avatar": "MH", "arrives": 62,
		"steps": [
			{"them": "MSG_TEACHER_EMAIL_S0",
			 "replies": [
				{"text": "MSG_TEACHER_EMAIL_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_TEACHER_EMAIL_S0_R1", "sanity": 3.0, "goto": 2},
				{"text": "MSG_TEACHER_EMAIL_S0_R2", "goto": 3}]},
			{"them": "MSG_TEACHER_EMAIL_S1",
			 "replies": [
				{"text": "MSG_TEACHER_EMAIL_S1_R0", "goto": 3}]},
			{"them": "MSG_TEACHER_EMAIL_S2",
			 "replies": [
				{"text": "MSG_TEACHER_EMAIL_S2_R0", "sanity": 7.0, "goto": 3},
				{"text": "MSG_TEACHER_EMAIL_S2_R1", "sanity": 8.0, "goto": 3}]},
			{"them": "MSG_TEACHER_EMAIL_S3",
			 "replies": [
				{"text": "MSG_TEACHER_EMAIL_S3_R0", "sanity": 11.0, "temptation": -4.0},
				{"text": "MSG_TEACHER_EMAIL_S3_R1", "sanity": 9.0}]},
		]},
	{
		"id": "ana_her_turn", "sender": "Ana", "avatar": "AN", "arrives": 64,
		"steps": [
			{"them": "MSG_ANA_HER_TURN_S0",
			 "replies": [
				{"text": "MSG_ANA_HER_TURN_S0_R0", "sanity": 6.0, "goto": 1},
				{"text": "MSG_ANA_HER_TURN_S0_R1", "sanity": 8.0, "goto": 1},
				{"text": "MSG_ANA_HER_TURN_S0_R2", "sanity": 12.0, "goto": 2}]},
			{"them": "MSG_ANA_HER_TURN_S1",
			 "replies": [
				{"text": "MSG_ANA_HER_TURN_S1_R0", "sanity": 15.0, "goto": 3},
				{"text": "MSG_ANA_HER_TURN_S1_R1", "sanity": 13.0, "goto": 3}]},
			{"them": "MSG_ANA_HER_TURN_S2",
			 "replies": [
				{"text": "MSG_ANA_HER_TURN_S2_R0", "sanity": 12.0, "goto": 1}]},
			{"them": "MSG_ANA_HER_TURN_S3",
			 "replies": [
				{"text": "MSG_ANA_HER_TURN_S3_R0", "sanity": 16.0},
				{"text": "MSG_ANA_HER_TURN_S3_R1", "sanity": 12.0}]},
		]},
	{
		"id": "scam_courier", "sender": "Unknown number", "avatar": "??", "arrives": 66,
		"steps": [
			{"them": "MSG_SCAM_COURIER_S0",
			 "replies": [
				{"text": "MSG_SCAM_COURIER_S0_R0", "sanity": 4.0, "goto": 1},
				{"text": "MSG_SCAM_COURIER_S0_R1", "temptation": 4.0, "goto": 2}]},
			{"them": "MSG_SCAM_COURIER_S1",
			 "replies": [
				{"text": "MSG_SCAM_COURIER_S1_R0", "sanity": 6.0, "goto": 3},
				{"text": "MSG_SCAM_COURIER_S1_R1", "sanity": 5.0, "goto": 3}]},
			{"them": "MSG_SCAM_COURIER_S2",
			 "replies": [
				{"text": "MSG_SCAM_COURIER_S2_R0", "sanity": 7.0, "goto": 3},
				{"text": "MSG_SCAM_COURIER_S2_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_SCAM_COURIER_S3",
			 "replies": [{"text": "MSG_SCAM_COURIER_S3_R0", "sanity": 3.0}]},
		]},
	{
		"id": "mum_before_exams", "sender": "Mum", "avatar": "MU", "arrives": 70,
		"steps": [
			{"them": "MSG_MUM_BEFORE_EXAMS_S0",
			 "replies": [
				{"text": "MSG_MUM_BEFORE_EXAMS_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_MUM_BEFORE_EXAMS_S0_R1", "sanity": 8.0, "goto": 2},
				{"text": "MSG_MUM_BEFORE_EXAMS_S0_R2", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_MUM_BEFORE_EXAMS_S1",
			 "replies": [
				{"text": "MSG_MUM_BEFORE_EXAMS_S1_R0", "sanity": 10.0, "goto": 4},
				{"text": "MSG_MUM_BEFORE_EXAMS_S1_R1", "sanity": 13.0, "goto": 4}]},
			{"them": "MSG_MUM_BEFORE_EXAMS_S2",
			 "replies": [
				{"text": "MSG_MUM_BEFORE_EXAMS_S2_R0", "sanity": 11.0, "goto": 4},
				{"text": "MSG_MUM_BEFORE_EXAMS_S2_R1", "sanity": 12.0, "goto": 4}]},
			{"them": "MSG_MUM_BEFORE_EXAMS_S3",
			 "replies": [
				{"text": "MSG_MUM_BEFORE_EXAMS_S3_R0", "sanity": 12.0, "goto": 4},
				{"text": "MSG_MUM_BEFORE_EXAMS_S3_R1", "sanity": 9.0, "goto": 4}]},
			{"them": "MSG_MUM_BEFORE_EXAMS_S4",
			 "replies": [
				{"text": "MSG_MUM_BEFORE_EXAMS_S4_R0", "sanity": 16.0},
				{"text": "MSG_MUM_BEFORE_EXAMS_S4_R1", "sanity": 9.0}]},
		]},
	{
		"id": "study_group_final", "sender": "Study group", "avatar": "SG", "arrives": 73,
		"steps": [
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FINAL_S0",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FINAL_S0_R0", "sanity": 10.0, "temptation": -5.0, "goto": 1, "commit": {"kind": "study_group", "label": "COMMIT_STUDY_DAY_PRIYA", "in": 2}},
				{"text": "MSG_STUDY_GROUP_FINAL_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_STUDY_GROUP_FINAL_S0_R2", "sanity": 3.0, "goto": 3}]},
			{"from": "Mika", "them": "MSG_STUDY_GROUP_FINAL_S1",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FINAL_S1_R0", "sanity": 9.0, "goto": 4}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FINAL_S2",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FINAL_S2_R0", "sanity": 9.0, "goto": 4},
				{"text": "MSG_STUDY_GROUP_FINAL_S2_R1", "sanity": 11.0, "temptation": -5.0, "goto": 4}]},
			{"from": "Priya", "them": "MSG_STUDY_GROUP_FINAL_S3",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FINAL_S3_R0", "sanity": 10.0, "goto": 4}]},
			{"from": "Ana", "them": "MSG_STUDY_GROUP_FINAL_S4",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_FINAL_S4_R0", "sanity": 14.0},
				{"text": "MSG_STUDY_GROUP_FINAL_S4_R1", "sanity": 13.0}]},
		]},
	{
		"id": "tane_night_before", "sender": "Tane", "avatar": "TA", "arrives": 77,
		"steps": [
			{"them": "MSG_TANE_NIGHT_BEFORE_S0",
			 "replies": [
				{"text": "MSG_TANE_NIGHT_BEFORE_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_TANE_NIGHT_BEFORE_S0_R1", "sanity": 6.0, "goto": 1}]},
			{"them": "MSG_TANE_NIGHT_BEFORE_S1",
			 "replies": [
				{"text": "MSG_TANE_NIGHT_BEFORE_S1_R0", "sanity": 7.0, "goto": 2},
				{"text": "MSG_TANE_NIGHT_BEFORE_S1_R1", "sanity": 11.0, "goto": 3},
				{"text": "MSG_TANE_NIGHT_BEFORE_S1_R2", "sanity": 9.0, "goto": 3}]},
			{"them": "MSG_TANE_NIGHT_BEFORE_S2",
			 "replies": [
				{"text": "MSG_TANE_NIGHT_BEFORE_S2_R0", "sanity": 8.0, "goto": 4}]},
			{"them": "MSG_TANE_NIGHT_BEFORE_S3",
			 "replies": [
				{"text": "MSG_TANE_NIGHT_BEFORE_S3_R0", "sanity": 9.0, "goto": 4}]},
			{"them": "MSG_TANE_NIGHT_BEFORE_S4",
			 "replies": [
				{"text": "MSG_TANE_NIGHT_BEFORE_S4_R0", "sanity": 12.0},
				{"text": "MSG_TANE_NIGHT_BEFORE_S4_R1", "sanity": 11.0}]},
		]},
	{
		"id": "reti_shift_swap", "sender": "Reti (work)", "avatar": "RE", "arrives": 80,
		"requires": "still_employed",
		"steps": [
			{"them": "MSG_RETI_SHIFT_SWAP_S0",
			 "replies": [
				{"text": "MSG_RETI_SHIFT_SWAP_S0_R0", "sanity": 5.0, "goto": 1},
				{"text": "MSG_RETI_SHIFT_SWAP_S0_R1", "sanity": -4.0, "goto": 2, "commit": {"kind": "work", "label": "COMMIT_COVER_RETI", "in": 1}},
				{"text": "MSG_RETI_SHIFT_SWAP_S0_R2", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_RETI_SHIFT_SWAP_S1",
			 "replies": [
				{"text": "MSG_RETI_SHIFT_SWAP_S1_R0", "sanity": 8.0},
				{"text": "MSG_RETI_SHIFT_SWAP_S1_R1", "sanity": 6.0}]},
			{"them": "MSG_RETI_SHIFT_SWAP_S2",
			 "replies": [
				{"text": "MSG_RETI_SHIFT_SWAP_S2_R0", "sanity": 5.0},
				{"text": "MSG_RETI_SHIFT_SWAP_S2_R1", "sanity": 2.0}]},
			{"them": "MSG_RETI_SHIFT_SWAP_S3",
			 "replies": [
				{"text": "MSG_RETI_SHIFT_SWAP_S3_R0", "sanity": 9.0},
				{"text": "MSG_RETI_SHIFT_SWAP_S3_R1", "sanity": 7.0}]},
		]},

	# --- STORY THREADS: delivered by the game, never at random ---------------
	{
		"id": "studylink_approved", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "MSG_STUDYLINK_APPROVED_S0",
			 "replies": [
				{"text": "MSG_STUDYLINK_APPROVED_S0_R0", "goto": 1}]},
			{"them": "LOAN_APPROVAL",
			 "replies": [
				{"text": "MSG_STUDYLINK_APPROVED_S1_R0", "sanity": 14.0, "goto": 2},
				{"text": "MSG_STUDYLINK_APPROVED_S1_R1", "sanity": 6.0, "goto": 2}]},
			{"them": "MSG_STUDYLINK_APPROVED_S2",
			 "replies": [
				{"text": "MSG_STUDYLINK_APPROVED_S2_R0", "sanity": 4.0}]},
		]},
	{
		"id": "studylink_declined", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "MSG_STUDYLINK_DECLINED_S0",
			 "replies": [
				{"text": "MSG_STUDYLINK_DECLINED_S0_R0", "goto": 1}]},
			{"them": "LOAN_DECLINE",
			 "replies": [
				{"text": "MSG_STUDYLINK_DECLINED_S1_R0", "goto": 2},
				{"text": "MSG_STUDYLINK_DECLINED_S1_R1", "sanity": -4.0, "goto": 2}]},
			{"them": "MSG_STUDYLINK_DECLINED_S2",
			 "replies": [
				{"text": "MSG_STUDYLINK_DECLINED_S2_R0", "sanity": -2.0}]},
		]},
	{
		"id": "allowance_result", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "MSG_ALLOWANCE_RESULT_S0",
			 "replies": [
				{"text": "MSG_ALLOWANCE_RESULT_S0_R0", "goto": 1}]},
			{"them": "ALLOWANCE_SUMMARY",
			 "replies": [
				{"text": "MSG_ALLOWANCE_RESULT_S1_R0", "sanity": 2.0, "goto": 2},
				{"text": "MSG_ALLOWANCE_RESULT_S1_R1", "sanity": 10.0, "goto": 2}]},
			{"them": "MSG_ALLOWANCE_RESULT_S2",
			 "replies": [
				{"text": "MSG_ALLOWANCE_RESULT_S2_R0", "sanity": 3.0}]},
		]},
	{
		"id": "allowance_parents", "sender": "Mum", "avatar": "MU", "arrives": 999,
		"steps": [
			{"them": "MSG_ALLOWANCE_PARENTS_S0",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_ALLOWANCE_PARENTS_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_ALLOWANCE_PARENTS_S0_R2", "goto": 3}]},
			{"them": "MSG_ALLOWANCE_PARENTS_S1",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S1_R0", "sanity": 5.0, "goto": 4},
				{"text": "MSG_ALLOWANCE_PARENTS_S1_R1", "sanity": 6.0, "goto": 4}]},
			{"them": "MSG_ALLOWANCE_PARENTS_S2",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S2_R0", "sanity": 5.0, "goto": 4}]},
			{"them": "MSG_ALLOWANCE_PARENTS_S3",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S3_R0", "sanity": 6.0, "goto": 4},
				{"text": "MSG_ALLOWANCE_PARENTS_S3_R1", "sanity": 7.0, "goto": 4}]},
			{"them": "PARENT_CONFIRM",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S4_R0", "sanity": 12.0, "goto": 5},
				{"text": "MSG_ALLOWANCE_PARENTS_S4_R1", "sanity": 10.0, "goto": 5}]},
			{"them": "MSG_ALLOWANCE_PARENTS_S5",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_S5_R0", "sanity": 8.0},
				{"text": "MSG_ALLOWANCE_PARENTS_S5_R1", "sanity": 9.0}]},
		]},
	{
		"id": "allowance_parents_nudge", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "MSG_ALLOWANCE_PARENTS_NUDGE_S0",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_NUDGE_S0_R0", "sanity": 2.0, "goto": 1},
				{"text": "MSG_ALLOWANCE_PARENTS_NUDGE_S0_R1", "sanity": 3.0, "goto": 1}]},
			{"them": "MSG_ALLOWANCE_PARENTS_NUDGE_S1",
			 "replies": [
				{"text": "MSG_ALLOWANCE_PARENTS_NUDGE_S1_R0", "sanity": 4.0}]},
		]},
	{
		"id": "work_noshow", "sender": "Deb (work)", "avatar": "DE", "arrives": 999,
		"steps": [
			{"them": "MSG_WORK_NOSHOW_S0",
			 "replies": [
				{"text": "MSG_WORK_NOSHOW_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_WORK_NOSHOW_S0_R1", "sanity": 1.0, "goto": 2},
				{"text": "MSG_WORK_NOSHOW_S0_R2", "sanity": -2.0, "goto": 3}]},
			{"them": "MSG_WORK_NOSHOW_S1",
			 "replies": [
				{"text": "MSG_WORK_NOSHOW_S1_R0", "sanity": 6.0, "goto": 3}]},
			{"them": "MSG_WORK_NOSHOW_S2",
			 "replies": [
				{"text": "MSG_WORK_NOSHOW_S2_R0", "sanity": 4.0, "goto": 1},
				{"text": "MSG_WORK_NOSHOW_S2_R1", "sanity": 2.0, "goto": 3}]},
			{"them": "MSG_WORK_NOSHOW_S3",
			 "replies": [
				{"text": "MSG_WORK_NOSHOW_S3_R0", "sanity": 2.0},
				{"text": "MSG_WORK_NOSHOW_S3_R1", "sanity": 5.0}]},
		]},
	{
		"id": "work_fired", "sender": "Deb (work)", "avatar": "DE", "arrives": 999,
		"steps": [
			{"them": "MSG_WORK_FIRED_S0",
			 "replies": [
				{"text": "MSG_WORK_FIRED_S0_R0", "sanity": -4.0, "goto": 1},
				{"text": "MSG_WORK_FIRED_S0_R1", "sanity": 2.0, "goto": 2}]},
			{"them": "MSG_WORK_FIRED_S1",
			 "replies": [
				{"text": "MSG_WORK_FIRED_S1_R0", "sanity": 3.0, "goto": 2},
				{"text": "MSG_WORK_FIRED_S1_R1", "sanity": 4.0, "goto": 3}]},
			{"them": "MSG_WORK_FIRED_S2",
			 "replies": [
				{"text": "MSG_WORK_FIRED_S2_R0", "sanity": 8.0},
				{"text": "MSG_WORK_FIRED_S2_R1", "sanity": 9.0}]},
			{"them": "MSG_WORK_FIRED_S3",
			 "replies": [
				{"text": "MSG_WORK_FIRED_S3_R0", "sanity": 4.0, "goto": 2}]},
		]},
	{
		"id": "study_group_noshow", "sender": "Priya", "avatar": "PR", "arrives": 999,
		"steps": [
			{"them": "MSG_STUDY_GROUP_NOSHOW_S0",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_NOSHOW_S0_R0", "sanity": 3.0, "goto": 1},
				{"text": "MSG_STUDY_GROUP_NOSHOW_S0_R1", "sanity": 0.0, "goto": 2},
				{"text": "MSG_STUDY_GROUP_NOSHOW_S0_R2", "sanity": 2.0, "goto": 1}]},
			{"them": "MSG_STUDY_GROUP_NOSHOW_S1",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_NOSHOW_S1_R0", "sanity": 5.0, "goto": 3},
				{"text": "MSG_STUDY_GROUP_NOSHOW_S1_R1", "sanity": 7.0, "goto": 3}]},
			{"them": "MSG_STUDY_GROUP_NOSHOW_S2",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_NOSHOW_S2_R0", "sanity": 4.0, "goto": 1}]},
			{"them": "MSG_STUDY_GROUP_NOSHOW_S3",
			 "replies": [
				{"text": "MSG_STUDY_GROUP_NOSHOW_S3_R0", "sanity": 8.0}]},
		]},
	{
		"id": "rock_bottom", "sender": "Ana", "avatar": "AN", "arrives": 999,
		"steps": [
			{"them": "MSG_ROCK_BOTTOM_S0",
			 "replies": [
				{"text": "MSG_ROCK_BOTTOM_S0_R0", "sanity": 14.0, "goto": 1},
				{"text": "MSG_ROCK_BOTTOM_S0_R1", "sanity": 4.0, "goto": 2},
				{"text": "MSG_ROCK_BOTTOM_S0_R2", "sanity": 12.0, "goto": 1}]},
			{"them": "MSG_ROCK_BOTTOM_S1",
			 "replies": [
				{"text": "MSG_ROCK_BOTTOM_S1_R0", "sanity": 15.0, "goto": 3},
				{"text": "MSG_ROCK_BOTTOM_S1_R1", "sanity": 8.0, "goto": 4}]},
			{"them": "MSG_ROCK_BOTTOM_S2",
			 "replies": [
				{"text": "MSG_ROCK_BOTTOM_S2_R0", "sanity": 14.0, "goto": 3},
				{"text": "MSG_ROCK_BOTTOM_S2_R1", "sanity": 10.0, "goto": 1}]},
			{"them": "MSG_ROCK_BOTTOM_S3",
			 "replies": [
				{"text": "MSG_ROCK_BOTTOM_S3_R0", "sanity": 20.0},
				{"text": "MSG_ROCK_BOTTOM_S3_R1", "sanity": 22.0}]},
			{"them": "MSG_ROCK_BOTTOM_S4",
			 "replies": [
				{"text": "MSG_ROCK_BOTTOM_S4_R0", "sanity": 16.0, "goto": 3},
				{"text": "MSG_ROCK_BOTTOM_S4_R1", "sanity": 15.0, "goto": 3}]},
		]},
	{
		"id": "allowance_review", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "MSG_ALLOWANCE_REVIEW_S0",
			 "replies": [
				{"text": "MSG_ALLOWANCE_REVIEW_S0_R0", "goto": 1}]},
			{"them": "ALLOWANCE_SUMMARY",
			 "replies": [
				{"text": "MSG_ALLOWANCE_REVIEW_S1_R0", "sanity": 2.0, "goto": 2},
				{"text": "MSG_ALLOWANCE_REVIEW_S1_R1", "sanity": 4.0, "goto": 2}]},
			{"them": "MSG_ALLOWANCE_REVIEW_S2",
			 "replies": [
				{"text": "MSG_ALLOWANCE_REVIEW_S2_R0", "sanity": 2.0}]},
		]},
	{
		"id": "nzqa_results", "sender": "NZQA", "avatar": "NZ", "arrives": 999,
		"steps": [
			{"them": "MSG_NZQA_RESULTS_S0",
			 "replies": [
				{"text": "MSG_NZQA_RESULTS_S0_R0", "goto": 1},
				{"text": "MSG_NZQA_RESULTS_S0_R1", "sanity": 2.0, "goto": 1}]},
			{"them": "RESULTS_SUMMARY",
			 "replies": [{"text": "MSG_NZQA_RESULTS_S1_R0", "goto": 2}]},
			{"them": "MSG_NZQA_RESULTS_S2",
			 "replies": [
				{"text": "MSG_NZQA_RESULTS_S2_R0", "goto": 3},
				{"text": "MSG_NZQA_RESULTS_S2_R1", "goto": 3}]},
			{"them": "MSG_NZQA_RESULTS_S3",
			 "replies": [{"text": "MSG_NZQA_RESULTS_S3_R0"}]},
		]},
	{
		"id": "university_offer", "sender": "Admissions", "avatar": "UN", "arrives": 999,
		"steps": [
			{"them": "MSG_UNIVERSITY_OFFER_S0",
			 "replies": [{"text": "MSG_UNIVERSITY_OFFER_S0_R0", "goto": 1}]},
			{"them": "OFFER_SUMMARY",
			 "replies": [{"text": "MSG_UNIVERSITY_OFFER_S1_R0"}]},
		]},
]


# HELPERS

## Translates a thread (the data holds localisation keys) and replaces {NAME}
## and {UNI} throughout. Placeholder bodies like RESULTS_SUMMARY have no key, so
## tr() hands them back untouched and the phone still expands them.
func personalise(thread: Dictionary, player_name: String) -> Dictionary:
	var out: Dictionary = thread.duplicate(true)
	var uni: String = GameBackend.university_full_name()
	for step in out.steps:
		step.them = _sub(tr(str(step.them)), player_name, uni)
		for reply in step.replies:
			reply.text = _sub(tr(str(reply.text)), player_name, uni)
	# The offer never comes from a vague national body — it comes from the
	# university's own admissions office.
	if str(out.get("id", "")) == "university_offer":
		out["sender"] = GameBackend.admissions_sender()
	return out


func _sub(text: String, player_name: String, uni: String) -> String:
	var out: String = text.replace("{NAME}", player_name).replace("{UNI}", uni)
	# One thread quotes the StudyLink cut-off day; keep it honest.
	out = out.replace("{LOANDAY}", str(GameBackend.LOAN_APPLY_CLOSES_DAY))
	return out


## A reply may carry "goto": <step index> to jump somewhere other than the
## next step, so conversations fork. Without it the thread advances by one.
func next_step_for(reply: Dictionary, current_step: int) -> int:
	return int(reply.get("goto", current_step + 1))


func thread_by_id(thread_id: String) -> Dictionary:
	for t in threads:
		if str(t.get("id", "")) == thread_id:
			return t
	return {}


func index_of(thread_id: String) -> int:
	for i in threads.size():
		if str(threads[i].get("id", "")) == thread_id:
			return i
	return -1


# --- Delivery -------------------------------------------------------------------
# Threads that should be in the inbox from day one; everything else drips in
# on or after its `arrives` day.
const STARTING_THREADS := ["mum_check_in", "tane_where_are_you"]

## Story threads are delivered explicitly by the game, never on a schedule.
const STORY_THREADS := ["nzqa_results", "university_offer", "studylink_approved",
	"studylink_declined", "allowance_result", "allowance_parents",
	"allowance_parents_nudge", "work_noshow", "work_fired", "study_group_noshow",
	"rock_bottom", "allowance_review"]

## Don't dump the whole term's texts in one morning.
const MAX_DELIVERIES_PER_DAY: int = 2



# RELEVANCE
# A scheduled text has to still make sense on the day it lands. StudyLink
# nagging you to apply when you applied three weeks ago, or the accommodation
# office asking whether you've thought about where you'll live when you've
# already paid a deposit, reads as the game not paying attention.
# A thread can carry "requires": "<id>" and it is only delivered while that
# condition holds. If it stops holding, the thread quietly never arrives.

func _requirement_met(requirement: String) -> bool:
	match requirement:
		"", "always":
			return true
		"no_loan_application":
			return GameBackend.loan_status == "none"
		"no_allowance_application":
			return GameBackend.allowance_status == "none"
		"no_accommodation":
			return GameBackend.accommodation_choice == ""
		"accommodation_unconfirmed":
			return not GameBackend.accommodation_deposit_paid
		"still_employed":
			return not GameBackend.fired_from_work
		"has_job_and_shifts":
			return not GameBackend.fired_from_work
		"before_results":
			return GameBackend.results_phase == 0
		"no_ue_yet":
			return not GameBackend.has_university_entrance()
	push_warning("MessageData: unknown requirement '%s'" % requirement)
	return true


## True when a thread has landed but its premise has since stopped being true
## — the reminder to apply for a loan you have now applied for. Checked again
## when you open it, because a text can sit unread for days while the world
## moves on underneath it.
func thread_is_stale(thread_id: String) -> bool:
	var t: Dictionary = thread_by_id(thread_id)
	if t.is_empty():
		return false
	return not _requirement_met(str(t.get("requires", "")))


## Every thread that is due (its arrival day has come) and hasn't landed yet.
func due_ids(current_day: int) -> Array:
	var out: Array = []
	for t in threads:
		var tid: String = str(t.get("id", ""))
		if tid == "" or tid in STORY_THREADS:
			continue
		if GameBackend.has_arrived(tid):
			continue
		if int(t.get("arrives", 0)) > current_day:
			continue
		# Still relevant? A text that contradicts what you've already done is
		# worse than no text at all.
		if not _requirement_met(str(t.get("requires", ""))):
			continue
		out.append(tid)
	return out


## Called once per in-game day from GameBackend.advance_day(). Delivers up to
## MAX_DELIVERIES_PER_DAY threads whose day has come, oldest first — so a
## backlog clears steadily instead of all at once.
func deliver_due_messages(current_day: int) -> void:
	var pool: Array = due_ids(current_day)
	if pool.is_empty():
		return
	var sent: int = 0
	for tid in pool:
		if sent >= MAX_DELIVERIES_PER_DAY:
			break
		GameBackend.deliver_message(tid)
		message_arrived.emit(str(thread_by_id(tid).get("sender", tid)))
		sent += 1


## Called once per in-game hour from game_manager. Small chance of a text
## turning up mid-day rather than all of them landing at midnight — but only
## from threads that are already due, so the year's pacing still holds.
func maybe_deliver_random(chance: float = 0.05) -> void:
	if randf() > chance:
		return
	var pool: Array = due_ids(GameBackend.get_elapsed_days())
	if pool.is_empty():
		return
	var tid: String = str(pool[randi() % pool.size()])
	GameBackend.deliver_message(tid)
	message_arrived.emit(str(thread_by_id(tid).get("sender", tid)))


## Puts the starting threads in the inbox at the beginning of a run.
func deliver_starting_threads() -> void:
	for tid in STARTING_THREADS:
		GameBackend.deliver_message(tid)
