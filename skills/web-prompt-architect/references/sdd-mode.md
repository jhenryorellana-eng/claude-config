# SDD mode — spec-driven scaffold for bigger builds

A single hero or one-pager only needs the build prompt from `prompt-template.md`. But when the person
is building a **multi-section site, a multi-page app, or something they'll keep iterating on**, a
single mega-prompt gets unwieldy and the agent loses the thread. That's what Spec-Driven Development
(SDD) solves: split intent into layered artifacts, each feeding the next, with a governing
constitution so every feature stays consistent.

This mirrors GitHub's Spec Kit flow: **Constitution → Specify → (Clarify) → Plan → Tasks →
(Analyze) → Implement → Verify.** Each phase produces a Markdown artifact that becomes the agent's
context, so output stays consistent across sessions and even across different agents.

## When to use SDD mode

Use it when ≥2 of these are true: multiple pages/routes, a shared component system, reused design
tokens across sections, ongoing iteration, or more than one person touching the build. Skip it for a
one-shot hero — the overhead isn't worth it there.

## The artifact structure

```
project/
├── spec/
│   ├── constitution/
│   │   ├── mission.md      # what we build, for whom, the single job of the site
│   │   ├── tech-stack.md   # stack, conventions, folder structure, naming — NON-NEGOTIABLE
│   │   └── design-system.md# fonts, color tokens, type scale, motion defaults, spacing
│   └── features/
│       ├── 001-hero/
│       │   ├── spec.md     # what this section does + acceptance criteria
│       │   ├── plan.md     # how: files, components, data, the mechanic's algorithm
│       │   └── tasks.md    # small verifiable checklist, ordered by dependency
│       ├── 002-about/
│       │   └── …
│       └── …
└── (code the agent generates)
```

## What goes in each artifact

### constitution/ (write once per project)
- **mission.md** — one paragraph: what the site is, who it's for, the one job of the homepage, the
  aesthetic direction (committed, not hedged).
- **tech-stack.md** — the exact stack + versions, folder structure, naming conventions, and any
  non-negotiables ("all components typed", "no inline styles", "Framer Motion for all animation").
  This is the "architectural DNA" — every feature is validated against it.
- **design-system.md** — the locked tokens: font imports + families, every color as a named hex,
  the fluid type scale, default easing/durations, spacing scale, radius scale. Every feature
  references these; no feature invents a new color.

### features/NNN-name/ (one folder per section or page)
- **spec.md** — *what* this feature does, the copy, the layout intent, and **acceptance criteria**
  (verifiable: "no overflow at 375px", "spotlight tracks within 100px", not "looks good").
- **plan.md** — *how*: which files/components, the signature mechanic written as an algorithm
  (refs, listeners, math, cleanup), animation timing, dependencies. Validate against the constitution.
- **tasks.md** — the plan broken into small, ordered, checkable tasks. Foundation → core UI →
  responsive → polish. Mark tasks that can run in parallel.

## How to run it (what to tell the person)

1. **Constitution first.** Fill the three constitution files. This is the highest-leverage step —
   it's what keeps every later section consistent.
2. **One feature at a time.** For each section: write `spec.md`, then `plan.md`, then `tasks.md`.
   A good, detailed spec produces a far better plan — front-load the thinking.
3. **Clarify before building.** Read each spec back and resolve ambiguities/edge cases explicitly
   before generating code (Spec Kit calls this the `/clarify` step). If you can't articulate it, the
   agent shouldn't build it.
4. **Implement per tasks**, one task at a time, checking each off.
5. **Verify against acceptance criteria.** If it fails, adjust the spec/plan, not just the code.
6. **(Optional) cross-check.** Before implementing, scan for gaps or constitution violations across
   spec/plan/tasks (Spec Kit's `/analyze`) — catches misalignment before it becomes rework.

## Optional: use GitHub Spec Kit's tooling directly

If the person wants the real slash-command workflow inside Claude Code (or Copilot/Cursor/Gemini),
Spec Kit installs it for them:

```
uvx --from git+https://github.com/github/spec-kit.git specify init <project> --integration claude
```

That drops in `/speckit.constitution`, `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`,
`/speckit.implement`, and the templates. Mention this as an option — but the plain folder structure
above works with any agent and needs no install.

> **On this machine** Spec Kit's CLI is already installed globally (`specify 0.8.13`), so you can run
> `specify init <project> --integration claude` directly — no `uvx` bootstrap needed. But the
> `/speckit.*` slash commands are created **per project** by `specify init`; they don't exist until a
> project is initialized, so never assume they're available in an arbitrary folder.

## The link back to prompt density

SDD and motionsites-style density are the same instinct at two scales. The **design-system.md** is
the token block from a build prompt; each feature's **plan.md** is the section-by-section spec; the
**acceptance criteria** are the "done" contract. SDD just externalizes the mega-prompt into files so
it stays coherent as the project grows.
