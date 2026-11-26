# Movement visuals

Working document. Decisions are marked **Decided**, **Proposed**, or **Open**.

This sits next to [planning.md](planning.md). The first thing this project builds is the figure. Clips for the movements come after the figure can hold a pose.

## Product bet

One cute, minimal human, modeled in this project. Body parts are separate shapes. A joint is the pivot where the next part attaches. Rotating that joint moves the attached part, and every part hung below it.

**Decided:** Start here. This figure is ours. No imported anatomy, no muscle meshes, no tendon simulation.

**Decided:** The joints are visible. A blue circle sits on the pivot, and the circle is larger on the larger parts. The waist and hips are the biggest, then the shoulders and knees, then the elbows, ankles, and wrists. The toe circles are the smallest. Each limb is a lighter blue squished oval, with shading so the roundness shows. The end of the oval just barely overlaps the circle, so the seam shows where they meet.

**Decided:** One generic body. A slightly large head. The upper arm, forearm, thigh, and calf are long. The thigh is a little thicker, and the calf and forearm are slimmer. A cartoon, and not a portrait of a real person.

**Decided:** Unity Personal, separate from the phone app. No hand-made frame series. You own what you create with it. It is free while revenue and funding for the last 12 months stay at or under $200,000. Above that, Unity Pro. No body is included.

**Decided:** A joint only rotates on its own axes. Neck, wrist, elbow, knee, ankle, and toes are a single hinge. Shoulder and hip raise the limb and swing it forward. A drag in Play mode follows those axes.

**Decided:** Each foot is flat and longer than it is wide, thick through the sole, narrower at the heel and wider at the ball. Five round toes sit in a row on the front. Each toe has its own small ball and bends on its own hinge. The head, chest, hips, and each limb have a black edge. The toes are spaced apart so each one reads on its own.

**Decided:** Hover a part and it outlines. Click it and the whole part turns around one joint. The upper arm turns around the shoulder, the forearm around the elbow, the hand around the wrist, the head around the neck, the thigh around the hip, the calf around the knee, the foot around the ankle, and each toe around its own joint. The head is large, with white eyes, a black pupil, and a small partial-circle smile. It sits on the neck joint. There is no neck limb. The chest and the hip both turn around the waist ball between them: the chest leans the upper body, and the hip swings the lower body. While a joint moves, a partial circle shows its range. Dragging the background turns the view, including from above. A Views button in the top-left shows or hides the circle and the front, left, right, back, and top buttons. They start hidden. The circle keeps turning the view while the dot is held out from the center, faster toward the ring. The ground is a light sage green, and the background is a warm taupe.

**Proposed:** Hands are one shape each. Fingers are the next joints, after this figure poses.

## First figure

The pelvis is the root. A waist joint sits between the pelvis and the torso, with a visible blue ball. The torso, neck, and arms hang from that joint. The legs hang from the pelvis. Joints are empty pivots parented in a chain. The mesh for a part is a child of its joint, so the knob and the part rotate together.

| Joint | What hangs from it |
| --- | --- |
| Waist | Torso, neck, head, and both arms |
| Neck | Head |
| Shoulder, each side | Upper arm, elbow, forearm, wrist, hand |
| Elbow, each side | Forearm, wrist, hand |
| Wrist, each side | Hand |
| Hip, each side | Thigh, knee, shin, ankle, foot |
| Knee, each side | Shin, ankle, foot |
| Ankle, each side | Foot and all five toes |
| Toe, five on each foot | That toe |

Parts: head, torso, pelvis, and on each side an upper arm, forearm, hand, thigh, shin, foot, and five toes. Plus a blue circle at each joint in the table. The view buttons use dark text.

Pose check: stand, lift one arm out, bend that elbow, bend one knee, point that foot. The limb below the joint follows. The other limbs stay put.

Hover to find an exercise, and the clips in [movements.md](movements.md), both use this same figure. Both wait until the pose check passes.

## Clips

**Proposed:** A clip is a short pose sequence on this figure. It is not a rep counter. Sets and reps stay numbers in the movement data. The clip shows one clear pass, one circle, or one held stretch, then the other direction or the other side when the description says so.

**Proposed:** Each clip is a list of keys. A key is a time, plus the hinge and raise angle for every joint that moves, plus the position of the whole figure when a foot has to slide. Joints that are left out stay at rest. Playback sets those angles directly. No separate animation software, and no imported clips.

**Proposed:** The shoulder and the hip only have two axes, so an arm circle is an oval on those two axes. Small shoulder circles are a small oval with the arms already out. Large arm circles use more of the same two axes. The clip does not invent a spin the joint cannot do.

**Decided:** The bottom center has a movement menu and a play button. Buttons are solid white, with rounded corners and black text. Play runs the selected clip. Pause holds it. Choosing a movement resets that clip to its start, turns the working joints yellow, and frames the camera on those joints. Arch roll and the ankle stretch sit back so the feet stay in view. Toe flex sits close on the foot. The view buttons still work while a clip plays.

| Order | Movement | What the clip shows | What has to move |
| --- | --- | --- | --- |
| 1 | Small shoulder circles | Both arms out. One small oval forward, then backward. Same view as the large circles. | Both shoulders. |
| 2 | Large arm circles | One bigger oval forward, then backward. | Both shoulders, through a larger range. |
| 3 | Toe flex | The foot stays on the ground. The toes curl and open once. The knee stays straight. | That foot's toes. The hand stays down until fingers exist. |
| 4 | Ankle stretch | Split stance. The body lowers and stays upright so both feet stay on the ground. Front knee bends, back heel stays down, hold. Then the other side. | Both hips, both knees, and the back ankle. Only that ankle is highlighted. |
| 5 | Arch roll | The right foot slides over a red ball that starts at the toe end. The ball rolls forward as the foot passes over it, and stays under the yellow sole. The underside of that foot is yellow. | A ball prop. The right hip and knee slide that foot over the ball. |

**Proposed:** When those five read clearly in Play mode, record each one from a fixed camera. Same figure, same light. One short video per movement name. That file is what the visuals row in [movements.md](movements.md) stores.

Hover to find an exercise stays later. The areas in [planning.md](planning.md) live on this figure. A shape starts light and turns blue on hover. Paired sides highlight together. A click opens the movements for that area.

## Open

- When fingers get their own joints. The pose check does not need them.
- A second body. Later.
