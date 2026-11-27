using UnityEngine;

public class MovementBar : MonoBehaviour
{
    public MovementPlayer player;

    const float Height = 26f;
    const float MenuWidth = 196f;
    const float PlayWidth = 64f;
    const float Arrow = 26f;
    const float Gap = 6f;
    const float Margin = 20f;

    bool open;

    public void Close()
    {
        open = false;
    }

    public bool Contains(Vector2 mouseFromBottom)
    {
        var gui = new Vector2(mouseFromBottom.x, Screen.height - mouseFromBottom.y);
        return Hit().Contains(gui);
    }

    void OnGUI()
    {
        if (player == null)
            return;

        Rect left;
        Rect menu;
        Rect right;
        Rect play;
        Place(out left, out menu, out right, out play);
        var names = player.Names;
        if (open)
        {
            for (int i = 0; i < names.Length; i++)
            {
                float y = menu.y - 4f - (names.Length - i) * (Height + 2f) + 2f;
                if (!FigureButtons.Button(new Rect(menu.x, y, menu.width, Height), names[i]))
                    continue;
                player.Select(i);
                open = false;
            }
        }

        if (FigureButtons.Triangle(left, false))
        {
            open = false;
            player.Step(-1);
        }

        if (FigureButtons.Button(menu, names[player.Index]))
            open = !open;

        if (FigureButtons.Triangle(right, true))
        {
            open = false;
            player.Step(1);
        }

        if (FigureButtons.Button(play, player.IsPlaying ? "Pause" : "Play"))
        {
            open = false;
            player.Toggle();
        }
    }

    Rect Hit()
    {
        Rect left;
        Rect menu;
        Rect right;
        Rect play;
        Place(out left, out menu, out right, out play);
        float top = menu.y;
        float height = Height;
        if (open && player != null)
        {
            float list = player.Names.Length * (Height + 2f) + 2f;
            top = menu.y - list;
            height = play.yMax - top;
        }

        return new Rect(left.x, top, play.xMax - left.x, height);
    }

    void Place(out Rect left, out Rect menu, out Rect right, out Rect play)
    {
        float y = Screen.height - Margin - Height;
        float total = Arrow + Gap + MenuWidth + Gap + Arrow + Gap + PlayWidth;
        float x = (Screen.width - total) * 0.5f;
        left = new Rect(x, y, Arrow, Height);
        menu = new Rect(left.xMax + Gap, y, MenuWidth, Height);
        right = new Rect(menu.xMax + Gap, y, Arrow, Height);
        play = new Rect(right.xMax + Gap, y, PlayWidth, Height);
    }
}

static class FigureButtons
{
    const int Radius = 10;

    static Texture2D face;
    static Texture2D pointLeft;
    static Texture2D pointRight;
    static GUIStyle background;
    static GUIStyle ink;
    static GUIStyle heading;
    static GUIStyle plain;

    public static bool Button(Rect rect, string text)
    {
        Ensure();
        var tint = GUI.color;
        var content = GUI.contentColor;
        var plate = GUI.backgroundColor;
        GUI.color = Color.white;
        GUI.backgroundColor = Color.white;
        GUI.contentColor = Color.black;
        bool hit = GUI.Button(rect, GUIContent.none, background);
        GUI.Label(rect, text, ink);
        GUI.color = tint;
        GUI.contentColor = content;
        GUI.backgroundColor = plate;
        return hit;
    }

    public static void Panel(Rect rect)
    {
        Ensure();
        var tint = GUI.color;
        GUI.color = Color.white;
        var shadow = new Rect(rect.x + 1f, rect.y + 3f, rect.width, rect.height);
        GUI.DrawTexture(shadow, Texture2D.whiteTexture, ScaleMode.StretchToFill, true, 0f, new Color(0f, 0f, 0f, 0.15f), 0f, Radius);
        GUI.Box(rect, GUIContent.none, background);
        GUI.color = tint;
    }

    public static void Text(Rect rect, string text, bool bold)
    {
        Ensure();
        var content = GUI.contentColor;
        GUI.contentColor = Color.black;
        GUI.Label(rect, text, bold ? heading : plain);
        GUI.contentColor = content;
    }

    public static bool Triangle(Rect rect, bool pointToRight)
    {
        Ensure();
        var tint = GUI.color;
        var plate = GUI.backgroundColor;
        GUI.color = Color.white;
        GUI.backgroundColor = Color.white;
        bool hit = GUI.Button(rect, GUIContent.none, background);
        var mark = new Rect(rect.x + 6f, rect.y + 6f, rect.width - 12f, rect.height - 12f);
        GUI.DrawTexture(mark, pointToRight ? pointRight : pointLeft);
        GUI.color = tint;
        GUI.backgroundColor = plate;
        return hit;
    }

    static void Ensure()
    {
        if (face != null)
            return;

        const int size = 48;
        face = new Texture2D(size, size, TextureFormat.RGBA32, false);
        face.wrapMode = TextureWrapMode.Clamp;
        face.filterMode = FilterMode.Bilinear;
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float dx = 0f;
                float dy = 0f;
                if (x < Radius)
                    dx = Radius - x;
                else if (x >= size - Radius)
                    dx = x - (size - Radius - 1);
                if (y < Radius)
                    dy = Radius - y;
                else if (y >= size - Radius)
                    dy = y - (size - Radius - 1);
                float outside = Mathf.Sqrt(dx * dx + dy * dy) - Radius;
                float alpha = Mathf.Clamp01(0.75f - outside);
                face.SetPixel(x, y, new Color(1f, 1f, 1f, alpha));
            }
        }

        face.Apply();
        pointLeft = TriangleTexture(false);
        pointRight = TriangleTexture(true);
        background = new GUIStyle
        {
            border = new RectOffset(Radius, Radius, Radius, Radius)
        };
        Paint(background.normal);
        Paint(background.hover);
        Paint(background.active);
        Paint(background.focused);
        Paint(background.onNormal);
        Paint(background.onHover);
        Paint(background.onActive);
        Paint(background.onFocused);

        ink = new GUIStyle
        {
            fontSize = 13,
            fontStyle = FontStyle.Bold,
            alignment = TextAnchor.MiddleCenter,
            clipping = TextClipping.Clip
        };
        var black = new Color(0f, 0f, 0f, 1f);
        ink.normal.textColor = black;
        ink.hover.textColor = black;
        ink.active.textColor = black;
        ink.focused.textColor = black;
        ink.onNormal.textColor = black;
        ink.onHover.textColor = black;
        ink.onActive.textColor = black;
        ink.onFocused.textColor = black;

        heading = new GUIStyle
        {
            fontSize = 14,
            fontStyle = FontStyle.Bold,
            alignment = TextAnchor.MiddleLeft
        };
        heading.normal.textColor = black;
        plain = new GUIStyle
        {
            fontSize = 12,
            alignment = TextAnchor.MiddleLeft
        };
        plain.normal.textColor = black;
    }

    static Texture2D TriangleTexture(bool pointToRight)
    {
        const int size = 32;
        var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.filterMode = FilterMode.Bilinear;
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float across = x / (size - 1f);
                float up = y / (size - 1f);
                float towardTip = pointToRight ? across : 1f - across;
                float half = (1f - towardTip) * 0.5f;
                bool inside = Mathf.Abs(up - 0.5f) <= half;
                tex.SetPixel(x, y, inside ? Color.black : new Color(0f, 0f, 0f, 0f));
            }
        }

        tex.Apply();
        return tex;
    }

    static void Paint(GUIStyleState state)
    {
        state.background = face;
        state.textColor = new Color(0f, 0f, 0f, 1f);
    }
}
