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
    public int number;
    public string label;
    public DragLimit limit = DragLimit.Both;

    public enum DragLimit
    {
        Both,
        Forward,
        Out,
        Locked
    }

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
        if (pixelDelta.sqrMagnitude < 0.25f || cam == null || limit == DragLimit.Locked)
            return;

        if (kind == Kind.Hinge || limit == DragLimit.Forward)
        {
            SetHinge(hinge + AxisDegrees(pixelDelta, cam, true, 1f));
            return;
        }

        if (limit == DragLimit.Out)
        {
            SetRaise(raise + AxisDegrees(pixelDelta, cam, false, 1f));
            return;
        }

        SetHinge(hinge + AxisDegrees(pixelDelta, cam, true, 1f));
        SetRaise(raise + AxisDegrees(pixelDelta, cam, false, 1f));
    }

    public void DragLower(Vector2 pixelDelta, Camera cam)
    {
        if (pixelDelta.sqrMagnitude < 0.25f || cam == null || limit == DragLimit.Locked)
            return;

        OrbitParent(AxisDegrees(pixelDelta, cam, true, -1f));
    }

    public void OrbitParent(float deltaDegrees)
    {
        if (transform.parent == null || Mathf.Abs(deltaDegrees) < 0.0001f)
            return;

        float before = hinge;
        hinge = Mathf.Clamp(hinge - deltaDegrees, hingeMin, hingeMax);
        float used = before - hinge;
        if (Mathf.Abs(used) < 0.0001f)
            return;

        var root = transform.parent;
        var axis = root.TransformDirection(hingeAxis);
        var pivot = transform.position;
        var turn = Quaternion.AngleAxis(used, axis);
        root.position = pivot + turn * (root.position - pivot);
        root.rotation = turn * root.rotation;
        Apply();
    }

    float AxisDegrees(Vector2 pixelDelta, Camera cam, bool swing, float directionSign)
    {
        const float sample = 20f;
        var motion = swing
            ? ScreenMotion(cam, hinge + sample, raise, directionSign) - ScreenMotion(cam, hinge, raise, directionSign)
            : ScreenMotion(cam, hinge, raise + sample, directionSign) - ScreenMotion(cam, hinge, raise, directionSign);

        if (motion.sqrMagnitude >= 16f)
            return Vector2.Dot(pixelDelta, motion) / motion.sqrMagnitude * sample;

        var perp = ScreenPerp(cam, swing ? hingeAxis : raiseAxis);
        float pixels = Vector2.Dot(pixelDelta, perp);
        float sign = motion.sqrMagnitude > 0.05f
            ? Mathf.Sign(Vector2.Dot(motion, perp))
            : TowardCameraSign(cam, swing, perp, directionSign);
        if (Mathf.Abs(sign) < 0.01f)
            sign = 1f;
        return pixels * 0.55f * sign;
    }

    Vector2 ScreenPerp(Camera cam, Vector3 localAxis)
    {
        var origin = (Vector2)cam.WorldToScreenPoint(transform.position);
        var axisWorld = transform.parent.TransformDirection(localAxis);
        var tip = (Vector2)cam.WorldToScreenPoint(transform.position + axisWorld * 0.2f);
        var axis = tip - origin;
        if (axis.sqrMagnitude < 0.01f)
            return Vector2.up;
        axis.Normalize();
        return new Vector2(-axis.y, axis.x);
    }

    float TowardCameraSign(Camera cam, bool swing, Vector2 perp, float directionSign)
    {
        var before = TipWorld(hinge, raise, directionSign);
        var after = swing ? TipWorld(hinge + 20f, raise, directionSign) : TipWorld(hinge, raise + 20f, directionSign);
        float toward = Vector3.Dot(after - before, cam.transform.forward);
        float up = Vector2.Dot(Vector2.up, perp);
        if (Mathf.Abs(up) < 0.2f)
            up = 1f;
        return toward >= 0f ? Mathf.Sign(up) : -Mathf.Sign(up);
    }

    Vector3 TipWorld(float hingeAngle, float raiseAngle, float directionSign)
    {
        var rotation = kind == Kind.Hinge
            ? Quaternion.AngleAxis(hingeAngle, hingeAxis)
            : Quaternion.AngleAxis(raiseAngle, raiseAxis) * Quaternion.AngleAxis(hingeAngle, hingeAxis);
        return transform.parent.TransformPoint(transform.localPosition + rotation * (restDirection * directionSign));
    }

    Vector2 ScreenMotion(Camera cam, float hingeAngle, float raiseAngle, float directionSign)
    {
        return cam.WorldToScreenPoint(TipWorld(hingeAngle, raiseAngle, directionSign));
    }
}
