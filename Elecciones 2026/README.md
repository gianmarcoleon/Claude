# Elecciones 2026 — voting-table opening delays (first round)

Mesa-level analysis of the April 12–13, 2026 first round: effects of late-opening
and next-day voting tables on turnout, blank/null votes, and candidate vote shares.

**Deliverable:** `outputs/report.pdf` (working note, 9 pp.)

## Pipeline (rerun in order)

1. `scripts/01_build_dataset.py` — parses the pre-extracted mesa CSVs (built from the
   raw ONPE JSONL in `Dropbox/Bases de datos/Elecciones y outcomes distritales/Eleccciones 2026/`
   by a scratchpad `extract.py`; re-extraction takes ~3 min) and writes
   `outputs/mesas_analysis.csv` with treatments:
   - `nextday`: 187 mesas in the 13 JNE-authorized April-13 locales (exact, matches
     official 55,261 registered voters);
   - `late6` / `late12`: locale-level proxy (median first acta transmission ≥6h/≥12h
     after the 5pm close, Lima Metro, excl. next-day locales).
2. `scripts/02_regressions.do` — Stata (batch: `stata -b do 02_regressions.do`);
   all specs → `outputs/results.csv`, dataset → `outputs/mesas_analysis.dta`.
3. `scripts/03_permutation_figures.py` — randomization inference (5,000 within-district
   permutations of the 13 treated locales) → `outputs/ri_pvalues.csv`; figures 1–3.
4. `scripts/04_make_tables.py` — LaTeX table fragments + back-of-envelope numbers.
5. `pdflatex report.tex` (×2) inside `outputs/`.

## Key results

- Next-day mesas: turnout −4.9pp (RI p=.019), fully recovered in the runoff;
  blank+null −1.4pp; Nieto (PBG) +16.7pp, Fujimori +5.4pp, Belmont −2.7pp —
  informed/strategic voting after results were public.
- Late-opening proxy: small effects (turnout −0.8pp, blank+null +0.8pp).
- Implied shift in the decisive Sánchez–López Aliaga margin ≈ 7k votes < 21,210 gap.

Related external work: Stanford Democracy Action Lab "Missing Voters"
(cddrl-impactoelectoral.com) — has actual opening times OCR'd from installation actas
(data by request: democracyactionlab@stanford.edu).
