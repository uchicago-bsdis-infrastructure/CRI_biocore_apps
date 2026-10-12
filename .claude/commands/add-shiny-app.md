Help the user add a new Shiny app to the CRI Biocore Apps repository by walking through each step interactively.

Start by asking: what is the app name and should it be **private** (CNet login required) or **public** (open to everyone)?

Then guide through each step below, reading the relevant files before making edits, and confirming names are consistent across all files.

---

## Naming rules to enforce

Derive all four names from the user's app name and confirm with them before touching any file:

| Name | Convention | Example |
|------|-----------|---------|
| Folder name | as-given, hyphens | `my-deapp` |
| Image name | `shiny-` prefix, lowercase, hyphens | `shiny-my-deapp` |
| App ID | lowercase, underscores | `my_deapp` |
| Display name | ask the user | `"My DE App"` |

Critical: folder name **must exactly match** `name:` in `deploy.yml`; image name must match the `docker pull` line; app ID must match `app.id` in `templates/index.html`.

---

## Step 1 — App folder

If the user's app files already exist locally, **read every `.R` file** in the app folder (typically `app.R`, `server.R`, `ui.R`, and any sourced helpers). Scan for all `library()`, `require()`, and `p_load()` calls to build the full package list. Also check for `BiocManager::install()` calls.

### Resolving system dependencies from R packages

For every R package found, determine which Debian/Ubuntu system libraries it needs using the reference table below. Collect all required `apt` packages, deduplicate, and include them in a single `apt-get install` layer.

**R package → system library mapping (common packages):**

| R package(s) | apt packages needed |
|---|---|
| `curl`, `RCurl` | `libcurl4-openssl-dev` |
| `openssl`, `httr`, `httr2` | `libssl-dev` |
| `xml2`, `XML`, `rvest` | `libxml2-dev` |
| `sf`, `terra`, `rgdal` | `libgdal-dev libgeos-dev libproj-dev` |
| `igraph` | `libglpk-dev libgmp-dev libxml2-dev` |
| `Rglpk`, `glpkAPI` | `libglpk-dev` |
| `Cairo`, `cairoDevice` | `libcairo2-dev` |
| `rgl` | `libgl1-mesa-dev libglu1-mesa-dev` |
| `magick` | `libmagick++-dev` |
| `pdftools`, `qpdf` | `libpoppler-cpp-dev` |
| `av`, `gifski` | `libavfilter-dev` |
| `sodium` | `libsodium-dev` |
| `RPostgres`, `RPostgreSQL` | `libpq-dev` |
| `RMySQL` | `default-libmysqlclient-dev` |
| `RSQLite` | *(none — bundled)* |
| `odbc` | `unixodbc-dev` |
| `xlsx`, `rJava` | `default-jdk` |
| `nloptr` | `libnlopt-dev` |
| `V8` | `libv8-dev` |
| `systemfonts`, `textshaping` | `libfontconfig1-dev libharfbuzz-dev libfreiburg-dev` |
| `ragg` | `libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev` |
| `hdf5r`, `rhdf5` | `libhdf5-dev` |
| `arrow` | `libzstd-dev` |
| `DESeq2`, `edgeR`, `limma` | *(Bioconductor — no extra system deps unless igraph is pulled in)* |

If a package is not in this table, use your knowledge of its compiled dependencies. When uncertain, note it as "verify system deps" in the summary.

### Build the Dockerfile

Construct the Dockerfile with **only the system libraries actually needed**, split into logical layers:

```dockerfile
FROM rocker/shiny:4.4.2

# System dependencies
RUN apt-get update && apt-get install -y \
    <only the libs required by this app's packages> \
    && rm -rf /var/lib/apt/lists/*

# CRAN packages
RUN R -e "install.packages(c('<pkg1>', '<pkg2>'))"

# Bioconductor packages (only if needed)
RUN R -e "install.packages('BiocManager')" \
 && R -e "BiocManager::install(c('<BiocPkg1>'))"

RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
```

**If the app requires data mounting**, add this line after `FROM` to remap the container's shiny user to match the host's shiny UID (992), so the container process can access host-owned directories securely:

```dockerfile
# Pin shiny UID to match host shiny user (UID 992) for volume mount permissions
RUN usermod -u 992 shiny
```

Show the user the detected packages and the resolved system dependencies before writing the Dockerfile, and ask them to confirm or add anything missing.

---

## Step 2 — Register in `deploy.yml`

Read `.github/workflows/deploy.yml` first. Then add to **both** locations:

**Matrix section** (10 spaces before `-`, 12 spaces before `name`/`image`):
```yaml
          - name: <folder-name>
            image: <image-name>
```

**Deploy step** (10 spaces before `docker`):
```yaml
          docker pull ghcr.io/<registry-owner-expr>/<image-name>:latest
```

