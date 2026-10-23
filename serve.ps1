param([int]$Port = 8000)

$root = $PSScriptRoot
$types = @{
    '.html'  = 'text/html; charset=utf-8'
    '.css'   = 'text/css; charset=utf-8'
    '.js'    = 'text/javascript; charset=utf-8'
    '.json'  = 'application/json; charset=utf-8'
    '.svg'   = 'image/svg+xml'
    '.png'   = 'image/png'
    '.jpg'   = 'image/jpeg'
    '.ico'   = 'image/x-icon'
    '.woff2' = 'font/woff2'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    $status = 200
    try {
        $res.Headers.Add('Cache-Control', 'no-store')
        if ($req.HttpMethod -ne 'GET' -and $req.HttpMethod -ne 'HEAD') {
            $status = 405
        } else {
            $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
            if ($rel -eq '') { $rel = 'index.html' }
            $path = [IO.Path]::GetFullPath((Join-Path $root $rel))
            $inRoot = $path.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)
            $hidden = $rel -match '^\.git(/|$)'
            if ($inRoot -and -not $hidden -and [IO.File]::Exists($path)) {
                $type = $types[[IO.Path]::GetExtension($path).ToLower()]
                if (-not $type) { $type = 'application/octet-stream' }
                $res.ContentType = $type
                if ($req.HttpMethod -eq 'GET') {
                    $bytes = [IO.File]::ReadAllBytes($path)
                    $res.ContentLength64 = $bytes.Length
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            } else {
                $status = 404
            }
        }
        $res.StatusCode = $status
    } catch {
        $status = 500
        Write-Host $_.Exception.Message
        try { $res.StatusCode = 500 } catch {}
    } finally {
        try { $res.Close() } catch {}
    }
    Write-Host "$($req.HttpMethod) $($req.Url.AbsolutePath) $status"
}
