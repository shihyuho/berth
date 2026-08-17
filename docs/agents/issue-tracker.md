# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`
- **Read an issue**: `gh issue view <number> --comments`
- **List issues**: `gh issue list` with appropriate state and label filters
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply or remove labels**: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`
- **Close an issue**: `gh issue close <number> --comment "..."`

Infer the repository from `git remote -v`; `gh` does this automatically inside the clone.

## Pull requests as a triage surface

**PRs as a request surface: no.**

GitHub shares one number space across issues and pull requests. If a bare reference such as `#42` is ambiguous, try `gh pr view 42` and fall back to `gh issue view 42`.

## Skill operations

When a skill says “publish to the issue tracker,” create a GitHub issue.

When a skill says “fetch the relevant ticket,” run:

```sh
gh issue view <number> --comments
```

## Wayfinding operations

The map is a GitHub issue labelled `wayfinder:map`; its tickets are linked as sub-issues.

- Represent blocking relationships with GitHub native issue dependencies.
- If native sub-issues or dependencies are unavailable, use task lists and explicit `Blocked by: #<number>` lines.
- Claim a ticket with `gh issue edit <number> --add-assignee @me`.
- Resolve it by commenting with the answer, closing the ticket, and recording the resulting context in the map.
