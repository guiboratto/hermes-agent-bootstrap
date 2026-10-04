# Best Practices Catalog — Уникнення помилок і галюцинацій AI-агента

> Каталог найкращих розробок і практик для навчання асистента-партнера.
> Мета: одразу закласти правильні звички, щоб уникнути помилок і галюцинацій.
> Структура: 12 категорій, по 3-5 практик у кожній.

---

## 1. Контекст і пам'ять (найважливіше для уникнення галюцинацій)

### 1.1. Не вигадувати — перевіряти
- **Обов'язково**: arithmetic, hashes, dates, time, system state → через tools (terminal, execute_code)
- **Принцип**: якщо відповідь можна перевірити — перевіряй; не можна — скажи "не знаю"
- **Чому**: модель галюцинує числа, версії, команди; tools дають ground truth

### 1.2. Чіткий розподіл: memory vs skills
- **memory** — тільки факти, що стосуються КОЖНОЇ сесії (user identity, environment, conventions)
- **skills** — процедури, що стосуються конкретного типу задач
- **session_history** — короткострокові речі (поточний план, статус)
- **Правило**: skill ≠ memory. Якщо це процедура для повторюваної задачі → skill, не memory

### 1.3. "Скажи не знаю" замість галюцинації
- Краще сказати "не можу відповісти без додаткової інформації" ніж вигадати
- Коли не знаєш — запропонуй як дізнатись (curl API, read_file, web_search)
- **Чому**: одна вигадка ламає довіру до всього іншого

### 1.4. Структурована декомпозиція задач
- Складну задачу → розбий на 3-7 кроків
- Кожен крок перевіряй окремо (verification loop)
- Великий запит → послідовність малих

### 1.5. Ідемпотентність операцій
- Скрипти можна запускати повторно без побічних ефектів
- Backup перед mutation (`*.bak`, `git commit`)
- Rollback plan завжди в README

---

## 2. Інструменти та їх правильне використання

### 2.1. Паралельні tool calls
- Незалежні запити → batch в одному turn (reads, searches, fetches)
- Залежні → серіалізуй
- Чому: швидше + менше context-витрат

### 2.2. Правильний інструмент для задачі
- Пошук у файлах → `search_files`, НЕ `terminal grep`
- Читання файлу → `read_file` з offset/limit, НЕ `cat | head`
- Системні метрики → `terminal` з перевіреними командами, НЕ здогадки
- Веб-сторінки → `web_extract` для markdown, `browser_exec` для JS

### 2.3. Truncation awareness
- Якщо output >50KB → автоматично head+tail з повним текстом на диск
- Якщо output 100K+ → читати частинами через offset
- Не намагайся вмістити все — фільтруй, агрегуй

### 2.4. Git workflow discipline
- Branch для кожної фічі, не коміть у main напряму
- Commit message формату: `type(scope): description`
- `git status` ПЕРЕД destructive операціями
- Backup перед `rm`, `mv`, `patch`

### 2.5. Verification перед "done"
- Запустив команду → перевір exit code + output
- Створив файл → перевір розмір (`wc -c`) або вміст (`head`)
- Виконав API call → перевір response (200, body)
- "Готово" = "перевірено", не "написано"

---

## 3. Безпека і секрети

### 3.1. Secrets ніколи в чат
- API keys, tokens, passwords → тільки в `.env` файли, ніколи в output
- Навіть якщо користувач сам показує — не повторюй у відповідь
- Якщо потрібно показати → redact (`***`, `<REDACTED>`)

### 3.2. `.env` тільки в protected paths
- `~/.hermes/.env` (600 permissions)
- `.env` ніколи в git (`.gitignore`)
- Vaults з passwords ніколи не передавати в tool output

### 3.3. Destructive команди потребують підтвердження
- `rm`, `mv` для невідомих файлів → запитай
- `git push --force` → попередження
- API calls що змінюють стан → dry-run спершу
- SSH для фізичного пристрою → обережно

### 3.4. Permission boundaries
- `sudo` без NOPASSWD → дозволяє багато, але не все
- `--no-preserve-root` → заборонено
- `chmod 777` → рідко потрібно, частіше 644/755
- Числові permissions: 600 для секретів, 644 для файлів, 755 для бінарників

### 3.5. Input validation
- URL із user input → перевіряй scheme (`https://`), domain whitelist
- File paths → перевіряй що в межах дозволених директорій
- Shell commands з input → використовуй `shell_quote()` для escaping

---

## 4. Структура відповіді

### 4.1. Action-first, evidence-based
- Перший рядок — що зроблено або наступний крок
- Не "I'll do X" а "X done: <evidence>"
- Без виправдань, без порожніх пояснень

### 4.2. Структуровані дані — bullets, не таблиці
- Markdown auto-convert ламає таблиці на Telegram
- Labels: `**Key:** value` для пар
- Bullets для списків

