# Movement visuals

Working document. Decisions are marked **Decided**, **Proposed**, or **Open**.

This sits next to [planning.md](planning.md). The Flutter app does not render 3D. This project only produces the clip for each movement.

## Product bet

A Unity project used as a studio. One figure. Each movement in [movements.md](movements.md) is one animation clip on that figure. Unity plays the clip and exports a short video. The Flutter visuals row stores that video, keyed by the movement name.

**Decided:** Unity, separate from the phone app. No hand-made frame series.

The phone app keeps the flat body map. These clips are the exercise demo, not the tappable figure.

## What the research found

No free product is a finished, commercial-ok body whose muscles and tendons move. The free pieces split in two. Anatomy models hold still. Animation tools have a body with skin and no muscles.

Checked November 2026 against each publisher's own license page. This is not legal advice.

### Anatomy, not animation

| Product | What it is | License | Commercial use | Moves? |
| --- | --- | --- | --- | --- |
| [BodyParts3D](https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html) | Named meshes from MRI. About 400 skeletal muscles, full skeleton. One adult male. Release 4.0. | License page updated 2025-02-27 says CC BY 4.0. Credit: "BodyParts3D, © The Database Center for Life Science licensed under CC Attribution 4.0 International". The 2013 OBJ files still say CC BY-SA 2.1 Japan and point at that page. | Yes, with that credit. No share-alike on the current page. | No. Anatomical position only. Rough meshes. |
| [Z-Anatomy](https://github.com/Z-Anatomy/Models-of-human-anatomy) | Blender atlas built on BodyParts3D. Cleaner meshes. Tendons and aponeuroses added as their own objects, including shared endings such as the quadriceps tendon. | CC BY-SA 4.0 | Yes, if distributed adaptations stay under the same license. | A skeleton rig exists. It moves bones only. Muscles and tendons stay in the bind pose. |
| [Écorché](https://github.com/Charleeh/ecorche) | One named mesh per bone and muscle. Tendon ends are pale vertex color, including the calcaneal tendon. | CC BY-SA 4.0, because it includes Z-Anatomy | Same share-alike rule | No rig and no poses. The author says so. |

CC BY-SA is the one to avoid for anything the app ships. A video made from those meshes is an adaptation. Sharing it means the video stays under CC BY-SA, so someone else can reuse it on the same terms. BodyParts3D's current page does not have that term. Z-Anatomy and Écorché do, and their extra tendon work is the part under share-alike. Use BodyParts3D directly. Do not start from Z-Anatomy or Écorché.

Tendons in these sets are shapes in the standing pose. They do not slide or wrap when a joint bends. Parenting a tendon mesh to a bone is as far as "how it would move" goes without building a simulator.

### Animation, not anatomy

| Product | What it is | License | Commercial use | Muscles? |
| --- | --- | --- | --- | --- |
| [Unity Personal](https://unity.com/products/unity-personal) | The engine. You own what you create with it. | Unity editor terms. Free while revenue and funding for the last 12 months stay at or under $200,000. Above that, Unity Pro. | Yes, inside that cap. | No body included. |
| [Blender](https://www.blender.org/about/license/) | Mesh cleanup, skinning, and posing. | GPL covers Blender. Images, video, and scene files you make are yours. | Yes, including commercial video. | No body included. The license of any model you import still applies. |
| [MakeHuman](https://static.makehumancommunity.org/makehuman/faq/can_i_sell_models_created_with_makehuman.html) | Generates a skinned human. Exports are CC0. | CC0 on the export | Yes. No attribution. | Skin. No muscle meshes. |
| [Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) | Free with an Adobe ID. Auto-rig and a library of humanoid clips. Royalty-free for games and film. | Adobe's Mixamo terms. Do not redistribute the raw character or animation files. Do not use them to train a model. | Yes, for a video inside the app. | Skin. The auto-rigger needs one connected humanoid mesh. It will not rig a pile of separate muscles. |

### Simulators

[OpenSim](https://github.com/opensim-org/opensim-core) is the free tool that actually computes muscle-driven movement. The software is Apache 2.0, so commercial use of the program is allowed. Each musculoskeletal model has its own license. The picture is a skeleton with lines for muscles. That is the wrong picture for the app. AnyBody and similar packages are paid.

### Paid products that already did this

These are out of scope. They are listed so the gap is obvious.

- Muscle Anatomy 3D by eklirik, on itch.io. Rigged male écorché, FBX for Unity, tendons as vertex color, 31 clips including squats and lunges, muscles highlighted from a simplified estimate. Geometry starts from BodyParts3D. The standard license allows embedding in an app and forbids redistributing the files. It is a paid download. Price was not on the public page.
- Alex Lashko, Muscle Anatomy écorché, $99. Standard license caps one commercial project at 2,000 sales or 20,000 views. Wrong cap for an app.
- Visible Body, Complete Anatomy, BioDigital, Zygote, Primal Pictures. Subscription atlases. Their models cannot be lifted into this project.

Catalog sites that advertise a free CC0 rigged muscle man, including Grab3D, do not name a creator or a source archive. Do not build on those.

## Proposed pipeline

Do not model a body. Do not simulate tendon physics.

1. Import the BodyParts3D muscles and bones for the region that movement uses.
2. Skin those meshes to a small rig in Blender. Blender is the skinning tool. Unity is a poor place to weight hundreds of separate muscles.
3. Import the rigged piece into Unity. Key the exercise as one AnimationClip.
4. Export one video per movement. Same camera, same figure, same lighting, so the library stays consistent.
5. The Flutter visuals field points at that file.

Only the structures that matter for that movement get skinned. A full-body skin of every muscle is the from-scratch project. The first five stay local: a foot, an ankle, a shoulder.

Mixamo clips can be a timing reference for the shoulder circles. They are not the anatomy, and the raw Mixamo files do not ship in the app.

The figure is one generic adult body. It is not a portrait of a real person. Every free full muscle set found is one adult male. A second body is later.

These meshes are teaching models. They are not accurate enough to diagnose or to claim a clinical path of a tendon.

## First five clips

| Movement | What the clip shows | Structures |
| --- | --- | --- |
| Arch roll | One foot rolls slowly along a ball. Pressure stays light. | Plantar foot. The ball is a prop. |
| Toe flex | One ankle rests on the other knee. Toes flex and extend. A hand may assist. | Toes and the long toe flexors and extensors. |
| Small shoulder circles | Both arms out. Small circles, then the other direction. | Shoulder girdle and deltoid. Harder than the foot. Many muscles cross the joint. |
| Large arm circles | Full circles, both directions. | Same shoulder, larger range. Weighting errors show more here. |
| Ankle stretch | Split stance. Front knee bends. Back heel stays down. Hold. Switch sides. | Back ankle and the calcaneal tendon. This is the clip that needs a tendon to read. |

Reps in the data stay numbers. The clip shows one clear pass, one circle, or one held stretch, then the other direction or the other side when the description says so.

## Open

- Confirm the BodyParts3D license in writing with the database center before release. The page and the files disagree, and the files are what an audit will see.
- Whether the first videos show the whole figure with a few muscles colored, or only the region, with the rest of the body omitted.
- A second body. Nothing free and commercial-ok found for a female figure.
- Whether a paid rigged écorché is worth it if skinning the first shoulder clip goes badly. That would drop the free-only rule for this one asset.
