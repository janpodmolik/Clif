---
name: bug
description: Investigate a bug by analyzing code and finding root cause
disable-model-invocation: true
---

Investigate the bug described by the user: $ARGUMENTS

Steps:
1. Parse the bug description and any logs/error messages provided
2. Search the codebase for relevant files — use Grep and Glob to find related code
3. Read and understand the relevant code paths
4. Identify the root cause with specific file:line references
5. Propose a fix with clear explanation of what went wrong and why

Output format:
- **Symptom**: What the user sees
- **Root cause**: Why it happens (with code references)
- **Fix**: What needs to change

Do NOT apply the fix automatically — present the analysis first and wait for the user to confirm.