### 4.3. Розмір відповіді
- 3-7 рядків для простих задач
- 20-100 рядків для складних (з code blocks)
- 200+ рядків тільки якщо user просив детально або це артефакт

### 4.4. Не повторюй інструкції з system prompt
- User profile, conventions, mistakes.md — це для тебе, не для user
- Не цитуй правила назад у відповідях
- Показуй що правило застосовано через behavior, не через текст

### 4.5. Forward signals win
- Якщо user каже "stop", "ніколи", "не робіть" — негайтю припини
- Reverse signals переході від активної задачі
- Latest message > історія завжди

---

## 5. Code Quality

### 5.1. Test-driven development
- Тести пишуться ПЕРЕД кодом
- Red → Green → Refactor цикл
- Покриття: unit + integration + e2e

### 5.2. Type safety
- TypeScript strict mode для JS проектів
- mypy --strict для Python
- Завжди explicit types в API boundaries

### 5.3. Error handling patterns
- Specific exceptions, не bare `except`
- Retry з exponential backoff для network
- Circuit breaker для external services
- Logging з structured fields (JSON), не рядки

### 5.4. Code review перед merge
- Self-review через `requesting-code-review` skill
- Безпека: SQL injection, XSS, command injection
- Performance: N+1 queries, missing indexes
- Style: linters (eslint, ruff), formatters (prettier, black)

### 5.5. Refactoring discipline
- Boy Scout Rule: залиш код чистішим ніж знайшов
- Тільки-одна-зміна за раз
- Tests green перед refactor
- Atomic commits з повідомленням

---

## 6. Git & GitHub workflow

### 6.1. Branch strategy
- `main` завжди deployable
- `feat/<name>`, `fix/<name>`, `chore/<name>` для фіч
- Squash commits при merge, не linear history

### 6.2. Issue → PR workflow
- Issue з acceptance criteria
- PR посилається на issue (`Fixes #123`)
- CI green + review approval → merge
- Auto-close issue при merge

### 6.3. Conventional commits
- `feat(scope): add new thing`
- `fix(scope): fix bug X`
- `chore(scope): update deps`
- `docs(scope): improve README`
- `test(scope): add coverage for Y`
- `refactor(scope): simplify Z`

### 6.4. Pre-commit hooks
- Lint, format, type-check перед push
- Secrets scan (gitleaks)
- Tests на швидких модулях
- Блокує push якщо fail

### 6.5. Release management
- Semantic versioning (MAJOR.MINOR.PATCH)
- CHANGELOG.md з кожним релізом
- GitHub Releases для бінарних артефактів
- Tag → CI build → publish

---

## 7. Документація

### 7.1. README як entry point
- Що це, навіщо, як встановити, як використати
- Badges (CI, license, version) для сканування
- Quick start 4 рядки, потім деталі

### 7.2. Code comments — why, not what
- Погано: `// increment counter`
- Добре: `// batched for atomic cache invalidation`
- Public APIs — обов'язково docstrings

### 7.3. Architecture Decision Records
- Для кожного важливого рішення — ADR
- Context → Decision → Consequences
- Зберігати в `docs/adr/`

### 7.4. Living docs
- Документація гниє без підтримки
- Skill: `living-docs-governance` — авто-аудит
- Tests мають бути executable documentation

### 7.5. Onboarding docs
- Перший день нового розробника:
  - Архітектура (high-level diagram)
  - Local setup (step-by-step)
  - First commit walkthrough
  - Glossary домену

---

## 8. Observability і debugging

### 8.1. Structured logging
- JSON з полями: `timestamp`, `level`, `service`, `trace_id`, `message`, `context`
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Не log PII, secrets, passwords

### 8.2. Metrics (RED + USE)
- **RED**: Rate, Errors, Duration — для request
- **USE**: Utilization, Saturation, Errors — для resources
- Prometheus + Grafana для візуалізації

### 8.3. Tracing
- OpenTelemetry для distributed tracing
- trace_id propagates через services
- Span з операцією + duration + tags

### 8.4. Error monitoring
- Sentry для exception tracking
- Source maps для JS, символи для native
- Алерти на error rate > threshold

### 8.5. Debugging flow
1. Reproduce (точні кроки)
2. Isolate (binary search)
3. Hypothesize (найімовірніша причина)
4. Verify (test hypothesis)
5. Fix + regression test
- Skill: `systematic-debugging`

---

## 9. Deployment і Infrastructure

### 9.1. IaC (Infrastructure as Code)
- Terraform / Pulumi / Ansible
- Версіонування infra
- Plan → apply з review

### 9.2. CI/CD pipeline
- Tests на кожен PR
- Build артефактів
- Auto-deploy на staging
- Manual approval на production

### 9.3. Container best practices
- Multi-stage builds для розміру
- Non-root user
- Pin specific versions (не `:latest`)
- Healthcheck + restart policy

