# Freckle CLI Setup

Use this reference for auth, organization selection, and active endpoint inspection.

## Auth

`freckle auth` is a device flow you run on the user's behalf whenever auth is missing or expired. It opens the approval page in the user's browser, prints a short one-time user code, and waits up to 15 minutes for approval. The credential lands directly in the CLI's local config; on this path nothing sensitive crosses the terminal or the conversation, and the user code itself is not a secret — show it to the user so they can match it in the browser.

```bash
freckle auth
freckle auth status
freckle auth status --json
```

While the command waits, tell the user to approve the request in the opened browser tab — signing in or creating an account there first is part of the same flow, and if no browser opened, give the user the printed URL and code; they can approve from any browser. The command exits 0 once approved; confirm with `freckle auth status`. When device authorization is unavailable, the command reports why; in a shell without an interactive terminal it then exits with token instructions instead of prompting.

`auth status` with no flags prints a human-readable summary. `auth status --json` prints `{ "status": "<token>" }` where the token is one of `authenticated`, `not-authenticated`, `invalid`, `network-unreachable`, or `verification-unavailable`. Read stdout; a zero exit does not mean authenticated.

Run device auth first. Use a token only when device authorization is unavailable; the user creates one at `https://next.freckle.io/cli-auth`:

```bash
freckle auth --token <frk_token>
```

Auth also resolves from `FRECKLE_CLI_TOKEN`.

## Organizations

List organizations:

```bash
freckle org list
freckle org list --token <frk_token>
freckle org list --json
```

`org list` prints an `organizations` list of `orgId` and `name`.

If exactly one organization is available, use it without asking. Otherwise, ask the user to choose from the full list. After automatic resolution or user selection, append `--org-id=<org-id>` after the complete subcommand path of every subsequent CLI command — for example, `freckle config path --org-id=<org-id>`.

## Config

Inspect CLI config and active endpoints:

```bash
freckle config path
freckle config api-base-url
freckle config app-host-url
```

Each `config` read prints one bare value rather than a mapping, so `--json` prints that value as a JSON string.

The `HTTP_API_ORIGIN` and `APP_HOST_URL` environment variables override the endpoints. `FRECKLE_CLI_PROFILE=<name>` isolates CLI config under `~/.config/freckle-<normalized-name>/config.json` (the name is lowercased and non-alphanumeric runs become `-`), which keeps concurrent agents from sharing state.
