using System.Collections.Generic;
using UnityEngine;

public class CuteFigure : MonoBehaviour
{
    const float Arm = 0.125f;
    const float Leg = 0.15f;
    const float NeckWidth = 0.1f;
    const float HeadRadius = 0.16f;
    const float Overlap = 0.05f;
    const float JointScale = 0.7f;

    readonly Dictionary<string, JointControl> joints = new Dictionary<string, JointControl>();
    readonly Dictionary<string, Transform> parts = new Dictionary<string, Transform>();

    Material limbMaterial;
    Material jointMaterial;
    Material eyeMaterial;

    public Transform Focus { get; private set; }

    public JointControl Joint(string name)
    {
        return joints[name];
    }

    public Transform Part(string name)
    {
        return parts[name];
    }

    public void Build()
    {
        for (int i = transform.childCount - 1; i >= 0; i--)
            DestroyNow(transform.GetChild(i).gameObject);

        joints.Clear();
        parts.Clear();

        limbMaterial = MakeMaterial(new Color(0.98f, 0.95f, 0.91f));
        jointMaterial = MakeMaterial(new Color(0.29f, 0.52f, 0.95f));
        eyeMaterial = MakeMaterial(new Color(0.2f, 0.22f, 0.28f));

        const float pelvisHeight = 0.16f;
        const float torsoHeight = 0.28f;
        const float waistDiameter = 0.24f;
        float visualRadius = waistDiameter * JointScale * 0.5f;
        float bite = waistDiameter * JointScale * Overlap;
        float waistY = pelvisHeight * 0.5f + visualRadius - bite;
        float torsoLocalY = visualRadius - bite + torsoHeight * 0.5f;

        var waist = AddJoint("Waist", transform, new Vector3(0f, waistY, 0f), waistDiameter, JointControl.Kind.Hinge,
            Vector3.right, new Vector2(-30f, 50f), Vector3.forward, Vector2.zero, Vector3.up);
        Tag(waist, 2, "Waist");
        var waistJoint = waist.GetComponent<JointControl>();

        AddBody("Pelvis", transform, Vector3.zero, new Vector3(0.32f, pelvisHeight, 0.22f), waistJoint, true);
        AddBody("Torso", waist, new Vector3(0f, torsoLocalY, 0f), new Vector3(0.36f, torsoHeight, 0.2f), waistJoint, false);
        Focus = parts["Torso"];

        var neck = AddJoint("Neck", waist, new Vector3(0f, torsoLocalY + 0.12f, 0f), NeckWidth, JointControl.Kind.Hinge,
            Vector3.right, new Vector2(-20f, 35f), Vector3.forward, Vector2.zero, Vector3.up);
        AddLimb(neck, "Neck", Vector3.up, 0.06f, NeckWidth, NeckWidth, NeckWidth * 0.75f);
        AddHead(neck);
        Tag(neck, 1, "Neck");

        BuildArm(false, waist, torsoLocalY);
        BuildArm(true, waist, torsoLocalY);
        BuildLeg(false);
        BuildLeg(true);
        PlantFeet();
    }

    void BuildArm(bool left, Transform chest, float torsoLocalY)
    {
        float side = left ? -1f : 1f;
        var raiseAxis = left ? Vector3.back : Vector3.forward;
        var shoulder = AddJoint("Shoulder." + Side(left), chest, new Vector3(0.22f * side, torsoLocalY + 0.08f, 0f), Arm,
            JointControl.Kind.TwoAxis, Vector3.left, new Vector2(-30f, 170f), raiseAxis, new Vector2(0f, 160f), Vector3.down);
        AddLimb(shoulder, "UpperArm." + Side(left), Vector3.down, 0.18f, Arm, Arm, Arm * 0.72f);
        var elbow = AddJoint("Elbow." + Side(left), shoulder, Vector3.down * Span(Arm, Arm, 0.18f), Arm,
            JointControl.Kind.Hinge, Vector3.left, new Vector2(0f, 150f), Vector3.forward, Vector2.zero, Vector3.down);

        AddLimb(elbow, "Forearm." + Side(left), Vector3.down, 0.16f, Arm, Arm, Arm * 0.72f);
        var wrist = AddJoint("Wrist." + Side(left), elbow, Vector3.down * Span(Arm, Arm, 0.16f), Arm,
            JointControl.Kind.Hinge, Vector3.left, new Vector2(-30f, 50f), Vector3.forward, Vector2.zero, Vector3.down);
        AddLimb(wrist, "Hand." + Side(left), Vector3.down, 0.1f, Arm, Arm, Arm * 0.62f);

        string sideName = left ? "L" : "R";
        int first = left ? 3 : 6;
        Tag(shoulder, first, sideName + " Shoulder");
        Tag(elbow, first + 1, sideName + " Elbow");
        Tag(wrist, first + 2, sideName + " Wrist");
    }

