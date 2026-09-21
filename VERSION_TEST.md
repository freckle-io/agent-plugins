# Claude version guidance preview

Pair this branch with `codex/claude-version-guidance` in freckle-io/next.
The only runtime change marks plugin-launched CLI requests when running in Claude.
The test CLI exchanges API compatibility versions and emits update instructions.
Codex manifests/hooks and existing Claude hooks are unchanged.

The production CLI pin remains unchanged intentionally: no preview binary has
been published. Installing this branch alone will not enable the new check.
The local integration harness copies this plugin, substitutes its compiled test
CLI pin, and stages that binary in an isolated cache:

```sh
cd /tmp/freckle-version-guidance
bun apps/cli/scripts/test-claude-version-guidance.ts /tmp/freckle-plugin-version-guidance/freckle
```

See `apps/cli/CLAUDE_VERSION_TEST.md` in the next test worktree for build commands,
version policy, results, and remaining Desktop verification. Do not merge this
preview version or publish it as a production release.
