using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;

public class FigureStage : MonoBehaviour
{
    CuteFigure figure;
    OrbitCamera orbit;
    Camera cam;
    JointControl grabbed;
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
            if (Physics.Raycast(ray, out var hit, 80f))
            {
                grabbed = hit.collider.GetComponentInParent<JointControl>();
                orbiting = grabbed == null;
            }
            else
            {
                grabbed = null;
                orbiting = true;
            }
        }

        if (mouse.leftButton.wasReleasedThisFrame)
        {
            grabbed = null;
            orbiting = false;
        }

        var delta = mouse.delta.ReadValue();
        if (grabbed != null)
            grabbed.Drag(delta, cam);
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
            "Drag a blue joint to bend it. Drag the background to turn.", hintStyle);
    }
}