> **Critical — do not hardcode the registry owner.** This repo's `build-and-push` job has flip-flopped between pushing to `${{ github.repository_owner }}` (the org) and `${{ secrets.GHCR_USER }}` (a personal namespace) — whichever one is *currently* in the `tags:` line of the `docker/build-push-action` step (around line 37) is where images actually land. Before writing the new `docker pull` line, read that `tags:` line and copy its exact owner expression verbatim. A mismatch here doesn't fail loudly at build time — the build succeeds, and only the *deploy* job's `docker pull` for the new app fails (`manifest unknown` or `denied`), while all pre-existing apps keep working because they already have images cached under whichever namespace they were pushed to historically. This bit a real deploy (`scvizappPublic`, 2026-07-13) — confirm the owner expression matches before considering the app "added."

Use spaces only — tabs will break the workflow.

---

## Step 3 — Register in ShinyProxy config

- Private app → `shinyproxy/application.yml`
- Public app → `shinyproxy/application-public.yml`

Read the file first, then add:
```yaml
    - id: <app-id>
      display-name: "<Display Name>"
      description: "<Short description of what the app does.>"
      container-image: ghcr.io/<registry-owner-expr>/<image-name>:latest
      port: 3838
```

Use the **same literal registry owner** (e.g. `uchicago-bsdis-infrastructure` or `zhongyuli2026`, whichever is currently correct per Step 2) as the `docker pull` line you just added — ShinyProxy launches containers directly from this field at runtime, so it must point at wherever the image was actually pushed, not necessarily whatever an existing app's spec happens to show (existing specs may be stale/inconsistent from past registry-owner changes).

> **New GHCR packages default to private.** The first time an image is pushed under a given owner/name, GitHub creates a new package that only the pushing credential can read by default. If the deploy job's `docker pull` fails with `denied` (not `manifest unknown`) even though the owner expression matches the build's push target, the new package needs its visibility set to Public (or the deploy job's pull account added under the package's **Manage Actions access** with Read role) in GHCR package settings — this is a manual, one-time step outside of git that whoever has org package admin rights needs to do after the first successful build.

If the app needs data files mounted from the server, also add:
```yaml
      container-volumes:
        - /srv/data/<folder-name>/:/srv/data/<folder-name>/
```

> **UID requirement:** Host directories under `/srv/data/` must be owned by the host's `shiny` user (UID 992). On the server run:
> ```bash
> sudo chown -R shiny:shiny /srv/data/<folder-name>/
> ```
> Also add `RUN usermod -u 992 shiny` to the Dockerfile (see above). This remaps the container's shiny user to UID 992, avoiding exposure of data to an uncontrolled UID on the host.

---

## Step 4 — Dashboard thumbnail image

First, scan the app folder for image files (`.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`).

**If an image is found in the app folder:**
- Tell the user which file was found (e.g., `apps/<folder-name>/thumbnail.jpg`)
- Ask: "I found `<filename>` in your app folder — use this as the dashboard thumbnail?"
- If yes:
  - Verify the file extension is one of: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`. If not, warn the user and fall back to `banner.jpg`.
  - Copy the file to `static/images/<image-name>.jpg` (use the image name, e.g., `shiny-024-optgroup-selectize.jpg`). If the source extension is not `.jpg`, keep the original extension (e.g., `shiny-024-optgroup-selectize.png`).
  - Use `/images/<image-name>.<ext>` as the thumbnail path in the template.
- If no: use `banner.jpg` as the default.

**If no image is found in the app folder:**
- Ask: "Do you have a thumbnail image to upload? If so, place it in `apps/<folder-name>/` and re-run, or I'll use the default `banner.jpg`."
- Proceed with `banner.jpg` as the default unless the user provides one.

**Then update `shinyproxy/templates/index.html`:**

Read the file. Find the `th:with` image mapping block and add a line **before** the final `'/images/banner.jpg'` fallback:

```html
(${app.id == '<app-id>'} ? '/images/<thumbnail-filename>' :
```

If using `banner.jpg` as default, still add the mapping line (it will just point to `banner.jpg`) so the app is explicitly handled.

---

## Step 5 — Summary and PR instructions

After all edits are complete, print a summary table:

| Item | Value |
|------|-------|
| Folder | `apps/<folder-name>/` |
| `deploy.yml` name | `<folder-name>` |
| `deploy.yml` image | `<image-name>` |
| ShinyProxy id | `<app-id>` |
| container-image | `ghcr.io/<registry-owner-expr>/<image-name>:latest` |
| template app.id | `<app-id>` |

Then remind them:
- Create a branch named after themselves: `git checkout -b yourname`
- Commit and push: `git add . && git commit -m "add <folder-name>" && git push origin yourname`
- Open a Pull Request on GitHub targeting `main`
- **Never push directly to `main`** — it triggers an immediate production deployment
- **After merge, check the Actions run's `deploy` job logs all the way through**, not just whether the run shows green — a registry-owner mismatch or a private-package permission issue on a brand-new image only shows up as a failure on the *last* `docker pull` line, while the build step and every pre-existing app's pull still succeed.
