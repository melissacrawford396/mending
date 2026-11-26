# Movement visuals

Working document. Decisions are marked **Decided**, **Proposed**, or **Open**.

This sits next to [planning.md](planning.md). The first thing this project builds is the figure. Clips for the movements come after the figure can hold a pose.

## Product bet

One cute, minimal human, modeled in this project. Body parts are separate shapes. A joint is the pivot where the next part attaches. Rotating that joint moves the attached part, and every part hung below it.

**Decided:** Start here. This figure is ours. No imported anatomy, no muscle meshes, no tendon simulation.

**Decided:** The joints are visible. A blue circle sits on the pivot, and the circle is larger on the larger parts. The waist and hips are the biggest, then the shoulders and knees, then the elbows, ankles, and wrists. The toe circles are the smallest. Each limb is a light beige squished oval. The end of the oval just barely overlaps the circle, so the seam shows where they meet.

**Decided:** One generic body. A slightly large head, short thick limbs. A cartoon, and not a portrait of a real person.

**Decided:** Unity Personal, separate from the phone app. No hand-made frame series. You own what you create with it. It is free while revenue and funding for the last 12 months stay at or under $200,000. Above that, Unity Pro. No body is included.

**Decided:** A joint only rotates on its own axes. Neck, wrist, elbow, knee, ankle, and toes are a single hinge. Shoulder and hip raise the limb and swing it forward. A drag in Play mode follows those axes.

**Decided:** Each foot is a flat rectangle, longer than it is wide. Five short toes sit in a row on the front. Each toe has its own small ball and bends on its own hinge.

**Decided:** Hover a part and it outlines. Click it and the whole part turns around one joint. The upper arm turns around the shoulder, the forearm around the elbow, the hand around the wrist, the head around the neck, the thigh around the hip, the calf around the knee, the foot around the ankle, and each toe around its own joint. The head is large, with white eyes, a black pupil, and a small partial-circle smile. It sits on the neck joint. There is no neck limb. The chest and the hip both turn around the waist ball between them: the chest leans the upper body, and the hip swings the lower body. While a joint moves, a partial circle shows its range. Dragging the background turns the view, including from above. A circle in the top-left corner keeps turning the view while the dot is held out from the center, faster toward the ring. Buttons above it jump to the front, left, right, back, and top. The ground is a pale see-through green, and the background is a light blue.

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

## Later

Hover to find an exercise. The areas in [planning.md](planning.md) live on this figure. A shape starts light and turns blue on hover. Paired sides highlight together. A click opens the movements for that area.

Then the clips. One pose sequence per movement, played on this figure and exported as a short video. Same camera, same figure, same light. The Flutter visuals row stores that video, keyed by the movement name.

| Movement | What the clip shows | What has to move |
| --- | --- | --- |
| Arch roll | One foot rolls slowly along a ball. Pressure stays light. | Ankle and foot. The ball is a prop. |
| Toe flex | One ankle rests on the other knee. Toes flex and extend. A hand may assist. | Hip, knee, and the toe semicircle. |
| Small shoulder circles | Both arms out. Small circles, then the other direction. | Shoulders. |
| Large arm circles | Full circles, both directions. | Shoulders, through a larger range. |
| Ankle stretch | Split stance. Front knee bends. Back heel stays down. Hold. Switch sides. | Hip, knee, and ankle. |

Reps in the data stay numbers. The clip shows one clear pass, one circle, or one held stretch, then the other direction or the other side when the description says so.

## Open

- When fingers get their own joints. The pose check does not need them.
- A second body. Later.
