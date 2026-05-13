# Data Transfer: HPC (Randi) → Shiny Server

This guide describes how to move data files from the Randi HPC cluster to the CRI Biocore Shiny server so that apps can access them.

---

## Overview

```
Randi GPFS  →  (Globus transfer)  →  Shiny server staging  →  (nightly script)  →  App data folder
```

---

## Step 1 — Drop files on Randi

Place your data files in the appropriate shared directory on Randi:

| App              | Randi drop folder                                |
| ---------------- | ------------------------------------------------ |
| scVizApp (scRNA) | `/gpfs/data/bioinformatics/shared/scrna_shiny/`  |
| FeaVis App       | `/gpfs/data/bioinformatics/shared/feavis_shiny/` |

Files placed here will be picked up by the nightly sync script after Globus transfer completes.

---

## Step 2 — Initiate transfer via Globus

1. Go to [https://app.globus.org](https://app.globus.org) and log in with your CNet ID.
2. Open the **File Manager** (two-panel view).
3. **Source (left panel):** search for the **Randi** endpoint and navigate to the drop folder:
   - `/gpfs/data/bioinformatics/shared/scrna_shiny/` — for scVizApp data
   - `/gpfs/data/bioinformatics/shared/feavis_shiny/` — for FeaVis App data
4. **Destination (right panel):** search for the endpoint named **`shiny`**. The default path is `/srv/globus_files/`. Navigate into the subfolder matching your app:
   - `/srv/globus_files/scrna_shiny/` — for scVizApp data
   - `/srv/globus_files/feavis_shiny/` — for FeaVis App data
5. Select the files or folders to transfer and click **Start**.
6. Globus will notify you by email when the transfer completes.

---

## Step 3 — Nightly sync script

A script runs automatically each night on the Shiny server to move Globus-transferred files from the staging directories into the locations the apps read from:

| Globus destination                | App data folder                                                           |
| --------------------------------- | ------------------------------------------------------------------------- |
| `/srv/globus_files/scrna_shiny/`  | `/srv/data/scrna_data/` → `/srv/shiny-server/data/` (scVizApp reads here) |
| `/srv/globus_files/feavis_shiny/` | `/srv/data/feavis_data/` (FeaVis App reads here)                          |

No manual action is needed after the Globus transfer completes — the script handles the move overnight.

---

## Notes

- Files in the Randi drop folders are **not automatically deleted** after transfer. Clean them up manually after confirming the transfer succeeded.
- The Shiny server data directories are owned by the `shiny` system user. Do not change their permissions.
- If data does not appear in the app by the next morning, check:
  1. The Globus transfer completed successfully (check your email or the Globus activity page).
  2. The nightly script ran without errors (contact the server admin to check logs).
