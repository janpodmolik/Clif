---
name: push
description: Push current branch to remote
disable-model-invocation: true
---

Push the current branch to the remote repository:

1. Run `git status` to check if branch is ahead of remote
2. Run `git log --oneline origin/HEAD..HEAD` to show what will be pushed
3. If there are commits to push, run `git push`
4. If the branch has no upstream, use `git push -u origin <branch-name>`
5. Show the result

Rules:
- NEVER force push unless the user explicitly asks for it
- Warn if pushing to main/master directly
