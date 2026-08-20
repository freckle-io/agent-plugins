#!/bin/sh
# Shared approval hook for the Freckle plugin across Claude Code and Codex.
# Each agent prompts before running shell commands; this auto-approves a
# `freckle` CLI call (optionally piped through a small set of read-only
# helpers, or `;`-chained with only `freckle` / `echo` / `printf` clauses) so
# the plugin stops asking on every invocation. The verdict shape differs per
# agent, selected by the first argument: claude | codex.
#
#   claude -> PreToolUse           (input .tool_input.command)
#   codex  -> PermissionRequest    (input .tool_input.command)
#
# "allow" only skips the prompt; deny/ask rules (including managed deny lists)
# still take precedence, so this can't punch through an admin block. Conservative
# by design: any command that redirects, substitutes, or expands the environment
# (`&`, `&&`, `||`, `>`, `<`, backticks, `$(…)`, any `$` parameter expansion
# like `$VAR`/`${VAR}`, or a backslash escape `\`) falls through to the normal
# prompt rather than being approved. Unquoted `|` and `;` are allowed as segment
# breaks under the rules below (see the awk pass); quoted `|`/`;` inside args
# are not separators. Semicolon clauses are stricter than pipes: file-reading
# helpers (`cat`, `jq`, …) are pipe-only, so `cat .env; freckle org list`
# cannot auto-approve and dump a cwd file into the agent context.

agent="${1:-claude}"

# Pipeline helpers allowed alongside `freckle` when joined by `|`. Read-only by
# intent; this is the security-relevant surface, kept in one place for review.
# `echo`/`printf` never open a file or socket, so they are exempt from the
# path/file-flag guards below -- but unquoted glob/tilde chars are still
# refused for every helper (including echo/printf), on both `|` and `;`, so
# shell expansion can't turn `echo .*` into a cwd listing under auto-approve.
# Semicolon-chained clauses may only use `freckle`, `echo`, or `printf` (not
# the rest of this list).
allowed_helpers="jq cat head tail wc grep sort uniq column tr echo printf"

# `freckle` subcommands that never auto-approve: credential and auth flows
# (`auth`, `connect`, `connection`, `connections` write or expose credentials),
# plus commands that modify the machine outside the working directory
# (`skills` writes agent skill directories, `update` replaces the installed
# binary, `org` can rewrite shared global config via `org switch`).
gated_subcommands="auth connect connection connections skills update org"

# Harden: no globbing, and unset variables are errors so a typo can't silently
# widen approval.
set -fu

# Fail open to the normal prompt if we lack the tools we rely on to parse the
# event (jq) or to vet the command (awk). Without awk the structure/operand
# checks can't run, so we must not approve.
command -v jq > /dev/null 2>&1 || exit 0
command -v awk > /dev/null 2>&1 || exit 0

input="$(cat)"

# Claude PreToolUse / Codex PermissionRequest both gate the Bash tool. One jq
# pass yields the command only for Bash; anything else comes back empty and
# falls through to the normal prompt below.
cmd="$(printf '%s' "$input" | jq -r 'if .tool_name == "Bash" then .tool_input.command // empty else empty end' 2> /dev/null)"

[ -n "$cmd" ] || exit 0

# Strip harmless redirections before the safety checks so they don't block
# otherwise-valid freckle pipelines. Only two shapes are removed: redirects
# whose target is /dev/null (anchored to a word boundary so we never eat a
# prefix of a real path like /dev/nullX), and fd-to-fd duplications (2>&1,
# 1>&2). Any redirection to a real file is intentionally left intact so it
# still falls through to the prompt.
cmd_stripped="$(printf '%s' "$cmd" | sed -E '
  s#([0-9]*|&)>>?[[:space:]]*/dev/null([[:space:]]|$)#\2#g
  s/[0-9]*>&[0-9]+//g
')"

# Reject redirection / substitution / env expansion / backgrounding outright.
# Runs on the raw (quoted) string so even a quoted `>`/`$`/etc. is conservatively
# refused. Unquoted `|` and `;` are handled as segment breaks in the awk pass
# below (not rejected here). The backslash is rejected too: the segment splitter
# below is not backslash-aware, so a `\"`/`\|`/`\;` would let awk and the shell
# disagree on where segments start and end (a total allowlist bypass). Refusing
# any `\` closes that desync.
case "$cmd_stripped" in
  *'&'* | *'<'* | *'>'* | *'`'* | *'$'* | *'\'*) exit 0 ;;
