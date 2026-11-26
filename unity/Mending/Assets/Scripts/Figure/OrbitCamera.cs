using UnityEngine;

public class OrbitCamera : MonoBehaviour
{
    public Transform target;
    public float distance = 2.7f;
    public float yaw = 18f;
    public float pitch = -18f;

    const float PitchMin = -89f;
    const float PitchMax = 32f;

    public void AddDelta(Vector2 pixelDelta)
    {
        yaw += pixelDelta.x * 0.7f;
        pitch = Mathf.Clamp(pitch - pixelDelta.y * 0.5f, PitchMin, PitchMax);
    }

    public void Hold(Vector2 deflection, float deltaTime)
    {
        yaw += deflection.x * 150f * deltaTime;
        pitch = Mathf.Clamp(pitch - deflection.y * 90f * deltaTime, PitchMin, PitchMax);
    }

    public void Look(float nextYaw, float nextPitch)
    {
        yaw = nextYaw;
        pitch = Mathf.Clamp(nextPitch, PitchMin, PitchMax);
    }

    public void Zoom(float scroll)
    {
        distance = Mathf.Clamp(distance - scroll * 0.01f, 1.15f, 18f);
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
