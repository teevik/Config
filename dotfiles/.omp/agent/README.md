# OMP extensions

This is the standalone TypeScript workspace for personal OMP extensions. It does not load, link, or
copy extensions from `.pi`.

Install and verify it with:

```sh
npm ci
npm run check
```

OMP automatically loads each `extensions/<name>/index.ts` entry point. The included example registers
`/effect-health`; restart OMP, then run that command to smoke-test the runtime integration.

OMP also loads the user-level `mcp.json` and `skills/` directory from this workspace. The
`agent-workspace-linux` server uses OMP's native MCP support, so no extension is required. Restart OMP
and run `/mcp test agent-workspace-linux` before first use.

Keep reusable code in `src/` and tests in `test/`. Runtime packages imported by extensions belong in
`dependencies`, because OMP resolves them from this workspace's `node_modules` directory.
