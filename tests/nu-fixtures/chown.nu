# Logging chown double: records ownership changes instead of making them.
def --wrapped main [...args] {
    {args: ($args | each { into string })} | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
    if ($env.MOCK_FAILURE? | default '') == chown { exit 1 }
}
