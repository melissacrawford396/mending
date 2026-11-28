# High-level plan

Working document. Decisions are marked **Decided**, **Proposed**, or **Open**.

This sits next to [readme.md](readme.md). The readme is the problem. This file is what to build first.

## Product bet

The app is called **Mending**.

A Flutter app. You tap a body area, see the movements for that area, and star the ones you are working on. Each starred movement has a cooldown. After you do it, a countdown runs until it is ready again, like a spell.

**Decided:** Flutter. Android first. The same project can build for iPhone later. The project is [flutter/](flutter/).

The library covers the whole body. New movements are added the same way as the first.

## Body map

Reference: [assets/body-map.jpg](assets/body-map.jpg). The picture is the style and the area split. The figure to build is the jointed cartoon in [planning-unity.md](planning-unity.md). Joints come first. Hover comes after they move.

A cartoon figure made of flat colors and thick outlines. Front and back. No realistic people. The back figure only colors the regions that are unique to the back: upper back and lower back. The rest of that outline stays blank.

The file uses color so the split is easy to read. In the app every shape starts white and turns blue on hover. Paired sides share one area, so both arms, both wrists, both hands, both ankles, and both feet highlight together.

Hover fills a panel on the right with that area's movements, starred first. The list is greyed out and does not take clicks yet. Click selects the area: the figure shrinks to a faded outline, the selected area stays blue, and the panel becomes clickable. Click the area again, or close the panel, to go back. On a narrow screen the panel opens under the figure. A finger press uses the same blue state, then the tap selects.

`BodyArea` is a fixed enum.

On the figure:

- head
- neck
- shoulders
- chest (front)
- upperBack (back)
- arms
- wrists (front)
- hands (front)
- core (front)
- lowerBack (back)
- hips
- thighs
- knees
- calves
- ankles (front)
- feet (front)

Not drawn as anatomy. Shown as their own controls under the figure:

- wholeBody
- other

## Data types

Five separate types. The catalog, your list, the pictures, the completion log, and the review log do not share one object.

### Movement type

The shared setup for a movement.

The records live in [flutter/assets/catalog/movements.json](flutter/assets/catalog/movements.json).

| Field | Meaning |
| --- | --- |
| Id | Identity, like `toe-flex`. Visuals, your list, the log, and reviews join on this. Never changes |
| Name | Display text. Can change without touching saved rows |
| Area | One `BodyArea` |
| Default sets | Suggested sets |
| Default reps | Suggested reps |
| Default cooldown | Every N days, 1 to 7. 1 = every day, 2 = every 2 days |
| Default per day | Times allowed in one day, 1 to 3. Above 1, cooldown is every day |
| Default rest seconds | Rest between sets in a guided session. 0 skips the rest screen |
| Description | How to do the movement |
| Steps | Optional list of moves, each with a name and a cue. A session set is the next step. Empty means every set is this movement |
| Both sides | When true, the session walks Steps on the left, then the same list on the right. Default sets is that full walk |

Changing a default does not rewrite your overrides or past log rows.

### Visuals

Keyed by the movement type id. Holds how that movement is drawn. Swapping the picture replaces this object only. The records live in [flutter/assets/catalog/visuals.json](flutter/assets/catalog/visuals.json).

| Field | Meaning |
| --- | --- |
| Movement id | Key. The movement type id |
| Representation | The clip. The movement page has a player: play, pause, and a seek bar. It loops and has no sound |
| Thumbnail | A still from the clip. Shown in lists so you can see what you are picking |

A movement with no clip shows a placeholder. Each body area also has an outline icon in [body-icons/](body-icons/). The Working tab shows that icon, and the movement page shows it in the title bar.

### My exercises

Your list. Each row points at one movement type. Sets, reps, cooldown, per day, gap hours, and rest can be overridden here. An override is stored on this row and leaves the movement type as it is.

This is a reference plus optional overrides. A factory creates it: `MyExercise.from(movementType)` links the id and leaves the overrides empty, so the numbers still come from the movement type. Setting your own sets, reps, or cooldown fills that field on your row. An empty override keeps using the current default.

| Field | Meaning |
| --- | --- |
| User | |
| Movement id | Points at the movement type |
| Sets override | Empty means use the default |
| Reps override | Empty means use the default |
| Cooldown override | Empty means use the default |
| Per day override | Empty means use the default |
| Gap hours override | Empty means use the default |
| Rest override | Seconds. Empty means use the default |
| Starred | Whether you are working on it |

