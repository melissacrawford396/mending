using UnityEngine;

public class JointControl : MonoBehaviour
{
    public enum Kind
    {
        Hinge,
        TwoAxis
    }

    public Kind kind;
    public Vector3 hingeAxis = Vector3.right;
    public Vector3 raiseAxis = Vector3.forward;
    public float hingeMin;
    public float hingeMax = 150f;
    public float raiseMin;
    public float raiseMax = 160f;
    public float hinge;
    public float raise;
    public float ballRadius = 0.05f;
    public Vector3 restDirection = Vector3.down;

    public void Define(Kind jointKind, Vector3 hingeAxis, Vector2 hingeLimits, Vector3 raiseAxis, Vector2 raiseLimits, Vector3 restDirection)
    {
        kind = jointKind;
        this.hingeAxis = hingeAxis;
        this.raiseAxis = raiseAxis;
        hingeMin = hingeLimits.x;
        hingeMax = hingeLimits.y;
        raiseMin = raiseLimits.x;
        raiseMax = raiseLimits.y;
        this.restDirection = restDirection;
        Apply();
    }

    public void SetHinge(float degrees)
    {
        hinge = Mathf.Clamp(degrees, hingeMin, hingeMax);
        Apply();
    }

    public void SetRaise(float degrees)
    {
        raise = Mathf.Clamp(degrees, raiseMin, raiseMax);
        Apply();
    }

    public void Apply()
    {
        var swing = Quaternion.AngleAxis(hinge, hingeAxis);
        transform.localRotation = kind == Kind.Hinge
            ? swing
            : Quaternion.AngleAxis(raise, raiseAxis) * swing;
    }

    public void Drag(Vector2 pixelDelta, Camera cam)
    {
        if (pixelDelta.sqrMagnitude < 0.01f || cam == null)
            return;

        if (kind == Kind.Hinge)
        {
            var motion = ScreenMotion(cam, hinge + 1f, raise) - ScreenMotion(cam, hinge, raise);
            if (motion.sqrMagnitude < 0.25f)
                return;
            SetHinge(hinge + Vector2.Dot(pixelDelta, motion) / motion.sqrMagnitude);
            return;
        }

        var swingMotion = ScreenMotion(cam, hinge + 1f, raise) - ScreenMotion(cam, hinge, raise);
        var raiseMotion = ScreenMotion(cam, hinge, raise + 1f) - ScreenMotion(cam, hinge, raise);
        float det = swingMotion.x * raiseMotion.y - swingMotion.y * raiseMotion.x;
        if (Mathf.Abs(det) < 0.25f)
            return;

        float swingDelta = (pixelDelta.x * raiseMotion.y - pixelDelta.y * raiseMotion.x) / det;
        float raiseDelta = (swingMotion.x * pixelDelta.y - swingMotion.y * pixelDelta.x) / det;
        SetHinge(hinge + swingDelta);
        SetRaise(raise + raiseDelta);
    }

    Vector2 ScreenMotion(Camera cam, float hingeAngle, float raiseAngle)
    {
        var rotation = kind == Kind.Hinge
            ? Quaternion.AngleAxis(hingeAngle, hingeAxis)
            : Quaternion.AngleAxis(raiseAngle, raiseAxis) * Quaternion.AngleAxis(hingeAngle, hingeAxis);
        var world = transform.parent.TransformPoint(transform.localPosition + rotation * restDirection);
        return cam.WorldToScreenPoint(world);
    }
}
