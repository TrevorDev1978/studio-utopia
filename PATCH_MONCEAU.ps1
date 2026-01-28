# PATCH_MONCEAU.ps1
# Usage:
#   cd C:\www.kellybehun.com
#   powershell -ExecutionPolicy Bypass -File .\PATCH_MONCEAU.ps1 -Path ".\miami-home.html"
#
param(
  [Parameter(Mandatory=$true)]
  [string]$Path
)

if (!(Test-Path $Path)) {
  Write-Host "File not found: $Path" -ForegroundColor Red
  exit 1
}

$html = Get-Content -Raw -Encoding UTF8 $Path

# 1) Disable Squarespace ImageLoader bootstrapper (it overwrites src with placeholders / remote)
$html = $html -replace '<script\s+data-sqs-type="imageloader-bootstrapper"[\s\S]*?</script>', '<!-- imageloader-bootstrapper disabled for local export -->'

# 2) Inject a local-image "forcer" right before </body> (idempotent)
$marker = "<!-- LOCAL_MONCEAU_FORCE_IMAGES -->"
if ($html -notmatch [regex]::Escape($marker)) {
  $inject = @"
$marker
<script>
(function(){
  function forceLocalMonceauImages(){
    var imgs = document.querySelectorAll('img[data-src], img[data-image]');
    imgs.forEach(function(img){
      var cand = img.getAttribute('data-src') || img.getAttribute('data-image');
      if(!cand) return;
      // Only touch the Monceau local set
      if(cand.indexOf('images/monceau/') === -1) return;

      // Build an absolute path (safe for root-served exports)
      var clean = cand.replace(/^(\.\.\/)+/,''); // strip ../
      if(clean.charAt(0) !== '/') clean = '/' + clean;

      // Prevent Squarespace loader from overriding again
      img.removeAttribute('data-loader');
      img.removeAttribute('data-load');
      img.removeAttribute('data-src');
      img.removeAttribute('data-image');
      img.removeAttribute('srcset');
      img.removeAttribute('sizes');

      img.setAttribute('src', clean);
      img.loading = 'eager';
      img.decoding = 'async';

      // Keep it visible even if original CSS expects cover
      img.style.width = '100%';
      img.style.height = 'auto';
      img.style.objectFit = 'contain';
      img.style.objectPosition = '50% 50%';
    });
  }

  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', forceLocalMonceauImages);
  } else {
    forceLocalMonceauImages();
  }

  // Run again after Squarespace scripts finish
  setTimeout(forceLocalMonceauImages, 250);
  setTimeout(forceLocalMonceauImages, 1000);
})();
</script>
"@

  $html = $html -replace '</body>', ($inject + "`r`n</body>")
}

# 3) Write patched copy next to original
$outPath = [IO.Path]::Combine([IO.Path]::GetDirectoryName((Resolve-Path $Path)), ([IO.Path]::GetFileNameWithoutExtension($Path) + "_PATCHED.html"))
Set-Content -Encoding UTF8 -Path $outPath -Value $html

Write-Host "✅ Patched file written:" -ForegroundColor Green
Write-Host $outPath -ForegroundColor Cyan
