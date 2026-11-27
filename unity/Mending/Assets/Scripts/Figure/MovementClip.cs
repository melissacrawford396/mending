using System.Collections.Generic;
using UnityEngine;

public class MovementClip
{
    public string name;
    public Key[] keys;
    public float yaw;
    public float pitch;
    public float distance;
    public string[] focus;

    public float Duration
    {
        get { return keys[keys.Length - 1].time; }
    }

    public Key Sample(float time)
    {
        if (time <= keys[0].time)
            return keys[0];
        if (time >= keys[keys.Length - 1].time)
            return keys[keys.Length - 1];

        int upper = 1;
        while (upper < keys.Length - 1 && keys[upper].time < time)
            upper++;

        float span = keys[upper].time - keys[upper - 1].time;
        float u = span <= 0.0001f ? 0f : (time - keys[upper - 1].time) / span;
        u = u * u * (3f - 2f * u);
        return Key.Lerp(keys[upper - 1], keys[upper], u);
    }

    public class Key
    {
        public float time;
        public string[] names;
        public float[] hinge;
        public float[] raise;
        public Vector3 root;

        public static Key Lerp(Key a, Key b, float u)
        {
            var names = new List<string>();
            AddNames(names, a);
            AddNames(names, b);
            var key = new Key
            {
                time = Mathf.Lerp(a.time, b.time, u),
                root = Vector3.Lerp(a.root, b.root, u),
                names = names.ToArray(),
                hinge = new float[names.Count],
                raise = new float[names.Count]
            };
            for (int i = 0; i < names.Count; i++)
            {
                float aHinge, aRaise, bHinge, bRaise;
                Read(a, names[i], out aHinge, out aRaise);
                Read(b, names[i], out bHinge, out bRaise);
                key.hinge[i] = Mathf.Lerp(aHinge, bHinge, u);
                key.raise[i] = Mathf.Lerp(aRaise, bRaise, u);
            }

            return key;
        }

        static void AddNames(List<string> names, Key key)
        {
            if (key.names == null)
                return;
            for (int i = 0; i < key.names.Length; i++)
            {
                if (!names.Contains(key.names[i]))
                    names.Add(key.names[i]);
            }
        }

        static void Read(Key key, string name, out float hinge, out float raise)
        {
            hinge = 0f;
            raise = 0f;
            if (key.names == null)
                return;
            for (int i = 0; i < key.names.Length; i++)
            {
                if (key.names[i] != name)
                    continue;
                hinge = key.hinge[i];
                raise = key.raise[i];
                return;
            }
        }
    }
}

public static class MovementLibrary
{
    public static MovementClip[] All()
    {
        return new[]
        {
            ArchRoll(),
            ToeFlex(),
            ShoulderCircles("Small shoulder circles", 14f, 12f, 4.8f),
            ShoulderCircles("Large arm circles", 48f, 42f, 4.8f),
            AnkleStretch()
        };
    }

    static MovementClip ShoulderCircles(string name, float hingeAmp, float raiseAmp, float distance)
    {
        const float raiseCenter = 82f;
        const float hingeCenter = 18f;
        var keys = new List<MovementClip.Key>();
        keys.Add(Arms(0f, 0f, 0f));
        keys.Add(Arms(0.7f, hingeCenter + hingeAmp, raiseCenter));
        Circle(keys, 0.7f, 3.1f, hingeCenter, hingeAmp, raiseCenter, raiseAmp, true);
        Circle(keys, 3.1f, 5.5f, hingeCenter, hingeAmp, raiseCenter, raiseAmp, false);
        keys.Add(Arms(6.2f, 0f, 0f));
        return Clip(name, keys, 42f, -8f, distance, "Shoulder.L", "Shoulder.R");
    }

    static void Circle(List<MovementClip.Key> keys, float start, float end, float hingeCenter, float hingeAmp, float raiseCenter, float raiseAmp, bool forward)
    {
        const int steps = 28;
        float direction = forward ? -1f : 1f;
        for (int i = 1; i <= steps; i++)
        {
            float t = i / (float)steps;
            float angle = direction * t * Mathf.PI * 2f;
            float time = Mathf.Lerp(start, end, t);
            keys.Add(Arms(time, hingeCenter + Mathf.Cos(angle) * hingeAmp, raiseCenter + Mathf.Sin(angle) * raiseAmp));
        }
    }

    static MovementClip.Key Arms(float time, float hinge, float raise)
    {
        return Joints(time, Vector3.zero,
            ("Shoulder.L", hinge, raise),
            ("Shoulder.R", hinge, raise));
    }

