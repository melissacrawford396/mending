using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using UnityEngine;

public class ClipCapture : MonoBehaviour
{
    const int Size = 720;
    const int FrameRate = 30;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot()
    {
        if (!HasFlag("-recordClips"))
            return;

        var host = new GameObject("ClipCapture");
        host.AddComponent<ClipCapture>();
    }

    IEnumerator Start()
    {
        yield return null;
        string output = Arg("-recordOutput") ?? Path.GetFullPath(Path.Combine(Application.dataPath, "../../../visuals"));
        string logPath = Arg("-recordLog") ?? Path.GetFullPath(Path.Combine(Application.dataPath, "../Logs/clip-record-result.txt"));
        string ffmpeg = Arg("-ffmpeg") ?? "/opt/homebrew/bin/ffmpeg";
        var only = Requested();
        Directory.CreateDirectory(output);
        Directory.CreateDirectory(Path.GetDirectoryName(logPath));
        var log = new StringBuilder();

        MovementPlayer player = null;
        for (int i = 0; i < 30 && player == null; i++)
        {
            player = FindAnyObjectByType<MovementPlayer>();
            if (player == null)
                yield return null;
        }

        if (player == null)
        {
            Finish(logPath, "No movement player.\n", 1);
            yield break;
        }

        foreach (var stage in FindObjectsByType<FigureStage>(FindObjectsSortMode.None))
            stage.enabled = false;
        foreach (var bar in FindObjectsByType<MovementBar>(FindObjectsSortMode.None))
            bar.enabled = false;
        foreach (var views in FindObjectsByType<ViewBar>(FindObjectsSortMode.None))
            views.enabled = false;
        foreach (var pad in FindObjectsByType<OrbitPad>(FindObjectsSortMode.None))
            pad.enabled = false;
        foreach (var menu in FindObjectsByType<ColorMenu>(FindObjectsSortMode.None))
            menu.enabled = false;
        var ground = GameObject.Find("Ground");
        if (ground != null)
        {
            float grow = 30f / ground.transform.localScale.x;
            ground.transform.localScale = new Vector3(30f, 0.012f, 30f);
            var floor = ground.GetComponent<Renderer>().sharedMaterial;
            if (floor.HasProperty("_BaseMap"))
                floor.SetTextureScale("_BaseMap", floor.GetTextureScale("_BaseMap") * grow);
        }

        var cam = Camera.main;
        var orbit = cam.GetComponent<OrbitCamera>();
        var buffer = new RenderTexture(Size, Size, 24);
        cam.targetTexture = buffer;
        cam.aspect = 1f;
        var shot = new Texture2D(Size, Size, TextureFormat.RGB24, false);
        var flipped = new byte[Size * Size * 3];
        var recorded = new HashSet<string>();
        int failures = 0;

        for (int clip = 0; clip < player.ClipCount; clip++)
        {
            player.Select(clip);
            if (only != null && !only.Contains(player.ClipName))
                continue;

            string path = Path.Combine(output, FileName(player.ClipName));
            var encoder = StartEncoder(ffmpeg, path);
            int frames = 0;
            for (float time = 0f; time <= player.ClipDuration + 0.0001f; time += 1f / FrameRate)
            {
                player.PoseAt(Mathf.Min(time, player.ClipDuration));
                if (orbit != null)
                    orbit.Snap();
                cam.Render();
                RenderTexture.active = buffer;
                shot.ReadPixels(new Rect(0f, 0f, Size, Size), 0, 0);
                shot.Apply(false);
                WriteFlipped(shot.GetRawTextureData(), flipped);
                encoder.StandardInput.BaseStream.Write(flipped, 0, flipped.Length);
                frames++;
            }

            encoder.StandardInput.Close();
            encoder.WaitForExit();
            recorded.Add(player.ClipName);
            bool ok = encoder.ExitCode == 0;
            log.AppendLine((ok ? "ok   " : "BAD  ") + player.ClipName + "  " + frames + " frames  " + path);
            if (!ok)
                failures++;
        }

        if (only != null)
        {
            foreach (var name in only)
            {
                if (recorded.Contains(name))
                    continue;
                log.AppendLine("BAD  no clip named \"" + name + "\"");
                failures++;
            }
        }

        cam.targetTexture = null;
        buffer.Release();
        Finish(logPath, log.ToString(), failures == 0 ? 0 : 1);
    }

    static Process StartEncoder(string ffmpeg, string path)
    {
        var encoder = new Process();
        encoder.StartInfo.FileName = ffmpeg;
        encoder.StartInfo.Arguments =
            "-y -loglevel error -f rawvideo -pix_fmt rgb24 -s " + Size + "x" + Size
            + " -r " + FrameRate + " -i pipe:0 -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart \""
            + path + "\"";
        encoder.StartInfo.UseShellExecute = false;
        encoder.StartInfo.RedirectStandardInput = true;
        encoder.StartInfo.RedirectStandardError = true;
        encoder.ErrorDataReceived += delegate { };
        encoder.Start();
        encoder.BeginErrorReadLine();
        return encoder;
    }

    static void WriteFlipped(byte[] raw, byte[] flipped)
    {
        int stride = Size * 3;
        for (int y = 0; y < Size; y++)
            Buffer.BlockCopy(raw, y * stride, flipped, (Size - 1 - y) * stride, stride);
    }

    static string FileName(string clipName)
    {
        return clipName.ToLowerInvariant().Replace(" ", "-") + ".mp4";
    }

    static HashSet<string> Requested()
    {
        var value = Arg("-recordOnly");
        if (string.IsNullOrEmpty(value))
            return null;
        return new HashSet<string>(value.Split('|'));
    }

    static bool HasFlag(string flag)
    {
        return Array.IndexOf(Environment.GetCommandLineArgs(), flag) >= 0;
    }

    static string Arg(string flag)
    {
        var args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == flag)
                return args[i + 1];
        }

        return null;
    }

    static void Finish(string logPath, string text, int exitCode)
    {
        File.WriteAllText(logPath, text);
#if UNITY_EDITOR
        UnityEditor.EditorApplication.Exit(exitCode);
#endif
    }
}
