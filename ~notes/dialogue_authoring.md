Dialogue Manager Authoring Command Reference

This is a simplified reference for the dialogue commands and authoring syntax currently used in this project.

==================================================
1. using
==================================================

Adds a state so its functions can be used in the dialogue file.

Example:
using DM
using QuestManager
using Inventory
using Interact
using CutsceneManager
using SceneManager

Notes:
DM should be included in this project.
Functions from these states can then be used in conditions and [do ...] calls.

==================================================
2. Title headers
==================================================

Defines a dialogue entry point.

Syntax:
~ title_name

Example:
~ start
~ npc1
~ shop_intro

Notes:
Dialogue usually begins at a title such as start.

==================================================
3. Spoken line
==================================================

Makes a speaker say a line.

Syntax:
speaker_id: dialogue text

Example:
npc_test_01: Hello stranger.
PLAYER: I should look around first.

Notes:
PLAYER is a special speaker id in this project.
Speaker ids can map to SpeakerResource entries.

==================================================
4. End or jump
==================================================

Ends the dialogue or jumps to another title.

Syntax:
=> END
=> title_name

Examples:
npc_test_01: Goodbye. => END
npc_test_01: Go talk to the guard. => guard_intro

==================================================
5. Mood tag
==================================================

Sets the portrait mood for the current line.

Syntax:
[#mood=mood_name]

Example:
npc_test_01: [#mood=angry] You need to talk to the other NPC.

Supported moods in DM:
normal
happy
angry
sad
surprise
special
tired

==================================================
6. Inline name insertion
==================================================

Inserts the display name of a speaker into dialogue text.

Syntax:
{{sname("speaker_id")}}

Examples:
NARRATOR: {{sname("PLAYER")}} looked tired.
NARRATOR: {{sname("healer04")}} stepped forward.

Notes:
Use function syntax exactly.

7. Inline pronoun insertion
==================================================

Inserts a pronoun form for a speaker into dialogue text.

Syntax:
{{pn("speaker_id", n)}}

Pronoun type reference:

| Value | Pronoun type          | HE      | SHE     | THEY       | IT     |
|-------|-----------------------|---------|----------|------------|--------|
| 1     | subject               | he      | she      | they       | it     |
| 2     | object                | him     | her      | them       | it     |
| 3     | possessive determiner | his     | her      | their      | its    |
| 4     | possessive pronoun    | his     | hers     | theirs     | its    |
| 5     | reflexive             | himself | herself  | themselves | itself |
Usage examples by type:

Type 1, subject
NARRATOR: {{name("healer04")}} said {{pn("healer04", 1)}} was ready.

Type 2, object
NARRATOR: I handed the satchel back to {{pn("healer04", 2)}}.

Type 3, possessive determiner
NARRATOR: That is {{pn("healer04", 3)}} staff.

Type 4, possessive pronoun
NARRATOR: That staff is {{pn("healer04", 4)}}.

Type 5, reflexive
NARRATOR: {{pn("healer04", 1)}} kept it for {{pn("healer04", 5)}}.

Notes:
Use function syntax exactly.
Do not use {{pn=speaker_id, 1}}.
Use type 3 when a noun comes after the pronoun.
Use type 4 when the pronoun stands alone.


==================================================
8. Conditions
==================================================

Branches dialogue based on logic.

Syntax:
if condition
elif condition

Example:
if quest_is_completed("quest0001") == false
	npc_test_01: You still have work to do. => END
elif quest_is_completed("quest0001") == true
	npc_test_01: Good work. => END

Notes:
The needed state must be declared with using.
Indent branch contents beneath the condition.

==================================================
9. do calls
==================================================

Calls a function during dialogue.

Syntax:
[do function_call()]
do function_call()

Inline example:
npc_test_01: You came back.[do advance_actions_taken("quest0001", 2)] => END

Standalone example:
npc_test_01: I gave you a quest.
do play_cutscene("CutsceneScript03")
=> END

Project examples:
[do add_item("testhpheal", 20)]
[do item_here_off()]
[do play_parent_animation("open")]
[do advance_actions_taken("quest0001", 0)]
[do play_cutscene("CutsceneScript03")]

==================================================
10. Choices
==================================================

Creates player dialogue choices.

Syntax:
- Choice text

Example:
- Yes
	npc_test_01: Good. => END
- No
	npc_test_01: Come back later. => END
- Start again => start
- End => END

Notes:
Indent the branch content under the choice.

==================================================
11. Random inline text
==================================================

Picks one option randomly.

Syntax:
[[Option A|Option B|Option C]]

Example:
Warrior: [#mood=happy] [[Hi|Hello|Howdy]], this is some dialogue.

==================================================
12. Wait tag
==================================================

Adds a pause in the line.

Syntax:
[wait=seconds]

Example:
npc_test_01: Here are some choices. [wait=0.5] Make your choice.

==================================================
13. Voice tag
==================================================

Assigns a voice audio file to the line.

Syntax:
[#voice=res://path/to/file.ogg]

Example:
npc_test_01: [#voice=res://audio/voice/test.ogg] Listen carefully.

==================================================
14. Minimal example
==================================================

using DM

~ start
npc_test_01: [#mood=normal] Hello, {{name("PLAYER")}}.
npc_test_01: Are you ready?
- Yes
	npc_test_01: Good. {{pn("PLAYER", 1)}} looks prepared.
	=> END
- No
	npc_test_01: Come back later.
	=> END
