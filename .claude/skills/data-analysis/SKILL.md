# Data Analysis Workflow Guide

This template establishes a structured Stata workflow for comprehensive data analysis. The process unfolds across five distinct phases:

**Setup & Loading:** Begin by reviewing project conventions, creating a properly formatted do-file with a header block (title, author, date, description), setting globals for file paths, and using `set seed` for reproducibility. Load data with `use` or `import delimited`/`import excel`, and work on a copy — never modify raw data.

**Exploratory Analysis:** Generate diagnostic outputs including `summarize`, `codebook`, and `tabulate` for summary statistics; `histogram`, `kdensity`, and `scatter` for distributions and relationships; and `tabstat` or `table` for group comparisons. Save diagnostics to `outputs/diagnostics/`.

**Main Analysis:** Conduct appropriate statistical modeling — using `reghdfe` for panel data with high-dimensional fixed effects, or `regress`/`logit`/`probit` for cross-sectional work. Document clustering decisions (e.g., `vce(cluster id)`), use `xtset` or `tsset` for panel/time-series data, and progressively add controls across specifications.

**Publication Output:** Create regression tables via `esttab` or `outreg2`, exporting as `.tex` and `.rtf`/`.csv`. Generate figures using `twoway` or `graph bar` with consistent scheme settings (e.g., `scheme(s2mono)`), and export in both `.pdf` and `.png` formats using `graph export`. Store all outputs in `outputs/`.

**Save & Review:** Use `save` or `saveold` for processed datasets and `estimates save` for model objects. Verify the do-file runs end-to-end without errors from a clean state (`clear all` at the top). Address any issues with hardcoded paths, missing error handling, or non-reproducible steps.

The framework emphasizes reproducibility through relative file paths via globals, transparency via intermediate results and logs (`log using`), issue detection (multicollinearity via `vif`, outliers via `leverage`/`rstudent`), and keeping raw data untouched.
