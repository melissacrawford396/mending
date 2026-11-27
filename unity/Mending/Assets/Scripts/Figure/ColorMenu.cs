using System;
using System.Globalization;
using System.Text;
using UnityEngine;

public class ColorMenu : MonoBehaviour
{
    const float Margin = 20f;
    const float Height = 26f;
    const float ButtonWidth = 76f;
    const float ListWidth = 140f;
    const float PanelWidth = 248f;
    const float Pad = 12f;
    const float Swatch = 30f;
    const float SwatchGap = 6f;
    const int Columns = 6;
    const float TitleHeight = 26f;
    const float BackWidth = 56f;
    const float SliderHeight = 40f;
    const float MainLightMax = 2f;
    const string Prefix = "mending.color.";
    const string MainLightKey = "mending.light.main";
    const string FillLightKey = "mending.light.fill";
    const string DefaultsKey = "mending.color.defaults";

    static readonly Color[] Palette =
    {
        new Color(1f, 0.85f, 0.7f),
        new Color(0.98f, 0.8f, 0.62f),
        new Color(0.9f, 0.7f, 0.52f),
        new Color(0.76f, 0.56f, 0.4f),
        new Color(0.55f, 0.38f, 0.26f),
        new Color(0.38f, 0.25f, 0.17f),
        new Color(0.96f, 0.8f, 0.79f),
        new Color(0.98f, 0.6f, 0.5f),
        new Color(1f, 0.86f, 0.45f),
        new Color(0.76f, 0.87f, 0.66f),
        new Color(0.6f, 0.8f, 0.98f),
        new Color(0.29f, 0.52f, 0.95f),
        new Color(0.78f, 0.7f, 0.95f),
        new Color(0.7f, 0.93f, 0.85f),
        new Color(0.83f, 0.74f, 0.64f),
        new Color(0.88f, 0.88f, 0.88f),
        new Color(0.45f, 0.5f, 0.58f),
        new Color(0.32f, 0.22f, 0.16f)
    };

    Target[] targets;
    Light sun;
    float mainLight;
    float mainLightDefault;
    float fillLight;
    float fillLightDefault;
    Color fillTint = Color.white;
    bool listOpen;
    int editing = -1;
    float hue;
    float saturation;
    float brightness;
    float copiedUntil;
    Texture2D hueStrip;

    int LightIndex
    {
        get { return targets.Length; }
    }

    public void Bind(CuteFigure figure, Camera cam, Material floor)
    {
        float floorAlpha = Read(floor).a;
        targets = new[]
        {
            new Target("Skin", () => Read(figure.SkinMaterial), c => Write(figure.SkinMaterial, c)),
            new Target("Joints", () => Read(figure.JointMaterial), c => Write(figure.JointMaterial, c)),
            new Target("Ground", () => Read(floor), c =>
            {
                c.a = floorAlpha;
                Write(floor, c);
            }),
            new Target("Background", () => cam.backgroundColor, c => cam.backgroundColor = c)
        };

        foreach (var target in targets)
            target.Default = target.Get();

        foreach (var sceneLight in FindObjectsByType<Light>(FindObjectsSortMode.None))
        {
            if (sceneLight.type == LightType.Directional)
            {
                sun = sceneLight;
                break;
            }
        }

        var ambient = RenderSettings.ambientLight;
        fillLightDefault = Mathf.Max(ambient.r, Mathf.Max(ambient.g, ambient.b));
        if (fillLightDefault > 0.0001f)
            fillTint = new Color(ambient.r / fillLightDefault, ambient.g / fillLightDefault, ambient.b / fillLightDefault);
        mainLightDefault = sun != null ? sun.intensity : 0f;

        ForgetPicksIfDefaultsChanged(ambient);
        foreach (var target in targets)
        {
            Color saved;
            if (Load(target, out saved))
                target.Set(saved);
        }
        SetLight(PlayerPrefs.GetFloat(MainLightKey, mainLightDefault), PlayerPrefs.GetFloat(FillLightKey, fillLightDefault), false);
    }

