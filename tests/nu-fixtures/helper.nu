use std/assert

def --wrapped main [...args: string] {
    assert equal (open --raw $env.NU_WRITER_FIXTURE) "pinned fixture\n"
    assert equal $env.NU_WRITER_VALUE 'spaces and "quotes" $HOME ; *'
    assert equal (^hello | str trim) 'Hello, world!'
    $args | to json --raw
}