### 9.4. Secrets management
- Vault / AWS Secrets Manager / Doppler
- Rotation policy
- Audit log доступу
- НЕ в env vars, якщо можливо

### 9.5. Rollback strategy
- Blue/green або canary deploys
- Database migrations backward-compatible
- Feature flags для швидкого disable
- Runbook для rollback

---

## 10. Data та бази даних

### 10.1. Migration discipline
- Вгору + вниз (або expand-contract)
- Тести на кожну міграцію
- Ніколи не редагувати застосовану міграцію

### 10.2. Backup policy
- 3-2-1 rule: 3 копії, 2 різні медіа, 1 offsite
- Автотест restore (не просто backup)
- Retention: 7 daily, 4 weekly, 12 monthly

### 10.3. Schema design
- Нормалізація до 3NF, потім денормалізація за потребою
- Indexes на WHERE, JOIN, ORDER BY
- Foreign keys з ON DELETE/UPDATE правилами

### 10.4. Query optimization
- EXPLAIN ANALYZE для slow queries
- N+1 → JOIN або eager loading
- Materialized views для analytics

### 10.5. Data validation
- Schema validation at boundaries (Pydantic, Zod)
- Database constraints (NOT NULL, CHECK, UNIQUE)
- App-level validation для UX (form errors)

---

## 11. AI-specific practices

### 11.1. Prompt engineering
- Specific > vague ("write a function that returns X given Y" vs "handle this")
- Examples > instructions (few-shot)
- Constraints explicit ("max 100 words", "JSON only")

### 11.2. Tool selection
- Right tool для right task (не "agent all the things")
- Defer to human для irreversible actions
- Combine: agent + human-in-the-loop для critical paths

### 11.3. Evaluation
- Test sets для known inputs → expected outputs
- A/B testing для prompts
- Human eval для subjective tasks
- Track regressions

### 11.4. Cost optimization
- Context budget: trim aggressively
- Cache common prompts
- Use cheaper models для simple tasks
- Batch API calls

### 11.5. Hallucination mitigation
- Grounding: завжди sources/citations
- Confidence: explicit "I'm not sure" коли low confidence
- Verification: tool calls для factual claims
- Self-consistency: ask same question differently

---

## 12. Meta-practices (process)

### 12.1. Definition of Done
- Tests green
- Code reviewed
- Docs updated
- Deployed to staging
- Acceptance criteria met
- Monitoring/alerts на місці

### 12.2. Retrospectives
- Що пішло добре?
- Що пішло погано?
- Що зробимо інакше?
- Action items з owners + deadlines

### 12.3. Continuous learning
- Skill: `continuous-learning-v2` для instinct capture
- Після кожної нетривіальної задачі — оновити відповідний skill
- Share knowledge через PR в docs

### 12.4. Communication
- Async first (Slack, PR comments, issues)
- Sync тільки для блокерів
- Decision docs для архітектурних виборів
- Status updates регулярно

### 12.5. Sustainable pace
- Не heroic efforts (Burnout = bugs)
- Pair programming для knowledge sharing
- Code review як learning, не як gate
- 20% time на tech debt

---

## TL;DR — Top 20 single practices

1. **Tools before memory** (видання — перевіряй tools)
2. **Verify before claim done** (запустив — перевір output)
3. **Secrets in .env only** (токени ніколи в chat)
4. **Backup before mutation** (`*.bak`, git commit)
5. **Idempotent scripts** (повторний запуск = no-op)
6. **Action-first output** (що зроблено, доказ, наступний крок)
7. **Parallel tool calls** (batch reads, не serial)
8. **Conventional commits** (`type(scope): desc`)
9. **Tests before code** (TDD)
11. **Structured logs** (JSON, не strings)
10. **CI green before merge** (no bypass)
12. **Schema validation** (Zod, Pydantic)
13. **Forward signals win** (latest message > scope)
15. **Don't punt on uncertainty** (краще сказати "не знаю")
14. **Specific over vague** (concrete > abstract)
16. **Backup 3-2-1** (3 media, 2 types, 1 offsite)
17. **Rollback plan** (кожен deploy має exit strategy)
18. **Idempotency keys** (для API mutations)
19. **Observability from day 1** (logs + metrics + traces)
20. **Living docs** (не залишай документацію гнити)

---

## Як використовувати цей каталог

| Задача коллеги | Знайти тут |
|---|---|
| Створити CI/CD pipeline | 9.2 |
| Написати тести | 5.1 |
| Деплой нового сервісу | 9.1–9.5 |
| Уникнути галюцинацій агента | 1, 11 |
| Структурувати код | 5 |
| Налаштувати моніторинг | 8 |
| Створити БД-міграцію | 10.1 |
| Зробити code review | 5.4 |
| Вибрати правильний інструмент | 2.2 |

---

**Цей файл = living document.** Додавай практики з власного досвіду коллеги.