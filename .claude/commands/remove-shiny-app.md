Help the user remove an existing Shiny app from the CRI Biocore Apps repository by walking through each step interactively.

Start by asking: which app should be removed? Ask them to provide the **folder name** (e.g., `024-optgroup-selectize`).

Then read the relevant files to confirm the app's details before making any edits.

---

## Step 1 — Confirm names from existing config

Read `.github/workflows/deploy.yml` and `shinyproxy/application.yml` and `shinyproxy/application-public.yml` to find the app's registered details. Confirm with the user before touching any file:

| Name | Where to find it |
|------|-----------------|
| Folder name | provided by user |
| Image name | `deploy.yml` matrix `image:` field |
| App ID | `application.yml` or `application-public.yml` `id:` field |
| Visibility | whichever ShinyProxy config file it appears in |

Warn the user: **this will remove the app from the dashboard and stop it from being built/deployed.** Ask them to confirm before proceeding.

---

## Step 2 — Remove from `deploy.yml`

Read `.github/workflows/deploy.yml` first. Remove **both** entries:

**From the matrix section** — remove the entire `- name: / image:` block for this app.

**From the deploy step** — remove the `docker pull` line for this app's image.

---

## Step 3 — Remove from ShinyProxy config

- Private app → `shinyproxy/application.yml`
- Public app → `shinyproxy/application-public.yml`

Read the file first, then remove the entire `- id: ...` block for this app (all fields: `id`, `display-name`, `description`, `container-image`, `port`, and any `container-volumes`).

---

## Step 4 — Dashboard template

Read `shinyproxy/templates/index.html`. Find and remove the `th:with` image mapping line for this app's ID:

```html
(${app.id == '<app-id>'} ? '/images/<something>.jpg' :
```

Make sure the remaining Thymeleaf ternary chain is still valid — check that parentheses are balanced after the removal.

---

## Step 5 — App folder

Ask the user: **do you also want to delete the `apps/<folder-name>/` folder?**

- If yes: delete the folder and all its contents.
- If no: leave it in place (it will simply no longer be built or shown).

---

## Step 6 — Summary and PR instructions

After all edits are complete, print a summary of what was removed:

| Item | Removed from |
|------|-------------|
| Matrix entry | `deploy.yml` |
| Docker pull line | `deploy.yml` |
| App spec | `shinyproxy/application.yml` or `application-public.yml` |
| Image mapping | `shinyproxy/templates/index.html` |
| App folder | deleted / kept (per user choice) |

Then remind them:
- Create a branch named after themselves: `git checkout -b yourname`
- Commit and push: `git add . && git commit -m "remove <folder-name>" && git push origin yourname`
- Open a Pull Request on GitHub targeting `main`
- **Never push directly to `main`** — it triggers an immediate production deployment
