# High-level plan

Working document. Decisions are marked **Decided**, **Proposed**, or **Open**.

This sits next to [readme.md](readme.md). The readme is the problem. This file is what to build first.

## Product bet

A Flutter app. You tap a body area, see the movements for that area, and star the ones you are working on. Each starred movement has a cooldown. After you do it, a countdown runs until it is ready again, like a spell.

**Decided:** Flutter. Android first. The same project can build for iPhone later.

The library covers the whole body. New movements are added the same way as the first.

## Body map

Reference: [assets/body-map.jpg](assets/body-map.jpg).

A cartoon figure made of flat colors and thick outlines. Front and back. No realistic people. The back figure only colors the regions that are unique to the back: upper back and lower back. The rest of that outline stays blank.

The file uses color so the split is easy to read. In the app every shape starts white and turns blue on hover. Paired sides share one area, so both arms, both wrists, both hands, both ankles, and both feet highlight together. Click opens the movements for that area. A finger press uses the same blue state, then the tap opens the list.

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

| Field | Meaning |
| --- | --- |
| Name | Identity. Visuals, your list, the log, and reviews join on this |
| Area | One `BodyArea` |
| Default sets | Suggested sets |
| Default reps | Suggested reps |
| Default cooldown | Every N days. 1 = every day, 2 = every 2 days |
| Description | How to do the movement |

Changing a default does not rewrite your overrides or past log rows.

### Visuals

Keyed by the movement type name. Holds how that movement is drawn. Empty until frames exist. Swapping the picture replaces this object only.

| Field | Meaning |
| --- | --- |
| Movement name | Key. The movement type name |
| Representation | Later: the frames or GIF |

### My exercises

Your list. Each row points at one movement type. Sets, reps, and cooldown can be overridden here. An override is stored on this row and leaves the movement type as it is.

This is a reference plus optional overrides. A factory creates it: `MyExercise.from(movementType)` links the name and leaves the overrides empty, so the numbers still come from the movement type. Setting your own sets, reps, or cooldown fills that field on your row. An empty override keeps using the current default.

| Field | Meaning |
| --- | --- |
| User | |
| Movement name | Points at the movement type |
| Sets override | Empty means use the default |
| Reps override | Empty means use the default |
| Cooldown override | Empty means use the default |
| Starred | Whether you are working on it |

Effective sets are the override when it is set, otherwise the movement type default. Reps and cooldown resolve the same way.

The countdown uses that effective cooldown and the latest completion time in the log. At zero the movement is ready. No log row means ready. Completing it starts the countdown from that time. Doing it again early restarts the countdown.

You work from the starred rows. Each one shows its countdown. The ones whose cooldown has finished are ready.

### Logging

Append-only fact rows in a columnar store, so later analysis can scan them. One row each time you finish an exercise. Rows are added, not edited. User and exercise name are both columns.

| Column | Meaning |
| --- | --- |
| User | |
| Exercise name | Movement type name |
| Completed at | Datetime you finished it |
| Sets | Sets you did |
| Reps | Reps you did |

A review of these rows, grouped by area, shows which parts you actually practice and which you skip. Whole-body and other are included. Area comes from the movement type.

### Review

Optional. When you come back to exercise, the app can ask whether a body part hurts from last time, and which exercise you think did it. Skipping the prompt writes nothing.

The app presents the exercises from the last time you exercised. A saved answer is keyed by exercise name and the datetime you are answering now. It also stores the datetime of that earlier completion, so the answer stays tied to the session being reviewed.

Append-only columnar rows, same as the log.

| Column | Meaning |
| --- | --- |
| User | |
| Exercise name | The exercise you think is involved |
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

**Exercise pictures.** Cartoon stills with flat color and an outline. You describe the movement, we split it into positions, I generate one frame at a time, and you accept or redo it. Accepted frames become a GIF. No 3D, and no realistic people.

**Session notes.** The review row above is the start. Richer follow-up, and warnings based on it, stay later.

**Overlap.** Other workouts changing a cooldown.

**iPhone.** After the Android app is in use.

**Anyone else.** Accounts and a shared catalog.

## Open

Confirm the proposed sets, reps, and cooldowns in [movements.md](movements.md).