esac

# Reject multi-line commands (heredocs, embedded scripts).
[ "$(printf '%s' "$cmd_stripped" | wc -l | tr -d ' ')" = "0" ] || exit 0

# Bound the input so the char-by-char awk pass below can't be forced to scan an
# unbounded string.
[ "${#cmd_stripped}" -le 10000 ] || exit 0

# Validate the pipeline/chain in a single quote-aware pass. awk first splits on
# unquoted `;` into clauses, then each clause on unquoted `|` into segments (so
# a `|` or `;` inside jq/grep args or a quoted freckle arg is not a separator;
# the `\`-reject guard above keeps this splitter in sync with the shell), trims
# surrounding whitespace per segment, then:
#   - any segment that leads with a `VAR=value` env-var assignment is rejected
#     outright -- we never vet the variable, so a prefix like `LD_PRELOAD=`,
#     `FRECKLE_CLI_TOKEN=`, or `FRECKLE_CONFIG_HOME=` must not ride in as a
#     plain call (the skill's documented `export FRECKLE_ORG_ID=...` runs as
#     its own prompted command, not under auto-approve);
#   - at least one segment across all clauses must be `freckle` (its own
#     path/URL args are left alone), so the pipeline/chain stays anchored to a
#     freckle call wherever it sits;
#   - the `freckle` segment's first non-flag word is refused if it is a gated
#     subcommand (auth, connect, connection, connections, skills, update, org)
#     so credential flows and machine-level changes never auto-approve;
#     ordinary read/build subcommands (workbook, workflow, dataset, credit,
#     config, status, ...) still do;
#   - within a `|` pipeline that contains `freckle`, every other segment's
#     command must be in the helper allowlist (membership is an exact key
#     lookup, so a token like `*` can't wildcard its way in);
#   - semicolon clauses with no `freckle` may only be `echo` or `printf` -- not
#     file-reading helpers -- so `cat .env; freckle org list` cannot
#     auto-approve and print a cwd file straight into the agent context;
#   - every helper segment (including echo/printf, on both `|` and `;`) must
#     not contain an unquoted glob or tilde metacharacter (`*`, `?`, `[`, `~`),
#     so the shell can't expand `echo .*` / `cat *.env` into a cwd listing
#     under auto-approve; quoted forms like `echo "*"` are fine;
#   - every non-echo/printf helper segment must not reference a path (`/`, `~`)
#     or a read/write file flag (long `--output`/`--file` or short clusters
#     containing `o`/`f`, attached value or not) -- helpers must transform
#     stdin, not open files. These checks apply to helpers on both sides of
#     freckle, so neither `cat /etc/passwd | freckle` nor
#     `freckle | cat /etc/passwd` slips by, and `freckle | sort -oPWNED.txt`
#     can't write a cwd file; quoted text is scanned too, so cat "/etc/passwd"
#     can't either. `echo` and `printf` are exempt from the path/flag guards (a
#     `/` in their args is data -- JSON, a URL -- not a file read) but not from
#     the unquoted glob/tilde guard. The `$`-reject guard above is what keeps
#     remaining args literal -- otherwise `printf "$SECRET"` would expand an
#     env var into freckle's stdin under the echo/printf exemption.
# Residual, knowingly accepted for `|` only: bare cwd-relative names (e.g.
# `cat .env | freckle`) aren't caught; since no allowlisted helper can reach
# the network or redirect, such a read stays in the agent's context and still
# can't be exfiltrated without a separate, non-approved (prompted) command.
# Semicolon chaining no longer widens that residual to standalone helper
# stdout.
verdict="$(printf '%s' "$cmd_stripped" | awk -v helpers="$allowed_helpers" -v gated="$gated_subcommands" '
  BEGIN {
    n = split(helpers, a, " ")
    for (i = 1; i <= n; i++) H[a[i]] = 1
    nd = split(gated, d, " ")
    for (i = 1; i <= nd; i++) D[d[i]] = 1
    sq = sprintf("%c", 39)
  }
  # True if t has an unquoted *, ?, [, or ~ (shell glob / tilde expansion).
  function has_unquoted_glob_or_tilde(t,    i, c, inq) {
    inq = ""
    for (i = 1; i <= length(t); i++) {
      c = substr(t, i, 1)
      if (inq != "") { if (c == inq) inq = ""; continue }
      if (c == sq || c == "\"") { inq = c; continue }
      if (c == "*" || c == "?" || c == "[" || c == "~") return 1
    }
    return 0
  }
  function check_freckle(t,    rest, m, w, j, sc) {
    rest = t
    sub(/^freckle([ \t]+|$)/, "", rest)
    m = split(rest, w, /[ \t]+/)
    sc = ""
    for (j = 1; j <= m; j++) {
      if (w[j] == "") continue
      if (substr(w[j], 1, 1) == "-") continue
      sc = w[j]; break
    }
    gsub(/"/, "", sc); gsub(sq, "", sc)
    if (sc ~ /[][*?]/) return 0
    if (sc in D) return 0
    return 1
  }
  function check_helper(t, tok, pipe_ok,    allow) {
    if (pipe_ok) {
      if (!(tok in H)) return 0
      allow = 1
    } else {
      if (tok != "echo" && tok != "printf") return 0
      allow = 1
    }
    # Shared across | and ; : refuse unquoted glob/tilde so echo/printf
    # (and other helpers) cannot expand into a cwd listing under auto-approve.
    if (allow && has_unquoted_glob_or_tilde(t)) return 0
    if (allow && tok != "echo" && tok != "printf") {
      if (index(t, "/") > 0) return 0
      if (index(t, "~") > 0) return 0
      if (t ~ /(^|[ \t])--(output|file)([ \t]|=|$)/) return 0
      if (t ~ /(^|[ \t])-[A-Za-z]*[of]/) return 0
    }
    return 1
  }
  {
    inq = ""; nclause = 0; cur = ""
    for (i = 1; i <= length($0); i++) {
      c = substr($0, i, 1)
      if (inq != "") { cur = cur c; if (c == inq) inq = ""; continue }
      if (c == sq || c == "\"") { inq = c; cur = cur c; continue }
      if (c == ";") { clause[nclause++] = cur; cur = ""; continue }
      cur = cur c
    }
    clause[nclause++] = cur

    saw_freckle = 0
    for (cl = 0; cl < nclause; cl++) {
      inq = ""; nseg = 0; cur = ""; cl_raw = clause[cl]
      for (i = 1; i <= length(cl_raw); i++) {
        c = substr(cl_raw, i, 1)
        if (inq != "") { cur = cur c; if (c == inq) inq = ""; continue }
        if (c == sq || c == "\"") { inq = c; cur = cur c; continue }
        if (c == "|") { seg[nseg++] = cur; cur = ""; continue }
        cur = cur c
      }
      seg[nseg++] = cur

      cl_freckle = 0
      for (s = 0; s < nseg; s++) {
        t = seg[s]
        sub(/^[ \t]+/, "", t)
        sub(/[ \t]+$/, "", t)
        if (t == "") exit
        if (t ~ /^[A-Za-z_][A-Za-z0-9_]*=/) exit
        tok = t
        sub(/[ \t].*$/, "", tok)
        if (tok == "freckle") cl_freckle = 1
      }
      if (cl_freckle) saw_freckle = 1

      for (s = 0; s < nseg; s++) {
        t = seg[s]
        sub(/^[ \t]+/, "", t)
        sub(/[ \t]+$/, "", t)
        tok = t
        sub(/[ \t].*$/, "", tok)
        if (tok == "freckle") {
          if (!check_freckle(t)) exit
        } else if (!check_helper(t, tok, cl_freckle)) {
          exit
        }
      }
    }
    if (saw_freckle) print "allow"
  }
')"

[ "$verdict" = "allow" ] || exit 0

case "$agent" in
  codex)
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    ;;
  claude | *)
    # claude (PreToolUse) is the default; an unknown agent also lands here, which
    # is safe because we only ever emit an allow after passing the checks above.
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"freckle CLI is allowlisted by the Freckle plugin"}}'
    ;;
esac
