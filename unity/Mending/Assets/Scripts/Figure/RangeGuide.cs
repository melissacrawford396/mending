using UnityEngine;
using UnityEngine.Rendering;

public class RangeGuide : MonoBehaviour
{
    const int Segments = 28;

    LineRenderer swing;
    LineRenderer lift;

    void Awake()
    {
        swing = CreateLine("SwingRange");
        lift = CreateLine("RaiseRange");
        gameObject.SetActive(false);
    }

    public void Show(JointControl joint)
    {
        gameObject.SetActive(true);
        float radius = Mathf.Max(joint.ballRadius * 2.6f, 0.11f);
        Fill(swing, joint, radius, true);
        if (joint.kind == JointControl.Kind.TwoAxis)
        {
            lift.gameObject.SetActive(true);
            Fill(lift, joint, radius, false);
        }
        else
        {
            lift.gameObject.SetActive(false);
        }
    }

    public void Hide()
    {
        gameObject.SetActive(false);
    }

    void Fill(LineRenderer line, JointControl joint, float radius, bool swingAxis)
    {
        float from = swingAxis ? joint.hingeMin : joint.raiseMin;
        float to = swingAxis ? joint.hingeMax : joint.raiseMax;
        line.positionCount = Segments;
        for (int i = 0; i < Segments; i++)
        {
            float t = i / (float)(Segments - 1);
            float angle = Mathf.Lerp(from, to, t);
            float hinge = swingAxis ? angle : joint.hinge;
            float raise = swingAxis ? joint.raise : angle;
            line.SetPosition(i, Point(joint, hinge, raise, radius));
        }
    }

    static Vector3 Point(JointControl joint, float hinge, float raise, float radius)
    {
        var rotation = joint.kind == JointControl.Kind.Hinge
            ? Quaternion.AngleAxis(hinge, joint.hingeAxis)
            : Quaternion.AngleAxis(raise, joint.raiseAxis) * Quaternion.AngleAxis(hinge, joint.hingeAxis);
        var local = joint.transform.localPosition + rotation * (joint.restDirection.normalized * radius);
        return joint.transform.parent.TransformPoint(local);
    }

    LineRenderer CreateLine(string name)
    {
        var go = new GameObject(name);
        var line = go.AddComponent<LineRenderer>();
        line.useWorldSpace = true;
        line.loop = false;
        line.widthMultiplier = 0.008f;
        line.numCapVertices = 4;
        line.numCornerVertices = 2;
        line.shadowCastingMode = ShadowCastingMode.Off;
        line.receiveShadows = false;
        line.positionCount = 0;
        go.transform.SetParent(transform, false);

        var shader = Shader.Find("Universal Render Pipeline/Unlit");
        if (shader == null)
            shader = Shader.Find("Sprites/Default");
        var material = new Material(shader);
        var color = new Color(0.16f, 0.38f, 0.82f);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
        line.material = material;
        line.startColor = color;
        line.endColor = color;
        return line;
    }
}
