using System;
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
        if (!Recording())
            return;

        var host = new GameObject("ClipCapture");
        host.AddComponent<ClipCapture>();
    }

    static bool Recording()
    {
        var args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "-recordClips")
                return true;
        }

        return false;
    }

    System.Collections.IEnumerator Start()
    {
        yield return null;
        string output = OutputDirectory();
        Directory.CreateDirectory(output);
        string logPath = Path.Combine(output, "record-log.txt");
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
            Fail(logPath, "No movement player.");
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
        var ground = GameObject.Find("Ground");
        if (ground != null)
            ground.transform.localScale = new Vector3(30f, 0.012f, 30f);

        var cam = Camera.main;
        var buffer = new RenderTexture(Size, Size, 24);
        buffer.antiAliasing = 1;
        cam.targetTexture = buffer;
        cam.aspect = 1f;
        var shot = new Texture2D(Size, Size, TextureFormat.RGB24, false);
        var flipped = new byte[Size * Size * 3];
        int failures = 0;

        for (int clip = 0; clip < player.ClipCount; clip++)
        {
            player.Select(clip);
            string path = Path.Combine(output, FileName(player.ClipName));
            var encoder = StartEncoder(path);
            var orbit = cam.GetComponent<OrbitCamera>();
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
            log.AppendLine(player.ClipName + " " + frames + " frames exit " + encoder.ExitCode + " " + path);
            if (encoder.ExitCode != 0)
                failures++;
        }

        cam.targetTexture = null;
        buffer.Release();
        File.WriteAllText(logPath, log.ToString());
#if UNITY_EDITOR
        UnityEditor.EditorApplication.Exit(failures == 0 ? 0 : 1);
#endif
    }

    static Process StartEncoder(string path)
    {
        var encoder = new Process();
        encoder.StartInfo.FileName = "/opt/homebrew/bin/ffmpeg";
        encoder.StartInfo.Arguments =
            "-y -loglevel error -f rawvideo -pix_fmt rgb24 -s " + Size + "x" + Size
            + " -r " + FrameRate + " -i pipe:0 -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart \""
            + path + "\"";
        encoder.StartInfo.UseShellExecute = false;
        encoder.StartInfo.RedirectStandardInput = true;
        encoder.StartInfo.RedirectStandardError = true;
        encoder.Start();
        encoder.ErrorDataReceived += delegate { };
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

    static string OutputDirectory()
    {
        var args = Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == "-recordOutput")
                return args[i + 1];
        }

        return Path.GetFullPath(Path.Combine(Application.dataPath, "../../visuals"));
    }

    static void Fail(string logPath, string message)
    {
        File.WriteAllText(logPath, message + "\n");
#if UNITY_EDITOR
        UnityEditor.EditorApplication.Exit(1);
#endif
    }

}

