param(
    [Parameter(Mandatory = $true)] [string]$InputPath,
    [Parameter(Mandatory = $true)] [string]$OutputPath,
    [int]$BrightnessThreshold = 224,
    [int]$NeutralTolerance = 24
)

Add-Type -AssemblyName System.Drawing
$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
Add-Type -ReferencedAssemblies $drawingAssembly -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class CheckerboardCleaner {
    public static void Run(string inputPath, string outputPath, int brightnessThreshold, int neutralTolerance) {
        using (var source = new Bitmap(inputPath))
        using (var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(output)) g.DrawImageUnscaled(source, 0, 0);
            int width = source.Width, height = source.Height;
            var visited = new bool[width * height];
            var queue = new int[width * height];
            int head = 0, tail = 0;
            Action<int, int> enqueue = (x, y) => {
                if (x < 0 || y < 0 || x >= width || y >= height) return;
                int index = y * width + x;
                if (visited[index]) return;
                visited[index] = true;
                Color c = source.GetPixel(x, y);
                int max = Math.Max(c.R, Math.Max(c.G, c.B));
                int min = Math.Min(c.R, Math.Min(c.G, c.B));
                int brightness = (c.R + c.G + c.B) / 3;
                if (brightness >= brightnessThreshold && max - min <= neutralTolerance) queue[tail++] = index;
            };
            for (int x = 0; x < width; x++) { enqueue(x, 0); enqueue(x, height - 1); }
            for (int y = 1; y < height - 1; y++) { enqueue(0, y); enqueue(width - 1, y); }
            while (head < tail) {
                int index = queue[head++];
                int x = index % width, y = index / width;
                output.SetPixel(x, y, Color.Transparent);
                enqueue(x - 1, y); enqueue(x + 1, y); enqueue(x, y - 1); enqueue(x, y + 1);
            }
            string parent = System.IO.Path.GetDirectoryName(System.IO.Path.GetFullPath(outputPath));
            if (!String.IsNullOrEmpty(parent)) System.IO.Directory.CreateDirectory(parent);
            output.Save(outputPath, ImageFormat.Png);
        }
    }
}
'@

[CheckerboardCleaner]::Run((Resolve-Path -LiteralPath $InputPath), $OutputPath, $BrightnessThreshold, $NeutralTolerance)
Write-Host "CHECKERBOARD_REMOVED: $OutputPath"
