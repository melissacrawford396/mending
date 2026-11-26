using System.Collections.Generic;
using UnityEngine;

public class CuteFigure : MonoBehaviour
{
    const float Arm = 0.125f;
    const float Leg = 0.15f;
    const float NeckWidth = 0.1f;
    const float HeadRadius = 0.21f;
    const float Overlap = 0.05f;
    const float JointScale = 0.7f;

    readonly Dictionary<string, JointControl> joints = new Dictionary<string, JointControl>();
    readonly Dictionary<string, Transform> parts = new Dictionary<string, Transform>();

    Material limbMaterial;
    Material jointMaterial;
    Material eyeMaterial;
    Material sparkleMaterial;

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
        eyeMaterial = MakeFlat(new Color(0.08f, 0.08f, 0.09f));
        sparkleMaterial = MakeFlat(new Color(0.96f, 0.97f, 0.98f));

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

        var neck = AddJoint("Neck", waist, new Vector3(0f, torsoLocalY + 0.13f, 0f), NeckWidth, JointControl.Kind.Hinge,
            Vector3.right, new Vector2(-20f, 35f), Vector3.forward, Vector2.zero, Vector3.up);
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
        const float shoulderDiameter = 0.16f;
        const float elbowDiameter = 0.11f;
        const float wristDiameter = 0.075f;
        var shoulder = AddJoint("Shoulder." + Side(left), chest, new Vector3(0.22f * side, torsoLocalY + 0.08f, 0f), shoulderDiameter,
            JointControl.Kind.TwoAxis, Vector3.left, new Vector2(-30f, 170f), raiseAxis, new Vector2(0f, 160f), Vector3.down);
        AddLimb(shoulder, "UpperArm." + Side(left), Vector3.down, 0.18f, shoulderDiameter, Arm, Arm * 0.72f);
        var elbow = AddJoint("Elbow." + Side(left), shoulder, Vector3.down * Span(shoulderDiameter, elbowDiameter, 0.18f), elbowDiameter,
            JointControl.Kind.Hinge, Vector3.left, new Vector2(0f, 150f), Vector3.forward, Vector2.zero, Vector3.down);

        AddLimb(elbow, "Forearm." + Side(left), Vector3.down, 0.16f, elbowDiameter, Arm, Arm * 0.72f);
        var wrist = AddJoint("Wrist." + Side(left), elbow, Vector3.down * Span(elbowDiameter, wristDiameter, 0.16f), wristDiameter,
            JointControl.Kind.Hinge, Vector3.left, new Vector2(-30f, 50f), Vector3.forward, Vector2.zero, Vector3.down);
        AddLimb(wrist, "Hand." + Side(left), Vector3.down, 0.1f, wristDiameter, Arm, Arm * 0.62f);

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
        const float hipDiameter = 0.19f;
        const float kneeDiameter = 0.13f;
        const float ankleDiameter = 0.09f;
        const float footLength = 0.24f;
        const float footWidth = 0.12f;
        var hip = AddJoint("Hip." + Side(left), transform, new Vector3(0.11f * side, -0.02f, 0f), hipDiameter,
            JointControl.Kind.TwoAxis, Vector3.left, new Vector2(-20f, 100f), raiseAxis, new Vector2(0f, 60f), Vector3.down);
        AddLimb(hip, "Thigh." + Side(left), Vector3.down, 0.2f, hipDiameter, Leg, Leg * 0.75f);
        var knee = AddJoint("Knee." + Side(left), hip, Vector3.down * Span(hipDiameter, kneeDiameter, 0.2f), kneeDiameter,
            JointControl.Kind.Hinge, Vector3.right, new Vector2(0f, 150f), Vector3.forward, Vector2.zero, Vector3.down);

        AddLimb(knee, "Shin." + Side(left), Vector3.down, 0.18f, kneeDiameter, Leg, Leg * 0.72f);
        var ankle = AddJoint("Ankle." + Side(left), knee, Vector3.down * Span(kneeDiameter, ankleDiameter, 0.18f), ankleDiameter,
            JointControl.Kind.Hinge, Vector3.right, new Vector2(-25f, 50f), Vector3.forward, Vector2.zero, Vector3.forward);

        AddLimb(ankle, "Foot." + Side(left), Vector3.forward, footLength, ankleDiameter, footWidth, 0.04f, true);
        AddToes(ankle, left, ankleDiameter, footLength);

        string sideName = left ? "L" : "R";
        int first = left ? 9 : 17;
        Tag(hip, first, sideName + " Hip");
        Tag(knee, first + 1, sideName + " Knee");
        Tag(ankle, first + 2, sideName + " Ankle");
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

