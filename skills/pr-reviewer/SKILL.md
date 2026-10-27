---
name: pr-reviewer
description: Review a git diff, branch, or pull request for security flaws, logic errors, resource leaks, and naming problems, and report findings as a severity-ranked table. Use when the user asks to review a PR, review changes, check a diff, or look over code before merging.
allowed-tools: Bash(git diff *), Bash(git log *), Bash(git show *), Bash(git status *), Read, Grep, Glob
---

# PR Reviewer

Review the changes the user points to. If no target is given, review the current branch against its merge base with the default branch.

## Find the changes

1. Determine the base: `git merge-base HEAD origin/main` (fall back to `origin/master`, then `HEAD~1`).
2. List changed files with `git diff --stat <base>...HEAD` and include uncommitted changes from `git diff` and `git diff --cached`.
3. Read each changed file in full where the diff alone does not show enough context to judge the change.

## What to check

- **Security:** injection (SQL, shell, path, template), secrets committed to source, missing authorization checks, unsafe deserialization, unvalidated input reaching sensitive APIs.
- **Correctness:** off-by-one errors, null or undefined handling, wrong conditions, unhandled error paths, race conditions, broken edge cases introduced by the change.
- **Resources:** unclosed files, connections, streams or sessions; unbounded caches or collections; work done in a loop that belongs outside it.
- **Naming and structure:** names that do not match the surrounding code's conventions, dead code, duplicated logic that already exists elsewhere in the repository.

Only report issues introduced or exposed by the change. Do not flag style preferences the codebase does not already follow.

## Output

A markdown table, most severe first:

| Severity | File:Line | Issue | Suggested fix |
|---|---|---|---|

Severity is one of `critical`, `high`, `medium`, `low`. If nothing is found, say so plainly and list what was reviewed.
