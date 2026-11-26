using System.Collections.Generic;
using UnityEngine;

public class MovementPlayer : MonoBehaviour
{
    CuteFigure figure;
    OrbitCamera orbit;
    JointControl[] joints;
    Dictionary<string, JointControl> lookup;
    MovementClip[] clips;
    Vector3 rest;
    GameObject ball;
    Material soleYellow;
    Material soleTan;
    Vector3 ballHome;
    Vector3 ankleHome;
    readonly List<JointKnob> marked = new List<JointKnob>();
    int index;
    float time;
    bool playing;

    public bool IsPlaying
    {
        get { return playing; }
    }

    public int Index
    {
        get { return index; }
    }

    public string[] Names
    {
        get
        {
            var names = new string[clips.Length];
            for (int i = 0; i < clips.Length; i++)
                names[i] = clips[i].name;
            return names;
        }
    }

    public void Bind(CuteFigure source, OrbitCamera camera)
    {
        figure = source;
        orbit = camera;
        rest = figure.transform.position;
        joints = figure.GetComponentsInChildren<JointControl>();
        lookup = new Dictionary<string, JointControl>();
        for (int i = 0; i < joints.Length; i++)
            lookup[joints[i].name] = joints[i];
        clips = MovementLibrary.All();
        CreateBall();
        ShowBall(clips[0].name == "Arch roll");
        FrameCurrent();
        PlaceBall();
    }

    public void Step(int direction)
    {
        if (clips == null || clips.Length == 0)
            return;
        int next = index + direction;
        if (next < 0)
            next = clips.Length - 1;
        if (next >= clips.Length)
            next = 0;
        Select(next);
    }

    public void Select(int next)
    {
        index = Mathf.Clamp(next, 0, clips.Length - 1);
        playing = false;
        time = 0f;
        Rest();
        ShowBall(clips[index].name == "Arch roll");
        FrameCurrent();
        if (clips[index].name == "Arch roll")
            PlaceBall();
    }

    void FrameCurrent()
    {
        if (clips == null)
            return;

        var clip = clips[index];
        if (orbit == null || clip.focus == null || clip.focus.Length == 0)
            return;

        bool any = false;
        var bounds = new Bounds();
        for (int k = 0; k < clip.keys.Length; k++)
        {
            Apply(clip.keys[k]);
            for (int i = 0; i < clip.focus.Length; i++)
            {
                JointControl joint;
                if (!lookup.TryGetValue(clip.focus[i], out joint))
                    continue;
                if (!any)
                {
                    bounds = new Bounds(joint.transform.position, Vector3.zero);
                    any = true;
                }
                else
                {
                    bounds.Encapsulate(joint.transform.position);
                }
            }
        }

        Apply(clip.keys[0]);
        Mark(clip);
        if (any)
            orbit.Frame(clip.yaw, clip.pitch, clip.distance, bounds.center);
    }

    void Mark(MovementClip clip)
    {
        SetSole(clip.name == "Arch roll");
        if (clip.name == "Ankle stretch")
        {
            MarkBackAnkle();
            return;
        }

        if (clip.name == "Arch roll")
        {
            MarkJoints();
            return;
        }

        MarkJoints(clip.focus);
    }

    void MarkBackAnkle()
    {
        JointControl left;
        JointControl right;
        if (!lookup.TryGetValue("Hip.L", out left) || !lookup.TryGetValue("Hip.R", out right))
            return;
        MarkJoints(right.hinge <= left.hinge ? "Ankle.R" : "Ankle.L");
    }

    void MarkJoints(params string[] names)
    {
        for (int i = 0; i < marked.Count; i++)
            marked[i].SetMarked(false);
        marked.Clear();
        if (names == null)
            return;

        for (int i = 0; i < names.Length; i++)
        {
            JointControl joint;
            if (!lookup.TryGetValue(names[i], out joint))
                continue;
            var knob = joint.GetComponentInChildren<JointKnob>();
            if (knob == null)
                continue;
            knob.SetMarked(true);
            marked.Add(knob);
        }
    }

