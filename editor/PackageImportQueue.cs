using System;
using System.IO;
using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
static class PackageImportQueue
{
    static readonly string Dir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".cache/unity-import");
    static double next;

    static PackageImportQueue() { EditorApplication.update += Poll; }

    static void Poll()
    {
        if (EditorApplication.timeSinceStartup < next) return;
        next = EditorApplication.timeSinceStartup + 0.5;
        if (!Directory.Exists(Dir) || EditorApplication.isCompiling || EditorApplication.isPlaying) return;

        foreach (var job in Directory.GetFiles(Dir, "*.job"))
        {
            var claimed = job + ".claimed";
            try { File.Move(job, claimed); } catch (IOException) { continue; }
            var age = DateTime.UtcNow - File.GetLastWriteTimeUtc(claimed);
            var path = File.ReadAllText(claimed).Trim();
            File.Delete(claimed);

            if (age.TotalSeconds >= 60) Debug.LogWarning("Package import expired: " + path);
            else if (!File.Exists(path)) Debug.LogWarning("Package not found: " + path);
            else AssetDatabase.ImportPackage(path, true);
        }
    }
}
