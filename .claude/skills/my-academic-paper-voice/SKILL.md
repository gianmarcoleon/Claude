---
name: my-academic-paper-voice
description: Write academic papers in Gianmarco León-Ciliotta's voice, based on his published work in development economics and political economy (JPE, ReStat, AEJ, JDE, JPubE, JEEA). Use this skill whenever drafting, revising, or structuring any part of an economics paper — abstracts, introductions, background sections, empirical strategy, results, mechanisms, or conclusions — and whenever Gianmarco asks to "write up" results, turn notes into paper text, or polish a manuscript. Trigger proactively for any academic paper writing, even if the voice or style is not explicitly mentioned.
---

# My (Academic Paper) Voice

This skill captures how Gianmarco León-Ciliotta writes empirical economics papers, distilled from the final working-paper versions of his publications (2017–2026), including papers in JPE, ReStat, AEJ: Applied, AEJ: Economic Policy, AER: Insights, JDE, JPubE, JEEA, and AJPS. The goal is text that reads like he wrote it: applied-micro prose that moves from a broad question to a precise design to quantified findings, always anticipating the referee's next objection.

For verbatim model passages from the actual papers, read `references/excerpts.md` — use them as calibration before drafting any major section.

## Voice at a glance

- First person, active voice: "I combine a field experiment with..." (solo), "We design a large field experiment..." (coauthored). Never "this study examines."
- Every effect is quantified, with units: percentage points (pp), percent, standard deviations (σ), elasticities, or monetary amounts with USD conversions in parentheses. "Raising incentives more than triples take-up (from 0.6% to 2.7%)" — never "substantially increases take-up" alone.
- Claims are calibrated, not hyped. Strong verbs for design ("exploit," "leverage," "identify," "document"), cautious framing for interpretation ("suggestive evidence," "consistent with," "we cannot rule out that... but").
- Objections are raised and answered in the same breath: "One might be concerned that X. Using data from Y, we show that Z."
- Signposting is explicit and numbered: "We provide three main findings. First, ... Second, ... Third, ..."; "Our analysis proceeds in four steps."
- Citations sit in parentheses inside the sentence flow; footnotes carry literature detail, caveats, and institutional color that would clog the main text.
- Em dashes set off asides and definitions — like this — frequently.

## Paper architecture

Default section structure (adapt names to the paper, but keep the logic):

1. **Introduction** (5–8 pages; see the formula below)
2. **Institutional Background / Context** — concrete facts about the setting, with numbers; for experiments, combined with **Experimental Design** (treatments, randomization, scripts quoted verbatim where useful)
3. **Data** — sources first, then variables, then descriptive statistics and balance checks
4. **Empirical Strategy** — sometimes merged with Results ("Empirical Strategy and Results")
5. **Results** — baseline → robustness → heterogeneity
6. **Mechanisms** — conceptual framework predictions tested one by one; alternative explanations ruled out explicitly; in recent papers, a structural model with counterfactuals
7. **Conclusion** ("Conclusions," "Summary and Discussion," "Concluding Remarks")

## The introduction formula

This is the most recognizable feature of the voice. Introductions follow a fixed sequence of moves, each one to three paragraphs:

1. **Broad opening.** Start from a widespread phenomenon, policy, or first-order economic question — not from the literature. ("Electoral institutions and policies to encourage voter participation are widespread around the world." / "Firms that generate externalities do not exist in isolation.") Close the paragraph with the gap: "However, little is known about...", "surprisingly little attention has been devoted to...".

2. **"In this paper, I/we..."** State exactly what the paper does in one paragraph: the question, the setting, the source of variation, and the design. This paragraph is the contract with the reader.

3. **Setting and design compressed.** Two or three paragraphs of essential institutional facts and the experiment/natural experiment, with concrete numbers (sample sizes, payment amounts, dates, thresholds).

4. **Findings preview, numbered and quantified.** "We provide three main findings. First...". Every finding carries its magnitude. Where useful, extrapolate: "if the fine was eliminated, turnout could decrease from 94.2 percent to about 72 percent, roughly what we observe in countries where voting is voluntary."

5. **Identification reassurance.** Name the main threats and dispatch them: robustness to controls and fixed effects, pre-trends, placebo checks, bounding exercises. Use the "one might be concerned that... we show that..." construction.

6. **Mechanisms.** Often opened with a question ("How could it be that CV had large impacts on turnout, but did not affect policy outcomes?" / "What mechanisms underlie the reduction in demand...?"), then the hypothesis, then the evidence consistent with it, then the alternatives ruled out.

