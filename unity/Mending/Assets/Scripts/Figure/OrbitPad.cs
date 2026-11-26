using UnityEngine;

public class OrbitPad : MonoBehaviour
{
    const float Size = 96f;
    const float KnobSize = 22f;
    const float Margin = 20f;

    public bool active;

    Texture2D face;
    Texture2D knob;
    Vector2 pull;

    public bool Contains(Vector2 mouseFromBottom)
    {
        return (ToGui(mouseFromBottom) - Center()).sqrMagnitude <= Size * Size * 0.25f;
    }

    public void Pull(Vector2 mouseFromBottom)
    {
        active = true;
        var offset = ToGui(mouseFromBottom) - Center();
        float limit = Travel();
        if (offset.sqrMagnitude > limit * limit)
            offset = offset.normalized * limit;
        pull = offset;
    }

    public Vector2 Deflection()
    {
        float limit = Travel();
        if (pull.sqrMagnitude < 0.01f || limit < 1f)
            return Vector2.zero;

        float reach = Mathf.Clamp01(pull.magnitude / limit);
        if (reach < 0.08f)
            return Vector2.zero;

        var direction = pull / pull.magnitude;
        return new Vector2(direction.x, -direction.y) * reach;
    }

    static float Travel()
    {
        return Size * 0.5f - KnobSize * 0.5f - 4f;
    }

    public void Release()
    {
        active = false;
        pull = Vector2.zero;
    }

    void OnGUI()
    {
        EnsureTextures();
        var center = Center();
        var previous = GUI.color;
        GUI.color = active ? Color.white : new Color(1f, 1f, 1f, 0.92f);
        GUI.DrawTexture(new Rect(center.x - Size * 0.5f, center.y - Size * 0.5f, Size, Size), face);
        GUI.DrawTexture(new Rect(center.x + pull.x - KnobSize * 0.5f, center.y + pull.y - KnobSize * 0.5f, KnobSize, KnobSize), knob);
        GUI.color = previous;
    }

    static Vector2 ToGui(Vector2 mouseFromBottom)
    {
        return new Vector2(mouseFromBottom.x, Screen.height - mouseFromBottom.y);
    }

    static Vector2 Center()
    {
        return new Vector2(Margin + Size * 0.5f, Margin + 34f + Size * 0.5f);
    }

    void EnsureTextures()
    {
        if (face != null)
            return;

        face = Disc(128, new Color(0.78f, 0.9f, 0.98f, 0.9f), new Color(0.42f, 0.62f, 0.86f, 0.95f));
        knob = Disc(32, new Color(0.29f, 0.52f, 0.95f, 1f), new Color(0.18f, 0.38f, 0.78f, 1f));
    }

    static Texture2D Disc(int size, Color fill, Color ring)
    {
        var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.filterMode = FilterMode.Bilinear;
        float radius = (size - 1) * 0.5f;
        var center = new Vector2(radius, radius);
        for (int y = 0; y < size; y++)
        {
            for (int x = 0; x < size; x++)
            {
                float distance = Vector2.Distance(new Vector2(x, y), center);
                float edge = Mathf.Clamp01(radius - distance + 0.75f);
                float ringBand = Mathf.Clamp01(2.2f - Mathf.Abs(distance - (radius - 4f)));
                var color = Color.Lerp(fill, ring, ringBand);
                color.a *= edge;
                texture.SetPixel(x, y, color);
            }
        }

        texture.Apply();
        return texture;
    }
}
