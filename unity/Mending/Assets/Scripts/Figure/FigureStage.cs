using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;

public class FigureStage : MonoBehaviour
{
    CuteFigure figure;
    OrbitCamera orbit;
    Camera cam;
    RangeGuide range;
    OrbitPad pad;
    ViewBar views;
    BodyPart hovered;
    JointControl highlighted;
    JointControl dragging;
    bool dragLower;
    bool orbiting;
    bool padDrag;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot()
    {
        if (FindAnyObjectByType<FigureStage>() != null)
            return;

        var stage = new GameObject("Figure");
        stage.AddComponent<FigureStage>();
    }

    void Awake()
    {
        figure = gameObject.AddComponent<CuteFigure>();
        figure.Build();

        cam = Camera.main;
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = new Color(0.85f, 0.93f, 0.99f);
        cam.fieldOfView = 32f;
        cam.nearClipPlane = 0.05f;

        orbit = cam.gameObject.GetComponent<OrbitCamera>();
        if (orbit == null)
            orbit = cam.gameObject.AddComponent<OrbitCamera>();
        orbit.target = figure.Focus;
        orbit.Snap();

        var guide = new GameObject("RangeGuide");
        range = guide.AddComponent<RangeGuide>();
        range.Hide();

        pad = gameObject.AddComponent<OrbitPad>();
        views = gameObject.AddComponent<ViewBar>();
        views.orbit = orbit;

        RenderSettings.ambientMode = AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.55f, 0.57f, 0.6f);
        foreach (var sceneLight in FindObjectsByType<Light>(FindObjectsSortMode.None))
        {
            if (sceneLight.type == LightType.Directional)
                sceneLight.intensity = 0.4f;
        }

        var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Ground";
        Destroy(ground.GetComponent<Collider>());
        ground.transform.position = new Vector3(0f, -0.02f, 0.08f);
        ground.transform.localScale = new Vector3(4.4f, 0.012f, 4.4f);
        ground.GetComponent<Renderer>().sharedMaterial = SeeThroughFloor();
    }

    static Material SeeThroughFloor()
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null)
            shader = Shader.Find("Standard");
        var material = new Material(shader);
        var color = new Color(0.68f, 0.9f, 0.66f, 0.24f);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
        if (material.HasProperty("_Smoothness"))
            material.SetFloat("_Smoothness", 0.04f);
        if (material.HasProperty("_Surface"))
            material.SetFloat("_Surface", 1f);
        if (material.HasProperty("_Blend"))
            material.SetFloat("_Blend", 0f);
        if (material.HasProperty("_SrcBlend"))
            material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
        if (material.HasProperty("_DstBlend"))
            material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
        if (material.HasProperty("_ZWrite"))
            material.SetInt("_ZWrite", 0);
        if (material.HasProperty("_Cull"))
            material.SetInt("_Cull", (int)CullMode.Off);
        material.SetOverrideTag("RenderType", "Transparent");
        material.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
        material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        material.DisableKeyword("_ALPHATEST_ON");
        material.renderQueue = (int)RenderQueue.Transparent;
        return material;
    }

    void Update()
    {
        var mouse = Mouse.current;
        if (mouse == null || cam == null)
            return;

        var mousePosition = mouse.position.ReadValue();
        bool onPad = pad != null && pad.Contains(mousePosition);
        bool onViews = views != null && views.Contains(mousePosition);

        if (mouse.leftButton.wasPressedThisFrame)
        {
            if (onPad)
            {
                padDrag = true;
                orbiting = false;
                dragging = null;
                dragLower = false;
                range.Hide();
                ShowLimb(null, null);
            }
            else if (onViews)
            {
                orbiting = false;
                dragging = null;
                dragLower = false;
                range.Hide();
                ShowLimb(null, null);
            }
            else if (Pick(mousePosition, out var part, out var knob, out _))
            {
                orbiting = false;
                dragging = part != null ? part.joint : knob.Joint;
                dragLower = part != null && part.movesParent;
                ShowLimb(part, dragging);
                if (dragging != null)
                    range.Show(dragging);
            }
            else
            {
                dragging = null;
                dragLower = false;
                orbiting = true;
                range.Hide();
                ShowLimb(null, null);
            }
        }

        if (mouse.leftButton.wasReleasedThisFrame)
        {
            dragging = null;
            dragLower = false;
            orbiting = false;
            padDrag = false;
            pad.Release();
            range.Hide();
        }

        var delta = mouse.delta.ReadValue();
        if (padDrag && mouse.leftButton.isPressed)
        {
            pad.Pull(mousePosition);
            orbit.Hold(pad.Deflection(), Time.deltaTime);
        }
        else if (dragging != null && mouse.leftButton.isPressed)
        {
            if (dragLower)
                dragging.DragLower(delta, cam);
            else
                dragging.Drag(delta, cam);
            range.Show(dragging);
        }
        else if (orbiting && mouse.leftButton.isPressed)
        {
            orbit.AddDelta(delta);
        }
        else if (onPad || onViews)
        {
            ShowLimb(null, null);
        }
        else
        {
            Hover(mousePosition);
        }

        float scroll = mouse.scroll.ReadValue().y;
        if (Mathf.Abs(scroll) > 0.01f)
            orbit.Zoom(scroll);
    }

    void Hover(Vector2 screen)
    {
        if (!Pick(screen, out var part, out var knob, out _))
        {
            ShowLimb(null, null);
            return;
        }

        if (part != null)
            ShowLimb(part, part.joint);
        else
            ShowLimb(null, knob.Joint);
    }

    bool Pick(Vector2 screen, out BodyPart part, out JointKnob knob, out Vector3 point)
    {
        part = null;
        knob = null;
        point = Vector3.zero;
        var hits = Physics.RaycastAll(cam.ScreenPointToRay(screen), 80f);
        if (hits.Length == 0)
            return false;

        System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));
        float partDistance = float.PositiveInfinity;
        float knobDistance = float.PositiveInfinity;
        foreach (var hit in hits)
        {
            var hitPart = hit.collider.GetComponent<BodyPart>();
            if (hitPart != null && hit.distance < partDistance)
            {
                part = hitPart;
                point = hit.point;
                partDistance = hit.distance;
            }

            var hitKnob = hit.collider.GetComponent<JointKnob>();
            if (hitKnob != null && hit.distance < knobDistance)
            {
                knob = hitKnob;
                knobDistance = hit.distance;
            }
        }

        if (part != null && partDistance <= knobDistance + 0.01f)
        {
            knob = null;
            return true;
        }

        if (knob != null)
        {
            part = null;
            point = knob.transform.position;
            return true;
        }

        return false;
    }

    void ShowLimb(BodyPart part, JointControl joint)
    {
        if (hovered != part)
        {
            if (hovered != null)
                hovered.SetOutlined(false);
            hovered = part;
            if (hovered != null)
                hovered.SetOutlined(true);
        }

        if (highlighted == joint)
            return;

        if (highlighted != null)
        {
            var previous = highlighted.GetComponentInChildren<JointKnob>();
            if (previous != null)
                previous.SetHighlighted(false);
        }

        highlighted = joint;
        if (highlighted == null)
            return;

        var next = highlighted.GetComponentInChildren<JointKnob>();
        if (next != null)
            next.SetHighlighted(true);
    }
}
