using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FigureStage : MonoBehaviour
{
    CuteFigure figure;
    OrbitCamera orbit;
    Camera cam;
    RangeGuide range;
    OrbitPad pad;
    ViewBar views;
    MovementPlayer player;
    MovementBar movements;
    ColorMenu colors;
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
        cam.backgroundColor = new Color(0.19f, 0.19f, 0.19f);
        cam.fieldOfView = 32f;
        cam.nearClipPlane = 0.05f;
        cam.GetUniversalAdditionalCameraData().renderPostProcessing = false;

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
        pad.views = views;
        player = gameObject.AddComponent<MovementPlayer>();
        player.Bind(figure, orbit);
        movements = gameObject.AddComponent<MovementBar>();
        movements.player = player;

        RenderSettings.ambientMode = AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.92f, 0.95f, 1f);
        foreach (var sceneLight in FindObjectsByType<Light>(FindObjectsSortMode.None))
        {
            if (sceneLight.type == LightType.Directional)
                sceneLight.intensity = 1.3f;
        }

        var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Ground";
        Destroy(ground.GetComponent<Collider>());
        ground.transform.position = new Vector3(0f, -0.02f, 0.08f);
        ground.transform.localScale = new Vector3(4.4f, 0.012f, 4.4f);
        var floor = SeeThroughFloor();
        ground.GetComponent<Renderer>().sharedMaterial = floor;

        colors = gameObject.AddComponent<ColorMenu>();
        colors.Bind(figure, cam, floor);
    }

    static Material SeeThroughFloor()
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null)
            shader = Shader.Find("Standard");
        var material = new Material(shader);
        var color = new Color(0.77f, 0.9f, 0.93f, 0.92f);
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
        var carpet = CarpetTexture();
        var tiles = new Vector2(6f, 6f);
        if (material.HasProperty("_BaseMap"))
        {
            material.SetTexture("_BaseMap", carpet);
            material.SetTextureScale("_BaseMap", tiles);
        }
        if (material.HasProperty("_MainTex"))
        {
            material.SetTexture("_MainTex", carpet);
            material.SetTextureScale("_MainTex", tiles);
        }
        if (material.HasProperty("_Smoothness"))
            material.SetFloat("_Smoothness", 0f);
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

    static Texture2D CarpetTexture()
    {
        const int size = 256;
        const int tuftCells = 64;
        const int patchCells = 8;
        var texture = new Texture2D(size, size, TextureFormat.RGBA32, true);
        texture.name = "Carpet";
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Trilinear;
        texture.anisoLevel = 4;
        var random = new System.Random(7);
        var tufts = Lattice(random, tuftCells);
        var patches = Lattice(random, patchCells);
        var pixels = new Color32[size * size];
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float tuft = Smooth(tufts, tuftCells, x * (float)tuftCells / size, y * (float)tuftCells / size);
                float patch = Smooth(patches, patchCells, x * (float)patchCells / size, y * (float)patchCells / size);
                float fiber = (float)random.NextDouble();
                float shade = Mathf.Clamp01(0.8f + tuft * 0.1f + patch * 0.05f + fiber * 0.07f);
                byte value = (byte)(shade * 255f);
                pixels[y * size + x] = new Color32(value, value, value, 255);
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply(true);
        return texture;
    }

    static float[] Lattice(System.Random random, int cells)
    {
        var values = new float[cells * cells];
        for (int i = 0; i < values.Length; i++)
            values[i] = (float)random.NextDouble();
        return values;
    }

    static float Smooth(float[] lattice, int cells, float u, float v)
    {
        int x0 = Mathf.FloorToInt(u);
        int y0 = Mathf.FloorToInt(v);
        float fx = u - x0;
        float fy = v - y0;
        fx = fx * fx * (3f - 2f * fx);
        fy = fy * fy * (3f - 2f * fy);
        int x1 = (x0 + 1) % cells;
        int y1 = (y0 + 1) % cells;
        x0 %= cells;
        y0 %= cells;
        float bottom = Mathf.Lerp(lattice[y0 * cells + x0], lattice[y0 * cells + x1], fx);
        float top = Mathf.Lerp(lattice[y1 * cells + x0], lattice[y1 * cells + x1], fx);
        return Mathf.Lerp(bottom, top, fy);
    }

    void Update()
    {
        var mouse = Mouse.current;
        if (mouse == null || cam == null)
            return;

        var mousePosition = mouse.position.ReadValue();
        if (views != null && !views.ControlsVisible && padDrag)
        {
            padDrag = false;
            pad.Release();
        }

        bool onPad = pad != null && pad.Contains(mousePosition);
        bool onViews = views != null && views.Contains(mousePosition);
        bool onMoves = movements != null && movements.Contains(mousePosition);
        bool onColors = colors != null && colors.Contains(mousePosition);
        bool playing = player != null && player.IsPlaying;

        if (mouse.leftButton.wasPressedThisFrame && !onMoves && movements != null)
            movements.Close();
        if (mouse.leftButton.wasPressedThisFrame && !onColors && colors != null)
            colors.Close();

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
            else if (onViews || onMoves || onColors)
            {
                orbiting = false;
                dragging = null;
                dragLower = false;
                range.Hide();
                ShowLimb(null, null);
            }
            else if (!playing && Pick(mousePosition, out var part, out var knob, out _))
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
        else if (!playing && dragging != null && mouse.leftButton.isPressed)
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
        else if (onPad || onViews || onMoves || onColors)
        {
            ShowLimb(null, null);
        }
        else
        {
            Hover(mousePosition);
        }

        if (player != null)
            player.Tick(Time.deltaTime);

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