    void BuildLeg(bool left)
    {
        float side = left ? -1f : 1f;
        var raiseAxis = left ? Vector3.back : Vector3.forward;
        var hip = AddJoint("Hip." + Side(left), transform, new Vector3(0.11f * side, -0.02f, 0f), Leg,
            JointControl.Kind.TwoAxis, Vector3.left, new Vector2(-20f, 100f), raiseAxis, new Vector2(0f, 60f), Vector3.down);
        AddLimb(hip, "Thigh." + Side(left), Vector3.down, 0.2f, Leg, Leg, Leg * 0.75f);
        var knee = AddJoint("Knee." + Side(left), hip, Vector3.down * Span(Leg, Leg, 0.2f), Leg,
            JointControl.Kind.Hinge, Vector3.right, new Vector2(0f, 150f), Vector3.forward, Vector2.zero, Vector3.down);

        AddLimb(knee, "Shin." + Side(left), Vector3.down, 0.18f, Leg, Leg, Leg * 0.72f);
        var ankle = AddJoint("Ankle." + Side(left), knee, Vector3.down * Span(Leg, Leg, 0.18f), Leg,
            JointControl.Kind.Hinge, Vector3.right, new Vector2(-25f, 50f), Vector3.forward, Vector2.zero, Vector3.forward);

        AddLimb(ankle, "Foot." + Side(left), Vector3.forward, 0.15f, Leg, Leg, Leg * 0.55f);
        var toes = AddJoint("Toes." + Side(left), ankle, Vector3.forward * Span(Leg, Leg, 0.15f), Leg,
            JointControl.Kind.Hinge, Vector3.right, new Vector2(-35f, 45f), Vector3.forward, Vector2.zero, Vector3.forward);
        AddToes(toes, "Toes." + Side(left), Leg);

        string sideName = left ? "L" : "R";
        int first = left ? 9 : 13;
        Tag(hip, first, sideName + " Hip");
        Tag(knee, first + 1, sideName + " Knee");
        Tag(ankle, first + 2, sideName + " Ankle");
        Tag(toes, first + 3, sideName + " Toes");
    }

    static string Side(bool left)
    {
        return left ? "L" : "R";
    }

    static void Tag(Transform joint, int number, string label)
    {
        var control = joint.GetComponent<JointControl>();
        control.number = number;
        control.label = label;
    }

    Transform AddJoint(string name, Transform parent, Vector3 localPosition, float diameter, JointControl.Kind kind,
        Vector3 hingeAxis, Vector2 hingeLimits, Vector3 raiseAxis, Vector2 raiseLimits, Vector3 restDirection)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = localPosition;
        var joint = go.AddComponent<JointControl>();
        joint.Define(kind, hingeAxis, hingeLimits, raiseAxis, raiseLimits, restDirection * 0.2f);
        joint.ballRadius = diameter * JointScale * 0.5f;
        joints.Add(name, joint);

