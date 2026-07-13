# **Development of interactive Single Cell Visualization Application (scVizApp) with R Shiny**

## 1.  **Abstract/Motivation:**

Single-cell RNA sequencing (scRNA-seq) has become a powerful tool for
uncovering cellular diversity and understanding tissue composition at
high resolution. Critical information about biological differences at
the cellular level can be obtained by comparing scRNA-seq datasets
(treatment vs. control). We used R Shiny to create scVizApp (Single-cell
Visualization Application), which enables users to easily explore and
interpret scRNA-seq data, in order to make such analysis more
accessible.

Our application focuses on comparative exploration by enabling users to
visualize cell populations under various experimental conditions and
interactively modify metadata. Regardless of the experiment model, users
can create and examine Multi-Dimensional Plots, Feature Plots, Violin
Plots, and Dot Plots by merely uploading an RDS/Rdata file.

Without requiring coding, scVizApp seeks to facilitate intuitive data
exploration and promote deeper biological insights. This tool offers a
practical solution for experimental researchers to independently
investigate and interpret their single-cell datasets.

## 2.  **Application Outline:**

### 2.1 Input Requirements

The application requires an integrated Seurat-compatible.RDS or.RData
file that includes a metadata table and a normalized gene expression
count matrix. The data should be preprocessed (post-integration) and
ready for visualization, with components such as graphs and reductions.

### 2.2 Application Structure

scVizApp streamlines the exploration and comparison of single-cell
datasets, offering five intuitive navigation sections:

#### **1. Load Input Data**
Easily upload .RDS or .RData files directly from your computer using
encrypted string. All uploaded datasets are preserved, allowing quick
access for comparisons or reanalysis. Navigate seamlessly through all
app sections using the header navigation bar or the handy navigation
buttons next to the 'Load Data' option.\
*(Tip: You can include illustrative images here.)*

#### **2. Application Overview**
Get a clear and succinct walkthrough of the app's workflow and key
functionalities. This is ideal for new users or collaborators who need a
quick tour of scVizApp's capabilities.

#### **3. Cell Summary Profile**
Discover the distribution of cells across experimental conditions.
Explore cell counts and proportions to gain insights into sample
composition and detect differences between conditions.

#### **4. Multi-Dimensional Plots**
Visualize cell cluster distributions using UMAP and t-SNE projections.
These powerful 2D plots are essential for annotating cell types and
revealing the complex structure of high-dimensional single-cell data.

#### **5. Expression-Level Visualizations**
Dive deep into gene expression with flexible visualization tools,
including Violin Plots, Feature Plots, and Dot Plots. Select your
markers of interest and conveniently download publication-quality plots
for reports or presentations.

## 3.  **Description:**

### **Data Access and Initialization**

To ensure secure and streamlined data access, the Biocore team
provisions an encrypted string for each user, granting access only to
RDS files pertaining to the client's specific analyses. Upon inputting
this string, users are permitted to access all modules within the
scVizApp platform.

### **Data Loading**

Users initiate data analysis via the \'Load/Input Data\' interface. This
page enables users to select an RDS file from a dropdown menu populated
dynamically according to the encrypted authorization string. Upon
selection, the user triggers data upload by activating the 'LOAD DATA'
button. A progress bar positioned above the button denotes the upload
status. Upon successful upload, confirmation is provided via a
notification displaying the completed file name (e.g., \'✅ File
uploaded: \'). Subsequently, the application transitions automatically
to the Cell Summary Profile module (Section 3.2).

### **User Guidance**

scVizApp includes an integrated \'Overview\' manual, accessible via the
navigation tab, which delineates each module's functionality. This
documentation provides an abstract, detailed outline, and comprehensive
descriptions, facilitating intuitive user engagement and workflow
navigation.

## 4.  **Analytical Modules**

### **4.1 Cell Summary Profile**

#### **4.1.1 Cell Summary**

This module empowers users to interrogate cell distribution across
samples, Seurat clusters, cell types, or experimental
conditions---metadata prerequisites included within the uploaded RDS
file. Users may designate specific metadata variables as rows and
columns to compute and visualize cell abundance and proportional
distribution accordingly. Results are depicted via a stacked bar plot,
illustrating distribution clarity. The module supports versatile summary
calculations under varying conditions, and users may export results as
CSV files or download the graphical output in PDF format. Plot
aesthetics (height and width) are adjustable per user requirements.

#### **4.1.2 MultiDimensional Plots**

This module facilitates visualization of dimensionality reductions
present within the RDS file, including PCA, UMAP, or tSNE embeddings.
Users may select from available reductions and annotations to explore
cluster organization. Cluster labels are selectable through a dropdown
menu, and the option to facet plots based on additional metadata is
provided via the \'Clusters Split\' parameter. Multi-dimensional plots
are exportable in PDF format with user-defined dimensions.

#### **4.2 Violin Plots**

Violin plots enable visualization of gene expression distributions at
single-cell resolution across clusters. The user may select genes of
interest (markers) via a dropdown populated by the normalized expression
matrix. The x-axis can be configured to display the expression
distribution across selected clusters or metadata variables. Faceting by
samples or other metadata is supported to facilitate comparative
expression analysis. All violin plots are downloadable in PDF format
with customizable sizing.

#### **4.3 Feature Plots**

Feature plots project marker gene expression onto a multidimensional
embedding (default: UMAP), aiding spatial interpretation of expression
patterns at single-cell resolution. Marker selection mirrors the
interface of the Violin Plot module, and the feature plots allow
faceting by experimental variables if desired. Outputs are exportable as
PDF files with flexible plot dimensions.

#### **4.4 Dot Plots**

In the Dot Plot module, users can examine relative average expression of
selected markers per cluster, with dot size and color encoding percent
expression and average expression levels, respectively. The platform
supports comparison of multiple genes/markers, provides cell type and
cell cycle phase marker options (Human only), and allows users to upload
custom gene lists via Excel/CSV/TXT files for bespoke analyses. Dot
plots are downloadable in adjustable PDF formats for integration into
downstream reports or publications.

## **Output Customization and Export**

All plots can be resized prior to export, and downloadable options
include high-resolution PDF for figures and CSV for tabular summaries.
This ensures compatibility with downstream analysis pipelines and
publication standards.

**Usability**

scVizApp is designed for users with varying expertise in single-cell
analysis, providing:

- **Straightforward navigation** via clearly labeled tabs and modules.

- **Dropdown- and button-based inputs** with real-time feedback.

- **Automatic feature detection** (e.g., reductions, markers) lowers the
  barrier for non-programmers.

- **Seamless export options** allow users to integrate figures and data
  into downstream publications or presentations.

<!-- -->

- **Security:** Robust data access via encrypted keys ensures client
  privacy and analysis exclusivity.

- **User-friendly:** Intuitive UI/UX minimizes required training time
  and improves analysis speed.

- **Comprehensiveness:** Covers all standard visualization needs for
  single-cell analysis (cell summaries, reductions, expression plots).

- **Customizability:** Adjustable plot dimensions, faceting, and gene
  selection empower users to tailor analyses to specific needs.

- **Interoperability:** Outputs are ready for publication or further
  computational analysis.

- **Scalability:** Capable of handling varying dataset sizes and
  complexities, accommodating heterogeneous client requirements.

- **Documentation:** Built-in guidance streamlines onboarding,
  troubleshooting, and workflow optimization.

- **Efficiency:** Automatic module progression and preset workflows save
  time and streamline the analysis process.

- **Versatile metadata-driven summaries** with user-configurable axes
  and grouping.
