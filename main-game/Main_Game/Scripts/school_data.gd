## SchoolData.gd
## Autoload: "SchoolData"
##
## Every face-to-face conversation in the school scene.
##
## These used to be one opening line plus three canned replies, which is why
## they read like a menu rather than a conversation. They now use exactly the
## same shape as the phone threads: a list of steps, each with replies that
## can "goto" any other step. So a chat runs three, four, five exchanges
## deep, remembers what you said two lines ago by virtue of where it sent
## you, and can end on completely different notes.
##
## Conversation shape:
##   id         unique string
##   speaker    who's talking (a named classmate, or Mr Halloway)
##   role       "student" | "teacher"
##   condition  when this conversation is allowed to come up (see _condition_met)
##   steps      [{them, replies:[{text, sanity, temptation, goto}]}]
##
## {NAME} is replaced with the player's name.
extends Node

# --- Named classmates ----------------------------------------------------------
# Students have names so conversations feel like people rather than a generic
# "student" prompt.
const STUDENT_NAMES := ["Mika", "Tane", "Priya", "Josh", "Ana", "Wiremu", "Chloe", "Sione"]
const TEACHER_NAME := "Mr Halloway"


static func random_student_name() -> String:
	return STUDENT_NAMES[randi() % STUDENT_NAMES.size()]


# =============================================================================
# WHEN A CONVERSATION IS ALLOWED TO COME UP
# =============================================================================
# The school reacts to the state you're actually in. Walk up to a classmate
# the day before an external and they talk about the external; walk up to one
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


## Substitutes {NAME} throughout a conversation.
static func personalise(convo: Dictionary, player_name: String) -> Dictionary:
	var out: Dictionary = convo.duplicate(true)
	for step in out.steps:
		step.them = str(step.them).replace("{NAME}", player_name)
		for reply in step.replies:
			reply.text = str(reply.text).replace("{NAME}", player_name)
	return out


func get_student_conversation(player_name: String) -> Dictionary:
	return personalise(_pick(_student_conversations), player_name)


func get_teacher_conversation(player_name: String) -> Dictionary:
	return personalise(_pick(_teacher_conversations), player_name)


## Where a reply sends you. Same rule as the phone threads.
func next_step_for(reply: Dictionary, current_step: int) -> int:
	return int(reply.get("goto", current_step + 1))