    void ForgetPicksIfDefaultsChanged(Color ambient)
    {
        var defaults = new StringBuilder();
        foreach (var target in targets)
            defaults.Append(ColorUtility.ToHtmlStringRGBA(target.Default)).Append('|');
        defaults.Append(Format(mainLightDefault)).Append('|').Append(ColorUtility.ToHtmlStringRGB(ambient));

        string current = defaults.ToString();
        if (PlayerPrefs.GetString(DefaultsKey, "") == current)
            return;

        foreach (var target in targets)
            PlayerPrefs.DeleteKey(Key(target));
        PlayerPrefs.DeleteKey(MainLightKey);
        PlayerPrefs.DeleteKey(FillLightKey);
        PlayerPrefs.SetString(DefaultsKey, current);
        PlayerPrefs.Save();
    }

    public bool Contains(Vector2 mouseFromBottom)
    {
        if (targets == null)
            return false;

        var gui = new Vector2(mouseFromBottom.x, Screen.height - mouseFromBottom.y);
        if (ButtonRect().Contains(gui))
            return true;
        if (listOpen && ListRect().Contains(gui))
            return true;
        return editing >= 0 && PanelRect().Contains(gui);
    }

    public void Close()
    {
        editing = -1;
        listOpen = false;
        PlayerPrefs.Save();
    }

    void OnGUI()
    {
        if (targets == null)
            return;

        if (editing == LightIndex)
            DrawLightPanel();
        else if (editing >= 0)
            DrawColorPanel();
        else if (listOpen)
            DrawList();

        if (FigureButtons.Button(ButtonRect(), "Colors"))
        {
            if (editing >= 0 || listOpen)
                Close();
            else
                listOpen = true;
        }
    }

    void OnDisable()
    {
        PlayerPrefs.Save();
    }

    void DrawList()
    {
        for (int i = 0; i < targets.Length; i++)
        {
            var row = ListRow(i);
            if (FigureButtons.Button(row, targets[i].Name))
                Open(i);
            DrawSwatch(new Rect(row.x + 8f, row.y + 6f, 14f, 14f), targets[i].Get(), false, 3f);
        }

        if (FigureButtons.Button(ListRow(LightIndex), "Light"))
            Open(LightIndex);

        if (FigureButtons.Button(ListRow(LightIndex + 1), Copied() ? "Copied" : "Copy all"))
        {
            var all = new StringBuilder();
            foreach (var target in targets)
                all.AppendLine(target.Name + ": " + Code(target.Get()));
            all.AppendLine(LightCode());
            Copy(all.ToString());
        }
    }

    void DrawColorPanel()
    {
        var panel = PanelRect();
        var target = targets[editing];
        FigureButtons.Panel(panel);

        float x = panel.x + Pad;
        float y = panel.y + Pad;
        float inner = panel.width - Pad * 2f;
        TitleRow(x, y, inner - 52f, target.Name);
        DrawSwatch(new Rect(panel.xMax - Pad - 44f, y + 2f, 44f, TitleHeight - 4f), target.Get(), false, 5f);
        y += TitleHeight + 8f;

        var current = target.Get();
        FigureButtons.Text(new Rect(x, y, inner - 72f, Height), Numbers(current), false);
        if (FigureButtons.Button(new Rect(panel.xMax - Pad - 64f, y, 64f, Height), Copied() ? "Copied" : "Copy"))
            Copy(Code(current));
        y += Height + 10f;

        for (int i = 0; i < Palette.Length; i++)
        {
            int column = i % Columns;
            int row = i / Columns;
            var rect = new Rect(x + column * (Swatch + SwatchGap), y + row * (Swatch + SwatchGap), Swatch, Swatch);
            DrawSwatch(rect, Palette[i], Same(Palette[i], current), 6f);
            if (GUI.Button(rect, GUIContent.none, GUIStyle.none))
                Choose(target, Palette[i]);
        }

        y += Rows() * (Swatch + SwatchGap) + 4f;

        float nextHue = Slider(ref y, x, inner, "Hue", hue, 0f, 1f, true);
        float nextSaturation = Slider(ref y, x, inner, "Saturation", saturation, 0f, 1f, false);
        float nextBrightness = Slider(ref y, x, inner, "Brightness", brightness, 0f, 1f, false);
        if (nextHue != hue || nextSaturation != saturation || nextBrightness != brightness)
        {
            hue = nextHue;
            saturation = nextSaturation;
            brightness = nextBrightness;
            target.Set(Color.HSVToRGB(hue, saturation, brightness));
            Save(target);
        }

        y += 6f;
        if (ResetDoneRow(x, y, inner))
        {
            target.Set(target.Default);
            PlayerPrefs.DeleteKey(Key(target));
            Color.RGBToHSV(target.Default, out hue, out saturation, out brightness);
        }
    }

