# Exercise real toplevel evaluation, bypassing cached warning-free results.
# Ignore only the Git worktree notice; never suppress evaluation warnings.
def main [...hosts: string] {
    cd ($env.FILE_PWD | path dirname)
    let hosts = if ($hosts | is-empty) { [zenbook] } else { $hosts }
    mut status = 0
    for host in $hosts {
        let result = (^nix eval --option eval-cache false --option warn-dirty false
            --abort-on-warn --show-trace
            --raw $".#nixosConfigurations.($host).config.system.build.toplevel.drvPath"
            | complete)
        if $result.exit_code != 0 {
            print --stderr --no-newline $result.stderr
            print --stderr $"FAIL: ($host) could not be evaluated"
            $status = 1
        } else if $result.stderr =~ '(^|\s)warning:' {
            print --stderr --no-newline $result.stderr
            print --stderr $"FAIL: ($host) emitted evaluation warnings"
            $status = 1
        } else {
            print $"PASS: ($host) evaluates without warnings"
        }
    }
    exit $status
}
