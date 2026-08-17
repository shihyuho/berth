# Domain docs

Engineering skills use this repository's domain documentation when exploring the codebase.

## Before exploring

Read these when they exist:

- `CONTEXT.md` at the repository root
- Relevant ADRs under `docs/adr/`

Proceed silently when they do not exist. Create them lazily through the domain-modeling workflow when terminology or architectural decisions need to be recorded.

## Layout

This repository uses a single-context layout:

```text
/
├── CONTEXT.md
├── docs/
│   └── adr/
└── Sources/
```

## Vocabulary

Use domain terms as defined in `CONTEXT.md`. Avoid introducing synonyms that conflict with its glossary.

If a required concept is absent, first reconsider whether existing vocabulary already covers it. Otherwise, record the gap for domain modeling.

## ADR conflicts

If proposed work contradicts an existing ADR, identify the conflict explicitly rather than silently overriding the decision.