    static MovementClip ToeFlex()
    {
        var keys = new List<MovementClip.Key>();
        keys.Add(Toes(0f, 0f, 0f, 0f));
        keys.Add(Toes(1.2f, 0f, 0f, 32f));
        keys.Add(Toes(2.6f, 0f, 0f, -15f));
        keys.Add(Toes(3.8f, 0f, 0f, 0f));
        return Clip("Toe flex", keys, 58f, -32f, 1.2f, "Toe.R.1", "Toe.R.2", "Toe.R.3", "Toe.R.4", "Toe.R.5");
    }

    static MovementClip.Key Toes(float time, float hipHinge, float hipRaise, float toe)
    {
        return Joints(time, Vector3.zero,
            ("Hip.R", hipHinge, hipRaise),
            ("Toe.R.1", toe, 0f),
            ("Toe.R.2", toe, 0f),
            ("Toe.R.3", toe, 0f),
            ("Toe.R.4", toe, 0f),
            ("Toe.R.5", toe, 0f));
    }

    static MovementClip AnkleStretch()
    {
        var keys = new List<MovementClip.Key>();
        var down = new Vector3(0f, -0.053f, 0f);
        keys.Add(Stance(0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, Vector3.zero));
        keys.Add(Stance(1.4f, 30f, 30f, 0f, -20f, 3f, -23f, 0f, down));
        keys.Add(Stance(3.1f, 30f, 30f, 0f, -20f, 3f, -23f, 0f, down));
        keys.Add(Stance(4.5f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, Vector3.zero));
        keys.Add(Stance(4.9f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, Vector3.zero));
        keys.Add(Stance(6.3f, -20f, 3f, -23f, 30f, 30f, 0f, 0f, down));
        keys.Add(Stance(8.0f, -20f, 3f, -23f, 30f, 30f, 0f, 0f, down));
        keys.Add(Stance(9.4f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, Vector3.zero));
        return Clip("Ankle stretch", keys, 90f, -14f, 5f, "Ankle.L", "Ankle.R");
    }

    static MovementClip.Key Stance(float time, float hipL, float kneeL, float ankleL, float hipR, float kneeR, float ankleR, float waist, Vector3 root)
    {
        return Joints(time, root,
            ("Hip.L", hipL, 0f),
            ("Knee.L", kneeL, 0f),
            ("Ankle.L", ankleL, 0f),
            ("Hip.R", hipR, 0f),
            ("Knee.R", kneeR, 0f),
            ("Ankle.R", ankleR, 0f),
            ("Waist", waist, 0f));
    }

    static MovementClip ArchRoll()
    {
        var keys = new List<MovementClip.Key>();
        RollPass(keys, 0f, 3.6f, false);
        RollPass(keys, 3.6f, 7.2f, true);
        return Clip("Arch roll", keys, 78f, -16f, 2.6f, "Ankle.R");
    }

    static void RollPass(List<MovementClip.Key> keys, float start, float end, bool reverse)
    {
        const int steps = 18;
        for (int i = 0; i <= steps; i++)
        {
            if (reverse && i == 0)
                continue;
            float u = i / (float)steps;
            float eased = u * u * (3f - 2f * u);
            eased = reverse ? (1f - eased) * 0.82f : eased * 0.82f;
            float hip = Mathf.Lerp(20f, 30f, eased);
            float knee = Mathf.Lerp(43f, 32f, eased);
            keys.Add(Roll(Mathf.Lerp(start, end, u), Vector3.zero, hip - knee, knee, hip));
        }
    }

    static MovementClip.Key Roll(float time, Vector3 root, float ankle, float knee, float hip)
    {
        return Joints(time, root,
            ("Ankle.R", ankle, 0f),
            ("Knee.R", knee, 0f),
            ("Hip.R", hip, 0f));
    }

    static MovementClip Clip(string name, List<MovementClip.Key> keys, float yaw, float pitch, float distance, params string[] focus)
    {
        return new MovementClip
        {
            name = name,
            keys = keys.ToArray(),
            yaw = yaw,
            pitch = pitch,
            distance = distance,
            focus = focus
        };
    }

    static MovementClip.Key Joints(float time, Vector3 root, params (string name, float hinge, float raise)[] joints)
    {
        var key = new MovementClip.Key
        {
            time = time,
            root = root,
            names = new string[joints.Length],
            hinge = new float[joints.Length],
            raise = new float[joints.Length]
        };
        for (int i = 0; i < joints.Length; i++)
        {
            key.names[i] = joints[i].name;
            key.hinge[i] = joints[i].hinge;
            key.raise[i] = joints[i].raise;
        }

        return key;
    }
}
