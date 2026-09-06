# nu-check returns a Boolean; printing false alone would still exit successfully.
def main [...scripts: path] {
    for script in $scripts {
        if not (nu-check --debug ($script | path expand)) {
            error make {msg: $"Invalid Nushell script: ($script)"}
        }
    }
}
