using System.Collections.Generic;
using UnityEngine;

public static class ToeMesh
{
    public static Mesh Create(float radius, float thickness, float degrees)
    {
        int segments = 14;
        float half = degrees * 0.5f * Mathf.Deg2Rad;
        float chord = Mathf.Cos(half) * radius;
        float halfHeight = thickness * 0.5f;

        var arc = new Vector3[segments + 1];
        for (int i = 0; i <= segments; i++)
        {
            float angle = Mathf.Lerp(-half, half, i / (float)segments);
            arc[i] = new Vector3(Mathf.Sin(angle) * radius, 0f, Mathf.Cos(angle) * radius - chord);
        }

        var vertices = new List<Vector3>();
        var triangles = new List<int>();
        vertices.Add(Vector3.down * halfHeight);
        vertices.Add(Vector3.up * halfHeight);

        for (int i = 0; i <= segments; i++)
        {
            vertices.Add(arc[i] + Vector3.down * halfHeight);
            vertices.Add(arc[i] + Vector3.up * halfHeight);
        }

        int Bottom(int arcIndex) => 2 + arcIndex * 2;
        int Top(int arcIndex) => 3 + arcIndex * 2;

        for (int i = 0; i < segments; i++)
        {
            triangles.Add(0);
            triangles.Add(Bottom(i + 1));
            triangles.Add(Bottom(i));

            triangles.Add(1);
            triangles.Add(Top(i));
            triangles.Add(Top(i + 1));

            triangles.Add(Bottom(i));
            triangles.Add(Bottom(i + 1));
            triangles.Add(Top(i + 1));
            triangles.Add(Bottom(i));
            triangles.Add(Top(i + 1));
            triangles.Add(Top(i));
        }

        triangles.Add(Bottom(0));
        triangles.Add(Top(segments));
        triangles.Add(Bottom(segments));
        triangles.Add(Bottom(0));
        triangles.Add(Top(0));
        triangles.Add(Top(segments));

        var mesh = new Mesh { name = "Toes" };
        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
        return mesh;
    }
}