    void AddLimb(Transform joint, string name, Vector3 direction, float length, float jointDiameter, float width, float depth, bool box = false)
    {
        var oval = GameObject.CreatePrimitive(box ? PrimitiveType.Cube : PrimitiveType.Sphere);
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
        float ballRadius = NeckWidth * JointScale * 0.5f;
        var pivot = new GameObject("Head");
        pivot.transform.SetParent(neck, false);
        pivot.transform.localPosition = Vector3.up * (HeadRadius - ballRadius * 0.35f);

        var skull = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        skull.name = "Head.Shape";
        skull.AddComponent<BodyPart>().Bind(neck.GetComponent<JointControl>());
        skull.transform.SetParent(pivot.transform, false);
        skull.transform.localScale = Vector3.one * HeadRadius * 2f;
        Paint(skull, limbMaterial);

        AddEye(pivot.transform, -1f);
        AddEye(pivot.transform, 1f);
        AddSmile(pivot.transform);
        parts.Add("Head", pivot.transform);
    }

    void AddEye(Transform head, float side)
    {
        float x = 0.078f * side;
        float y = 0.05f;
        float surface = Mathf.Sqrt(Mathf.Max(0.0001f, HeadRadius * HeadRadius - x * x - y * y));
        var eye = new GameObject(side < 0f ? "Eye.L" : "Eye.R");
        eye.transform.SetParent(head, false);
        eye.transform.localPosition = new Vector3(x, y, surface + 0.012f);
        AddDisc(eye.transform, "Ring", 0.118f, 0f, eyeMaterial);
        AddDisc(eye.transform, "White", 0.1f, 0.006f, sparkleMaterial);
        AddDisc(eye.transform, "Pupil", 0.055f, 0.012f, eyeMaterial);
    }

    void AddDisc(Transform parent, string name, float diameter, float forward, Material material)
    {
        var disc = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        disc.name = name;
        DestroyNow(disc.GetComponent<Collider>());
        disc.transform.SetParent(parent, false);
        disc.transform.localPosition = new Vector3(0f, 0f, forward);
        disc.transform.localScale = new Vector3(diameter, diameter, 0.01f);
        Paint(disc, material);
    }

    void AddSmile(Transform head)
    {
        var smile = new GameObject("Smile");
        smile.transform.SetParent(head, false);
        smile.transform.localPosition = new Vector3(0f, -0.02f, HeadRadius + 0.008f);
        var filter = smile.AddComponent<MeshFilter>();
        filter.sharedMesh = SmileArc(0.05f, 0.008f, 130f);
        smile.AddComponent<MeshRenderer>().sharedMaterial = eyeMaterial;
    }

    static Mesh SmileArc(float radius, float thickness, float degrees)
    {
        const int segments = 14;
        float half = degrees * 0.5f * Mathf.Deg2Rad;
        var vertices = new List<Vector3>();
        var triangles = new List<int>();
        float inner = radius - thickness * 0.5f;
        float outer = radius + thickness * 0.5f;
        for (int i = 0; i <= segments; i++)
        {
            float angle = -Mathf.PI * 0.5f + Mathf.Lerp(-half, half, i / (float)segments);
            float x = Mathf.Cos(angle);
            float y = Mathf.Sin(angle);
            vertices.Add(new Vector3(x * inner, y * inner, 0f));
            vertices.Add(new Vector3(x * outer, y * outer, 0f));
        }

        for (int i = 0; i < segments; i++)
        {
            int a = i * 2;
            int b = a + 1;
            int c = a + 2;
            int d = a + 3;
            triangles.Add(a);
            triangles.Add(c);
            triangles.Add(b);
            triangles.Add(b);
            triangles.Add(c);
            triangles.Add(d);
            triangles.Add(a);
            triangles.Add(b);
            triangles.Add(c);
            triangles.Add(b);
            triangles.Add(d);
            triangles.Add(c);
        }

        var mesh = new Mesh { name = "Smile" };
        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
        return mesh;
    }

    void AddToes(Transform ankle, bool left, float ankleDiameter, float footLength)
    {
        float medial = left ? 1f : -1f;
        float front = TipInset(ankleDiameter) + footLength;
        float[] fromMedial = { 0.04f, 0.02f, 0f, -0.02f, -0.04f };
        float[] width = { 0.024f, 0.018f, 0.016f, 0.015f, 0.014f };
        const float jointSize = 0.016f;
        const float toeLength = 0.02f;
        string sideName = left ? "L" : "R";
        int first = left ? 12 : 20;
        for (int i = 0; i < 5; i++)
        {
            var toe = AddJoint("Toe." + Side(left) + "." + (i + 1), ankle, new Vector3(medial * fromMedial[i], -0.006f, front - 0.004f), jointSize,
                JointControl.Kind.Hinge, Vector3.right, new Vector2(-20f, 40f), Vector3.forward, Vector2.zero, Vector3.forward);
            AddLimb(toe, "Toe." + Side(left) + "." + (i + 1), Vector3.forward, toeLength, jointSize, width[i], 0.014f, true);
            Tag(toe, first + i, sideName + " Toe " + (i + 1));
        }
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
            material.SetFloat("_Smoothness", 0.02f);
        if (material.HasProperty("_Metallic"))
            material.SetFloat("_Metallic", 0f);
        return material;
    }

    Material MakeFlat(Color color)
    {
        var shader = Shader.Find("Universal Render Pipeline/Unlit");
        if (shader == null)
            shader = Shader.Find("Unlit/Color");
        if (shader == null)
            return MakeMaterial(color);
        var material = new Material(shader);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
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
