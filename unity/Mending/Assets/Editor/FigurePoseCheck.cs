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

            var toes = figure.Part("Toes.R.Shape").position;
            figure.Joint("Ankle.R").SetHinge(40f);
            Check(report, ref failed, "foot points down", figure.Part("Toes.R.Shape").position.y < toes.y - 0.02f,
                "toe y " + toes.y.ToString("0.000") + " -> " + figure.Part("Toes.R.Shape").position.y.ToString("0.000"));
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
