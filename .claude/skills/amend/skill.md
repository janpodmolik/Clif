---
name: amend
description: Stage current changes and amend them into the last commit
disable-model-invocation: true
---

Amend the last git commit with current changes:

1. Run `git status` (without -uall flag) and `git diff` in parallel to see all changes
2. Run `git log --oneline -1` to show the commit being amended
3. Stage relevant files by name (never use `git add -A` or `git add .`)
4. Amend the commit: `git commit --amend --no-edit`
5. Run `git status` after amend to verify success

Rules:
- Do NOT push to remote unless explicitly asked
- Do NOT commit files that may contain secrets (.env, credentials, etc.)
- If there are no changes to amend, inform the user
- Keep the existing commit message (--no-edit) unless the user asks to change it
