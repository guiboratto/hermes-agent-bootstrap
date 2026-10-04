# hermes-agent-bootstrap

One-shot setup script for Hermes Agent.

```bash
git clone https://github.com/guiboratto/hermes-agent-bootstrap
cd hermes-agent-bootstrap
chmod +x bootstrap-hermes.sh
./bootstrap-hermes.sh
```

## What the script does

1. Backup `~/.hermes` for rollback
2. `hermes doctor --fix`, `hermes update`, `hermes skills repair-official`
3. Install skills from a co-located `hermes-skills-bundle.tar.gz` (optional)
5. Install recommended Skills (interactive, skipped with `--non-interactive`)
6. Install recommended Plugins (interactive, skipped with `--non-interactive`)

Idempotent — safe to re-run.

## Flags

```
--bundle PATH         Path to a skills bundle tar.gz (auto-detected if co-located)
--non-interactive     Skip prompts
-h, --help            Show help
```

## Recommended Skills

These are installed by the script via `hermes skills inspect → install`.

| Skill | Source | Purpose |
|-------|--------|--------|
| `archify` | `official/creative/archify` | Architecture diagrams as polished SVG/HTML |
| `i-have-adhd` | `ayghri/i-have-adhd` | Output style: action-first, no fluff |

Manual install (one-off, any time):
```bash
hermes skills inspect official/creative/archify
hermes skills install official/creative/archify
hermes skills inspect ayghri/i-have-adhd
hermes skills install ayghri/i-have-adhd
```

## Recommended Plugins

| Plugin | Purpose |
|--------|---------|
| `custodian` | Autonomous ops monitor for the Hermes install |
| `handflow` | Manus-style step-by-step planning |
| `git-hook` | Auto fetch/pull before reads; commit+push only your own |

Manual install:
```bash
hermes plugins install custodian
hermes plugins install handflow
hermes plugins install git-hook
```

> Always review plugin capabilities before enabling:
> `hermes plugins capabilities <name>`

## Recommended MCP servers

MCP servers eat context — pick 5–8, not more.

| MCP | Why |
|-----|-----|
| `n8n-official` | If you work with n8n workflows |
| `deepwiki` | Ask questions about any public GitHub repo |
| `supabase` / `prisma-postgres` / `neon` | Managed Postgres |
| `cloudflare` / `vercel` / `netlify` / `railway` | Deploy targets |
| `sentry` | Production error monitoring |
| `semgrep` | Code security scan |
| `hugging_face` | Models / datasets / papers |
| `wolfram` | Math + knowledge |

Manual install:
```bash
hermes mcp install n8n-official
hermes mcp install deepwiki
hermes mcp install cloudflare
# ...
```

After install, prune unused tools per-server:
```bash
hermes mcp configure <name>
```

## Rollback

If something goes wrong:
```bash
rm -rf ~/.hermes
tar xzf ~/.hermes/.pre-bootstrap.bak.tar -C ~/
```

## License

MIT — see [LICENSE](LICENSE).