---
name: review
description: Code review of recent changes or a specific commit
disable-model-invocation: true
---

Perform a code review on current changes or recent commits.

If $ARGUMENTS is provided, review that specific commit or range.
Otherwise, review uncommitted changes (staged + unstaged).

Steps:
1. Run `git diff` (or `git show <commit>` if a commit was specified) to see the changes
2. Read the full context of modified files to understand the surrounding code
3. Review for:
   - Correctness and potential bugs
   - Edge cases that might be missed
   - Consistency with existing patterns in the codebase
   - Security issues (OWASP top 10)
4. Provide a concise summary:
   - What the changes do
   - Any issues found (with file:line references)
   - Whether the changes look good to commit

Keep the review focused and actionable. Don't nitpick style if it matches the existing codebase.
