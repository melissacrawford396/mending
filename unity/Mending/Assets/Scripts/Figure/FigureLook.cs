using UnityEngine;
using UnityEngine.Rendering;

public class BodyPart : MonoBehaviour
{
    GameObject outline;

    public void SetOutlined(bool on)
    {
        if (on)
            EnsureOutline();
        if (outline != null)
            outline.SetActive(on);
    }

    void EnsureOutline()
    {
        if (outline != null)
            return;

        var source = GetComponent<MeshFilter>();
        outline = new GameObject("Outline");
        outline.transform.SetParent(transform, false);
        outline.AddComponent<MeshFilter>().sharedMesh = source.sharedMesh;
        var renderer = outline.AddComponent<MeshRenderer>();
        renderer.sharedMaterial = FigureLook.PartOutline();
        renderer.shadowCastingMode = ShadowCastingMode.Off;
        renderer.receiveShadows = false;
    }
}

public class JointKnob : MonoBehaviour
{
    public JointControl Joint { get; private set; }

    Renderer knobRenderer;
    MaterialPropertyBlock block;
    GameObject outline;

    public void Bind(JointControl joint)
    {
        Joint = joint;
        knobRenderer = GetComponent<Renderer>();
    }

    public void SetHighlighted(bool on)
    {
        if (knobRenderer == null)
            knobRenderer = GetComponent<Renderer>();

        if (on)
        {
            if (block == null)
                block = new MaterialPropertyBlock();
            var color = new Color(0.72f, 0.9f, 1f);
            knobRenderer.GetPropertyBlock(block);
            block.SetColor("_BaseColor", color);
            block.SetColor("_Color", color);
            knobRenderer.SetPropertyBlock(block);
            EnsureOutline();
        }
        else
        {
            knobRenderer.SetPropertyBlock(null);
        }

        if (outline != null)
            outline.SetActive(on);
    }

    void EnsureOutline()
    {
        if (outline != null)
            return;

        outline = new GameObject("Outline");
        outline.transform.SetParent(transform, false);
        outline.AddComponent<MeshFilter>().sharedMesh = GetComponent<MeshFilter>().sharedMesh;
        var renderer = outline.AddComponent<MeshRenderer>();
        renderer.sharedMaterial = FigureLook.JointOutline();
        renderer.shadowCastingMode = ShadowCastingMode.Off;
        renderer.receiveShadows = false;
    }
}

public static class FigureLook
{
    static Material partOutline;
    static Material jointOutline;

    public static Material PartOutline()
    {
        if (partOutline == null)
            partOutline = Outline(new Color(0.2f, 0.46f, 0.95f), 0.008f);
        return partOutline;
    }

    public static Material JointOutline()
    {
        if (jointOutline == null)
            jointOutline = Outline(new Color(0.85f, 0.94f, 1f), 0.006f);
        return jointOutline;
    }

    static Material Outline(Color color, float width)
    {
        var shader = Shader.Find("Mending/Outline");
        var material = new Material(shader);
        material.SetColor("_Color", color);
        material.SetFloat("_Width", width);
        return material;
    }
}