    public void Toggle()
    {
        if (playing)
        {
            playing = false;
            return;
        }

        if (time >= clips[index].Duration - 0.02f)
            time = 0f;
        playing = true;
        ShowBall(clips[index].name == "Arch roll");
    }

    public void Tick(float deltaTime)
    {
        if (!playing || clips == null)
            return;

        time += deltaTime;
        if (time >= clips[index].Duration)
        {
            time = clips[index].Duration;
            playing = false;
        }

        Apply(clips[index].Sample(time));
        if (clips[index].name == "Ankle stretch")
            MarkBackAnkle();
        if (clips[index].name == "Arch roll")
            RollBall();
    }

    void Rest()
    {
        Apply(new MovementClip.Key());
    }

    void Apply(MovementClip.Key pose)
    {
        if (joints == null)
            return;

        for (int i = 0; i < joints.Length; i++)
        {
            joints[i].SetHinge(0f);
            joints[i].SetRaise(0f);
        }

        if (pose.names != null)
        {
            for (int i = 0; i < pose.names.Length; i++)
            {
                JointControl joint;
                if (!lookup.TryGetValue(pose.names[i], out joint))
                    continue;
                joint.SetHinge(pose.hinge[i]);
                joint.SetRaise(pose.raise[i]);
            }
        }

        if (figure != null)
            figure.transform.position = rest + pose.root;
    }

    void CreateBall()
    {
        ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        ball.name = "ArchBall";
        Destroy(ball.GetComponent<Collider>());
        var renderer = ball.GetComponent<Renderer>();
        var shader = Shader.Find("Universal Render Pipeline/Unlit");
        if (shader == null)
            shader = Shader.Find("Unlit/Color");
        var material = new Material(shader);
        var color = new Color(0.86f, 0.15f, 0.12f);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
        renderer.sharedMaterial = material;

        ball.transform.localScale = Vector3.one * 0.07f;
    }

    void SetSole(bool yellow)
    {
        if (figure == null)
            return;
        var renderer = figure.Part("Foot.R").GetComponent<Renderer>();
        var materials = renderer.sharedMaterials;
        if (materials.Length < 2)
            return;
        if (soleTan == null)
            soleTan = materials[0];
        if (soleYellow == null)
        {
            var shader = Shader.Find("Universal Render Pipeline/Unlit");
            if (shader == null)
                shader = Shader.Find("Unlit/Color");
            soleYellow = new Material(shader);
            var color = new Color(1f, 0.86f, 0.12f);
            if (soleYellow.HasProperty("_BaseColor"))
                soleYellow.SetColor("_BaseColor", color);
            if (soleYellow.HasProperty("_Color"))
                soleYellow.SetColor("_Color", color);
        }

        materials[1] = yellow ? soleYellow : soleTan;
        renderer.sharedMaterials = materials;
    }

    void PlaceBall()
    {
        if (ball == null || figure == null)
            return;
        var foot = figure.Part("Foot.R");
        const float radius = 0.035f;
        var toe = foot.TransformPoint(new Vector3(0f, 0.35f, 0.25f));
        ballHome = new Vector3(toe.x, radius, toe.z);
        ball.transform.position = ballHome;
        ball.transform.rotation = Quaternion.identity;
        JointControl ankle;
        ankleHome = lookup.TryGetValue("Ankle.R", out ankle) ? ankle.transform.position : ballHome;
    }

    void RollBall()
    {
        if (ball == null)
            return;
        JointControl ankle;
        if (!lookup.TryGetValue("Ankle.R", out ankle))
            return;

        const float radius = 0.035f;
        var traveled = ankle.transform.position - ankleHome;
        traveled.y = 0f;
        var shift = traveled * 0.5f;
        ball.transform.position = ballHome + shift;
        if (shift.sqrMagnitude < 0.0000001f)
        {
            ball.transform.rotation = Quaternion.identity;
            return;
        }

        float degrees = shift.magnitude / radius * Mathf.Rad2Deg;
        var axis = Vector3.Cross(Vector3.up, shift.normalized);
        ball.transform.rotation = Quaternion.AngleAxis(-degrees, axis);
    }

    void ShowBall(bool visible)
    {
        if (ball != null)
            ball.SetActive(visible);
    }
}