# =============================================================================
# CLASSMATES
# =============================================================================
var _student_conversations: Array = [

	{
		"id": "mika_chem", "speaker": "Mika", "role": "student", "condition": "early_year",
		"steps": [
			# 0
			{"them": "\"{NAME}. Serious question. Why did I take chemistry.\"",
			 "replies": [
				{"text": "\"You took it because Priya took it.\"", "sanity": 6.0, "goto": 1},
				{"text": "\"Because it looked good on a form?\"", "sanity": 5.0, "goto": 1},
				{"text": "\"Do you actually want an answer or a moan?\"", "sanity": 8.0, "goto": 2}]},
			# 1
			{"them": "\"...I hate that you know that. Yes. That is exactly why.\"",
			 "replies": [
				{"text": "\"You can still get the credits out of it.\"", "sanity": 9.0, "goto": 3},
				{"text": "\"One year. Then never again.\"", "sanity": 8.0, "goto": 3},
				{"text": "\"Drop it and pick something you'd turn up to.\"", "sanity": 4.0, "temptation": 3.0, "goto": 4}]},
			# 2
			{"them": "\"A moan. Obviously a moan. Nobody wants an answer at 8:40 in the morning.\"",
			 "replies": [
				{"text": "\"Go on then. I've got four minutes.\"", "sanity": 10.0, "goto": 5},
				{"text": "\"Fair. Moan away.\"", "sanity": 8.0, "goto": 5}]},
			# 3
			{"them": "\"Credits. Right. Not marks, credits. Everyone keeps saying that and it hasn't gone in yet.\"",
			 "replies": [
				{"text": "\"Fourteen a subject. That's the whole game.\"", "sanity": 10.0, "temptation": -3.0, "goto": 6},
				{"text": "\"It went in for me about a week ago. Horribly.\"", "sanity": 7.0, "goto": 6}]},
			# 4
			{"them": "\"It's September. I can't unlearn a year. That ship has not just sailed, it's sunk.\"",
			 "replies": [
				{"text": "\"Sorry. Bad advice. Finish it out.\"", "sanity": 7.0, "goto": 3},
				{"text": "\"Then we make chemistry survivable.\"", "sanity": 10.0, "goto": 6}]},
			# 5
			{"them": "\"It's fine. It's genuinely fine. I just wanted someone to hear me say that it's not fine.\"",
			 "replies": [
				{"text": "\"Heard. It's not fine.\"", "sanity": 13.0, "goto": 6},
				{"text": "\"That's the most Year 13 sentence ever said.\"", "sanity": 10.0, "goto": 6}]},
			# 6
			{"them": "\"Right. Enough. Thanks {NAME}. See you at the desks.\"",
			 "replies": [
				{"text": "\"See you.\"", "sanity": 6.0},
				{"text": "\"Sit next to me, I'll help with the mole stuff.\"", "sanity": 11.0, "temptation": -2.0}]},
		]},

	{
		"id": "priya_marks", "speaker": "Priya", "role": "student", "condition": "mid_year",
		"steps": [
			# 0
			{"them": "\"Can I show you something and you not react?\"",
			 "replies": [
				{"text": "\"Go on.\"", "sanity": 5.0, "goto": 1},
				{"text": "\"I make no promises about my face.\"", "sanity": 6.0, "goto": 1}]},
			# 1
			{"them": "\"Sixty-eight. On the stats internal.\" (She says it like a confession.)",
			 "replies": [
				{"text": "\"Priya, that's a good mark.\"", "sanity": 6.0, "goto": 2},
				{"text": "\"How do you feel about it?\"", "sanity": 9.0, "goto": 3},
				{"text": "\"...And? What's the problem?\"", "sanity": 3.0, "goto": 2}]},
			# 2
			{"them": "\"It isn't. Not for what I want. Everyone I'm up against gets high eighties.\"",
			 "replies": [
				{"text": "\"You're not up against anyone. That's not how offers work.\"", "sanity": 12.0, "goto": 4},
				{"text": "\"Who told you that? Genuinely, who?\"", "sanity": 10.0, "goto": 5},
				{"text": "\"Then get high eighties next time.\"", "sanity": 2.0, "temptation": 2.0, "goto": 6}]},
			# 3
			{"them": "\"Like I've failed. Which I know is insane, because sixty-eight is not failing.\"",
			 "replies": [
				{"text": "\"You're allowed to be disappointed AND fine.\"", "sanity": 14.0, "goto": 4},
				{"text": "\"Knowing that and feeling it are different things.\"", "sanity": 12.0, "goto": 4}]},
			# 4
			{"them": "(She lets out a breath.) \"Nobody's said that to me all year.\"",
			 "replies": [
				{"text": "\"Then everyone's been rubbish at this all year.\"", "sanity": 12.0, "goto": 7},
				{"text": "\"You say it to other people constantly, you know.\"", "sanity": 13.0, "goto": 7}]},
			# 5
			{"them": "\"...Me. It was me. I told me.\" (She almost laughs.)",
			 "replies": [
				{"text": "\"Then you can also untell yourself.\"", "sanity": 13.0, "goto": 7},
				{"text": "\"Brutal source. Very unreliable.\"", "sanity": 11.0, "goto": 7}]},
			# 6
			{"them": "\"Right. Great. Thanks.\" (That landed badly and you both know it.)",
			 "replies": [
				{"text": "\"Sorry. That was a rubbish thing to say.\"", "sanity": 6.0, "goto": 4},
				{"text": "\"I meant it helpfully. I said it badly.\"", "sanity": 7.0, "goto": 4}]},
			# 7
			{"them": "\"Okay. I'm putting the mark away and going to English. Thanks {NAME}.\"",
			 "replies": [
				{"text": "\"Any time. I mean it.\"", "sanity": 10.0},
				{"text": "\"Find me at lunch if it starts up again.\"", "sanity": 13.0}]},
		]},

	{
		"id": "ana_notices_you", "speaker": "Ana", "role": "student", "condition": "low_sanity",
		"steps": [
			# 0
			{"them": "\"{NAME}. Stop for a second. When did you last have a day off? An actual one.\"",
			 "replies": [
				{"text": "\"I genuinely can't remember.\"", "sanity": 8.0, "goto": 1},
				{"text": "\"Sunday. Sort of. I did an essay.\"", "sanity": 6.0, "goto": 2},
				{"text": "\"I'm fine, Ana.\"", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "\"Right. That's what I thought. Do you want advice, or do you want someone to just say that's a lot?\"",
			 "replies": [
				{"text": "\"The second one. Definitely the second one.\"", "sanity": 15.0, "goto": 4},
				{"text": "\"Advice. I'm past the point of feelings.\"", "sanity": 11.0, "goto": 5}]},
			# 2
			{"them": "\"An essay is not a day off. That is a day at work with a worse chair.\"",
			 "replies": [
				{"text": "\"...Okay, that's fair.\"", "sanity": 9.0, "goto": 1},
				{"text": "\"I don't have a spare day to give away.\"", "sanity": 6.0, "goto": 5}]},
			# 3
			{"them": "\"Okay.\" (She doesn't push. She doesn't leave either.)",
			 "replies": [
				{"text": "\"...I'm not fine.\"", "sanity": 12.0, "goto": 1},
				{"text": "\"Why are you still standing there?\"", "sanity": 5.0, "goto": 6},
				{"text": "\"Thanks for asking anyway.\"", "sanity": 7.0, "goto": 7}]},
			# 4
			{"them": "\"That's a lot. That's genuinely a lot and you're allowed to be flattened by it.\"",
			 "replies": [
				{"text": "\"Thank you. That's exactly it.\"", "sanity": 18.0, "goto": 7},
				{"text": "\"Nobody's said that yet.\"", "sanity": 16.0, "goto": 7}]},
			# 5
			{"them": "\"Pick one thing today. One. Do that, badly if you have to, and let the rest wait until tomorrow.\"",
			 "replies": [
				{"text": "\"One thing. Okay.\"", "sanity": 14.0, "goto": 7},
				{"text": "\"Everything's urgent though.\"", "sanity": 8.0, "goto": 8}]},
			# 6
			{"them": "\"Because you say fine in a very particular voice and I've heard it four times this week.\"",
			 "replies": [
				{"text": "\"...Okay. It's been bad.\"", "sanity": 13.0, "goto": 1},
				{"text": "\"That's annoying of you.\"", "sanity": 9.0, "goto": 7}]},
			# 7
			{"them": "\"Good. Go and sit down somewhere for ten minutes before class. That's the whole prescription.\"",
			 "replies": [
				{"text": "\"I'll do it.\"", "sanity": 12.0},
				{"text": "\"Ten minutes. Fine.\"", "sanity": 9.0}]},
			# 8
			{"them": "\"Nothing is urgent. Two things are urgent and the rest are wearing a costume.\"",
			 "replies": [
				{"text": "\"...That's a very good line.\"", "sanity": 13.0, "goto": 7},
				{"text": "\"Which two?\"", "sanity": 11.0, "goto": 7}]},
		]},

	{
		"id": "tane_shifts", "speaker": "Tane", "role": "student", "condition": "always",
		"steps": [
			# 0
			{"them": "\"I picked up two more shifts. And I'm behind on everything. Was that stupid?\"",
			 "replies": [
				{"text": "\"You needed the money. That's not stupid.\"", "sanity": 9.0, "goto": 1},
				{"text": "\"Yeah. A bit.\"", "sanity": 3.0, "goto": 2},
				{"text": "\"Depends. What are you behind on?\"", "sanity": 7.0, "goto": 3}]},
			# 1
			{"them": "\"Feels stupid at one in the morning with an internal due.\"",
			 "replies": [
				{"text": "\"Drop one shift. Just one.\"", "sanity": 10.0, "goto": 4},
				{"text": "\"Everyone's at one in the morning with an internal due.\"", "sanity": 8.0, "goto": 4}]},
			# 2
			{"them": "\"...Cheers. Really needed the honesty there, mate.\"",
			 "replies": [
				{"text": "\"Sorry. You asked.\"", "sanity": 4.0, "goto": 5},
				{"text": "\"I'd have done the exact same thing.\"", "sanity": 9.0, "goto": 1}]},
			# 3
			{"them": "\"All of it. Every subject. It's not even one bad thing, it's a slow leak.\"",
			 "replies": [
				{"text": "\"Then pick the leak that's costing the most credits.\"", "sanity": 11.0, "temptation": -3.0, "goto": 4},
				{"text": "\"A slow leak is fixable. Panic isn't.\"", "sanity": 10.0, "goto": 4}]},
			# 4
			{"them": "\"Yeah. Yeah okay. I'll ask Deb to take me off Wednesdays.\"",
			 "replies": [
				{"text": "\"Ask her today. Not next week.\"", "sanity": 11.0, "goto": 6},
				{"text": "\"She'll be fine about it, she's decent.\"", "sanity": 9.0, "goto": 6}]},
			# 5
			{"them": "\"Nah, you're right. I did ask.\" (He shrugs.) \"Doesn't make it nicer.\"",
			 "replies": [
				{"text": "\"No. Sorry.\"", "sanity": 6.0, "goto": 6},
				{"text": "\"Fix it with me at lunch?\"", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "\"Right. Class. See you at the desks, {NAME}.\"",
			 "replies": [
				{"text": "\"See you.\"", "sanity": 5.0},
				{"text": "\"Tell me how it goes with Deb.\"", "sanity": 8.0}]},
		]},

	{
		"id": "wiremu_exam_nerves", "speaker": "Wiremu", "role": "student", "condition": "exam_soon",
		"steps": [
			# 0
			{"them": "\"You ready for this one? Because I am absolutely not.\"",
			 "replies": [
				{"text": "\"Not even slightly.\"", "sanity": 8.0, "goto": 1},
				{"text": "\"Weirdly, yeah, I think I am.\"", "sanity": 6.0, "goto": 2},
				{"text": "\"What are you worried about specifically?\"", "sanity": 9.0, "goto": 3}]},
			# 1
			{"them": "\"Good. Honestly good. If you'd said yes I'd have had to walk off.\"",
			 "replies": [
				{"text": "\"We can be underprepared together.\"", "sanity": 11.0, "goto": 4},
				{"text": "\"Let's do twenty minutes now. Right now.\"", "sanity": 13.0, "temptation": -4.0, "goto": 5}]},
			# 2
			{"them": "\"Right. Cool. Cool cool cool.\" (He is not cool.)",
			 "replies": [
				{"text": "\"Sit with me, I'll go over the hard bit.\"", "sanity": 14.0, "temptation": -4.0, "goto": 5},
				{"text": "\"You'll be fine. You always say this.\"", "sanity": 7.0, "goto": 4}]},
			# 3
			{"them": "\"Going blank. Not knowing anything. Sitting there for three hours with nothing.\"",
			 "replies": [
				{"text": "\"That's never actually happened to you.\"", "sanity": 11.0, "goto": 4},
				{"text": "\"If it happens, you write what you do know and get partial credit.\"", "sanity": 13.0, "goto": 5},
				{"text": "\"Then that's what the derived grade is for.\"", "sanity": 10.0, "goto": 6}]},
			# 4
			{"them": "\"Ha. True. Alright. Misery, company, all that.\"",
			 "replies": [
				{"text": "\"See you in there.\"", "sanity": 8.0},
				{"text": "\"We've done more work than we think.\"", "sanity": 10.0}]},
			# 5
			{"them": "\"Right. Twenty minutes. Then I'm not thinking about it again until the day.\"",
			 "replies": [
				{"text": "\"Deal.\"", "sanity": 12.0, "temptation": -3.0},
				{"text": "\"That's a healthier plan than mine.\"", "sanity": 10.0}]},
			# 6
			{"them": "\"Wait, that's a real thing? You can just... apply?\"",
			 "replies": [
				{"text": "\"If something genuinely goes wrong, yes. Ask the office.\"", "sanity": 12.0, "goto": 4},
				{"text": "\"It's a safety net, not a plan.\"", "sanity": 10.0, "goto": 4}]},
		]},

	{
		"id": "sione_balance", "speaker": "Sione", "role": "student", "condition": "high_temptation",
		"steps": [
			# 0
			{"them": "\"You've been on that phone every time I've walked past you today.\"",
			 "replies": [
				{"text": "\"I know. I can't seem to stop.\"", "sanity": 7.0, "goto": 1},
				{"text": "\"It's the only break I get.\"", "sanity": 5.0, "goto": 2},
				{"text": "\"Bold from someone who lives in the gym.\"", "sanity": 6.0, "goto": 3}]},
			# 1
			{"them": "\"Yeah. It's not a break though, is it. You never come back from it feeling better.\"",
			 "replies": [
				{"text": "\"...No. I feel worse, usually.\"", "sanity": 11.0, "goto": 4},
				{"text": "\"So what do I do instead?\"", "sanity": 9.0, "goto": 4}]},
			# 2
			{"them": "\"Then make it a proper one. Twenty minutes outside beats two hours of scrolling, and I'll die on that hill.\"",
			 "replies": [
				{"text": "\"You might be right.\"", "sanity": 10.0, "goto": 4},
				{"text": "\"I don't have twenty minutes.\"", "sanity": 5.0, "goto": 5}]},
			# 3
			{"them": "\"Difference is I come out of the gym able to sit down and work. You come off that thing and do another hour of it.\"",
			 "replies": [
				{"text": "\"That's annoyingly accurate.\"", "sanity": 10.0, "goto": 4},
				{"text": "\"Alright, alright.\"", "sanity": 6.0, "goto": 4}]},
			# 4
			{"them": "\"Come to the gym after. Or don't — walk home the long way. Anything that isn't a screen.\"",
			 "replies": [
				{"text": "\"Yeah, alright. The long way.\"", "sanity": 13.0, "temptation": -8.0},
				{"text": "\"Gym. Fine. You've worn me down.\"", "sanity": 12.0, "temptation": -6.0}]},
			# 5
			{"them": "\"You had two hours yesterday. You spent them on a feed with nothing new on it.\"",
			 "replies": [
				{"text": "\"Okay, that's enough truth for one morning.\"", "sanity": 9.0, "goto": 4},
				{"text": "\"Point taken.\"", "sanity": 11.0, "temptation": -5.0, "goto": 4}]},
		]},

	{
		"id": "chloe_gossip", "speaker": "Chloe", "role": "student", "condition": "always",
		"steps": [
			# 0
			{"them": "\"Okay so apparently the physics external got moved forward two weeks.\"",
			 "replies": [
				{"text": "\"WHAT.\"", "sanity": 1.0, "goto": 1},
				{"text": "\"No it didn't. I checked this morning.\"", "sanity": 6.0, "goto": 2},
				{"text": "\"Chloe. Where did you hear that.\"", "sanity": 5.0, "goto": 3}]},
			# 1
			{"them": "\"...I'm joking. I'm so sorry. Your face.\"",
			 "replies": [
				{"text": "\"I aged five years.\"", "sanity": 7.0, "goto": 4},
				{"text": "\"Never speak to me again.\"", "sanity": 6.0, "goto": 4}]},
			# 2
			{"them": "\"Ugh. You're no fun. How did you know?\"",
			 "replies": [
				{"text": "\"Because I check it four times a day.\"", "sanity": 8.0, "goto": 4},
				{"text": "\"Because you do this every single term.\"", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "\"...Someone's cousin. Look, I'll be honest, the sourcing was weak.\"",
			 "replies": [
				{"text": "\"The sourcing was nonexistent.\"", "sanity": 8.0, "goto": 4},
				{"text": "\"Check the noticeboard before you start a panic.\"", "sanity": 7.0, "goto": 4}]},
			# 4
			{"them": "\"Fine. Real news then: half of year 13 haven't applied for their loan yet.\"",
			 "replies": [
				{"text": "\"...I might be in that half.\"", "sanity": 4.0, "goto": 5},
				{"text": "\"Mine's sorted.\"", "sanity": 8.0, "goto": 6},
				{"text": "\"That's not news, that's just Tuesday.\"", "sanity": 6.0, "goto": 6}]},
			# 5
			{"them": "\"Do it tonight. Laptop, StudyLink, IRD number, twenty minutes. That one's actually worth the panic.\"",
			 "replies": [
				{"text": "\"Okay. Tonight. Genuinely.\"", "sanity": 11.0},
				{"text": "\"Twenty minutes I can do.\"", "sanity": 9.0}]},
			# 6
			{"them": "\"Look at us. Functional adults. Terrifying.\"",
			 "replies": [
				{"text": "\"Give it a week.\"", "sanity": 8.0},
				{"text": "\"Don't jinx it.\"", "sanity": 7.0}]},
		]},

	{
		"id": "josh_credits", "speaker": "Josh", "role": "student", "condition": "short_credits",
		"steps": [
			# 0
			{"them": "\"Can I ask you something and you not tell anyone I asked?\"",
			 "replies": [
				{"text": "\"Go on.\"", "sanity": 5.0, "goto": 1},
				{"text": "\"Depends how bad it is.\"", "sanity": 4.0, "goto": 1}]},
			# 1
			{"them": "\"What's the actual difference between passing and getting UE? Because I've nodded along for two years.\"",
			 "replies": [
				{"text": "\"Passing is credits. UE is WHICH credits, and how many, in what.\"", "sanity": 11.0, "goto": 2},
				{"text": "\"Honestly? I only worked it out last month myself.\"", "sanity": 9.0, "goto": 3},
				{"text": "\"You should ask Halloway, not me.\"", "sanity": 4.0, "goto": 4}]},
			# 2
			{"them": "\"So I could pass everything and still not get in.\"",
			 "replies": [
				{"text": "\"Yes. That's exactly the trap.\"", "sanity": 10.0, "goto": 5},
				{"text": "\"Fourteen in three subjects, plus literacy and numeracy.\"", "sanity": 12.0, "goto": 5}]},
			# 3
			{"them": "\"Oh thank god. I thought I was the only one.\"",
			 "replies": [
				{"text": "\"Nobody explains it properly. It's not you.\"", "sanity": 12.0, "goto": 2},
				{"text": "\"Half the year is bluffing it, Josh.\"", "sanity": 10.0, "goto": 2}]},
			# 4
			{"them": "\"Yeah. I will.\" (He clearly won't.)",
			 "replies": [
				{"text": "\"...Come on. I'll explain it now.\"", "sanity": 11.0, "goto": 2},
				{"text": "\"Go today. He's actually alright about it.\"", "sanity": 8.0, "goto": 5}]},
			# 5
			{"them": "\"Right. I'm going to go and count mine. Cheers {NAME}. Genuinely.\"",
			 "replies": [
				{"text": "\"Come find me if the numbers look bad.\"", "sanity": 12.0},
				{"text": "\"Count them properly. Not optimistically.\"", "sanity": 9.0}]},
		]},

	{
		"id": "mika_after", "speaker": "Mika", "role": "student", "condition": "late_year",
		"steps": [
			# 0
			{"them": "\"Everyone keeps asking what I'm doing next year like I'm supposed to know.\"",
			 "replies": [
				{"text": "\"I know exactly what you mean.\"", "sanity": 11.0, "goto": 1},
				{"text": "\"I've got a rough plan, at least.\"", "sanity": 6.0, "goto": 2},
				{"text": "\"Just tell them anything. They stop asking.\"", "sanity": 8.0, "temptation": 3.0, "goto": 3}]},
			# 1
			{"them": "\"Right? It's exhausting. Like there's a form and everyone else got given it in year 11.\"",
			 "replies": [
				{"text": "\"There isn't a form. That's the actual secret.\"", "sanity": 13.0, "goto": 4},
				{"text": "\"Nobody's got the form. They're all guessing loudly.\"", "sanity": 12.0, "goto": 4}]},
			# 2
			{"them": "\"That's more than me. Go on then, teach me your ways.\"",
			 "replies": [
				{"text": "\"It's less a plan and more a direction.\"", "sanity": 9.0, "goto": 4},
				{"text": "\"Pick something you'd turn up to on a bad day.\"", "sanity": 12.0, "goto": 4}]},
			# 3
			{"them": "\"Ha. I might try that at the next family dinner and watch it go horribly wrong.\"",
			 "replies": [
				{"text": "\"Report back.\"", "sanity": 8.0, "goto": 4},
				{"text": "\"Or tell them the truth and watch that go worse.\"", "sanity": 9.0, "goto": 4}]},
			# 4
			{"them": "\"Okay. That helped more than the careers talk did. Which is bleak for the careers talk.\"",
			 "replies": [
				{"text": "\"The bar was on the floor.\"", "sanity": 9.0},
				{"text": "\"Any time, Mika.\"", "sanity": 11.0}]},
		]},

	{
		"id": "ana_burnout_warning", "speaker": "Ana", "role": "student", "condition": "very_low_sanity",
		"steps": [
			# 0
			{"them": "(She doesn't open with a question. She just stands next to you for a second.) \"...You're not okay, are you.\"",
			 "replies": [
				{"text": "\"No.\"", "sanity": 12.0, "goto": 1},
				{"text": "\"I'm managing.\"", "sanity": 5.0, "goto": 2},
				{"text": "\"I don't have time to not be okay.\"", "sanity": 8.0, "goto": 3}]},
			# 1
			{"them": "\"Okay. Thank you for saying that. Who else knows?\"",
			 "replies": [
				{"text": "\"Nobody.\"", "sanity": 10.0, "goto": 4},
				{"text": "\"Mum, sort of. Not properly.\"", "sanity": 11.0, "goto": 4}]},
			# 2
			{"them": "\"Managing isn't a state, it's a verb. You can't do it forever.\"",
			 "replies": [
				{"text": "\"...I know.\"", "sanity": 11.0, "goto": 1},
				{"text": "\"I only need to do it for a few more weeks.\"", "sanity": 7.0, "goto": 3}]},
			# 3
			{"them": "\"That's what people say right before they lose a month instead of a day.\"",
			 "replies": [
				{"text": "\"That's a horrible thing to be right about.\"", "sanity": 12.0, "goto": 4},
				{"text": "\"So what, I just stop?\"", "sanity": 9.0, "goto": 5}]},
			# 4
			{"them": "\"Then tell one more person. Not for advice. Just so it isn't only you carrying it.\"",
			 "replies": [
				{"text": "\"Okay. I'll talk to Mum properly.\"", "sanity": 20.0, "goto": 6},
				{"text": "\"I'll talk to Halloway.\"", "sanity": 18.0, "goto": 6},
				{"text": "\"I'll think about it.\"", "sanity": 10.0, "goto": 6}]},
			# 5
			{"them": "\"No. You rest, which is different, and you go back at it tomorrow with something in the tank.\"",
			 "replies": [
				{"text": "\"Rest isn't a break from the work. Got it.\"", "sanity": 16.0, "goto": 4},
				{"text": "\"That's the same thing dressed up.\"", "sanity": 8.0, "goto": 4}]},
			# 6
			{"them": "\"Good. Go home after school today. Not the library. Home.\"",
			 "replies": [
				{"text": "\"Home. Okay.\"", "sanity": 14.0},
				{"text": "\"You're very bossy for someone this nice.\"", "sanity": 12.0}]},
		]},

	{
		"id": "tane_ahead", "speaker": "Tane", "role": "student", "condition": "ahead",
		"steps": [
			# 0
			{"them": "\"Alright, show-off. How are you actually doing this?\"",
			 "replies": [
				{"text": "\"Sleeping. Genuinely, that's most of it.\"", "sanity": 8.0, "goto": 1},
				{"text": "\"I'm not. It just looks like it from outside.\"", "sanity": 9.0, "goto": 2},
				{"text": "\"Small amounts, constantly. Not big heroic sessions.\"", "sanity": 10.0, "goto": 1}]},
			# 1
			{"them": "\"That's so boring. I wanted a secret.\"",
			 "replies": [
				{"text": "\"That is the secret. It's boring on purpose.\"", "sanity": 11.0, "goto": 3},
				{"text": "\"Sorry to disappoint.\"", "sanity": 7.0, "goto": 3}]},
			# 2
			{"them": "\"...Huh. That's weirdly reassuring and also a bit worrying.\"",
			 "replies": [
				{"text": "\"Both, yeah.\"", "sanity": 9.0, "goto": 3},
				{"text": "\"Don't worry about me. Worry about your chem internal.\"", "sanity": 8.0, "goto": 3}]},
			# 3
			{"them": "\"Right. Teach me the boring thing. Properly.\"",
			 "replies": [
				{"text": "\"Half an hour a night. Same time. That's it.\"", "sanity": 12.0, "temptation": -4.0},
				{"text": "\"Sit with me after school and I'll show you.\"", "sanity": 14.0, "temptation": -4.0}]},
		]},

	{
		"id": "priya_loan_nag", "speaker": "Priya", "role": "student", "condition": "no_loan",
		"steps": [
			# 0
			{"them": "\"Random question. Have you done your StudyLink application?\"",
			 "replies": [
				{"text": "\"...No.\"", "goto": 1},
				{"text": "\"Why, is there a deadline?\"", "goto": 2},
				{"text": "\"I keep meaning to.\"", "sanity": 3.0, "goto": 1}]},
			# 1
			{"them": "\"Right. Do it tonight. I'm not being your mother, I'm being someone whose sister missed it.\"",
			 "replies": [
				{"text": "\"What happened to her?\"", "sanity": 5.0, "goto": 3},
				{"text": "\"Tonight. On the laptop. Promise.\"", "sanity": 10.0, "goto": 4}]},
			# 2
			{"them": "\"There's a cut-off, yes. And it takes about a week to come back, so the cut-off is really a week earlier than it says.\"",
			 "replies": [
				{"text": "\"Nobody mentioned that.\"", "sanity": 6.0, "goto": 1},
				{"text": "\"Okay, that's genuinely useful.\"", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "\"Got the offer. Couldn't pay the fees. Sat out a year working at the Warehouse.\"",
			 "replies": [
				{"text": "\"That's the worst possible version of it.\"", "sanity": 7.0, "goto": 4},
				{"text": "\"Right. I'm doing it tonight.\"", "sanity": 12.0, "goto": 4}]},
			# 4
			{"them": "\"Good. That's the one bit of admin this year that actually decides something.\"",
			 "replies": [
				{"text": "\"Thanks Priya.\"", "sanity": 10.0},
				{"text": "\"You should work in the careers office.\"", "sanity": 9.0}]},
		]},
]


# =============================================================================
# MR HALLOWAY
# =============================================================================
var _teacher_conversations: Array = [

	{
		"id": "halloway_uneven", "speaker": TEACHER_NAME, "role": "teacher", "condition": "mid_year",
		"steps": [
			# 0
			{"them": "\"{NAME}. A word — I've been looking at your internals.\"",
			 "replies": [
				{"text": "\"Is it bad?\"", "sanity": 4.0, "goto": 1},
				{"text": "\"I know I've been slipping.\"", "sanity": 8.0, "goto": 2},
				{"text": "\"They're fine, aren't they?\"", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "\"No. Uneven. You're strong where you're interested and thin where you're not, and an external paper doesn't care which is which.\"",
			 "replies": [
				{"text": "\"I know exactly which subject you mean.\"", "sanity": 9.0, "goto": 4},
				{"text": "\"So I should put the hours into the weak one.\"", "sanity": 11.0, "goto": 5}]},
			# 2
			{"them": "\"Owning it is most of the work, in my experience. The rest is a plan and someone to tell it to.\"",
			 "replies": [
				{"text": "\"Can that someone be you?\"", "sanity": 15.0, "goto": 5},
				{"text": "\"I'll sort a plan.\"", "sanity": 9.0, "goto": 5}]},
			# 3
			{"them": "\"They're passable. 'Fine' won't get you where you told me in February you wanted to go.\"",
			 "replies": [
				{"text": "\"That's a bit blunt.\"", "sanity": 5.0, "goto": 6},
				{"text": "\"...Fair. What do I fix first?\"", "sanity": 11.0, "goto": 5}]},
			# 4
			{"them": "\"Everyone does. That's rather the point of me raising it rather than telling you.\"",
			 "replies": [
				{"text": "\"So what do I actually do about it?\"", "sanity": 10.0, "goto": 5}]},
			# 5
			{"them": "\"Twenty minutes a day on the subject you like least. Not an hour, not a weekend — twenty minutes, every day, on the thing you're avoiding.\"",
			 "replies": [
				{"text": "\"That sounds almost too easy.\"", "sanity": 12.0, "temptation": -5.0, "goto": 7},
				{"text": "\"I'll start tonight.\"", "sanity": 14.0, "temptation": -6.0, "goto": 7}]},
			# 6
			{"them": "\"It is. I'd rather be blunt in September than sympathetic in December.\"",
			 "replies": [
				{"text": "\"...Okay. What do I fix first?\"", "sanity": 10.0, "goto": 5},
				{"text": "\"I'd rather you were sympathetic now.\"", "sanity": 6.0, "goto": 5}]},
			# 7
			{"them": "\"It is easy. That's why almost nobody does it. Off you go.\"",
			 "replies": [
				{"text": "\"Thanks, sir.\"", "sanity": 9.0},
				{"text": "\"Twenty minutes. Every day.\"", "sanity": 11.0, "temptation": -3.0}]},
		]},

	{
		"id": "halloway_credits", "speaker": TEACHER_NAME, "role": "teacher", "condition": "short_credits",
		"steps": [
			# 0
			{"them": "\"Do you know how many Level 3 credits you're carrying right now? Not roughly. Exactly.\"",
			 "replies": [
				{"text": "\"...No.\"", "goto": 1},
				{"text": "\"Roughly, yes.\"", "sanity": 3.0, "goto": 2},
				{"text": "\"Should I?\"", "goto": 1}]},
			# 1
			{"them": "\"Then that's tonight's homework, and I mean it more than any of the actual homework I've set you.\"",
			 "replies": [
				{"text": "\"Why does it matter that much?\"", "sanity": 5.0, "goto": 3},
				{"text": "\"I'll count them tonight.\"", "sanity": 9.0, "goto": 3}]},
			# 2
			{"them": "\"Roughly is how people end up two credits short in February with nothing left to sit.\"",
			 "replies": [
				{"text": "\"That's genuinely terrifying.\"", "sanity": 6.0, "goto": 3},
				{"text": "\"Right. Exact numbers. Tonight.\"", "sanity": 10.0, "goto": 3}]},
			# 3
			{"them": "\"Because University Entrance is a checklist, not an impression. Fourteen credits in each of three approved subjects, ten literacy, ten numeracy. Miss one line and the rest doesn't matter.\"",
			 "replies": [
				{"text": "\"Even with good marks?\"", "sanity": 6.0, "goto": 4},
				{"text": "\"Where do I check mine?\"", "sanity": 9.0, "goto": 5}]},
			# 4
			{"them": "\"Especially with good marks. Every year I lose someone bright who assumed the marks would carry it.\"",
			 "replies": [
				{"text": "\"That's not going to be me.\"", "sanity": 13.0, "temptation": -5.0, "goto": 6},
				{"text": "\"Where do I check mine?\"", "sanity": 9.0, "goto": 5}]},
			# 5
			{"them": "\"Your NZQA login, or the journal you're clearly keeping. Either. Just look at the actual numbers.\"",
			 "replies": [
				{"text": "\"I'll look tonight.\"", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "\"Good. Come and tell me the numbers tomorrow, whatever they are. Especially if they're bad.\"",
			 "replies": [
				{"text": "\"I will.\"", "sanity": 12.0},
				{"text": "\"Even if they're bad?\"", "sanity": 10.0}]},
		]},

	{
		"id": "halloway_burnout", "speaker": TEACHER_NAME, "role": "teacher", "condition": "low_sanity",
		"steps": [
			# 0
			{"them": "\"I'll be blunt: the students who burn out are almost never the lazy ones. They're the ones who never stop.\"",
			 "replies": [
				{"text": "\"That's a bit close to home.\"", "sanity": 12.0, "goto": 1},
				{"text": "\"I've got a decent balance.\"", "sanity": 7.0, "goto": 2},
				{"text": "\"Stopping feels like falling behind.\"", "sanity": 10.0, "goto": 3}]},
			# 1
			{"them": "\"I thought it might be. Take a real evening off this week. Not a guilty one — a real one.\"",
			 "replies": [
				{"text": "\"Is that an instruction?\"", "sanity": 12.0, "goto": 4},
				{"text": "\"I wouldn't know what to do with it.\"", "sanity": 10.0, "goto": 5}]},
			# 2
			{"them": "\"Then you're ahead of most of this cohort.\" (He does not sound convinced.)",
			 "replies": [
				{"text": "\"...Okay, I don't.\"", "sanity": 13.0, "goto": 1},
				{"text": "\"You don't believe me.\"", "sanity": 9.0, "goto": 6}]},
			# 3
			{"them": "\"I know it does. It isn't. Rest is part of the work — it's not time off from it.\"",
			 "replies": [
				{"text": "\"Nobody's ever put it like that.\"", "sanity": 16.0, "goto": 4},
				{"text": "\"That sounds like something you'd say to a class.\"", "sanity": 8.0, "goto": 6}]},
			# 4
			{"them": "\"Yes. Consider it set homework. I'll be checking, in my own irritating way.\"",
			 "replies": [
				{"text": "\"Understood, sir.\"", "sanity": 14.0},
				{"text": "\"You are quite irritating.\"", "sanity": 12.0}]},
			# 5
			{"them": "\"Then that's your evening's task: work out what you'd do with an evening. That's it. That's the whole assignment.\"",
			 "replies": [
				{"text": "\"That's harder than the actual homework.\"", "sanity": 14.0},
				{"text": "\"I'll give it a go.\"", "sanity": 12.0}]},
			# 6
			{"them": "\"It is. I say it to a class every year and about two of them hear it. Be one of the two.\"",
			 "replies": [
				{"text": "\"...Alright.\"", "sanity": 13.0, "goto": 4},
				{"text": "\"No pressure then.\"", "sanity": 10.0, "goto": 4}]},
		]},

	{
		"id": "halloway_derived", "speaker": TEACHER_NAME, "role": "teacher", "condition": "exam_soon",
		"steps": [
			# 0
			{"them": "\"Before the externals — do you know what a derived grade is, and how you'd get one?\"",
			 "replies": [
				{"text": "\"Vaguely. Not really.\"", "goto": 1},
				{"text": "\"If I'm sick on the day, right?\"", "sanity": 4.0, "goto": 2},
				{"text": "\"I'd rather just sit the paper.\"", "sanity": 6.0, "goto": 3}]},
			# 1
			{"them": "\"If something genuinely goes wrong — illness, a family emergency — NZQA can award a grade based on the evidence you've already produced this year.\"",
			 "replies": [
				{"text": "\"So my internals become the evidence.\"", "sanity": 9.0, "goto": 4},
				{"text": "\"How do I apply?\"", "sanity": 8.0, "goto": 5}]},
			# 2
			{"them": "\"Sick, or something serious enough to affect the paper. It isn't a get-out for a bad night's sleep, and you have to apply — it isn't automatic.\"",
			 "replies": [
				{"text": "\"Apply where?\"", "sanity": 8.0, "goto": 5},
				{"text": "\"Good to know it exists at all.\"", "sanity": 9.0, "goto": 4}]},
			# 3
			{"them": "\"Good attitude. Just don't be a martyr about it if you're genuinely unwell — a derived grade beats a bad paper written with a temperature.\"",
			 "replies": [
				{"text": "\"Noted.\"", "sanity": 8.0, "goto": 4},
				{"text": "\"How would I even apply?\"", "sanity": 8.0, "goto": 5}]},
			# 4
			{"them": "\"Exactly. Which is another reason your internals matter more than people think — they're your insurance policy.\"",
			 "replies": [
				{"text": "\"That's a good way to frame it.\"", "sanity": 11.0, "goto": 6},
				{"text": "\"I'll stop treating them as practice.\"", "sanity": 13.0, "temptation": -4.0, "goto": 6}]},
			# 5
			{"them": "\"The office, with evidence, and BEFORE the exam period if you can. Not three weeks after, which is when most people try.\"",
			 "replies": [
				{"text": "\"Before, not after. Got it.\"", "sanity": 11.0, "goto": 6}]},
			# 6
			{"them": "\"Right. Go and be quietly competent about it. That's all any of this is.\"",
			 "replies": [
				{"text": "\"Quietly competent. I'll try.\"", "sanity": 10.0},
				{"text": "\"Thanks, sir.\"", "sanity": 9.0}]},
		]},

	{
		"id": "halloway_hours", "speaker": TEACHER_NAME, "role": "teacher", "condition": "always",
		"steps": [
			# 0
			{"them": "\"You know the ones who do best aren't usually the ones who put in the most hours?\"",
			 "replies": [
				{"text": "\"That's reassuring, actually.\"", "sanity": 9.0, "goto": 1},
				{"text": "\"Easier said than done, though.\"", "sanity": 7.0, "goto": 2},
				{"text": "\"I'll believe that when I see the marks.\"", "sanity": 5.0, "goto": 3}]},
			# 1
			{"them": "\"It should be. It's also a trap, if you take it as permission to do nothing.\"",
			 "replies": [
				{"text": "\"So what's the difference?\"", "sanity": 9.0, "goto": 4}]},
			# 2
			{"them": "\"Everything worth doing is. Doesn't make it wrong.\"",
			 "replies": [
				{"text": "\"So what's the actual difference?\"", "sanity": 9.0, "goto": 4},
				{"text": "\"Fine. What should I be doing instead?\"", "sanity": 10.0, "goto": 4}]},
			# 3
			{"them": "\"Fair enough. Come back in December and tell me I was wrong. I'd genuinely enjoy that conversation.\"",
			 "replies": [
				{"text": "\"...Alright, go on then. What's the difference?\"", "sanity": 9.0, "goto": 4},
				{"text": "\"I'll hold you to that.\"", "sanity": 8.0, "goto": 5}]},
			# 4
			{"them": "\"Attention. Four focused half-hours beat one exhausted four-hour sitting, every time. Your brain files it while you sleep, not while you stare.\"",
			 "replies": [
				{"text": "\"So the sleep is part of the studying.\"", "sanity": 13.0, "goto": 5},
				{"text": "\"I've been doing the four-hour thing.\"", "sanity": 10.0, "goto": 5}]},
			# 5
			{"them": "\"Now go on. You've got a desk with your name on it and I've got a stack of marking with everyone else's.\"",
			 "replies": [
				{"text": "\"Cheers, sir.\"", "sanity": 8.0},
				{"text": "\"Good luck with the stack.\"", "sanity": 9.0}]},
		]},

	{
		"id": "halloway_behind", "speaker": TEACHER_NAME, "role": "teacher", "condition": "behind",
		"steps": [
			# 0
			{"them": "\"I'm going to say something you won't enjoy, and then I'm going to help. In that order.\"",
			 "replies": [
				{"text": "\"...Go on.\"", "sanity": 4.0, "goto": 1},
				{"text": "\"Can we do the helping first?\"", "sanity": 6.0, "goto": 2}]},
			# 1
			{"them": "\"On your current average you don't get the offer you're aiming for. Not close-but-no — genuinely short.\"",
			 "replies": [
				{"text": "\"I know.\"", "sanity": 6.0, "goto": 3},
				{"text": "\"There's still time though.\"", "sanity": 8.0, "goto": 4},
				{"text": "\"Then what's the point.\"", "sanity": 2.0, "goto": 5}]},
			# 2
			{"them": "\"No. The helping only works if you've heard the other bit.\"",
			 "replies": [
				{"text": "\"Fine. Say it.\"", "sanity": 5.0, "goto": 1}]},
			# 3
			{"them": "\"Good. Then we're not wasting time on denial, which is where most of these conversations go.\"",
			 "replies": [
				{"text": "\"So what do I actually change?\"", "sanity": 10.0, "goto": 6}]},
			# 4
			{"them": "\"There is. That's the entire reason I'm telling you in September rather than filing it and saying nothing.\"",
			 "replies": [
				{"text": "\"So what do I change?\"", "sanity": 11.0, "goto": 6}]},
			# 5
			{"them": "\"The point is that second-choice programmes and foundation years are real, they're not failure, and people who plan for them do fine. But you plan for them NOW, not in December.\"",
			 "replies": [
				{"text": "\"That's oddly comforting.\"", "sanity": 13.0, "goto": 6},
				{"text": "\"I don't want a second choice.\"", "sanity": 9.0, "goto": 6}]},
			# 6
			{"them": "\"One subject. The weakest one. Everything into that for a fortnight — grades move in blocks, not smoothly, and one subject climbing pulls the whole average up.\"",
			 "replies": [
				{"text": "\"Two weeks, one subject. I can do that.\"", "sanity": 15.0, "temptation": -6.0},
				{"text": "\"And if it doesn't work?\"", "sanity": 10.0}]},
		]},

	{
		"id": "halloway_loan", "speaker": TEACHER_NAME, "role": "teacher", "condition": "no_loan",
		"steps": [
			# 0
			{"them": "\"Non-academic question, and possibly the most important one I'll ask you all year. Have you applied to StudyLink?\"",
			 "replies": [
				{"text": "\"Not yet.\"", "goto": 1},
				{"text": "\"Is that really the most important one?\"", "sanity": 4.0, "goto": 2},
				{"text": "\"I don't think I'll need a loan.\"", "sanity": 3.0, "goto": 3}]},
			# 1
			{"them": "\"Then that's tonight. It takes twenty minutes and about a week to come back, and it decides whether an offer is a real offer or a piece of paper.\"",
			 "replies": [
				{"text": "\"Tonight. On the laptop.\"", "sanity": 12.0, "goto": 4},
				{"text": "\"What do I need for it?\"", "sanity": 9.0, "goto": 5}]},
			# 2
			{"them": "\"Every year I watch a student earn a place and not take it up because the fees weren't there. That's a worse outcome than a bad exam and it's entirely preventable.\"",
			 "replies": [
				{"text": "\"...Right. Point taken.\"", "sanity": 9.0, "goto": 1},
				{"text": "\"That's grim.\"", "sanity": 6.0, "goto": 1}]},
			# 3
			{"them": "\"Apply anyway. An approved loan you don't draw on costs you nothing. A loan you didn't apply for costs you a year.\"",
			 "replies": [
				{"text": "\"That's a very good argument.\"", "sanity": 11.0, "goto": 4},
				{"text": "\"Fine. I'll apply.\"", "sanity": 10.0, "goto": 4}]},
			# 4
			{"them": "\"Good. Tell me when it's submitted and I'll stop asking.\"",
			 "replies": [
				{"text": "\"You won't stop asking.\"", "sanity": 10.0},
				{"text": "\"I'll tell you tomorrow.\"", "sanity": 11.0}]},
			# 5
			{"them": "\"Your IRD number and about twenty minutes of patience with a government website. That's genuinely it.\"",
			 "replies": [
				{"text": "\"I don't know my IRD number.\"", "sanity": 8.0, "goto": 6},
				{"text": "\"I can manage twenty minutes.\"", "sanity": 11.0, "goto": 7},
				{"text": "\"The patience is the hard part.\"", "sanity": 10.0, "goto": 7}]},
			# 6
			{"them": "\"Nobody does off the top of their head. It's in your banking app under your profile, it's on any payslip, and the StudyLink form will look it up for you if you ask it nicely.\"",
			 "replies": [
				{"text": "\"Oh. That's easy then.\"", "sanity": 10.0, "goto": 7},
				{"text": "\"Why does nobody say that part out loud?\"", "sanity": 9.0, "goto": 7}]},
			# 7
			{"them": "\"And apply for the Allowance while you're in there. Different thing entirely — you don't pay that one back.\"",
			 "replies": [
				{"text": "\"What's the catch?\"", "sanity": 9.0, "goto": 8},
				{"text": "\"I'll do both.\"", "sanity": 12.0, "goto": 4}]},
			# 8
			{"them": "\"It's means-tested on your parents' income, so plenty of people are turned down. Costs you nothing to be turned down, though, and it's real money if you're not.\"",
			 "replies": [
				{"text": "\"Right. Both of them. Tonight.\"", "sanity": 13.0, "goto": 4},
				{"text": "\"Worth a shot then.\"", "sanity": 10.0, "goto": 4}]},
		]},
]


# --- Extra-credit flavour lines -------------------------------------------------

var _teacher_lines_intro: Array = [
	"\"Keen for some extra credit? Answer this one properly and I'll put it toward your internal.\"",
	"\"Here's a tougher one. Good chance to prove the last mark was a fluke — in either direction.\"",
	"\"Let's see if you've actually been listening or just nodding at the right moments.\"",
	"\"One question. Worth more than it looks. No pressure.\"",
]

var _teacher_lines_correct: Array = [
	"\"Nicely done. That's exactly the kind of thinking the marker wants to see.\"",
	"\"Good. Keep that up and December looks a lot less frightening.\"",
	"\"Correct, and quickly. Do that under exam conditions and you're fine.\"",
]

var _teacher_lines_incorrect: Array = [
	"\"Not quite — but don't stress, that's the mistake nearly everyone makes.\"",
	"\"Close. Worth going back over that topic before it turns up in an external.\"",
	"\"No. Good instinct, wrong step. Come and see me about it.\"",
]


func get_teacher_intro_line() -> String:
	return _teacher_lines_intro[randi() % _teacher_lines_intro.size()]


func get_teacher_result_line(is_correct: bool) -> String:
	var pool: Array = _teacher_lines_correct if is_correct else _teacher_lines_incorrect
	return pool[randi() % pool.size()]
