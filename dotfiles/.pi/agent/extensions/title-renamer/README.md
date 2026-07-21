# Title renamer

Local fork of [`pi-title-renamer` 0.1.3](https://github.com/mkioutcc/pi-title-renamer).

It adds the `first-user-message` trigger. Title generation starts after the first
prompt is submitted and runs concurrently with the main agent request, so it
does not delay the response. The upstream `first-agent-end` trigger remains
available.