7. **Contributions to the literature.** "This paper contributes to three strands of the literature. First, ... Second, ... Finally, ...". Each strand: a tight characterization of what exists (with parenthetical citations), then the precise marginal contribution — "We add to this literature by...", "To our knowledge, this is the first paper to estimate...". Distinguish the paper from its closest neighbors by name and explain exactly what they could not do ("León (2015) can only analyze policy preferences and cannot analyze actual policies as our paper does").

8. **Roadmap.** One short paragraph: "The paper proceeds as follows. Section 2 provides background... Section 7 concludes."

## The abstract formula

100–150 words, no motivation sentences. The sequence: (i) what we study and where ("We study X, leveraging Y"); (ii) the design in one clause; (iii) the main finding with its magnitude; (iv) the secondary finding or the mechanism ("This is explained by..."; "The results are driven by..."); (v) optionally, a one-sentence design or policy implication ("Organizations designing incentive schemes should therefore pay attention to both the level and the transparency of such incentives."). No citations, no "we discuss implications" filler.

## Empirical strategy sections

- Where identification is subtle, open with the **ideal experiment**: "In the ideal experiment we would randomly allocate... Obviously, random variation of this sort is nearly impossible to find. Instead, we rely on..."
- State the estimating equation early, then define every symbol immediately after in a "where..." sentence: subscripts, treatment variables, fixed effects, and the clustering level ("Standard errors are clustered at the treatment unit level, the municipality").
- Name the coefficient of interest and say in words what variation identifies it: "We are interested in the coefficient β, which is estimated using variation in..."
- Follow with identification assumptions and the tests that support them (parallel pre-trends, balance, McCrary-style checks), each tied to a table or figure.

## Results prose

- Lead each results subsection with the economic question it answers, not the table number.
- Report point estimates in sentences with both the raw coefficient's meaning and a benchmark: "a 10% increase in the number of reported cases leads to a 0.9% lower usage of contraceptives"; "equivalent to moving from the first to the third quartile of the distribution."
- After the baseline result, the order is: robustness (attrition bounds, alternative specifications, alternative measures), then heterogeneity, each motivated by why it matters rather than presented as a checklist.
- Interpret heterogeneity through a framework: "These heterogeneous effects are consistent with the predictions of..."
- When a result could be read two ways, say so and adjudicate with auxiliary evidence; concede honestly what cannot be ruled out: "While we cannot rule out that alternative mechanisms also play a role, our results indicate that..."

## Conclusions

Two to five paragraphs, in this order: restate the question and design in two or three sentences; summarize the findings with their headline magnitudes; draw out policy implications concretely (often "These results have strong implications for the design of..." with numbered implications); discuss external validity — to which settings do the results travel, and where might they not ("the optimal allocation might differ in organizations where..."); optionally close with what improved data or technology implies for future work. A back-of-the-envelope cost-effectiveness or welfare calculation often appears here or just before.

## Sentence-level habits

- Preferred verbs: exploit, leverage, document, identify, estimate, shed light on, speak to, complement, underscore, highlight.
- Stock constructions: "consistent with the hypothesis that"; "is an ideal setting to study X for several reasons. First, ..."; "a key challenge in... is..."; "to put these numbers into perspective"; "a back-of-the-envelope calculation"; "taken together, our results imply".
- Hedging hierarchy: established results get plain indicative ("a smaller fine has a robust, negative effect"); mechanism evidence gets "suggestive evidence" or "consistent with"; speculation gets "may," "might," "we hypothesize."
- Footnotes do real work: extended literature strands, data details, institutional anecdotes, quotes from interviews or officials, and responses to potential referee objections.
- Acronyms defined at first use and reused aggressively (CV, GOTV, VSL, CHW, PS, DiD, ITT).
- Spell out study-design transparency where relevant: pre-registration numbers, IRB approvals, prediction-platform forecasts.

## What to avoid

- Unquantified effect claims ("large effect," "significant impact" without numbers).
- Passive constructions for the paper's own actions ("it is shown that" → "we show that").
- Motivation-heavy abstracts or literature-first introductions.
- Bullet points in paper text — everything is prose; numbered lists live inside sentences ("three main findings. First, ...").
- Overselling: never "groundbreaking," "novel" is used sparingly and concretely ("novel evidence on the optimal structure of...").
- Rhetorical throat-clearing ("It is important to note that," "Interestingly," used at most once per section).

## Workflow

1. Before drafting, read `references/excerpts.md` and skim the move structure relevant to the section being written.
2. Draft the section following the formulas above, inserting placeholder magnitudes in brackets ("[X] pp") if the numbers are not yet available — never invent numbers.
3. Reread the draft against the "What to avoid" list and the voice checklist; tighten until every paragraph earns its place.
