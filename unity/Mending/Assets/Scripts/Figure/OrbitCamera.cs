using UnityEngine;

public class OrbitCamera : MonoBehaviour
{
    public Transform target;
    public float distance = 2.7f;
    public float yaw = 18f;
    public float pitch = 12f;

    public void AddDelta(Vector2 pixelDelta)
    {
        yaw += pixelDelta.x * 0.22f;
        pitch = Mathf.Clamp(pitch - pixelDelta.y * 0.16f, -5f, 55f);
    }

    public void Zoom(float scroll)
    {
        distance = Mathf.Clamp(distance - scroll * 0.002f, 1.3f, 6f);
    }

    public void Snap()
    {
        Apply();
    }

    void LateUpdate()
    {
        Apply();
    }

    void Apply()
    {
        if (target == null)
            return;

        var pivot = target.position + Vector3.up * 0.05f;
        var rotation = Quaternion.Euler(pitch, yaw, 0f);
        transform.position = pivot + rotation * new Vector3(0f, 0f, distance);
        transform.LookAt(pivot);
    }
}
