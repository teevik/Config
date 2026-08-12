# OMP extension workspace

## Scope

- This directory is an independent project for personal OMP TypeScript extensions.
- Do not import, copy, symlink, or configure extensions from `.pi`.
- OMP automatically discovers `extensions/<name>/index.ts`. Keep shared modules in `src/` and tests in
  `test/`; loose helper files directly under `extensions/` may be mistaken for extension entry points.
- Import OMP APIs from `@oh-my-pi/pi-coding-agent` and keep that package pinned to the installed OMP
  version.

## Required workflow

1. Install exactly the lockfile dependencies with `npm ci`.
2. Make the smallest coherent change and add or update tests for behavior you change.
3. Run `npm run format` after editing.
4. Run `npm run check`. Work is complete only when formatting, Effect-aware typechecking, and tests pass.
5. For runtime changes, restart OMP and exercise the affected command, tool, or event handler manually.

Effect v4 is pre-release software. Before changing Effect code, read `node_modules/effect/AGENTS.md` and
the relevant version-matched files it points to under `node_modules/effect/ai-docs/`. When an API is still
uncertain or dependencies are upgraded, verify it against the installed declarations and current official
Effect documentation instead of relying on v3 examples. See
`../../../../docs/research/omp-effect-v4-extension-scaffold.md` for the version and design research behind
this workspace.

## Extension boundaries

- Keep each `index.ts` thin: register commands, tools, and event handlers there, then delegate behavior to
  Effect programs in adjacent modules or `src/`.
- Extension factories run in OMP's process and are unsandboxed. Do only registration during factory load;
  perform file, network, subprocess, or UI work inside registered handlers.
- Return a `Promise` from OMP async boundaries by running one fully-provided Effect with
  `Effect.runPromise`. Do not call `Effect.run*` from inside another Effect.
- Model expected failures in the Effect error channel and handle them before returning to OMP. Log defects
  with `pi.logger`, and give the user a concise UI notification when recovery is not possible.
- Use `pi.zod` for OMP tool parameter schemas. Use Effect Schema for domain parsing and validation after
  values enter the extension.
- Use the timer methods supplied by the OMP extension context for detached UI callbacks. Inside an Effect
  workflow, use Effect timing and scheduling APIs. Raw detached timer callbacks can crash the host process.
- Treat cancellation as normal control flow: pass OMP's `AbortSignal` into interruptible Effect adapters
  and acquire external resources with scoped Effect APIs so finalizers run.

## Effect v4 conventions

- Core fallible or asynchronous workflows return `Effect`; keep pure transformations as ordinary
  functions.
- Compose with `Effect.gen`, `yield*`, and `.pipe(...)`. Wrap Promise APIs with `Effect.tryPromise` and give
  failures a domain-specific tagged error rather than throwing or using the global `Error` as the error
  channel.
- Define replaceable dependencies as Effect services and provide them with Layers at the extension
  boundary. Use scoped Layers or `Effect.acquireRelease` for resources with cleanup.
- Prefer Effect services for clocks, configuration, logging, randomness, HTTP, and concurrency when they
  make behavior testable. Avoid hidden reads from globals inside core programs.
- Keep error and requirement channels precise: do not erase them with `any`, `unknown`, unsafe assertions,
  or premature `orDie` calls.

## Tests and dependencies

- Use `@effect/vitest`: `it.effect` for Effect programs and ordinary `it` for pure code. Exercise success,
  expected failure, cancellation, and resource cleanup when those paths exist.
- Provide test Layers at the test boundary; do not reach real credentials, networks, or user state in unit
  tests.
- Put packages imported at OMP runtime in `dependencies`; tooling and type-only host packages belong in
  `devDependencies`. Pin Effect v4 and its Effect ecosystem packages to the same exact release line.
- Never log secrets or commit credentials, generated databases, session state, or `node_modules`.