    void DrawLightPanel()
    {
        var panel = PanelRect();
        FigureButtons.Panel(panel);

        float x = panel.x + Pad;
        float y = panel.y + Pad;
        float inner = panel.width - Pad * 2f;
        TitleRow(x, y, inner, "Light");
        y += TitleHeight + 10f;

        float nextMain = Slider(ref y, x, inner, "Main light   " + Format(mainLight), mainLight, 0f, MainLightMax, false);
        float nextFill = Slider(ref y, x, inner, "Fill light   " + Format(fillLight), fillLight, 0f, 1f, false);
        if (nextMain != mainLight || nextFill != fillLight)
            SetLight(nextMain, nextFill, true);

        y += 4f;
        FigureButtons.Text(new Rect(x, y, inner - 72f, Height), "Main " + Format(mainLight) + "   Fill " + Format(fillLight), false);
        if (FigureButtons.Button(new Rect(panel.xMax - Pad - 64f, y, 64f, Height), Copied() ? "Copied" : "Copy"))
            Copy(LightCode());
        y += Height + 10f;

        if (ResetDoneRow(x, y, inner))
        {
            SetLight(mainLightDefault, fillLightDefault, false);
            PlayerPrefs.DeleteKey(MainLightKey);
            PlayerPrefs.DeleteKey(FillLightKey);
        }
    }

    void TitleRow(float x, float y, float width, string title)
    {
        if (FigureButtons.Button(new Rect(x, y, BackWidth, Height), "Back"))
            ShowList();
        FigureButtons.Text(new Rect(x + BackWidth + 10f, y, width - BackWidth - 10f, TitleHeight), title, true);
    }

    bool ResetDoneRow(float x, float y, float width)
    {
        float half = (width - 8f) * 0.5f;
        bool reset = FigureButtons.Button(new Rect(x, y, half, Height), "Reset");
        if (FigureButtons.Button(new Rect(x + half + 8f, y, half, Height), "Done"))
            ShowList();
        return reset;
    }

    float Slider(ref float y, float x, float width, string label, float value, float min, float max, bool rainbow)
    {
        FigureButtons.Text(new Rect(x, y, width, 18f), label, false);
        y += 18f;
        if (rainbow)
            GUI.DrawTexture(new Rect(x, y + 14f, width, 4f), HueStrip(), ScaleMode.StretchToFill, false);
        float next = GUI.HorizontalSlider(new Rect(x, y, width, 16f), value, min, max);
        y += SliderHeight - 18f;
        return next;
    }

    void SetLight(float main, float fill, bool save)
    {
        mainLight = Mathf.Clamp(main, 0f, MainLightMax);
        fillLight = Mathf.Clamp01(fill);
        if (sun != null)
            sun.intensity = mainLight;
        RenderSettings.ambientLight = FillColor();
        if (!save)
            return;
        PlayerPrefs.SetFloat(MainLightKey, mainLight);
        PlayerPrefs.SetFloat(FillLightKey, fillLight);
    }

    Color FillColor()
    {
        return new Color(fillTint.r * fillLight, fillTint.g * fillLight, fillTint.b * fillLight, 1f);
    }

    string LightCode()
    {
        return "Main light: " + Number(mainLight) + "\nFill light: " + Code(FillColor());
    }

    void Open(int index)
    {
        editing = index;
        listOpen = false;
        if (index < targets.Length)
            Color.RGBToHSV(targets[index].Get(), out hue, out saturation, out brightness);
    }

    void ShowList()
    {
        editing = -1;
        listOpen = true;
        PlayerPrefs.Save();
    }

    void Choose(Target target, Color color)
    {
        target.Set(color);
        Save(target);
        Color.RGBToHSV(color, out hue, out saturation, out brightness);
    }

    static void DrawSwatch(Rect rect, Color color, bool selected, float radius)
    {
        color.a = 1f;
        var tint = GUI.color;
        GUI.color = Color.white;
        if (selected)
        {
            var ring = new Rect(rect.x - 3f, rect.y - 3f, rect.width + 6f, rect.height + 6f);
            GUI.DrawTexture(ring, Texture2D.whiteTexture, ScaleMode.StretchToFill, false, 0f, Color.black, 0f, radius + 3f);
        }

        GUI.DrawTexture(rect, Texture2D.whiteTexture, ScaleMode.StretchToFill, false, 0f, color, 0f, radius);
        GUI.DrawTexture(rect, Texture2D.whiteTexture, ScaleMode.StretchToFill, false, 0f, new Color(0f, 0f, 0f, 0.25f), 1f, radius);
        GUI.color = tint;
    }

