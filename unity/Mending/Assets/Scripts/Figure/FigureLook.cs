using UnityEngine;
using UnityEngine.Rendering;

public class BodyPart : MonoBehaviour
{
    public JointControl joint;
    public bool movesParent;

    GameObject outline;

    public void Bind(JointControl driven, bool parentMoves = false)
    {
        joint = driven;
        movesParent = parentMoves;
    }

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
    bool hoverOn;
    bool marked;

    public void Bind(JointControl joint)
    {
        Joint = joint;
        knobRenderer = GetComponent<Renderer>();
    }

    public void SetHighlighted(bool on)
    {
        hoverOn = on;
        Refresh();
    }

    public void SetMarked(bool on)
    {
        marked = on;
        Refresh();
    }

    void Refresh()
    {
        if (knobRenderer == null)
            knobRenderer = GetComponent<Renderer>();

        bool on = hoverOn || marked;
        if (on)
        {
            if (block == null)
                block = new MaterialPropertyBlock();
            var color = marked ? new Color(1f, 0.86f, 0.12f) : new Color(0.72f, 0.9f, 1f);
            knobRenderer.GetPropertyBlock(block);
            block.SetColor("_BaseColor", color);
            block.SetColor("_Color", color);
            knobRenderer.SetPropertyBlock(block);
            EnsureOutline();
            outline.GetComponent<Renderer>().sharedMaterial = marked ? FigureLook.MarkedOutline() : FigureLook.JointOutline();
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
    static Material markedOutline;
    static Material limbEdge;
    static Material toeEdge;

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

    public static void AttachEdge(GameObject part, bool small = false)
    {
        var source = part.GetComponent<MeshFilter>();
        if (source == null || source.sharedMesh == null)
            return;

        var edge = new GameObject("Edge");
        edge.transform.SetParent(part.transform, false);
        edge.AddComponent<MeshFilter>().sharedMesh = source.sharedMesh;
        var renderer = edge.AddComponent<MeshRenderer>();
        int count = Mathf.Max(1, source.sharedMesh.subMeshCount);
        var materials = new Material[count];
        var material = small ? ToeEdge() : LimbEdge();
        for (int i = 0; i < count; i++)
            materials[i] = material;
        renderer.sharedMaterials = materials;
        renderer.shadowCastingMode = ShadowCastingMode.Off;
        renderer.receiveShadows = false;
    }

    public static Material LimbEdge()
    {
        if (limbEdge == null)
            limbEdge = Outline(Color.black, 0.0055f);
        return limbEdge;
    }

    public static Material ToeEdge()
    {
        if (toeEdge == null)
            toeEdge = Outline(Color.black, 0.0018f);
        return toeEdge;
    }

    public static Material MarkedOutline()
    {
        if (markedOutline == null)
            markedOutline = Outline(new Color(1f, 0.78f, 0.05f), 0.008f);
        return markedOutline;
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
