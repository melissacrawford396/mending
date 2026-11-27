using System.Globalization;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

public static class FigurePoseCheck
{
    public static void Run()
    {
        var report = new StringBuilder();
        var failed = false;
        var root = new GameObject("Figure");
        var figure = root.AddComponent<CuteFigure>();
        figure.Build();

        try
        {
            Check(report, ref failed, "standing feet", Lowest(figure) < 0.02f && Lowest(figure) > -0.001f,
                "lowest point " + Lowest(figure).ToString("0.000", CultureInfo.InvariantCulture));

            var handR = figure.Part("Hand.R").position;
            var handL = figure.Part("Hand.L").position;
            var footL = figure.Part("Foot.L").position;
            figure.Joint("Elbow.R").SetHinge(90f);
            var bentHand = figure.Part("Hand.R").position;
            Check(report, ref failed, "elbow bends forward", bentHand.z > handR.z + 0.05f,
                "hand z " + handR.z.ToString("0.000") + " -> " + bentHand.z.ToString("0.000"));
            Check(report, ref failed, "other hand stays", Vector3.Distance(figure.Part("Hand.L").position, handL) < 0.001f,
                "left hand moved");
            Check(report, ref failed, "other foot stays during elbow", Vector3.Distance(figure.Part("Foot.L").position, footL) < 0.001f,
                "left foot moved");
            figure.Joint("Elbow.R").SetHinge(0f);

            var ankleR = figure.Joint("Ankle.R").transform.position;
            var ankleL = figure.Joint("Ankle.L").transform.position;
            figure.Joint("Knee.R").SetHinge(90f);
            var bentAnkle = figure.Joint("Ankle.R").transform.position;
            Check(report, ref failed, "knee bends back", bentAnkle.z < ankleR.z - 0.05f,
                "ankle z " + ankleR.z.ToString("0.000") + " -> " + bentAnkle.z.ToString("0.000"));
            Check(report, ref failed, "other ankle stays", Vector3.Distance(figure.Joint("Ankle.L").transform.position, ankleL) < 0.001f,
                "left ankle moved");
            figure.Joint("Knee.R").SetHinge(0f);

            handR = figure.Part("Hand.R").position;
            handL = figure.Part("Hand.L").position;
            figure.Joint("Shoulder.R").SetRaise(80f);
            Check(report, ref failed, "shoulder raises out", figure.Part("Hand.R").position.x > handR.x + 0.08f,
                "hand x " + handR.x.ToString("0.000") + " -> " + figure.Part("Hand.R").position.x.ToString("0.000"));
            Check(report, ref failed, "other arm stays during raise", Vector3.Distance(figure.Part("Hand.L").position, handL) < 0.001f,
                "left hand moved");
            figure.Joint("Shoulder.R").SetRaise(0f);

            var toes = figure.Part("Toe.R.1").position;
            figure.Joint("Ankle.R").SetHinge(40f);
            Check(report, ref failed, "foot points down", figure.Part("Toe.R.1").position.y < toes.y - 0.02f,
                "toe y " + toes.y.ToString("0.000") + " -> " + figure.Part("Toe.R.1").position.y.ToString("0.000"));

            var shoulderKnob = KnobScale(figure, "Shoulder.R");
            var elbowKnob = KnobScale(figure, "Elbow.R");
            var wristKnob = KnobScale(figure, "Wrist.R");
            var hipKnob = KnobScale(figure, "Hip.R");
            var kneeKnob = KnobScale(figure, "Knee.R");
            var ankleKnob = KnobScale(figure, "Ankle.R");
            var toeKnob = KnobScale(figure, "Toe.R.1");
            Check(report, ref failed, "joints scale with the body",
                shoulderKnob > elbowKnob + 0.02f && elbowKnob > wristKnob + 0.015f
                && hipKnob > kneeKnob + 0.02f && kneeKnob > ankleKnob + 0.015f && ankleKnob > toeKnob + 0.02f,
                "shoulder " + shoulderKnob.ToString("0.000") + " elbow " + elbowKnob.ToString("0.000")
                + " wrist " + wristKnob.ToString("0.000") + " hip " + hipKnob.ToString("0.000")
                + " knee " + kneeKnob.ToString("0.000") + " ankle " + ankleKnob.ToString("0.000")
                + " toe " + toeKnob.ToString("0.000"));
            var foot = figure.Part("Foot.R");
            Check(report, ref failed, "foot is longer than it is wide", foot.localScale.y > foot.localScale.x + 0.05f,
                "length " + foot.localScale.y.ToString("0.000") + " width " + foot.localScale.x.ToString("0.000"));
            var eye = figure.Part("Head").Find("Eye.L");
            var white = eye.Find("White");
            var pupil = eye.Find("Pupil");
            Check(report, ref failed, "eyes are white with a black pupil",
                white != null && pupil != null && white.localScale.x > pupil.localScale.x + 0.02f && white.localScale.z < white.localScale.x * 0.25f,
                "white " + (white == null ? "missing" : white.localScale.x.ToString("0.000"))
                + " pupil " + (pupil == null ? "missing" : pupil.localScale.x.ToString("0.000")));
            Check(report, ref failed, "smile is on the face", figure.Part("Head").Find("Smile") != null, "smile");
            Check(report, ref failed, "limb can be clicked", figure.Part("Forearm.R").GetComponent<BodyPart>() != null,
                "forearm body part");

            Check(report, ref failed, "upper arm drives the shoulder", Drives(figure, "UpperArm.R", "Shoulder.R", false), "shoulder");
            Check(report, ref failed, "forearm drives the elbow", Drives(figure, "Forearm.R", "Elbow.R", false), "elbow");
            Check(report, ref failed, "hand drives the wrist", Drives(figure, "Hand.R", "Wrist.R", false), "wrist");
            Check(report, ref failed, "head drives the neck",
                figure.Part("Head").Find("Head.Shape").GetComponent<BodyPart>().joint == figure.Joint("Neck"), "neck");
            Check(report, ref failed, "thigh drives the hip", Drives(figure, "Thigh.R", "Hip.R", false), "hip");
            Check(report, ref failed, "calf drives the knee", Drives(figure, "Shin.R", "Knee.R", false), "knee");
            Check(report, ref failed, "foot drives the ankle", Drives(figure, "Foot.R", "Ankle.R", false), "ankle");
            Check(report, ref failed, "toes drive their own joints",
                Drives(figure, "Toe.R.1", "Toe.R.1", false) && Drives(figure, "Toe.R.5", "Toe.R.5", false)
                && Drives(figure, "Toe.L.3", "Toe.L.3", false), "toes");
            Check(report, ref failed, "chest drives the waist", Drives(figure, "Torso", "Waist", false), "torso");
            Check(report, ref failed, "hip drives the waist from below", Drives(figure, "Pelvis", "Waist", true), "pelvis");

            var waist = figure.Joint("Waist");
            var waistKnob = waist.transform.Find("Waist.Knob");
            Check(report, ref failed, "waist ball is visible", waistKnob != null && Mathf.Abs(waistKnob.localScale.x - 0.168f) < 0.001f,
                "knob scale " + (waistKnob == null ? "missing" : waistKnob.localScale.x.ToString("0.000")));
            Check(report, ref failed, "waist sits between chest and hip",
                figure.Part("Torso").position.y > waist.transform.position.y && waist.transform.position.y > figure.Part("Pelvis").position.y,
                "torso " + figure.Part("Torso").position.y.ToString("0.000") + " waist " + waist.transform.position.y.ToString("0.000")
                + " pelvis " + figure.Part("Pelvis").position.y.ToString("0.000"));

            var torso = figure.Part("Torso").position;
            var pelvis = figure.Part("Pelvis").position;
            waist.SetHinge(30f);
            Check(report, ref failed, "chest bends at the waist", figure.Part("Torso").position.z > torso.z + 0.02f,
                "torso z " + torso.z.ToString("0.000") + " -> " + figure.Part("Torso").position.z.ToString("0.000"));
            Check(report, ref failed, "hip stays while the chest bends", Vector3.Distance(figure.Part("Pelvis").position, pelvis) < 0.001f,
                "pelvis moved");
            waist.SetHinge(0f);

            torso = figure.Part("Torso").position;
            pelvis = figure.Part("Pelvis").position;
            var waistPoint = waist.transform.position;
            waist.OrbitParent(20f);
            Check(report, ref failed, "hip swings around the waist", Vector3.Distance(figure.Part("Pelvis").position, pelvis) > 0.02f,
                "pelvis moved " + Vector3.Distance(figure.Part("Pelvis").position, pelvis).ToString("0.000"));
            Check(report, ref failed, "chest stays while the hip swings", Vector3.Distance(figure.Part("Torso").position, torso) < 0.01f,
                "torso moved " + Vector3.Distance(figure.Part("Torso").position, torso).ToString("0.000"));
            Check(report, ref failed, "waist ball stays put", Vector3.Distance(waist.transform.position, waistPoint) < 0.001f,
                "waist moved");

            Check(report, ref failed, "joints are numbered",
                figure.Joint("Neck").number == 1 && figure.Joint("Waist").number == 2
                && figure.Joint("Shoulder.L").number == 3 && figure.Joint("Toe.R.5").number == 24,
                "neck " + figure.Joint("Neck").number + " waist " + figure.Joint("Waist").number
                + " shoulder " + figure.Joint("Shoulder.L").number + " little toe " + figure.Joint("Toe.R.5").number);
        }
        finally
        {
            var directory = Path.Combine(Directory.GetCurrentDirectory(), "Logs");
            Directory.CreateDirectory(directory);
            var text = (failed ? "FAIL\n" : "PASS\n") + report;
            File.WriteAllText(Path.Combine(directory, "pose-check-result.txt"), text);
            Debug.Log(text);
        }

        EditorApplication.Exit(failed ? 1 : 0);
    }

    static float KnobScale(CuteFigure figure, string joint)
    {
        var knob = figure.Joint(joint).transform.Find(joint + ".Knob");
        return knob == null ? 0f : knob.localScale.x;
    }

    static bool Drives(CuteFigure figure, string part, string joint, bool movesParent)
    {
        var body = figure.Part(part).GetComponent<BodyPart>();
        return body != null && body.joint == figure.Joint(joint) && body.movesParent == movesParent;
    }

    static float Lowest(CuteFigure figure)
    {
        var lowest = float.PositiveInfinity;
        foreach (var renderer in figure.GetComponentsInChildren<Renderer>())
            lowest = Mathf.Min(lowest, renderer.bounds.min.y);
        return lowest;
    }

    static void Check(StringBuilder report, ref bool failed, string name, bool ok, string detail)
    {
        report.Append(ok ? "ok  " : "BAD ").Append(name).Append(" — ").Append(detail).Append('\n');
        if (!ok)
            failed = true;
    }
}