        var knob = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        knob.name = name + ".Knob";
        knob.transform.SetParent(go.transform, false);
        knob.transform.localScale = Vector3.one * diameter * JointScale;
        Paint(knob, jointMaterial);
        knob.AddComponent<JointKnob>().Bind(joint);
        return go.transform;
    }

    void AddLimb(Transform joint, string name, Vector3 direction, float length, float jointDiameter, float width, float depth)
    {
        var oval = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        oval.name = name;
        ReplaceWithBoxCollider(oval);
        oval.AddComponent<BodyPart>().Bind(joint.GetComponent<JointControl>());
        oval.transform.SetParent(joint, false);
        float inset = TipInset(jointDiameter);
        oval.transform.localPosition = direction.normalized * (inset + length * 0.5f);
        oval.transform.localRotation = AlignLongAxis(direction, Vector3.up);
        oval.transform.localScale = new Vector3(width, length, depth);
        Paint(oval, limbMaterial);
        parts.Add(name, oval.transform);
    }

    void AddBody(string name, Transform parent, Vector3 localPosition, Vector3 scale, JointControl joint, bool movesParent)
    {
        var oval = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        oval.name = name;
        ReplaceWithBoxCollider(oval);
        oval.AddComponent<BodyPart>().Bind(joint, movesParent);
        oval.transform.SetParent(parent, false);
        oval.transform.localPosition = localPosition;
        oval.transform.localScale = scale;
        Paint(oval, limbMaterial);
        parts.Add(name, oval.transform);
    }

    void AddHead(Transform neck)
    {
        float inset = TipInset(NeckWidth);
        float farTip = inset + 0.06f;
        var pivot = new GameObject("Head");
        pivot.transform.SetParent(neck, false);
        pivot.transform.localPosition = Vector3.up * (farTip - 0.02f + HeadRadius);

        var skull = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        skull.name = "Head.Shape";
        skull.AddComponent<BodyPart>().Bind(neck.GetComponent<JointControl>());
        skull.transform.SetParent(pivot.transform, false);
        skull.transform.localScale = Vector3.one * HeadRadius * 2f;
        Paint(skull, limbMaterial);

        AddEye(pivot.transform, -1f);
        AddEye(pivot.transform, 1f);
        parts.Add("Head", pivot.transform);
    }

    void AddEye(Transform head, float side)
    {
        var eye = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        eye.name = side < 0f ? "Eye.L" : "Eye.R";
        DestroyNow(eye.GetComponent<Collider>());
        eye.transform.SetParent(head, false);
        float eyeRadius = 0.022f;
        eye.transform.localPosition = new Vector3(0.055f * side, 0.025f, HeadRadius - eyeRadius * 0.15f);
        eye.transform.localScale = Vector3.one * eyeRadius * 2f;
        Paint(eye, eyeMaterial);
    }

    void AddToes(Transform joint, string name, float jointDiameter)
    {
        var go = new GameObject(name + ".Shape");
        go.transform.SetParent(joint, false);
        go.transform.localPosition = new Vector3(0f, 0f, TipInset(jointDiameter));
        var filter = go.AddComponent<MeshFilter>();
        filter.sharedMesh = ToeMesh.Create(jointDiameter * 0.7f, jointDiameter * 0.32f, 150f);
        var renderer = go.AddComponent<MeshRenderer>();
        renderer.sharedMaterial = limbMaterial;
        var collider = go.AddComponent<BoxCollider>();
        var bounds = filter.sharedMesh.bounds;
        collider.center = bounds.center;
        collider.size = new Vector3(bounds.size.x, Mathf.Max(bounds.size.y, 0.05f), bounds.size.z);
        go.AddComponent<BodyPart>().Bind(joint.GetComponent<JointControl>());
        parts.Add(name + ".Shape", go.transform);
    }

    void PlantFeet()
    {
        var bounds = new Bounds(transform.position, Vector3.zero);
        bool started = false;
        foreach (var renderer in GetComponentsInChildren<Renderer>())
        {
            if (!started)
            {
                bounds = renderer.bounds;
                started = true;
            }
            else
            {
                bounds.Encapsulate(renderer.bounds);
            }
        }

        if (!started)
            return;

        var position = transform.position;
        position.y += 0.005f - bounds.min.y;
        transform.position = position;
    }

    static void ReplaceWithBoxCollider(GameObject go)
    {
        var existing = go.GetComponent<Collider>();
        if (existing != null)
            DestroyImmediate(existing);
        var collider = go.AddComponent<BoxCollider>();
        collider.center = Vector3.zero;
        collider.size = Vector3.one * 1.15f;
    }

    static float TipInset(float diameter)
    {
        return diameter * JointScale * (0.5f - Overlap);
    }

    static float Span(float fromDiameter, float toDiameter, float length)
    {
        return TipInset(fromDiameter) + length + TipInset(toDiameter);
    }

    static Quaternion AlignLongAxis(Vector3 direction, Vector3 upHint)
    {
        var along = direction.normalized;
        var side = Vector3.Cross(upHint, along);
        if (side.sqrMagnitude < 0.0001f)
            side = Vector3.Cross(Vector3.forward, along);
        side.Normalize();
        var depth = Vector3.Cross(side, along);
        return Quaternion.LookRotation(depth, along);
    }

    static void Paint(GameObject go, Material material)
    {
        go.GetComponent<Renderer>().sharedMaterial = material;
    }

    Material MakeMaterial(Color color)
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null)
            shader = Shader.Find("Standard");
        var material = new Material(shader);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
        if (material.HasProperty("_Smoothness"))
            material.SetFloat("_Smoothness", 0.18f);
        if (material.HasProperty("_Metallic"))
            material.SetFloat("_Metallic", 0f);
        return material;
    }

    static void DestroyNow(Object target)
    {
        if (Application.isPlaying)
            Destroy(target);
        else
            DestroyImmediate(target);
    }
}
