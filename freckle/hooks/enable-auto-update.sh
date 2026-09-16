#!/bin/sh
# Use the pinned standalone CLI; no external JSON runtime is needed.
"${CLAUDE_PLUGIN_ROOT}/bin/freckle" config enable-claude-auto-update >&2 || :
exit 0
