using UnityEngine;

public class ViewBar : MonoBehaviour
{
    public OrbitCamera orbit;

    const float Height = 26f;
    const float Gap = 4f;
    const float Left = 20f;
    const float Top = 20f;

    static readonly View[] Views =
    {
        new View("Front", 52f, 0f, -12f),
        new View("Left", 46f, -90f, -12f),
        new View("Right", 52f, 90f, -12f),
        new View("Back", 48f, 180f, -12f),
        new View("Top", 44f, 0f, -89f)
    };

    GUIStyle style;

    public bool Contains(Vector2 mouseFromBottom)
    {
        var gui = new Vector2(mouseFromBottom.x, Screen.height - mouseFromBottom.y);
        return Row().Contains(gui);
    }

    void OnGUI()
    {
        if (orbit == null)
            return;

        EnsureStyle();
        var row = Row();
        float x = row.x;
        var previous = GUI.backgroundColor;
        GUI.backgroundColor = new Color(0.78f, 0.9f, 0.98f);
        foreach (var view in Views)
        {
            if (GUI.Button(new Rect(x, row.y, view.Width, Height), view.Label, style))
                orbit.Look(view.Yaw, view.Pitch);
            x += view.Width + Gap;
        }

        GUI.backgroundColor = previous;
    }

    Rect Row()
    {
        float width = 0f;
        foreach (var view in Views)
            width += view.Width;
        width += Gap * (Views.Length - 1);
        return new Rect(Left, Top, width, Height);
    }

    void EnsureStyle()
    {
        if (style != null)
            return;

        style = new GUIStyle(GUI.skin.button)
        {
            fontSize = 12,
            alignment = TextAnchor.MiddleCenter
        };
        var ink = Color.black;
        style.normal.textColor = ink;
        style.hover.textColor = ink;
        style.active.textColor = ink;
        style.focused.textColor = ink;
        style.onNormal.textColor = ink;
        style.onHover.textColor = ink;
        style.onActive.textColor = ink;
        style.onFocused.textColor = ink;
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