Effective sets are the override when it is set, otherwise the movement type default. The other fields resolve the same way. Sets are capped at 10 and reps at 50. A movement with steps is capped at the length of its walk instead.

Every day and every N days wait a gap measured from the last completion. Every day is 18 hours. Every N days is (N − 1) × 24 hours plus 18, so every 2 days is 42 hours and every 7 days is 162 hours. There is no 4 AM reset on these.

Two and three times a day still use a day, and a day runs from 4 AM to 4 AM local time. Under the day's limit, the exercise is ready after the gap, or at the next 4 AM if that comes first. At the limit, it waits for the next 4 AM. The gap defaults to 8 hours at 2x a day and 4 hours at 3x a day.

You can change any gap by an hour at a time, down to 1 hour. Same-day gaps stop at 12 hours. Every N days can go 12 hours past its default. Changing the frequency resets the gap to that frequency's default.

No log row means ready. On the movement page, one Cooldown stepper runs from 3x a day to every 7 days.

**Start exercise** walks through the sets. A movement with steps titles each set with the step name and that step's cue. When both sides is set, the first half of the sets is the left side and the second half is the right. Fewer sets stops partway through that walk. A clock on the set counts up while you work. Each set starts at its prescribed reps, and the count can change before Done. A timed movement, such as Ankle stretch, uses a hold in seconds instead, stepping by 5 from 5 seconds to 5 minutes, starting at 30 seconds. Done at 0 ends the session with the sets already finished. Otherwise it records that count and, unless it was the last set, rests. The rest ring shrinks smoothly. A quieter count-up under it keeps running, and the page stays put when the countdown hits zero. Add 30s extends the rest. Skip rest, or Next set once the countdown is done, moves on. After the last set, or Save and finish from the back arrow, it logs one completion and shows a short celebration. The celebration stays until Back to list. Then, on the Working list, the row greys out where it was, a "Move to waiting" note hovers there, and the row moves to the bottom of Waiting. The celebration shows one rep count when every set matches, and the list when they differ. A timed movement shows seconds. End from the back arrow logs nothing. **Mark done** logs in one tap and plays the same celebration.

You work from the starred rows. Each one shows its countdown. The ones whose cooldown has finished are ready.

### Logging

Append-only fact rows in a columnar store, so later analysis can scan them. One row each time you finish an exercise. Rows are added, not edited. User and movement id are both columns.

| Column | Meaning |
| --- | --- |
| User | |
| Movement id | Movement type id |
| Completed at | Datetime you finished it |
| Sets | Sets you did |
| Reps | Kept for older rows |
| Set reps | Reps in each finished set. An older row without this repeats Reps once per set |

A review of these rows, grouped by area, shows which parts you actually practice and which you skip. Whole-body and other are included. Area comes from the movement type.

### Review

Optional. When you come back to exercise, the app can ask whether a body part hurts from last time, and which exercise you think did it. Skipping the prompt writes nothing.

The app presents the exercises from the last time you exercised. A saved answer is keyed by movement id and the datetime you are answering now. It also stores the datetime of that earlier completion, so the answer stays tied to the session being reviewed.

Append-only columnar rows, same as the log.

| Column | Meaning |
| --- | --- |
| User | |
| Movement id | The exercise you think is involved |
| Area | The body part you are answering about |
| Reviewed at | Datetime you are in the app now. Part of the key |
| Exercised at | Datetime of the completion being reviewed |
| Sensation | How it feels |

`Sensation`:

- muscleSoreness
- hurt
- stingingPain
- fine
- tight
- tingling

More can be added to this enum later. Old rows keep the value they were saved with.

## Later

Parked on purpose.

**Exercise pictures.** The Unity project starts with the jointed cartoon figure. Clips come after it can hold a pose. Hover on that same figure is the body map. See [planning-unity.md](planning-unity.md).

**Session notes.** The review row above is the start. Richer follow-up, and warnings based on it, stay later.

**Overlap.** Other workouts changing a cooldown.

**iPhone.** After the Android app is in use.

**Anyone else.** Accounts and a shared catalog.

## Open

None. Sets, reps, and cooldowns in [movements.json](flutter/assets/catalog/movements.json) are decided.
