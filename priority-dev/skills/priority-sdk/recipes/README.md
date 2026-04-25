# Priority SDK Quick Recipes

Atomic, NLP-discoverable recipes for routine Priority development tasks.

Each recipe is self-contained: preconditions, the calls to make, and how to verify success. Pick the right recipe by matching the user's phrasing against the table in `../SKILL.md` § "Quick Recipes".

If your task isn't in the catalog, use the topical references one level up: `../references/forms.md`, `../references/procedures.md`, etc.

Template (every recipe uses this shape):

- `# <Title>` — verb-first, matches user phrasing
- `**Triggers:**` — comma-separated phrases the user is likely to type
- `**Before:**` — preconditions (verify entity name, etc.)
- `**Calls:**` — numbered sequence of WebSDK / SQLI calls, with placeholders
- `**After:**` — how to confirm success
- `**See also:**` — back-pointers to references and common-mistakes
