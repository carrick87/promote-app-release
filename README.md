# promote-app-release

**AI agent skill to build a release marketing pack — simulator screenshots, feature boards, iPhone mockup posters, and a newsletter draft — for Cursor, Claude Code, Codex, Antigravity, Gemini CLI, and any [Agent Skills](https://agentskills.io/specification) compatible tool.**

Reads **README Version History** (after a release), captures **real Simulator screenshots**, generates marketing images, and writes **newsletter copy**. Saves to **Desktop** and **`marketing/<VERSION>/`**.

**Does not bump versions.** Pair with [publish-new-version](https://github.com/carrick87/publish-new-version) for semver + changelog, then run this skill for promo assets.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-SKILL.md-6366f1)](https://agentskills.io/specification)
[![Cursor](https://img.shields.io/badge/Cursor-compatible-000000)](https://cursor.com)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-d97757)](https://code.claude.com)
[![Codex](https://img.shields.io/badge/OpenAI%20Codex-compatible-412991)](https://developers.openai.com/codex)
[![Antigravity](https://img.shields.io/badge/Antigravity-compatible-4285F4)](https://antigravity.google/docs/skills)

---

## Why use this skill?

After you ship an app version, marketing still needs:

- Real device screenshots of key tabs
- Feature highlight / “What’s New” boards
- Hero mockups and newsletter banners
- Paste-ready Slack/email newsletter copy

**promote-app-release** teaches your AI coding agent a repeatable promo pipeline so you say *"promote release"* or *"make posters for v3.2.9"* and get a full pack — without mixing version bumps into the same run.

---

## Supported AI tools

| Tool | Personal (global) install | Project install |
|------|---------------------------|-----------------|
| **[Cursor](https://cursor.com)** | `~/.cursor/skills/promote-app-release/` | `.cursor/skills/promote-app-release/` |
| **[Claude Code](https://code.claude.com)** | `~/.claude/skills/promote-app-release/` | `.claude/skills/promote-app-release/` |
| **[OpenAI Codex](https://developers.openai.com/codex)** | `~/.codex/skills/promote-app-release/` | — |
| **[Google Antigravity](https://antigravity.google/docs/skills)** | `~/.gemini/config/skills/promote-app-release/` or `~/.gemini/antigravity/skills/promote-app-release/` | `.agents/skills/promote-app-release/` |
| **[Gemini CLI](https://geminicli.com)** | `~/.gemini/skills/promote-app-release/` | `.gemini/skills/promote-app-release/` or `.agents/skills/promote-app-release/` |
| **Windsurf, Copilot Chat, other Agent Skills hosts** | Copy into that product’s skills directory | Same |

Follows the open **[Agent Skills standard](https://agentskills.io/specification)** (`SKILL.md` + `references/`). Write once, use across major AI coding agents.

---

## Requirements

| Capability | Used for |
|------------|----------|
| **iOS Simulator / `xcrun simctl`** | Real app screenshots (see [references/sim-screenshots.md](references/sim-screenshots.md)) |
| **Image generation** (e.g. Cursor `GenerateImage`) | Feature board, hero mockup, strip, newsletter banner |
| **App icon + screenshots as references** | Brand-accurate posters |
| **README `## Version History`** | “What’s new” copy source |

Screenshot automation is optimized for **HAR StockApp** defaults; override brand/paths in chat for other apps.

---

## Quick install

### Cursor

```bash
git clone https://github.com/carrick87/promote-app-release.git ~/.cursor/skills/promote-app-release
```

### Claude Code

```bash
git clone https://github.com/carrick87/promote-app-release.git ~/.claude/skills/promote-app-release
```

### OpenAI Codex

```bash
git clone https://github.com/carrick87/promote-app-release.git ~/.codex/skills/promote-app-release
```

Enable skills in `~/.codex/config.toml` if needed:

```toml
[features]
skills = true
```

### Google Antigravity

**Global (recommended):**

```bash
git clone https://github.com/carrick87/promote-app-release.git ~/.gemini/config/skills/promote-app-release

# Or Antigravity-specific global path
# git clone https://github.com/carrick87/promote-app-release.git ~/.gemini/antigravity/skills/promote-app-release
```

**Workspace / project:**

```bash
git clone https://github.com/carrick87/promote-app-release.git .agents/skills/promote-app-release
```

See [Antigravity skills docs](https://antigravity.google/docs/skills).

### Gemini CLI

```bash
git clone https://github.com/carrick87/promote-app-release.git ~/.gemini/skills/promote-app-release
```

Or project-local:

```bash
git clone https://github.com/carrick87/promote-app-release.git .agents/skills/promote-app-release
```

### One-liner for multiple tools

```bash
REPO=https://github.com/carrick87/promote-app-release.git
git clone "$REPO" ~/.cursor/skills/promote-app-release
git clone "$REPO" ~/.claude/skills/promote-app-release
git clone "$REPO" ~/.codex/skills/promote-app-release
git clone "$REPO" ~/.gemini/config/skills/promote-app-release
```

Restart your agent / IDE after installing.

### Update

```bash
git -C ~/.cursor/skills/promote-app-release pull
# repeat for other install paths you use
```

---

## Usage — example prompts

```
/promote-app-release
```

```
promote release
```

```
make posters for v3.2.9
```

```
release newsletter and App Store promo images
```

```
marketing posters for the current version
```

### Recommended flow with publish-new-version

```
1) /publish-new-version   → bump semver, changelog, push
2) /promote-app-release   → screenshots + posters + newsletter
```

### What the agent does

1. **Confirms** target version (default: README `### vX.Y.Z (Current)`) and baseline for “what’s new”  
2. **Parses** Version History into user-facing feature themes  
3. **Builds / installs** the app on Simulator and captures key tabs  
4. **Generates** feature board, hero mockup, feature strip, newsletter banner  
5. **Writes** `NEWSLETTER.md` and copies assets to Desktop + `marketing/<VERSION>/`  
6. **Reports** paths and any screens that could not be captured  

---

## Outputs

| Asset | Typical filename |
|-------|------------------|
| Screenshots | `marketing/screenshots/<VERSION>/01-search.png` … |
| Feature board | `HAR-StockApp-<VER>-feature-board.png` |
| Hero mockup | `HAR-StockApp-<VER>-hero-mockup.png` |
| Feature strip | `HAR-StockApp-<VER>-feature-strip.png` |
| Newsletter banner | `HAR-StockApp-<VER>-newsletter-banner.png` |
| Newsletter copy | `marketing/<VERSION>/NEWSLETTER.md` |

Also copied to `~/Desktop/` where applicable.

---

## How it works

```
Promote request → Read Version History (no version bump)
    → Diff features since baseline → Simulator screenshots
    → GenerateImage posters (icon + shots) → Newsletter → Desktop + marketing/
```

Repo layout:

```
promote-app-release/
├── SKILL.md                         # Main marketing pipeline
├── references/
│   └── sim-screenshots.md           # xcrun / AppleScript helpers
├── README.md                        # Install & usage
└── LICENSE                          # MIT
```

---

## HAR StockApp defaults (overridable)

| Setting | Default |
|---------|---------|
| Brand | HAR StockApp |
| Icon | `StockMaster/.../AppIcon.appiconset/1024.png` |
| Palette | Harbour Teal + navy (no purple neon) |
| OTP bypass (screenshots) | `admin@testing.local` / `csd.exec` |

---

## Keywords

`agent-skills` · `cursor-skills` · `claude-code-skills` · `codex-skills` · `antigravity-skills` · `app-store` · `release-marketing` · `screenshots` · `newsletter` · `ios-simulator` · `SKILL.md` · `ai-coding-agent` · `developer-tools`

> **Tip:** Add GitHub Topics: `agent-skills`, `cursor`, `claude-code`, `codex`, `antigravity`, `skill-md`, `app-store`, `release-marketing`, `ios`, `ai-agent`, `developer-tools`.

---

## Related projects

- [publish-new-version](https://github.com/carrick87/publish-new-version) — bump semver + changelog + push  
- [ot-leave-claim](https://github.com/carrick87/ot-leave-claim) — OT / leave-replacement claims  
- [Agent Skills specification](https://agentskills.io/specification)  
- [Antigravity skills](https://antigravity.google/docs/skills)

---

## Contributing

1. [Fork](https://github.com/carrick87/promote-app-release/fork) this repo  
2. Improve `SKILL.md` or `references/`  
3. Open a pull request  

Issues welcome on [GitHub Issues](https://github.com/carrick87/promote-app-release/issues).

---

## License

[MIT](LICENSE) — free to use, fork, and adapt.
