---
name: commit
description: Stage changes, generate a commit message, and create a git commit
disable-model-invocation: true
---

Create a git commit by following these steps:

1. Run `git status` (without -uall flag) and `git diff` in parallel to see all changes
2. Run `git log --oneline -5` to match recent commit message style
3. Analyze changes and draft a concise commit message (1-2 sentences) that focuses on the "why"
4. Stage relevant files by name (never use `git add -A` or `git add .`)
5. Create the commit with the generated message, ending with:
   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
6. Run `git status` after commit to verify success

Rules:
- Do NOT push to remote unless explicitly asked
- Do NOT commit files that may contain secrets (.env, credentials, etc.)
- If there are no changes to commit, inform the user
- Use HEREDOC syntax for multi-line commit messages
