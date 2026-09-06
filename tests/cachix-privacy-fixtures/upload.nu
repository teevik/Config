def main [] {
    $"($env.OUT_PATHS)\n" | save --append $env.UPLOAD_LOG
    exit ($env.UPLOAD_STATUS? | default '0' | into int)
}
