using UnityEngine;

public class ViewBar : MonoBehaviour
{
    public OrbitCamera orbit;
    public bool ControlsVisible;

    const float Height = 26f;
    const float Gap = 4f;
    const float Left = 20f;
    const float Top = 20f;
    const float ToggleWidth = 72f;

    static readonly View[] Views =
    {
        new View("Front", 52f, 0f, -12f),
        new View("Left", 46f, -90f, -12f),
        new View("Right", 52f, 90f, -12f),
        new View("Back", 48f, 180f, -12f),
        new View("Top", 44f, 0f, -89f)
    };

    public bool Contains(Vector2 mouseFromBottom)
    {
        var gui = new Vector2(mouseFromBottom.x, Screen.height - mouseFromBottom.y);
        if (ToggleRect().Contains(gui))
            return true;
        return ControlsVisible && Row().Contains(gui);
    }

    void OnGUI()
    {
        if (orbit == null)
            return;

        if (FigureButtons.Button(ToggleRect(), ControlsVisible ? "Hide" : "Views"))
            ControlsVisible = !ControlsVisible;
        if (!ControlsVisible)
            return;

        var row = Row();
        float x = row.x;
        foreach (var view in Views)
        {
            if (FigureButtons.Button(new Rect(x, row.y, view.Width, Height), view.Label))
                orbit.Look(view.Yaw, view.Pitch);
            x += view.Width + Gap;
        }
    }

    Rect ToggleRect()
    {
        return new Rect(Left, Top, ToggleWidth, Height);
    }

    Rect Row()
    {
        float width = 0f;
        foreach (var view in Views)
            width += view.Width;
        width += Gap * (Views.Length - 1);
        return new Rect(Left + ToggleWidth + Gap, Top, width, Height);
    }

    struct View
    {
        public string Label;
        public float Width;
        public float Yaw;
        public float Pitch;

        public View(string label, float width, float yaw, float pitch)
        {
            Label = label;
            Width = width;
            Yaw = yaw;
            Pitch = pitch;
        }
    }
}
