using UnityEditor;
using UnityEditor.SceneManagement;

public static class ClipRecorder
{
    public static void Run()
    {
        EditorSceneManager.OpenScene("Assets/Scenes/SampleScene.unity");
        EditorApplication.EnterPlaymode();
    }
}