    Texture2D HueStrip()
    {
        if (hueStrip != null)
            return hueStrip;

        const int width = 128;
        hueStrip = new Texture2D(width, 1, TextureFormat.RGB24, false);
        hueStrip.wrapMode = TextureWrapMode.Clamp;
        for (int i = 0; i < width; i++)
            hueStrip.SetPixel(i, 0, Color.HSVToRGB(i / (width - 1f), 1f, 1f));
        hueStrip.Apply();
        return hueStrip;
    }

    static string Numbers(Color color)
    {
        return "R " + Format(color.r) + "   G " + Format(color.g) + "   B " + Format(color.b);
    }

    static string Format(float value)
    {
        return value.ToString("0.00", CultureInfo.InvariantCulture);
    }

    static string Code(Color color)
    {
        string text = "new Color(" + Number(color.r) + ", " + Number(color.g) + ", " + Number(color.b);
        if (color.a < 0.999f)
            text += ", " + Number(color.a);
        return text + ")";
    }

    static string Number(float value)
    {
        return value.ToString("0.##", CultureInfo.InvariantCulture) + "f";
    }

    void Copy(string text)
    {
        GUIUtility.systemCopyBuffer = text;
        copiedUntil = Time.unscaledTime + 1.5f;
    }

    bool Copied()
    {
        return Time.unscaledTime < copiedUntil;
    }

    static bool Same(Color a, Color b)
    {
        return Mathf.Abs(a.r - b.r) < 0.02f && Mathf.Abs(a.g - b.g) < 0.02f && Mathf.Abs(a.b - b.b) < 0.02f;
    }

    static int Rows()
    {
        return (Palette.Length + Columns - 1) / Columns;
    }

    Rect ButtonRect()
    {
        return new Rect(Screen.width - Margin - ButtonWidth, Margin, ButtonWidth, Height);
    }

    Rect ListRow(int index)
    {
        var button = ButtonRect();
        return new Rect(button.xMax - ListWidth, button.yMax + 4f + index * (Height + 2f), ListWidth, Height);
    }

    Rect ListRect()
    {
        var first = ListRow(0);
        var last = ListRow(LightIndex + 1);
        return new Rect(first.x, first.y, ListWidth, last.yMax - first.y);
    }

    Rect PanelRect()
    {
        var button = ButtonRect();
        float height = editing == LightIndex
            ? Pad + TitleHeight + 10f + SliderHeight * 2f + 4f + Height + 10f + Height + Pad
            : Pad + TitleHeight + 8f + Height + 10f + Rows() * (Swatch + SwatchGap) + 4f + SliderHeight * 3f + 6f + Height + Pad;
        return new Rect(button.xMax - PanelWidth, button.yMax + 6f, PanelWidth, height);
    }

    static Color Read(Material material)
    {
        if (material.HasProperty("_BaseColor"))
            return material.GetColor("_BaseColor");
        return material.color;
    }

    static void Write(Material material, Color color)
    {
        if (material.HasProperty("_BaseColor"))
            material.SetColor("_BaseColor", color);
        if (material.HasProperty("_Color"))
            material.SetColor("_Color", color);
    }

    static string Key(Target target)
    {
        return Prefix + target.Name.ToLowerInvariant();
    }

    static void Save(Target target)
    {
        PlayerPrefs.SetString(Key(target), ColorUtility.ToHtmlStringRGB(target.Get()));
    }

    static bool Load(Target target, out Color color)
    {
        color = Color.white;
        string saved = PlayerPrefs.GetString(Key(target), "");
        return saved.Length > 0 && ColorUtility.TryParseHtmlString("#" + saved, out color);
    }

    class Target
    {
        public readonly string Name;
        public readonly Func<Color> Get;
        public readonly Action<Color> Set;
        public Color Default;

        public Target(string name, Func<Color> get, Action<Color> set)
        {
            Name = name;
            Get = get;
            Set = set;
        }
    }
}
