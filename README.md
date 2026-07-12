# Claude Code Skills for CRI Biocore Apps

This folder contains Claude Code skills — reusable AI prompts you can invoke directly inside Claude Code using a `/` command. No setup required beyond having Claude Code installed.

---

## Prerequisites

1. Install Claude Code: https://claude.ai/code
2. Open a terminal in the `CRI_biocore_apps` repo root
3. Launch Claude Code:
   ```bash
   claude
   ```

That's it. Skills in `.claude/commands/` are automatically available in any Claude Code session opened inside this repo.

---

## Available skills

| Command          | What it does                                                           |
| ---------------- | ---------------------------------------------------------------------- |
| `/add-shiny-app` | Interactively walks you through adding and registering a new Shiny app |

---

## How to use `/add-shiny-app`

This skill guides you through every file you need to touch to deploy a new Shiny app — Dockerfile, `deploy.yml`, ShinyProxy config, and dashboard template.

### Step 1 — Have your app files ready

Before invoking the skill, place your app files somewhere accessible (they don't need to be in the repo yet). At minimum you need:

```
your-app-name/
├── app.R          # or server.R + ui.R
└── (other files)
```

### Step 2 — Open Claude Code in the repo

```bash
cd CRI_biocore_apps
claude
```

### Step 3 — Invoke the skill

Type the following at the Claude Code prompt:

```
/add-shiny-app
```

### Step 4 — Answer the prompts

Claude will ask you two questions to start:

1. **What is your app name?** (e.g., `scrna-vis`)
2. **Private or public?**
   - Private → requires UChicago CNet login (`/apps`)
   - Public → open to everyone (`/public`)

### Step 5 — Let Claude scan your R files

If your `.R` files are already in the repo under `apps/`, Claude will read them automatically and:

- Extract every `library()`, `require()`, and `BiocManager::install()` call
- Resolve which Linux system libraries each R package needs
- Propose a complete `Dockerfile` with only the dependencies your app actually uses

Claude will show you the detected packages and system deps **before writing anything** and ask you to confirm.

> If your files are not in the repo yet, copy them into `apps/<your-app-name>/` first, then invoke the skill.

### Step 6 — Review and confirm each edit

Claude will make one edit at a time and pause for your confirmation:

| Edit                        | File                                                     |
| --------------------------- | -------------------------------------------------------- |
| Create Dockerfile           | `apps/<your-app-name>/Dockerfile`                        |
| Add matrix + deploy entries | `.github/workflows/deploy.yml`                           |
| Add app spec                | `shinyproxy/application.yml` or `application-public.yml` |
| Add image mapping           | `shinyproxy/templates/index.html`                        |

### Step 7 — Create a branch and open a PR

At the end Claude will print a summary of all names used and remind you to:

```bash
git checkout -b yourname
git add .
git commit -m "add your-app-name"
git push origin yourname
```

Then open a Pull Request on GitHub targeting `main`. Once merged, the GitHub Action automatically builds, pushes, and deploys your app.

> **Never push directly to `main`** — it triggers an immediate production deployment.

---

## Example session

```
$ claude

> /add-shiny-app

Claude: What is the name of your app, and should it be private (CNet login)
        or public (open to everyone)?

You:    scrna-vis, private

Claude: Here are the names I'll use — please confirm:
        • Folder:       apps/scrna-vis/
        • Image:        shiny-scrna-vis
        • App ID:       scrna_vis
        • Display name: (what would you like?)

You:    "scRNA Visualization"

Claude: Reading apps/scrna-vis/app.R ...
        Detected packages: shiny, DESeq2, ggplot2, igraph, DT
        Resolved system deps: libglpk-dev, libgmp-dev, libxml2-dev
        Does this look right? Anything to add?

You:    looks good

Claude: Writing Dockerfile ... done.
        Editing deploy.yml ... done.
        ...
```

---

## Troubleshooting

**Skill not found (`/add-shiny-app` not recognized)**

- Make sure you launched `claude` from inside the `CRI_biocore_apps` directory
- The `.claude/commands/` folder must be present (it is tracked in git)

**Claude edited the wrong indentation in `deploy.yml`**

- Tell Claude: "the indentation looks off, please re-read the file and fix it"
- YAML requires spaces only — tabs cause "Invalid workflow file" errors

**App not appearing after merge**

- Check the GitHub Actions tab for build/deploy errors
- Red X → click into the job to read the logs
