## Agent skills

### Issue tracker

Issues and specs are tracked in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default triage label vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context domain documentation layout. See `docs/agents/domain.md`.

## Commit hygiene

CI runs commitlint (`@commitlint/config-conventional`) and blocks merge on violations. Run this right after every `git commit` to catch issues before push:

```bash
npx --yes -p @commitlint/cli -p @commitlint/config-conventional \
  commitlint --last --extends @commitlint/config-conventional
```

On failure, fix with `git commit --amend -m "<corrected message>"` and re-run. Amend only before the commit is pushed.
