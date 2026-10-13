# Workspace context

Call `workspace_context` to read the authenticated user, current org ID/role, and available Workspaces. Every tool operates inside the consent-selected org; no argument changes it. OAuth sign-in and token refresh belong to the MCP client. If authentication fails, reconnect the Freckle MCP server and select the intended Workspace. Do not request access tokens in chat.

For an existing resource, extract the ID after `workbooks` or `tools` in its URL, and compare the URL's org with the current context. Inspect in that Workspace. Follow cursors when finding a named target, including archived Workbooks when relevant. No match is a lookup failure, not permission to invent a replacement. For a different Workspace, use the client's OAuth reauthorization flow; one connection does not silently search all organizations.

Builder and Admin roles have this full interface. Sales reps, missing roles, and unknown roles are denied and must use Rep MCP or ask their Workspace admin for the appropriate access. A denied connection does not authorize changing roles.
