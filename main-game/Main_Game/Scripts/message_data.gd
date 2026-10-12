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
			{"them": "hey hun. you've been really quiet this week. everything alright?",
			 "replies": [
				{"text": "honestly? struggling a bit", "sanity": 6.0, "goto": 1},
				{"text": "yeah all good, just busy", "sanity": 2.0, "goto": 3},
				{"text": "don't really want to get into it", "sanity": 1.0, "goto": 5}]},
			{"them": "oh love. what's the worst bit of it?",
			 "replies": [
				{"text": "there's just no time. work, school, all of it", "sanity": 5.0, "goto": 2},
				{"text": "I don't think I'm going to get the grades", "sanity": 5.0, "goto": 2}]},
			{"them": "right. we're doing something about that. no shifts this Sunday, I'll square it with them. you're having a day off.",
			 "replies": [
				{"text": "you don't have to do that", "sanity": 8.0, "goto": 6},
				{"text": "...okay. thank you", "sanity": 14.0, "goto": 6}]},
			{"them": "mm. you say that in exactly the same voice your father does.",
			 "replies": [
				{"text": "ok fine, it's been rough", "sanity": 7.0, "goto": 1},
				{"text": "I'm genuinely fine mum", "sanity": 3.0, "goto": 4}]},
			{"them": "alright. I'll take your word for it. door's open though.",
			 "replies": [
				{"text": "I know. thanks", "sanity": 6.0, "goto": 6}]},
			{"them": "that's ok. you don't have to. I just wanted you to know I noticed.",
			 "replies": [
				{"text": "...that actually helps", "sanity": 9.0, "goto": 6},
				{"text": "thanks mum", "sanity": 5.0, "goto": 6}]},
			{"them": "eat something that isn't from the dairy. love you.",
			 "replies": [
				{"text": "love you too", "sanity": 8.0},
				{"text": "no promises", "sanity": 5.0}]},
		]},
	{
		"id": "tane_where_are_you", "sender": "Tane", "avatar": "TA", "arrives": 0,
		"steps": [
			{"them": "right. you've cancelled on me three times. what's going on with you",
			 "replies": [
				{"text": "I know. I'm sorry. I'm drowning a bit", "sanity": 6.0, "goto": 1},
				{"text": "I've just got a lot on", "sanity": 2.0, "goto": 3},
				{"text": "not everything's about you mate", "temptation": 3.0, "goto": 4}]},
			{"them": "yeah I could tell. why didn't you say something?",
			 "replies": [
				{"text": "felt stupid complaining when everyone's busy", "sanity": 7.0, "goto": 2},
				{"text": "didn't want to make it your problem", "sanity": 7.0, "goto": 2}]},
			{"them": "that's the dumbest thing you've ever said and I've known you since year 4. saturday. two hours. no excuses.",
			 "replies": [
				{"text": "fine. two hours", "sanity": 14.0, "temptation": 4.0, "goto": 6},
				{"text": "make it one and you've got a deal", "sanity": 11.0, "temptation": 2.0, "goto": 6}]},
			{"them": "everyone's got a lot on. that's not an answer.",
			 "replies": [
				{"text": "ok, fair. it's been bad actually", "sanity": 6.0, "goto": 1},
				{"text": "I don't owe you a breakdown of my week", "temptation": 3.0, "goto": 4}]},
			{"them": "wow. ok.",
			 "replies": [
				{"text": "sorry. that came out wrong", "sanity": 5.0, "goto": 5},
				{"text": "whatever", "sanity": -3.0, "temptation": 4.0, "goto": 6}]},
			{"them": "it's alright. you're clearly running on empty. talk to me when you're ready.",
			 "replies": [
				{"text": "give me a few days", "sanity": 7.0, "goto": 6}]},
			{"them": "later then.",
			 "replies": [{"text": "later", "sanity": 2.0}]},
		]},
	{
		"id": "year13_chat", "sender": "Year 13 groupchat", "avatar": "Y13", "arrives": 1,
		"steps": [
			{"from": "Chloe", "them": "does anyone else feel like this year is going way too fast",
			 "replies": [
				{"text": "constantly", "sanity": 6.0, "goto": 1},
				{"text": "not fast enough for me honestly", "sanity": 5.0, "goto": 1}]},
			{"from": "Sione", "them": "we have got MONTHS left. months. plural. calm down.",
			 "replies": [
				{"text": "months go fast", "sanity": 4.0, "goto": 2},
				{"text": "you say that now", "sanity": 5.0, "goto": 2}]},
			{"from": "Ana", "them": "ok everyone breathe. one week at a time. that is genuinely the only way through this.",
			 "replies": [
				{"text": "needed that. cheers Ana", "sanity": 10.0},
				{"text": "speak for yourself", "sanity": 4.0}]},
		]},
	{
		"id": "school_notices_1", "sender": "School Notices", "avatar": "SN", "arrives": 2,
		"steps": [
			{"them": "WELCOME BACK YEAR 13. A reminder that this is an assessment year and attendance is monitored from week one.",
			 "replies": [
				{"text": "ok", "goto": 1},
				{"text": "thanks, very calming", "sanity": 2.0, "goto": 1}]},
			{"them": "Course confirmation and university applications open this term. See the careers office. Do not leave it until October.",
			 "replies": [
				{"text": "noted", "sanity": 2.0},
				{"text": "I will absolutely leave it until October", "temptation": 3.0}]},
		]},
	{
		"id": "work_first_roster", "sender": "Deb (work)", "avatar": "DE", "arrives": 3,
		"requires": "still_employed",
		"steps": [
			{"them": "Hi {NAME}, Deb here. Rosters are up. I have you Thursday and Saturday to start. Sing out if that clashes with anything.",
			 "replies": [
				{"text": "that works, thanks Deb", "goto": 1, "commit": {"kind": "work", "label": "Shift at the supermarket", "in": 2}},
				{"text": "can I do one weekday instead of Saturday?", "sanity": 3.0, "goto": 2},
				{"text": "I might need fewer hours this year", "sanity": 5.0, "goto": 3}]},
			{"them": "Lovely. Wear closed shoes, the deli floor is a hazard.",
			 "replies": [{"text": "will do", "sanity": 2.0}]},
			{"them": "I can do Wednesday. Bit quieter, bit more shelf-stacking. Suit you?",
			 "replies": [
				{"text": "perfect", "sanity": 5.0},
				{"text": "actually Saturday's fine, more hours", "sanity": -2.0}]},
			{"them": "Understood. Year 13 is Year 13. Tell me early if it gets too much rather than just not turning up — that's all I ask.",
			 "replies": [
				{"text": "that's really decent of you", "sanity": 9.0},
				{"text": "I'll keep the hours for now", "sanity": 3.0}]},
		]},
	{
		"id": "study_group_forming", "sender": "Study group", "avatar": "SG", "arrives": 4,
		"steps": [
			{"from": "Priya", "them": "genuine question. is anyone actually on top of the internals or are we all quietly drowning",
			 "replies": [
				{"text": "drowning. absolutely drowning", "sanity": 5.0, "goto": 1},
				{"text": "I'm actually alright so far", "sanity": 3.0, "goto": 2}]},
			{"from": "Mika", "them": "oh thank god. I thought it was just me",
			 "replies": [
				{"text": "definitely not just you", "sanity": 6.0, "goto": 3}]},
			{"from": "Mika", "them": "ok show off. can you help then?",
			 "replies": [
				{"text": "yeah course, what are you stuck on", "sanity": 8.0, "temptation": -2.0, "goto": 3},
				{"text": "I've barely got time for my own tbh", "sanity": 2.0, "goto": 4}]},
			{"from": "Priya", "them": "library thursday? we go through past papers properly. no phones.",
			 "replies": [
				{"text": "I'm in", "sanity": 10.0, "temptation": -4.0, "goto": 5, "commit": {"kind": "study_group", "label": "Study group at the library", "in": 3}},
				{"text": "depends on my shift, I'll try", "sanity": 5.0, "goto": 5},
				{"text": "can't, sorry", "sanity": 2.0, "goto": 4}]},
			{"from": "Priya", "them": "fair enough. shout if that changes.",
			 "replies": [{"text": "will do", "sanity": 3.0}]},
			{"from": "Mika", "them": "I'm bringing snacks. this is not up for discussion.",
			 "replies": [
				{"text": "now it's a proper study session", "sanity": 8.0},
				{"text": "see you thursday", "sanity": 6.0}]},
		]},
	{
		"id": "nan_first_text", "sender": "Nan", "avatar": "NA", "arrives": 5,
		"steps": [
			{"them": "Hello dear it is Nan. I do not know if this is sending.",
			 "replies": [
				{"text": "it's sending nan", "sanity": 9.0, "goto": 1},
				{"text": "WHO IS THIS", "sanity": 6.0, "goto": 2}]},
			{"them": "Oh good. Your mother says you are working very hard. Do not forget to enjoy yourself.",
			 "replies": [
				{"text": "I'll try. thanks nan", "sanity": 11.0, "goto": 3},
				{"text": "no time for that right now", "sanity": 4.0, "goto": 3}]},
			{"them": "It is your Nan. Do not be cheeky.",
			 "replies": [{"text": "sorry nan, couldn't resist", "sanity": 10.0, "goto": 1}]},
			{"them": "There is always time. Love Nan. x",
			 "replies": [{"text": "love you nan x", "sanity": 13.0}]},
		]},

	# --- WEEKS 2-4: settling in-------------------------------
	{
		"id": "careers_confirm", "sender": "Careers Advisor", "avatar": "CA", "arrives": 8,
		"requires": "before_results",
		"steps": [
			{"them": "Hi {NAME} — just confirming your first preference is still {UNI}?",
			 "replies": [
				{"text": "yes, that's still the plan", "sanity": 4.0, "goto": 1},
				{"text": "actually I've been second-guessing it", "sanity": 6.0, "goto": 2}]},
			{"them": "Great. One thing people forget: an offer is conditional on University Entrance, not on your average. Credits first, marks second.",
			 "replies": [
				{"text": "that's a useful way to put it", "sanity": 6.0, "goto": 3},
				{"text": "I did not know that", "sanity": 4.0, "goto": 3}]},
			{"them": "That's completely normal at this stage. Nobody decides once and never wobbles. Want to book a slot?",
			 "replies": [
				{"text": "yeah, that'd help", "sanity": 11.0, "goto": 3},
				{"text": "I'll think about it", "sanity": 6.0, "goto": 3}]},
			{"them": "Also — apply to StudyLink early. Every year I have someone with an offer they cannot afford to accept.",
			 "replies": [
				{"text": "noted. I'll do it on the laptop tonight", "sanity": 8.0},
				{"text": "surely that's a later problem", "temptation": 4.0}]},
		]},
	{
		"id": "priya_law_or_commerce", "sender": "Priya", "avatar": "PR", "arrives": 10,
		"steps": [
			{"them": "can I ask you something and you not make it weird",
			 "replies": [
				{"text": "course, what's up", "sanity": 6.0, "goto": 1},
				{"text": "no promises but go on", "sanity": 5.0, "goto": 1}]},
			{"them": "everyone says do law. I want to do commerce. am I being an idiot?",
			 "replies": [
				{"text": "do the one you'll actually turn up to", "sanity": 11.0, "goto": 2},
				{"text": "law's just the one that sounds impressive at dinner", "sanity": 10.0, "goto": 2},
				{"text": "honestly? law probably opens more doors", "sanity": 4.0, "goto": 3}]},
			{"them": "yeah. yeah you're right. thanks {NAME}, genuinely",
			 "replies": [
				{"text": "any time", "sanity": 8.0},
				{"text": "you'll be great at it", "sanity": 10.0}]},
			{"them": "...that's what my dad said. I was kind of hoping you'd say the other thing.",
			 "replies": [
				{"text": "then you already know what you want", "sanity": 12.0},
				{"text": "sorry. do commerce. clearly you want commerce.", "sanity": 9.0}]},
		]},
	{
		"id": "sione_gym", "sender": "Sione", "avatar": "SI", "arrives": 11,
		"steps": [
			{"them": "gym after school? clears the head before study",
			 "replies": [
				{"text": "yeah go on then", "sanity": 11.0, "temptation": 3.0, "goto": 1},
				{"text": "can't, work", "sanity": 3.0, "goto": 2},
				{"text": "I should really study", "sanity": 4.0, "goto": 3}]},
			{"them": "sweet. see you at 4.",
			 "replies": [{"text": "see you there", "sanity": 5.0}]},
			{"them": "all good. next week?",
			 "replies": [{"text": "next week", "sanity": 5.0}]},
			{"them": "you'll study better after. that's not me making excuses, that's just true.",
			 "replies": [
				{"text": "...fine, you're right", "sanity": 12.0, "temptation": 2.0},
				{"text": "I'll take your word for it another day", "sanity": 5.0}]},
		]},
	{
		"id": "wrong_number", "sender": "Unknown number", "avatar": "??", "arrives": 12,
		"steps": [
			{"them": "hey are we still on for 6",
			 "replies": [
				{"text": "wrong number sorry", "goto": 1},
				{"text": "yes absolutely", "temptation": 2.0, "goto": 2}]},
			{"them": "oh no. sorry!! I've been texting my sister for twenty minutes",
			 "replies": [
				{"text": "she's going to be so confused", "sanity": 6.0, "goto": 3},
				{"text": "happens to everyone", "sanity": 4.0, "goto": 3}]},
			{"them": "great. see you at nans. wait. who is this",
			 "replies": [
				{"text": "nobody. enjoy nans", "sanity": 7.0, "goto": 3}]},
			{"them": "have a good day whoever you are",
			 "replies": [
				{"text": "you too", "sanity": 5.0}]},
		]},
	{
		"id": "mika_group_project", "sender": "Mika", "avatar": "MI", "arrives": 14,
		"steps": [
			{"them": "WHO put the group project entirely on my plate",
			 "replies": [
				{"text": "I'll take half. send it over.", "sanity": 10.0, "temptation": -2.0, "goto": 1},
				{"text": "not me, I've been buried all week", "sanity": 4.0, "goto": 2},
				{"text": "genuinely who did that", "sanity": 5.0, "goto": 3}]},
			{"them": "you are the only person in this school with a conscience. sending now.",
			 "replies": [
				{"text": "get it done tonight", "sanity": 7.0},
				{"text": "you owe me a pie", "sanity": 8.0}]},
			{"them": "yeah fair. everyone is. sorry for shouting.",
			 "replies": [
				{"text": "shout away, it's a rubbish situation", "sanity": 7.0},
				{"text": "ask Sione, he's got time", "sanity": 5.0}]},
			{"them": "Josh. it was Josh. he added himself to the doc and then left.",
			 "replies": [
				{"text": "incredible commitment to doing nothing", "sanity": 8.0},
				{"text": "I'll say something to him", "sanity": 9.0}]},
		]},
	{
		"id": "chloe_prank", "sender": "Chloe", "avatar": "CH", "arrives": 16,
		"steps": [
			{"them": "did you hear they moved the physics external forward two weeks",
			 "replies": [
				{"text": "WHAT", "sanity": 1.0, "goto": 1},
				{"text": "no they didn't, I checked the timetable this morning", "sanity": 5.0, "goto": 2}]},
			{"them": "kidding!! sorry. that was genuinely mean.",
			 "replies": [
				{"text": "I aged five years", "sanity": 6.0},
				{"text": "never speak to me again", "sanity": 5.0}]},
			{"them": "...ok you're no fun. how did you know",
			 "replies": [{"text": "because I check it four times a day", "sanity": 7.0}]},
		]},
	{
		"id": "dad_awkward", "sender": "Dad", "avatar": "DA", "arrives": 17,
		"steps": [
			{"them": "Hi mate. Your mother mentioned you've got a big year. Thought I'd check in.",
			 "replies": [
				{"text": "yeah. it's a lot.", "sanity": 5.0, "goto": 1},
				{"text": "all under control", "sanity": 2.0, "goto": 2},
				{"text": "you could just ring me you know", "sanity": 4.0, "goto": 3}]},
			{"them": "Right. Well. I never did any of this university business so I'm not much use on the detail.",
			 "replies": [
				{"text": "you don't have to be useful, it's fine", "sanity": 9.0, "goto": 4},
				{"text": "that's alright. nobody knows what they're doing", "sanity": 8.0, "goto": 4}]},
			{"them": "Good. Good. That's what I like to hear.",
			 "replies": [
				{"text": "...it's not entirely under control", "sanity": 7.0, "goto": 1},
				{"text": "cheers dad", "sanity": 3.0, "goto": 4}]},
			{"them": "Ha. You know I'm no good on the phone.",
			 "replies": [
				{"text": "I know. this is fine.", "sanity": 7.0, "goto": 4}]},
			{"them": "If money gets tight you tell me. Don't do the thing where you don't tell me.",
			 "replies": [
				{"text": "I'll tell you", "sanity": 13.0},
				{"text": "I'm managing", "sanity": 6.0}]},
		]},
	{
		"id": "manaia_at_uni", "sender": "Manaia (cousin)", "avatar": "MA", "arrives": 19,
		"steps": [
			{"them": "oi. year 13. how's it treating you",
			 "replies": [
				{"text": "how did you survive this", "sanity": 5.0, "goto": 1},
				{"text": "fine so far", "sanity": 3.0, "goto": 2}]},
			{"them": "badly! I survived it badly. but here's the actual advice nobody gave me",
			 "replies": [
				{"text": "go on", "sanity": 4.0, "goto": 3}]},
			{"them": "give it time. it gets real around week eight when the internals stack up.",
			 "replies": [
				{"text": "that's ominous", "sanity": 3.0, "goto": 3}]},
			{"them": "credits are the only thing that gets you in the door. your average decides WHICH door. people mix those two up and lose a year over it.",
			 "replies": [
				{"text": "ok that actually clarified a lot", "sanity": 12.0, "goto": 4},
				{"text": "I already knew that", "sanity": 5.0, "goto": 4}]},
			{"them": "also apply for the loan now. not later. now. I applied in january of first year and ate rice for two months.",
			 "replies": [
				{"text": "doing it tonight", "sanity": 10.0},
				{"text": "noted, chief", "sanity": 6.0}]},
		]},
	{
		"id": "josh_notes", "sender": "Josh (maths)", "avatar": "JO", "arrives": 21,
		"steps": [
			{"them": "hey it's Josh from maths. got the notes from tuesday?",
			 "replies": [
				{"text": "yeah I'll send them over", "sanity": 7.0, "goto": 1},
				{"text": "I wasn't there either sorry", "sanity": 4.0, "goto": 2},
				{"text": "did you actually do any of the group project", "sanity": 3.0, "goto": 3}]},
			{"them": "legend, owe you one",
			 "replies": [
				{"text": "you can buy me a pie", "sanity": 8.0},
				{"text": "all g", "sanity": 5.0}]},
			{"them": "ah. skiving together then. solidarity.",
			 "replies": [{"text": "something like that", "sanity": 6.0}]},
			{"them": "...ok that's fair. I'll do the conclusion tonight. genuinely.",
			 "replies": [
				{"text": "I'll hold you to that", "sanity": 7.0},
				{"text": "Mika will kill you otherwise", "sanity": 8.0}]},
		]},

	# --- WEEKS 4-8: the middle, where it gets heavy -------------------------
	{
		"id": "work_extra_shift", "sender": "Deb (work)", "avatar": "DE", "arrives": 23,
		"requires": "still_employed",
		"steps": [
			{"them": "Hi {NAME}! Any chance you can pick up Thursday night? Short-handed again.",
			 "replies": [
				{"text": "yep I can do that", "sanity": -3.0, "goto": 1, "commit": {"kind": "work", "label": "Extra Thursday shift", "in": 2}},
				{"text": "sorry, I've got study on", "sanity": 4.0, "goto": 2},
				{"text": "I've done five nights this fortnight already", "sanity": 6.0, "goto": 3}]},
			{"them": "You're a lifesaver. I'll put you down.",
			 "replies": [{"text": "no worries", "sanity": 1.0}]},
			{"them": "No worries at all — exams first. I'll ask someone else.",
			 "replies": [{"text": "appreciate it", "sanity": 5.0}]},
			{"them": "...you have, haven't you. Sorry, that's on me. Take the week off, I'll sort cover.",
			 "replies": [
				{"text": "thank you. genuinely.", "sanity": 12.0},
				{"text": "I can still do one if you're stuck", "sanity": 4.0}]},
		]},
	{
		"id": "ana_noticed", "sender": "Ana", "avatar": "AN", "arrives": 25,
		"steps": [
			{"them": "hey. you seemed off in class today. you don't have to talk about it.",
			 "replies": [
				{"text": "not really no. it's been a week.", "sanity": 10.0, "goto": 1},
				{"text": "just tired, thanks for checking", "sanity": 7.0, "goto": 2},
				{"text": "I'm fine", "sanity": 3.0, "goto": 2}]},
			{"them": "do you want advice or do you just want someone to say that sounds rubbish?",
			 "replies": [
				{"text": "the second one", "sanity": 13.0, "goto": 3},
				{"text": "advice would actually help", "sanity": 10.0, "goto": 4}]},
			{"them": "ok. well I'm around either way.",
			 "replies": [{"text": "cheers Ana", "sanity": 8.0}]},
			{"them": "that sounds absolutely rubbish and you're allowed to find it hard.",
			 "replies": [
				{"text": "thank you. that's exactly it.", "sanity": 15.0},
				{"text": "yeah. it is.", "sanity": 12.0}]},
			{"them": "pick one thing. do only that today. the rest can wait a day, I promise.",
			 "replies": [
				{"text": "ok. one thing.", "sanity": 13.0},
				{"text": "that's easier said than done", "sanity": 8.0}]},
		]},
	{
		"id": "work_chat", "sender": "Store groupchat", "avatar": "WK", "arrives": 27,
		"requires": "still_employed",
		"steps": [
			{"from": "Reti", "them": "whoever left the trolley of frozen peas in aisle 4 overnight. we need to talk.",
			 "replies": [
				{"text": "wasn't me", "sanity": 4.0, "goto": 1},
				{"text": "...how bad", "sanity": 3.0, "goto": 2}]},
			{"from": "Reti", "them": "that's what everyone's said. someone in this chat is lying to me.",
			 "replies": [
				{"text": "it's always Bex", "sanity": 6.0, "goto": 3}]},
			{"from": "Reti", "them": "there is a lake. there is a lake in aisle 4.",
			 "replies": [
				{"text": "I'm so sorry", "sanity": 5.0, "goto": 3},
				{"text": "on my way in early to help", "sanity": 8.0, "goto": 3}]},
			{"from": "Deb", "them": "I can see this chat, you know. All of it. Every message.",
			 "replies": [
				{"text": "hi Deb", "sanity": 9.0},
				{"text": "we love you Deb", "sanity": 8.0}]},
		]},
	{
		"id": "tane_panic", "sender": "Tane", "avatar": "TA", "arrives": 29,
		"steps": [
			{"them": "MATE. the internal is due TOMORROW not next week",
			 "replies": [
				{"text": "how many words have you got", "sanity": 5.0, "goto": 1},
				{"text": "oh no", "sanity": 4.0, "goto": 1}]},
			{"them": "four hundred. out of fifteen hundred.",
			 "replies": [
				{"text": "ask for an extension. seriously, just ask.", "sanity": 9.0, "goto": 2},
				{"text": "right. all-nighter. I'll stay up with you.", "sanity": 11.0, "temptation": 3.0, "goto": 3},
				{"text": "rip", "sanity": 3.0, "goto": 4}]},
			{"them": "...I didn't think you could just do that. I'll email him now.",
			 "replies": [{"text": "let me know how it goes", "sanity": 7.0}]},
			{"them": "you're a legend. ok. 1500 words. we ride at dawn.",
			 "replies": [{"text": "we ride at dawn", "sanity": 9.0}]},
			{"them": "thanks. very helpful. very supportive.",
			 "replies": [{"text": "you'll be fine honestly", "sanity": 5.0}]},
		]},
	{
		"id": "scam_prize", "sender": "Unknown number", "avatar": "??", "arrives": 30,
		"steps": [
			{"them": "Congratulations!! You have been selected for a FREE prize draw!!!",
			 "replies": [
				{"text": "block", "sanity": 4.0, "goto": 2},
				{"text": "what prize", "sanity": 1.0, "temptation": 3.0, "goto": 1}]},
			{"them": "Simply reply with your bank details to claim!!",
			 "replies": [{"text": "ok now I'm blocking you", "sanity": 5.0, "goto": 2}]},
			{"them": "[blocked]",
			 "replies": [{"text": "sorted", "sanity": 2.0}]},
		]},
	{
		"id": "wiremu_last_game", "sender": "Wiremu", "avatar": "WI", "arrives": 32,
		"steps": [
			{"them": "last game of the season friday. you coming or what",
			 "replies": [
				{"text": "wouldn't miss it", "sanity": 12.0, "temptation": 5.0, "goto": 1},
				{"text": "if I get my work done first, yeah", "sanity": 8.0, "temptation": 2.0, "goto": 2},
				{"text": "can't. exams.", "sanity": 3.0, "goto": 3}]},
			{"them": "good. it's been ages since you came to anything.",
			 "replies": [{"text": "yeah I know. see you friday.", "sanity": 8.0}]},
			{"them": "that's the most {NAME} answer I've ever read. see you there.",
			 "replies": [{"text": "probably fair", "sanity": 9.0}]},
			{"them": "the externals are in like two months bro",
			 "replies": [
				{"text": "...ok that's a fair point", "sanity": 9.0, "temptation": 3.0},
				{"text": "two months is nothing", "sanity": 4.0}]},
		]},
	{
		"id": "nan_recipe", "sender": "Nan", "avatar": "NA", "arrives": 34,
		"steps": [
			{"them": "Dear {NAME}. I am sending you the recipe for the soup. It is cheap and it is good for you.",
			 "replies": [
				{"text": "yes please", "sanity": 9.0, "goto": 1},
				{"text": "I can barely work the stove nan", "sanity": 7.0, "goto": 2}]},
			{"them": "Onion. Carrot. Whatever is old in the fridge. Stock. Do not overthink it, that is the whole recipe.",
			 "replies": [
				{"text": "that's the best recipe I've ever been sent", "sanity": 12.0, "goto": 3},
				{"text": "there's no quantities", "sanity": 8.0, "goto": 3}]},
			{"them": "Then it is time you learned. You cannot live on those instant noodles.",
			 "replies": [
				{"text": "how do you know about the noodles", "sanity": 10.0, "goto": 1}]},
			{"them": "Quantities are for people who do not trust themselves. Ring me if it goes wrong. x",
			 "replies": [
				{"text": "love you nan x", "sanity": 13.0},
				{"text": "I'll send you a photo", "sanity": 11.0}]},
		]},
	{
		"id": "study_group_slipping", "sender": "Study group", "avatar": "SG", "arrives": 36,
		"steps": [
			{"from": "Priya", "them": "nobody came thursday. I sat in the library on my own for two hours.",
			 "replies": [
				{"text": "I'm so sorry. that's on me.", "sanity": 6.0, "goto": 1},
				{"text": "I had a shift, I did message", "sanity": 3.0, "goto": 2},
				{"text": "honestly I forgot completely", "sanity": 4.0, "goto": 1}]},
			{"from": "Priya", "them": "it's fine. it's just. I organised it and then it was me and a stack of past papers.",
			 "replies": [
				{"text": "next thursday. I'll be there. properly.", "sanity": 12.0, "temptation": -4.0, "goto": 3, "commit": {"kind": "study_group", "label": "Study group — you promised Priya", "in": 3}},
				{"text": "do you want to just do it as a two?", "sanity": 11.0, "goto": 3}]},
			{"from": "Mika", "them": "we're all terrible. Priya you are carrying this group and we do not deserve you",
			 "replies": [
				{"text": "seconded", "sanity": 7.0, "goto": 3}]},
			{"from": "Priya", "them": "...ok. thursday. and Mika you are on snacks and that is a binding contract.",
			 "replies": [
				{"text": "see you thursday", "sanity": 9.0},
				{"text": "legally binding", "sanity": 8.0}]},
		]},
	{
		"id": "neighbour_lawns", "sender": "Mrs Tuiloma", "avatar": "MT", "arrives": 38,
		"steps": [
			{"them": "Hello love, it's next door. My mower is playing up and my back is worse. Would you do the lawns Saturday? I'll pay properly.",
			 "replies": [
				{"text": "yeah of course", "sanity": 6.0, "goto": 1},
				{"text": "I can't this weekend sorry", "sanity": 2.0, "goto": 2},
				{"text": "you don't have to pay me", "sanity": 9.0, "goto": 3}]},
			{"them": "Wonderful. Forty dollars and a cup of tea. Non-negotiable.",
			 "replies": [
				{"text": "deal", "sanity": 8.0},
				{"text": "the tea's the real payment", "sanity": 9.0}]},
			{"them": "Not to worry. Another time. You look tired, by the way. I'm allowed to say that, I'm old.",
			 "replies": [
				{"text": "you are allowed to say that", "sanity": 7.0},
				{"text": "I'll come round next weekend", "sanity": 9.0}]},
			{"them": "I absolutely do have to pay you. Don't be silly. Forty dollars.",
			 "replies": [
				{"text": "alright, alright", "sanity": 10.0},
				{"text": "twenty. final offer.", "sanity": 11.0}]},
		]},
	{
		"id": "school_notices_timetable", "sender": "School Notices", "avatar": "SN", "arrives": 40,
		"steps": [
			{"them": "REMINDER: Provisional external examination timetables are now available. Check yours and note any clashes immediately.",
			 "replies": [
				{"text": "already checked it", "sanity": 3.0, "goto": 1},
				{"text": "oh no. I have not checked it.", "sanity": 1.0, "goto": 1}]},
			{"them": "Derived grade applications require evidence and close shortly after the examination period. See the office BEFORE the exam, not after.",
			 "replies": [
				{"text": "noted", "sanity": 3.0},
				{"text": "hopefully won't need it", "sanity": 2.0}]},
		]},
	{
		"id": "mum_worried", "sender": "Mum", "avatar": "MU", "arrives": 42,
		"steps": [
			{"them": "your light was on at 2am again. I'm not telling you off. I'm just saying I saw it.",
			 "replies": [
				{"text": "I couldn't get the essay to work", "sanity": 6.0, "goto": 1},
				{"text": "I wasn't working. I was on my phone.", "sanity": 8.0, "goto": 2},
				{"text": "sorry. I'll be quieter.", "sanity": 2.0, "goto": 3}]},
			{"them": "nothing works at 2am. nothing has ever worked at 2am in the history of the world.",
			 "replies": [
				{"text": "that's annoyingly true", "sanity": 9.0, "goto": 4},
				{"text": "it has to be finished though", "sanity": 4.0, "goto": 4}]},
			{"them": "right. well. at least you're honest. that's more than I got out of your brother at your age.",
			 "replies": [
				{"text": "I'll put it away earlier", "sanity": 10.0, "goto": 4},
				{"text": "don't tell dad", "sanity": 7.0, "goto": 4}]},
			{"them": "that's not what I meant and you know it.",
			 "replies": [
				{"text": "I know. sorry.", "sanity": 6.0, "goto": 4}]},
			{"them": "bed by midnight. I'm not asking as your mother, I'm asking as someone who's watched you do this for four weeks.",
			 "replies": [
				{"text": "ok. midnight.", "sanity": 14.0},
				{"text": "I'll try", "sanity": 8.0}]},
		]},
	{
		"id": "ball_committee", "sender": "Ball committee", "avatar": "BC", "arrives": 44,
		"steps": [
			{"from": "Chloe", "them": "TICKETS ARE $95 AND THE VENUE WANTS A DEPOSIT BY FRIDAY",
			 "replies": [
				{"text": "ninety five DOLLARS", "sanity": 3.0, "goto": 1},
				{"text": "I'm in, put me down", "sanity": 8.0, "temptation": 4.0, "goto": 2},
				{"text": "I'll decide later", "sanity": 3.0, "goto": 3}]},
			{"from": "Chloe", "them": "I KNOW. I fought them. they have a chocolate fountain and apparently that costs money",
			 "replies": [
				{"text": "does the fountain know I work at a supermarket", "sanity": 9.0, "goto": 3},
				{"text": "ok fine put me down", "sanity": 7.0, "temptation": 4.0, "goto": 2}]},
			{"from": "Chloe", "them": "yes!! that's most of year 13 now. it's actually going to be good.",
			 "replies": [
				{"text": "it better be", "sanity": 8.0},
				{"text": "worth every dollar hopefully", "sanity": 7.0}]},
			{"from": "Ana", "them": "no pressure either way. genuinely. plenty of people aren't going and they'll be fine.",
			 "replies": [
				{"text": "thanks Ana", "sanity": 9.0},
				{"text": "I'll see how money looks", "sanity": 5.0}]},
		]},
	{
		"id": "bank_alert", "sender": "Bank", "avatar": "$", "arrives": 46,
		"steps": [
			{"them": "A transaction of $89.99 to CLOUDBURST DIGITAL was attempted on your card. Was this you?",
			 "replies": [
				{"text": "no. definitely not.", "goto": 1},
				{"text": "...possibly", "temptation": 3.0, "goto": 2}]},
			{"them": "Thank you. The transaction was declined and your card has been blocked. A replacement is on its way.",
			 "replies": [
				{"text": "how long does that take", "sanity": 3.0, "goto": 3},
				{"text": "cheers", "sanity": 4.0, "goto": 3}]},
			{"them": "Please check the merchant name carefully. If you did not authorise this, reply NO.",
			 "replies": [
				{"text": "no, it wasn't me", "sanity": 3.0, "goto": 1}]},
			{"them": "Five to seven working days. In the meantime you can still use cash and internet banking.",
			 "replies": [
				{"text": "great. wonderful timing.", "sanity": 2.0},
				{"text": "fine. thanks for catching it.", "sanity": 6.0}]},
		]},
	{
		"id": "tane_apology", "sender": "Tane", "avatar": "TA", "arrives": 48,
		"steps": [
			{"them": "been thinking. I was a bit of a dick about the cancelling thing",
			 "replies": [
				{"text": "you weren't. you were right.", "sanity": 8.0, "goto": 1},
				{"text": "a bit, yeah", "sanity": 6.0, "goto": 2},
				{"text": "we're good mate", "sanity": 7.0, "goto": 3}]},
			{"them": "nah I was. I knew you were struggling and I made it about me not seeing you.",
			 "replies": [
				{"text": "we're both bad at this", "sanity": 11.0, "goto": 3},
				{"text": "I'd have done the same", "sanity": 9.0, "goto": 3}]},
			{"them": "yeah. sorry. I'm working on it.",
			 "replies": [
				{"text": "appreciated", "sanity": 8.0, "goto": 3}]},
			{"them": "anyway. saturday still on? I'll come to you. you don't even have to leave the house.",
			 "replies": [
				{"text": "that's the best offer I've had all term", "sanity": 14.0, "temptation": 3.0},
				{"text": "bring food and it's a deal", "sanity": 12.0, "temptation": 3.0}]},
		]},
	{
		"id": "dairy_owner", "sender": "Ravi (dairy)", "avatar": "RA", "arrives": 50,
		"steps": [
			{"them": "You left your student ID on my counter. Again.",
			 "replies": [
				{"text": "oh no. thank you.", "sanity": 5.0, "goto": 1},
				{"text": "how do you have my number", "sanity": 4.0, "goto": 2}]},
			{"them": "It is behind the till. Come get it before I start charging rent.",
			 "replies": [
				{"text": "on my way", "sanity": 6.0, "goto": 3},
				{"text": "how much is the rent", "sanity": 7.0, "goto": 3}]},
			{"them": "It is written on the ID. Along with your name. Which I now know. Hello {NAME}.",
			 "replies": [
				{"text": "fair enough", "sanity": 6.0, "goto": 1}]},
			{"them": "One pie. That is the rent. Also you look like you have not slept, take a proper lunch tomorrow.",
			 "replies": [
				{"text": "everyone keeps saying that", "sanity": 8.0},
				{"text": "deal. one pie.", "sanity": 9.0}]},
		]},
	{
		"id": "mika_meltdown", "sender": "Mika", "avatar": "MI", "arrives": 52,
		"steps": [
			{"them": "I think I've made a huge mistake with my subjects and it's too late to change",
			 "replies": [
				{"text": "talk me through it", "sanity": 8.0, "goto": 1},
				{"text": "it is definitely not too late", "sanity": 7.0, "goto": 2},
				{"text": "everyone thinks that in september", "sanity": 5.0, "goto": 3}]},
			{"them": "I took chem because Priya took chem. that's the whole reason. I don't even like it.",
			 "replies": [
				{"text": "you can still get the credits out of it", "sanity": 9.0, "goto": 4},
				{"text": "that's such a year 12 thing to do", "sanity": 6.0, "goto": 4},
				{"text": "honestly? same energy as half my choices", "sanity": 10.0, "goto": 4}]},
			{"them": "it IS though. it's september. what am I meant to do, unlearn a year",
			 "replies": [
				{"text": "no. finish it. it's one year.", "sanity": 8.0, "goto": 4}]},
			{"them": "...ok that's oddly comforting. misery loves company.",
			 "replies": [
				{"text": "misery loves a study group", "sanity": 9.0, "goto": 4}]},
			{"them": "right. I'm going to grind out the credits and never think about a titration again as long as I live.",
			 "replies": [
				{"text": "that's the spirit", "sanity": 11.0},
				{"text": "you'll be at uni doing chem in two years, watch", "sanity": 9.0}]},
		]},

	# --- WEEKS 8-11: exam run-in --------------------------------------------
	{
		"id": "studylink_reminder", "sender": "StudyLink", "avatar": "SL", "arrives": 54,
		"requires": "no_loan_application",
		"steps": [
			{"them": "Kia ora {NAME}. Our records show you have not yet submitted a Student Loan application for next year.",
			 "replies": [
				{"text": "I'll do it this week", "sanity": 3.0, "goto": 1},
				{"text": "I don't think I'll need one", "sanity": 1.0, "goto": 2},
				{"text": "how do I even apply", "goto": 3}]},
			{"them": "Applications take around five working days to process. We recommend applying well before you accept any offer of place.",
			 "replies": [
				{"text": "understood", "sanity": 4.0, "goto": 4}]},
			{"them": "Course fees for a first year degree typically run to several thousand dollars. We would encourage you to apply regardless.",
			 "replies": [
				{"text": "...right. yeah. I'll apply.", "sanity": 6.0, "goto": 4},
				{"text": "I've got savings", "sanity": 2.0, "goto": 4}]},
			{"them": "Online, through the StudyLink section of your MyStudy portal. You will need your IRD number.",
			 "replies": [
				{"text": "found it, thanks", "sanity": 5.0, "goto": 4}]},
			{"them": "Applications for the coming academic year close on day {LOANDAY}. Late applications cannot be guaranteed.",
			 "replies": [
				{"text": "noted", "sanity": 4.0},
				{"text": "doing it tonight", "sanity": 7.0}]},
		]},
	{
		"id": "priya_wobble", "sender": "Priya", "avatar": "PR", "arrives": 56,
		"steps": [
			{"them": "I got 68 on the stats internal",
			 "replies": [
				{"text": "that's a good mark", "sanity": 6.0, "goto": 1},
				{"text": "how do you feel about it", "sanity": 8.0, "goto": 2},
				{"text": "and? that's fine?", "sanity": 4.0, "goto": 1}]},
			{"them": "it's not. I need high 80s. everyone I'm competing against gets high 80s.",
			 "replies": [
				{"text": "you're not competing against anyone", "sanity": 11.0, "goto": 3},
				{"text": "who told you that", "sanity": 9.0, "goto": 3}]},
			{"them": "...like I've failed. which I know is insane. 68 is not failing.",
			 "replies": [
				{"text": "you're allowed to be disappointed and also fine", "sanity": 13.0, "goto": 3},
				{"text": "it's really not failing", "sanity": 8.0, "goto": 3}]},
			{"them": "my brain, mostly. ok. thank you. I'm going to go and not look at the mark for a bit.",
			 "replies": [
				{"text": "good plan", "sanity": 9.0},
				{"text": "text me if it starts spiralling again", "sanity": 13.0}]},
		]},
	{
		"id": "halls_accommodation", "sender": "Accommodation Office", "avatar": "AC", "arrives": 58,
		"requires": "no_accommodation",
		"steps": [
			{"them": "Hi {NAME}. Halls of residence applications for {UNI} close soon. Have you considered where you will live next year?",
			 "replies": [
				{"text": "I genuinely have not thought about this", "goto": 1},
				{"text": "catered halls, ideally", "goto": 2},
				{"text": "I'll flat", "goto": 3}]},
			{"them": "You would not be the first. Catered halls run around $18,000 for the year; flatting is cheaper but you cook, clean and chase a landlord.",
			 "replies": [
				{"text": "eighteen thousand", "sanity": 1.0, "goto": 4},
				{"text": "ok. good to know the actual numbers.", "sanity": 5.0, "goto": 4}]},
			{"them": "Noted. Please be aware places are limited and offers are made alongside your academic offer.",
			 "replies": [
				{"text": "understood", "sanity": 3.0, "goto": 4}]},
			{"them": "A sensible option, and considerably cheaper. Most first years who flat do so with people from their halls, so it is worth applying anyway.",
			 "replies": [
				{"text": "hadn't thought of it like that", "sanity": 6.0, "goto": 4}]},
			{"them": "Whatever you decide, decide before the offer arrives. People lose their place over accommodation, not grades.",
			 "replies": [
				{"text": "that's genuinely useful", "sanity": 7.0},
				{"text": "one thing at a time", "sanity": 4.0}]},
		]},
	{
		"id": "wiremu_after_season", "sender": "Wiremu", "avatar": "WI", "arrives": 60,
		"steps": [
			{"them": "season's done. weirdly quiet now",
			 "replies": [
				{"text": "you ok?", "sanity": 8.0, "goto": 1},
				{"text": "more time to study", "sanity": 3.0, "goto": 2}]},
			{"them": "yeah. just. that was the thing I was good at and now it's the exams and I'm not good at those.",
			 "replies": [
				{"text": "you got better at rugby by doing it badly first", "sanity": 13.0, "goto": 3},
				{"text": "you don't have to be good at it. you have to get through it.", "sanity": 12.0, "goto": 3},
				{"text": "you're better at them than you think", "sanity": 7.0, "goto": 3}]},
			{"them": "ha. that's one way to look at it.",
			 "replies": [
				{"text": "it's the only way to look at it", "sanity": 6.0, "goto": 3}]},
			{"them": "cheers bro. anyway. wanna study together? I'll be useless but I'll turn up.",
			 "replies": [
				{"text": "turning up is most of it", "sanity": 12.0, "temptation": -3.0},
				{"text": "yeah go on", "sanity": 10.0, "temptation": -2.0}]},
		]},
	{
		"id": "teacher_email", "sender": "Mr Halloway", "avatar": "MH", "arrives": 62,
		"steps": [
			{"them": "{NAME} — I have your internal marks in front of me and I would like a word. Nothing sinister.",
			 "replies": [
				{"text": "that's a very sinister way to say nothing sinister", "sanity": 5.0, "goto": 1},
				{"text": "ok. is it bad?", "sanity": 3.0, "goto": 2},
				{"text": "sure, when?", "goto": 3}]},
			{"them": "Yes, on reflection. Apologies. You are not in trouble.",
			 "replies": [
				{"text": "ok good. what's up?", "goto": 3}]},
			{"them": "Not bad. Uneven. You are strong where you are interested and thin where you are not, and the externals will not care which is which.",
			 "replies": [
				{"text": "that's a fair read", "sanity": 7.0, "goto": 3},
				{"text": "I know exactly which subject you mean", "sanity": 8.0, "goto": 3}]},
			{"them": "Tuesday lunch. Bring the subject you have been avoiding. That is the whole meeting.",
			 "replies": [
				{"text": "I'll be there", "sanity": 11.0, "temptation": -4.0},
				{"text": "how did you know I'm avoiding one", "sanity": 9.0}]},
		]},
	{
		"id": "ana_her_turn", "sender": "Ana", "avatar": "AN", "arrives": 64,
		"steps": [
			{"them": "ok this is going to be weird because I'm normally the one asking. but I'm not doing great.",
			 "replies": [
				{"text": "tell me", "sanity": 6.0, "goto": 1},
				{"text": "it's not weird at all", "sanity": 8.0, "goto": 1},
				{"text": "do you want advice or just to be heard?", "sanity": 12.0, "goto": 2}]},
			{"them": "everyone comes to me. all day. and I don't mind, I really don't. but there's nobody doing it back.",
			 "replies": [
				{"text": "I'm doing it back. right now.", "sanity": 15.0, "goto": 3},
				{"text": "that sounds exhausting and lonely", "sanity": 13.0, "goto": 3}]},
			{"them": "ha. using my own line on me. ...to be heard, please.",
			 "replies": [
				{"text": "go on then. I'm listening.", "sanity": 12.0, "goto": 1}]},
			{"them": "thank you. genuinely. I'm ok, I just needed someone to notice for once.",
			 "replies": [
				{"text": "I'll keep noticing. that's a promise.", "sanity": 16.0},
				{"text": "any time, seriously", "sanity": 12.0}]},
		]},
	{
		"id": "scam_courier", "sender": "Unknown number", "avatar": "??", "arrives": 66,
		"steps": [
			{"them": "NZ POST: your parcel could not be delivered. Pay the $2.30 redelivery fee here to reschedule.",
			 "replies": [
				{"text": "I'm not expecting a parcel", "sanity": 4.0, "goto": 1},
				{"text": "it's only $2.30 though", "temptation": 4.0, "goto": 2}]},
			{"them": "URGENT: parcel will be returned in 24 hours.",
			 "replies": [
				{"text": "blocked and reported", "sanity": 6.0, "goto": 3},
				{"text": "nice try", "sanity": 5.0, "goto": 3}]},
			{"them": "Please enter your card number to proceed.",
			 "replies": [
				{"text": "absolutely not", "sanity": 7.0, "goto": 3},
				{"text": "oh. oh that's a scam isn't it.", "sanity": 4.0, "goto": 3}]},
			{"them": "[blocked]",
			 "replies": [{"text": "that's the second one this month", "sanity": 3.0}]},
		]},
	{
		"id": "mum_before_exams", "sender": "Mum", "avatar": "MU", "arrives": 70,
		"steps": [
			{"them": "so. externals soon.",
			 "replies": [
				{"text": "please don't", "sanity": 3.0, "goto": 1},
				{"text": "yeah. I'm scared actually.", "sanity": 8.0, "goto": 2},
				{"text": "I've got it handled", "sanity": 4.0, "goto": 3}]},
			{"them": "I wasn't going to ask about revision. I was going to ask what you want for dinner that week.",
			 "replies": [
				{"text": "oh", "sanity": 10.0, "goto": 4},
				{"text": "...that's really nice actually", "sanity": 13.0, "goto": 4}]},
			{"them": "I know. that's allowed. I was terrified of mine and I turned out fine. mostly.",
			 "replies": [
				{"text": "mostly", "sanity": 11.0, "goto": 4},
				{"text": "that did help, weirdly", "sanity": 12.0, "goto": 4}]},
			{"them": "good. then I'll stop asking. what do you want for dinner that week?",
			 "replies": [
				{"text": "nan's soup", "sanity": 12.0, "goto": 4},
				{"text": "anything I don't have to make", "sanity": 9.0, "goto": 4}]},
			{"them": "consider it done. and {NAME} — whatever the results say, it does not change anything. I mean that literally.",
			 "replies": [
				{"text": "I know. thanks mum.", "sanity": 16.0},
				{"text": "you have to say that", "sanity": 9.0}]},
		]},
	{
		"id": "study_group_final", "sender": "Study group", "avatar": "SG", "arrives": 73,
		"steps": [
			{"from": "Priya", "them": "final session before externals. saturday, all day, my place. mum's doing food.",
			 "replies": [
				{"text": "in", "sanity": 10.0, "temptation": -5.0, "goto": 1, "commit": {"kind": "study_group", "label": "All-day study session at Priya's", "in": 2}},
				{"text": "all day is a lot", "sanity": 4.0, "goto": 2},
				{"text": "I've got a shift", "sanity": 3.0, "goto": 3}]},
			{"from": "Mika", "them": "we are doing this. we are actually doing this. year 13 study group, final form.",
			 "replies": [
				{"text": "final form", "sanity": 9.0, "goto": 4}]},
			{"from": "Priya", "them": "come for as long as you can. even two hours. genuinely no pressure.",
			 "replies": [
				{"text": "I'll come for the morning", "sanity": 9.0, "goto": 4},
				{"text": "ok, all day. fine.", "sanity": 11.0, "temptation": -5.0, "goto": 4}]},
			{"from": "Priya", "them": "then come after. we'll still be going. we will absolutely still be going.",
			 "replies": [
				{"text": "see you after work then", "sanity": 10.0, "goto": 4}]},
			{"from": "Ana", "them": "whatever happens next month — this bit, right now, was the good part. just saying.",
			 "replies": [
				{"text": "don't do that, I'll cry", "sanity": 14.0},
				{"text": "yeah. it was.", "sanity": 13.0}]},
		]},
	{
		"id": "tane_night_before", "sender": "Tane", "avatar": "TA", "arrives": 77,
		"steps": [
			{"them": "you awake",
			 "replies": [
				{"text": "unfortunately", "sanity": 5.0, "goto": 1},
				{"text": "no", "sanity": 6.0, "goto": 1}]},
			{"them": "first external tomorrow. can't sleep. keep thinking about that one topic I skipped.",
			 "replies": [
				{"text": "go over it now, ten minutes, then sleep", "sanity": 7.0, "goto": 2},
				{"text": "it's one topic. sleep is worth more.", "sanity": 11.0, "goto": 3},
				{"text": "same. exactly the same.", "sanity": 9.0, "goto": 3}]},
			{"them": "ten minutes. ok. deal.",
			 "replies": [
				{"text": "then phone off", "sanity": 8.0, "goto": 4}]},
			{"them": "yeah. you're right. you're always right about this stuff and never about anything else.",
			 "replies": [
				{"text": "I'll take it", "sanity": 9.0, "goto": 4}]},
			{"them": "see you in there. we've done the work. mostly. some of the work.",
			 "replies": [
				{"text": "see you in there", "sanity": 12.0},
				{"text": "some of the work is enough", "sanity": 11.0}]},
		]},
	{
		"id": "reti_shift_swap", "sender": "Reti (work)", "avatar": "RE", "arrives": 80,
		"requires": "still_employed",
		"steps": [
			{"them": "bro. I know it's exam week. but I am BEGGING you. two hours friday.",
			 "replies": [
				{"text": "I've got an external friday", "sanity": 5.0, "goto": 1},
				{"text": "fine. two hours. you owe me.", "sanity": -4.0, "goto": 2, "commit": {"kind": "work", "label": "Covering Reti's Friday shift", "in": 1}},
				{"text": "ask Deb, she said she'd cover exam week", "sanity": 7.0, "goto": 3}]},
			{"them": "oh. right. no, forget I asked. seriously. go and sit your exam.",
			 "replies": [
				{"text": "thanks mate", "sanity": 8.0},
				{"text": "I'll pick up something next week", "sanity": 6.0}]},
			{"them": "you're a machine. I'll bring you an energy drink you don't need.",
			 "replies": [
				{"text": "I do need it", "sanity": 5.0},
				{"text": "I'm going to regret this", "sanity": 2.0}]},
			{"them": "...I didn't know she said that. mate you might have just saved my whole week.",
			 "replies": [
				{"text": "she's better than she lets on", "sanity": 9.0},
				{"text": "go ask her now", "sanity": 7.0}]},
		]},

	# --- STORY THREADS: delivered by the game, never at random ---------------
	{
		"id": "studylink_approved", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. Your Student Loan application has been APPROVED.",
			 "replies": [
				{"text": "open the details", "goto": 1}]},
			{"them": "LOAN_APPROVAL",
			 "replies": [
				{"text": "...that's a relief", "sanity": 14.0, "goto": 2},
				{"text": "that is a lot of money to owe", "sanity": 6.0, "goto": 2}]},
			{"them": "Repayments begin once you are earning above the threshold. You can adjust your living costs entitlement at any time through the portal.",
			 "replies": [
				{"text": "understood", "sanity": 4.0}]},
		]},
	{
		"id": "studylink_declined", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. We are unable to approve your Student Loan application at this time.",
			 "replies": [
				{"text": "why?", "goto": 1}]},
			{"them": "LOAN_DECLINE",
			 "replies": [
				{"text": "can I appeal this?", "goto": 2},
				{"text": "great. brilliant. thanks.", "sanity": -4.0, "goto": 2}]},
			{"them": "You may reapply for the following academic year. We are sorry we could not help on this occasion.",
			 "replies": [
				{"text": "right.", "sanity": -2.0}]},
		]},
	{
		"id": "allowance_result", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. A decision has been made on your Student Allowance application.",
			 "replies": [
				{"text": "open it", "goto": 1}]},
			{"them": "ALLOWANCE_SUMMARY",
			 "replies": [
				{"text": "...right.", "sanity": 2.0, "goto": 2},
				{"text": "that's a weight off", "sanity": 10.0, "goto": 2}]},
			{"them": "The allowance is assessed separately from your Student Loan. A decision on one does not affect the other.",
			 "replies": [
				{"text": "understood", "sanity": 3.0}]},
		]},
	{
		"id": "allowance_parents", "sender": "Mum", "avatar": "MU", "arrives": 999,
		"steps": [
			{"them": "just got an email from StudyLink saying they need MY details? what have you signed me up for",
			 "replies": [
				{"text": "it's the student allowance. they means-test it on your income.", "sanity": 3.0, "goto": 1},
				{"text": "sorry, I should have warned you", "sanity": 4.0, "goto": 2},
				{"text": "long story. can you just fill it in?", "goto": 3}]},
			{"them": "oh. right. so they want to know what your father and I earn.",
			 "replies": [
				{"text": "yeah. I don't even see the number, they just tell me yes or no.", "sanity": 5.0, "goto": 4},
				{"text": "I know it's a weird thing to have to ask", "sanity": 6.0, "goto": 4}]},
			{"them": "no no it's fine, I just wasn't expecting it. what is it for?",
			 "replies": [
				{"text": "weekly payment toward living costs. I don't pay it back.", "sanity": 5.0, "goto": 4}]},
			{"them": "I will, but tell me what it IS first. I'm not putting my income into a website because you said so.",
			 "replies": [
				{"text": "fair. it's the student allowance — means-tested, not repaid.", "sanity": 6.0, "goto": 4},
				{"text": "that's completely fair actually", "sanity": 7.0, "goto": 4}]},
			{"them": "PARENT_CONFIRM",
			 "replies": [
				{"text": "thank you. genuinely.", "sanity": 12.0, "goto": 5},
				{"text": "you're a legend", "sanity": 10.0, "goto": 5}]},
			{"them": "don't get your hopes up though love. I've a feeling we're just over the line.",
			 "replies": [
				{"text": "then at least we'll know", "sanity": 8.0},
				{"text": "the loan doesn't care about your income, so I'm covered either way", "sanity": 9.0}]},
		]},
	{
		"id": "allowance_parents_nudge", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. Your Student Allowance application cannot be assessed until your parent or guardian completes their section. It has been outstanding for a week.",
			 "replies": [
				{"text": "I'll chase them", "sanity": 2.0, "goto": 1},
				{"text": "I've asked twice already", "sanity": 3.0, "goto": 1}]},
			{"them": "Applications with an incomplete parental section at the cut-off date are declined automatically.",
			 "replies": [
				{"text": "right. ringing them now.", "sanity": 4.0}]},
		]},
	{
		"id": "work_noshow", "sender": "Deb (work)", "avatar": "DE", "arrives": 999,
		"steps": [
			{"them": "{NAME} — you were rostered on and you weren't here. No call, nothing. That's not like you.",
			 "replies": [
				{"text": "I'm so sorry Deb. I completely forgot.", "sanity": 3.0, "goto": 1},
				{"text": "something came up and I couldn't get to a phone", "sanity": 1.0, "goto": 2},
				{"text": "yeah. sorry.", "sanity": -2.0, "goto": 3}]},
			{"them": "Right. Well. It happens once. Ring me next time — I'd rather an hour's notice than an empty till.",
			 "replies": [
				{"text": "I will. Promise.", "sanity": 6.0, "goto": 3}]},
			{"them": "Mm. I've heard that one before, from better liars.",
			 "replies": [
				{"text": "...ok, fair. I forgot.", "sanity": 4.0, "goto": 1},
				{"text": "it won't happen again", "sanity": 2.0, "goto": 3}]},
			{"them": "Three no-shows and I have to take you off the roster. That's not me being harsh, that's the rule.",
			 "replies": [
				{"text": "understood", "sanity": 2.0},
				{"text": "I'll be there Thursday.", "sanity": 5.0}]},
		]},
	{
		"id": "work_fired", "sender": "Deb (work)", "avatar": "DE", "arrives": 999,
		"steps": [
			{"them": "That's the third one, {NAME}. I've taken you off the roster.",
			 "replies": [
				{"text": "Deb, please. I need this job.", "sanity": -4.0, "goto": 1},
				{"text": "I understand. I'm sorry.", "sanity": 2.0, "goto": 2}]},
			{"them": "I know you do. And I held it open twice. I've got a team who turn up and I can't keep explaining why you don't.",
			 "replies": [
				{"text": "you're right.", "sanity": 3.0, "goto": 2},
				{"text": "it's been a really bad year", "sanity": 4.0, "goto": 3}]},
			{"them": "Come back to me next year with a reference request and I'll write you a good one. I mean that.",
			 "replies": [
				{"text": "that's more than I deserve", "sanity": 8.0},
				{"text": "thanks Deb. for everything.", "sanity": 9.0}]},
			{"them": "I know. That's why I'm not being nastier about it. But the roster's the roster.",
			 "replies": [
				{"text": "yeah. fair enough.", "sanity": 4.0, "goto": 2}]},
		]},
	{
		"id": "study_group_noshow", "sender": "Priya", "avatar": "PR", "arrives": 999,
		"steps": [
			{"them": "you said you'd be there.",
			 "replies": [
				{"text": "I know. I'm sorry.", "sanity": 3.0, "goto": 1},
				{"text": "something came up", "sanity": 0.0, "goto": 2},
				{"text": "I genuinely forgot", "sanity": 2.0, "goto": 1}]},
			{"them": "it's fine. I'm not angry. I just organised it around you being there and then sat there.",
			 "replies": [
				{"text": "that's worse than you being angry", "sanity": 5.0, "goto": 3},
				{"text": "next one. I'll be there. properly.", "sanity": 7.0, "goto": 3}]},
			{"them": "something always comes up. that's sort of the point of saying yes to things.",
			 "replies": [
				{"text": "...yeah. that's fair.", "sanity": 4.0, "goto": 1}]},
			{"them": "ok. I'm holding you to that.",
			 "replies": [
				{"text": "hold me to it.", "sanity": 8.0}]},
		]},
	{
		"id": "rock_bottom", "sender": "Ana", "avatar": "AN", "arrives": 999,
		"steps": [
			{"them": "I don't know how to say this over text so I'm just going to say it. you look like you've stopped.",
			 "replies": [
				{"text": "I think I have.", "sanity": 14.0, "goto": 1},
				{"text": "I'm fine.", "sanity": 4.0, "goto": 2},
				{"text": "I can't do this.", "sanity": 12.0, "goto": 1}]},
			{"them": "ok. then today you do three things and nothing else. eat something. sleep properly. tell one adult.",
			 "replies": [
				{"text": "that's all?", "sanity": 15.0, "goto": 3},
				{"text": "I've got so much on though", "sanity": 8.0, "goto": 4}]},
			{"them": "you're not. and I'm not going to argue about it. three things, today.",
			 "replies": [
				{"text": "...alright. three things.", "sanity": 14.0, "goto": 3},
				{"text": "go on then", "sanity": 10.0, "goto": 1}]},
			{"them": "that's all. the year will still be there tomorrow. you might not be, at this rate.",
			 "replies": [
				{"text": "ok. I'm going to bed.", "sanity": 20.0},
				{"text": "thank you for noticing.", "sanity": 22.0}]},
			{"them": "yeah. and none of it gets done by you in this state. that's not me being nice, that's just arithmetic.",
			 "replies": [
				{"text": "...fair.", "sanity": 16.0, "goto": 3},
				{"text": "I hate that you're right", "sanity": 15.0, "goto": 3}]},
		]},
	{
		"id": "allowance_review", "sender": "StudyLink", "avatar": "SL", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. Your Student Allowance has been reassessed following an update to your parents' income details.",
			 "replies": [
				{"text": "reassessed how", "goto": 1}]},
			{"them": "ALLOWANCE_SUMMARY",
			 "replies": [
				{"text": "nobody warned me that could change", "sanity": 2.0, "goto": 2},
				{"text": "ok, noted", "sanity": 4.0, "goto": 2}]},
			{"them": "Entitlement is reviewed whenever income information changes. You do not need to reapply.",
			 "replies": [
				{"text": "right.", "sanity": 2.0}]},
		]},
	{
		"id": "nzqa_results", "sender": "NZQA", "avatar": "NZ", "arrives": 999,
		"steps": [
			{"them": "Kia ora {NAME}. Your external examination results are now available.",
			 "replies": [
				{"text": "open them", "goto": 1},
				{"text": "not yet. give me a minute.", "sanity": 2.0, "goto": 1}]},
			{"them": "RESULTS_SUMMARY",
			 "replies": [{"text": "...okay.", "goto": 2}]},
			{"them": "A full breakdown, including how each standard contributed to your University Entrance, is available on the NZQA site.",
			 "replies": [
				{"text": "I'll look on the laptop", "goto": 3},
				{"text": "thanks", "goto": 3}]},
			{"them": "University offers are made by each university directly, not by us. You should hear from them within a day.",
			 "replies": [{"text": "thanks"}]},
		]},
	{
		"id": "university_offer", "sender": "Admissions", "avatar": "UN", "arrives": 999,
		"steps": [
			{"them": "{NAME} — a decision has been made on your application.",
			 "replies": [{"text": "open it", "goto": 1}]},
			{"them": "OFFER_SUMMARY",
			 "replies": [{"text": "..."}]},
		]},
]


# HELPERS

## Replaces {NAME} and {UNI} throughout a thread.
func personalise(thread: Dictionary, player_name: String) -> Dictionary:
	var out: Dictionary = thread.duplicate(true)
	var uni: String = GameBackend.university_full_name()
	for step in out.steps:
		step.them = _sub(str(step.them), player_name, uni)
		for reply in step.replies:
			reply.text = _sub(str(reply.text), player_name, uni)
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
