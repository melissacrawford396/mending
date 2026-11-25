using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;

public class FigureStage : MonoBehaviour
{
    CuteFigure figure;
    OrbitCamera orbit;
    Camera cam;
    RangeGuide range;
    JointControl selected;
    JointControl dragging;
    bool orbiting;
    GUIStyle hintStyle;

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
        cam.backgroundColor = new Color(0.96f, 0.93f, 0.88f);
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

        RenderSettings.ambientMode = AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(0.62f, 0.59f, 0.54f);

        var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Ground";
        Destroy(ground.GetComponent<Collider>());
        ground.transform.position = new Vector3(0f, -0.01f, 0.08f);
        ground.transform.localScale = new Vector3(3.2f, 0.02f, 3.2f);
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null)
            shader = Shader.Find("Standard");
        var material = new Material(shader);
        var color = new Color(0.9f, 0.86f, 0.8f);
        material.SetColor("_BaseColor", color);
        material.SetFloat("_Smoothness", 0.05f);
        ground.GetComponent<Renderer>().sharedMaterial = material;
    }

    void Update()
    {
        var mouse = Mouse.current;
        if (mouse == null || cam == null)
            return;

        if (mouse.leftButton.wasPressedThisFrame)
        {
            var ray = cam.ScreenPointToRay(mouse.position.ReadValue());
            var hits = Physics.RaycastAll(ray, 80f);
            System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));

            JointKnob knob = null;
            BodyPart part = null;
            float knobDistance = float.PositiveInfinity;
            float partDistance = float.PositiveInfinity;
            foreach (var hit in hits)
            {
                var hitKnob = hit.collider.GetComponent<JointKnob>();
                if (hitKnob != null && hit.distance < knobDistance)
                {
                    knob = hitKnob;
                    knobDistance = hit.distance;
                }

                var hitPart = hit.collider.GetComponent<BodyPart>();
                if (hitPart != null && hit.distance < partDistance)
                {
                    part = hitPart;
                    partDistance = hit.distance;
                }
            }

            bool knobFirst = knob != null && knobDistance <= partDistance + 0.012f;
            if (knobFirst)
            {
                Select(knob.Joint);
                dragging = null;
                orbiting = false;
            }
            else if (part != null && selected != null && part.transform.IsChildOf(selected.transform))
            {
                dragging = selected;
                range.Show(selected);
                orbiting = false;
            }
            else if (hits.Length == 0)
            {
                Select(null);
                dragging = null;
                orbiting = true;
            }
            else
            {
                dragging = null;
                orbiting = false;
            }
        }

        if (mouse.leftButton.wasReleasedThisFrame)
        {
            dragging = null;
            range.Hide();
            orbiting = false;
        }

        var delta = mouse.delta.ReadValue();
        if (dragging != null)
        {
            dragging.Drag(delta, cam);
            range.Show(dragging);
        }
        else if (orbiting)
            orbit.AddDelta(delta);

        float scroll = mouse.scroll.ReadValue().y;
        if (Mathf.Abs(scroll) > 0.01f)
            orbit.Zoom(scroll);
    }

    void OnGUI()
    {
        if (hintStyle == null)
        {
            hintStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = 16,
                alignment = TextAnchor.LowerCenter
            };
            hintStyle.normal.textColor = new Color(0.28f, 0.3f, 0.34f);
        }

        GUI.Label(new Rect(0f, Screen.height - 52f, Screen.width, 36f),
            "Click a blue joint, then drag an outlined part. Drag the background to turn.", hintStyle);
    }

    void Select(JointControl joint)
    {
        selected = joint;
        foreach (var part in figure.GetComponentsInChildren<BodyPart>(true))
            part.SetOutlined(joint != null && part.transform.IsChildOf(joint.transform));
        foreach (var knob in figure.GetComponentsInChildren<JointKnob>(true))
            knob.SetHighlighted(joint != null && knob.Joint == joint);
        if (joint == null)
            range.Hide();
    }
}
