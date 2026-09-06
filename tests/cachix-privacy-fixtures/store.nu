def --wrapped main [...args: string] {
    if ($args | length) != 3 or ($args | first 2) != [--query --requisites] { exit 2 }
    let closure = match $args.2 {
        '/nix/store/test-safe' => [test-safe test-public-library]
        '/nix/store/test-marble' => [test-marble]
        '/nix/store/test-wrapper' => [test-wrapper test-middle test-marble]
        '/nix/store/test-astal-wrapper' => [test-astal-wrapper test-astal]
        '/nix/store/test-uppercase' => [test-uppercase test-Marble]
        '/nix/store/test-empty' => []
        _ => { exit 1 }
    }
    for entry in $closure { print $"/nix/store/($entry)" }
}
