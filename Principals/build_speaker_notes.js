const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, PageNumber, Header, Footer
} = require("docx");

// ---------- helpers ----------
const BLUE = "1F4E79";
const GREY = "555555";

function h1(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(text)] });
}
function h2(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(text)] });
}
function label(text) {
  return new Paragraph({
    spacing: { before: 120, after: 40 },
    children: [new TextRun({ text, bold: true, color: BLUE, size: 22 })],
  });
}
// body paragraph supporting simple **bold** segments
function body(text) {
  return new Paragraph({
    spacing: { after: 80 },
    children: parseRuns(text),
  });
}
function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bul", level },
    spacing: { after: 40 },
    children: parseRuns(text),
  });
}
function sayBox(text) {
  return new Paragraph({
    spacing: { before: 60, after: 160 },
    indent: { left: 360 },
    border: { left: { style: BorderStyle.SINGLE, size: 18, color: BLUE, space: 12 } },
    children: [new TextRun({ text, italics: true, color: "333333" })],
  });
}
// parse **bold** markup into runs
function parseRuns(text) {
  const runs = [];
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  for (const p of parts) {
    if (!p) continue;
    if (p.startsWith("**") && p.endsWith("**")) {
      runs.push(new TextRun({ text: p.slice(2, -2), bold: true }));
    } else {
      runs.push(new TextRun(p));
    }
  }
  return runs;
}

// A standard slide block: title, "shows", key points (array), say
function slide(num, title, shows, points, say, extra) {
  const out = [h2(`Slide ${num} — ${title}`)];
  if (shows) { out.push(label("What the slide shows")); out.push(body(shows)); }
  if (points && points.length) {
    out.push(label("Key points to make"));
    for (const pt of points) {
      if (Array.isArray(pt)) out.push(bullet(pt[0], 1));
      else out.push(bullet(pt));
    }
  }
  if (extra) { for (const e of extra) out.push(e); }
  if (say) { out.push(label("What you can say")); out.push(sayBox(say)); }
  return out;
}

let content = [];

// ---------- Title page ----------
content.push(new Paragraph({
  spacing: { after: 80 },
  children: [new TextRun({ text: "Speaker Notes", bold: true, size: 48, color: BLUE })],
}));
content.push(new Paragraph({
  spacing: { after: 40 },
  children: [new TextRun({ text: "Signal Extraction in Hiring: Evidence from Teacher Recruiting", bold: true, size: 30 })],
}));
content.push(new Paragraph({
  spacing: { after: 40 },
  children: [new TextRun({ text: "Bobba, Ederer, León-Ciliotta, Neilson & Nieddu", size: 24, color: GREY })],
}));
content.push(new Paragraph({
  spacing: { after: 240 },
  children: [new TextRun({ text: "Venice Summer Institute — “Managing the State: A New Look at Bureaucrats and Public Administration”, 24–25 June 2026", size: 22, italics: true, color: GREY })],
}));
content.push(body("These notes give, for each slide: (i) what the slide shows and how to read it, (ii) the key points to land, and (iii) a short verbatim narration you can say out loud. The full deck runs long; for the 30-minute Venice slot, the slides marked **[trim-able]** can be skipped or compressed — they are method detail the audience can take on faith."));
content.push(body("A general caveat to keep in mind throughout: the structural estimates and counterfactuals (the last block of slides) come from a **preliminary** draft. State them as current best estimates, not final numbers."));
content.push(new Paragraph({ spacing: { after: 120 }, border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 4 } }, children: [] }));

// ---------- SECTION: Setup ----------
content.push(h1("Setup: Motivation & Roadmap"));

content = content.concat(slide(1, "Title slide",
  "Just the title, authors, and venue. Use it to set the hook in one breath before moving on.",
  [
    "Introduce the paper as being about **how hiring managers screen workers when productivity is hard to observe** — using teacher recruitment in Peru as the laboratory.",
    "Flag the one-sentence selling point: you observe the same candidates ranked **before and after** a private interview, and you can benchmark those choices against an **objective** measure of productivity (value-added).",
  ],
  "Thanks very much. This paper asks a simple question with broad reach: when managers are given discretion to hire, why do they so often fail to pick the most productive workers? We study it in a setting — teacher recruitment in Peru — where we can see what principals do before and after they interview candidates, and where we can measure how good those candidates actually turn out to be in the classroom."));

content = content.concat(slide(2, "Motivation (1): why hiring, why the public sector",
  "Frames the economic importance of the hiring margin, especially in the public sector, and that discretionary screening frequently goes wrong.",
  [
    "Hiring is one of the **most consequential** decisions organizations make.",
    "In the **public sector** it is arguably the central personnel margin: wages are rigid, dismissals are rare, careers are long — so the quality of public services (learning, health, justice) is largely locked in **at the recruitment stage**.",
    "These decisions are made by **line managers** inferring productivity from noisy signals (resumes, tests, interviews), and the evidence shows discretionary screening often **misfires** — in both the private and public sectors.",
  ],
  "Start from the observation that hiring is one of the most consequential things an organization does — and nowhere more so than in the public sector, where you can’t easily adjust pay or let people go. Once you’ve hired a teacher, you’ve largely determined the quality of instruction for years. Yet these decisions are delegated to line managers working from noisy signals, and a large literature — in firms and in government — shows that this discretion frequently selects the wrong people."));

content = content.concat(slide(3, "Motivation (2): the two frictions and the identification problem",
  "States the central conceptual distinction the whole paper rests on, and why it is hard to test.",
  [
    "Two competing explanations for why discretion fails: **information frictions** (managers can’t tell good applicants from bad) vs. **agency frictions** (managers pursue something other than productivity).",
    "These call for **opposite policies**: information frictions → better signals/screening tools; agency frictions → changed incentives or limits on discretion.",
    "Separating them requires seeing what managers **know, learn, and choose**, all benchmarked against an **objective productivity measure** — data that rarely exist. That gap is the paper’s opportunity.",
  ],
  "Why might discretion fail? Two very different reasons. One is an information friction: the manager wants a good worker but simply can’t tell who’s good. The other is an agency friction: the manager can tell, but is optimizing for something else. The distinction matters enormously for policy — the first calls for better information, the second for better incentives. But you usually can’t separate them, because all you see is the final choice. To pull them apart you need to observe what managers know, what they learn, and what they choose — and check it against a real measure of productivity. That combination almost never exists in the data. Here it does."));

content = content.concat(slide(4, "This Paper",
  "The setting and the two-part research design (descriptive design + structural model).",
  [
    "Setting: **centralized recruitment of permanent teachers in Peru**, where schools interview shortlisted candidates and have real discretion over the final ranking.",
    "The key data asset: the **candidate ranking before and after the interview**, linked to student outcomes, with choices benchmarked against **teacher value-added**.",
    "On top of the descriptive design, a **structural model** of signal extraction: principals form priors about value-added, update on a noisy interview signal, and may also pursue other objectives / learn about other traits.",
  ],
  "Our setting is the centralized hiring of permanent teachers in Peru. Schools get a shortlist, interview the candidates, and retain genuine discretion over who is ranked first. Crucially, we observe each school’s ranking of the same candidates before and after that interview, and we can link the people they pick to how their students actually do. The ranking before the interview reveals what principals want; the change after it reveals what they learn. We then build a structural model around exactly that logic so we can run counterfactual screening policies."));

content = content.concat(slide(5, "Preview of (Preliminary) Results",
  "The headline numbers, so the audience knows where the talk is going. These are the punchlines you will return to.",
  [
    "**Substantial heterogeneity** across principals in both their preferences over value-added and their ability to learn from the interview.",
    "The interview reveals **little information on average**: it raises the value-added of the top-ranked candidate by only about **0.01σ**.",
    "Decomposition of the two frictions: eliminating **information frictions** is worth ~**0.11σ**, **agency frictions** ~**0.09σ**, and **both together ~0.21σ** of student value-added.",
    "A counterfactual policy — **disclosing value-added estimates** to schools — achieves the same gains as the interview while **avoiding the bias against women**.",
  ],
  "Here’s where we land. First, principals differ enormously, both in what they want and in how well they read the interview. Second, on average the interview is nearly uninformative about productivity — it moves selected value-added by about a hundredth of a standard deviation. Third, when we decompose the cost of the two frictions, they’re of similar size — about 0.11 and 0.09 sigma — and they compound to roughly 0.21 together. And finally, a simple policy of just handing schools a value-added estimate does about as well as the interview, without the gender penalty. I’ll build up to each of these."));

content = content.concat(slide(6, "Literature  [trim-able]",
  "Positions the contribution against three strands. In a 30-minute talk, summarize verbally in two sentences rather than dwelling.",
  [
    "**Employer learning / information in labor markets** (Jovanovic; Farber–Gibbons; Altonji–Pierret; Lange; Pallais): you move the learning problem **inside the hiring process**, modeling the interview as a pre-hire signal-extraction event.",
    "**Personnel economics of public-sector hiring** (Hoffman–Kahn–Li; Autor–Scarborough; Estrada; Colonnelli et al.; Weaver): you **decompose why** discretion underperforms — information vs. agency.",
    "**Teacher sorting, value-added and inequality** (Rivkin et al.; Chetty et al.; Bobba et al.; Bates et al.; Biasi et al.): you study the **demand side** and the role of principals in generating inequality.",
  ],
  "We sit at the intersection of three literatures. The employer-learning tradition studies how the market learns about workers after they’re hired; we bring that learning inside the recruitment process itself. The personnel-economics-of-the-public-sector work documents that discretion often selects poorly; we decompose why. And the teacher value-added literature focuses on supply and pay; we turn to the demand side — what principals do — and how it shapes inequality."));

// ---------- SECTION: Context, Data, TVA ----------
content.push(h1("Context, Data, and Teacher Value-Added"));

content = content.concat(slide(7, "Allocation Mechanism for Permanent Teachers in Peru",
  "The three-stage institution. Emphasize the features that make identification possible — this slide is doing double duty as ‘institutions’ and ‘research design’.",
  [
    "**Application stage**: a national test of skills/curricular knowledge; scoring above 60% makes you eligible; eligible applicants submit **rank-ordered lists (ROLs)** over schools.",
    "**Shortlisting**: a serial-dictatorship variant ranks applicants by test score and assigns them to up to three of their preferred schools — shortlists of at most 10.",
    "**School-based evaluation**: each school awards points via CV, interview, and classroom observation; the final ranking combines the test score with school-assigned points.",
    "Three features that the design exploits: schools have **real discretion** (points can overturn the test ranking), there are **rankings of the same candidates at successive stages**, and the **ROLs** reveal applicants’ preferences (used later to correct value-added).",
  ],
  "The mechanism has three stages. Applicants first sit a national test; clear 60% and you’re eligible, and you submit a ranked list of schools. A serial-dictatorship rule then builds each school a shortlist of up to ten candidates. Finally — and this is the heart of the paper — each school runs its own evaluation: it reviews the CV, interviews the candidate, and watches a demonstration lesson, awarding points that combine with the test score to set the final ranking. Three things matter for us: principals have genuine discretion, we see their ranking of the same people at each stage, and the applicants’ ranked lists tell us their preferences, which we’ll use to clean up the value-added estimates."));

content = content.concat(slide(8, "School-based Evaluation Matters (Figure 1)",
  "Motivating evidence that the discretionary stage is not a rubber stamp. Panel (a): distribution of cumulative scores at each stage. Panel (b): probability the top-ranked candidate changes.",
  [
    "Panel (a): as you add CV, interview, and classroom components, the score distribution shifts right and — importantly — **spreads out**, i.e. schools actively use these stages to reshuffle candidates.",
    "Panel (b): the probability that the **first-ranked candidate changes** is ~19 pp after the CV stage, +16 pp after the interview, +33 pp after the classroom observation.",
    "Cumulatively, there is about a **50% chance** the top-ranked teacher is different from the one the test score alone would have picked.",
  ],
  "Before any modeling, is the discretionary stage even consequential? Yes. On the left, each evaluation component shifts and widens the score distribution — schools are reshuffling, not rubber-stamping. On the right, the probability that the top-ranked candidate changes relative to the pure test ranking builds up across stages to about fifty percent. So in half of all shortlists, discretion changes who would be hired. That’s what makes the question quantitatively interesting."));

content = content.concat(slide(9, "Data  [trim-able]",
  "The data sources. In a short talk, name them quickly and move on.",
  [
    "Core: the **centralized recruitment drive, 2015–2019** — universe of applicants and postings, submitted ROLs, shortlists, and candidate rankings at **each stage**. (~31,700 vacancies; ~51,500 applicants; estimation sample 14,638 applicants in 3,778 school pools.)",
    "Linked sources: a matched **teacher–student dataset** (demographics + test scores), public-sector **employment records 2012–2021**, and the **school census**.",
  ],
  "The data combine the full centralized recruitment drive between 2015 and 2019 — applicants, postings, ranked lists, shortlists, and the rankings at every stage — with three linked sources: a matched teacher–student dataset that lets us estimate value-added, employment records that track careers, and the school census for local characteristics."));

content = content.concat(slide(10, "Measuring Teacher Effectiveness",
  "The value-added model. Defines the object the whole paper benchmarks against.",
  [
    "Student potential outcome (4th-grade score): Y = αⱼ + Xℓ′βⱼ + Zℓ′γ + εℓⱼ.",
    "**αⱼ = the ATE** — teacher j’s average effect on scores. **βⱼ = match effects** — how j’s effectiveness depends on the student’s prior score and gender (comparative advantage).",
    "Rich controls Zℓ at student/classroom/school level, but you flag the worry up front: **selection on observables may be too strong** — better teachers may sort into certain schools/students — which the next slides correct.",
  ],
  "We measure teacher quality with a value-added model. Alpha-j is the teacher’s average effect on test scores — overall quality. Beta-j captures comparative advantage: whether a teacher is relatively better with high- or low-achieving students, or with girls. We control for a rich set of student, classroom, and school characteristics — but we’re worried that’s not enough, because good teachers may sort into particular schools. So the next two slides correct for that selection."));

content = content.concat(slide(11, "Selection on Unobservables (1)  [trim-able]",
  "First half of the selection correction: use applicants’ ROLs as a control function for unobserved match quality. Method slide — present at the level of intuition.",
  [
    "Idea: the applicants’ **own ranked lists** reveal their preferences over schools, which carry information about **unobserved match quality** that would otherwise bias value-added.",
    "Specify a **utility** teacher j gets from school i, u(zⱼ, xᵢ, dᵢⱼ, τⱼ) + ηᵢⱼ, where distance dᵢⱼ is **excluded from the outcome equation** (the exclusion restriction), and τⱼ is an unobserved preference type.",
  ],
  "To handle that sorting, we use a control-function approach built from the applicants’ ranked lists. The intuition: a teacher’s revealed preferences over schools tell us something about the unobserved match quality that would otherwise contaminate value-added. We write down the utility a teacher gets from each school — where geographic distance shifts preferences but is excluded from the student-outcome equation — and back out a correction term."));

content = content.concat(slide(12, "Selection on Unobservables (2)  [trim-able]",
  "Second half: the rank-ordered (exploded) logit likelihood, estimated by EM, delivering selection-corrected value-added.",
  [
    "Under truthful ranking and EVT1 shocks, the ROL likelihood is the standard **exploded/rank-ordered logit**.",
    "Estimate utility by the **EM algorithm** (to integrate out the unobserved types τⱼ), build the **control-function terms**, and recover **selection-corrected** value-added (α̂ⱼ, β̂ⱼ).",
    "(Robustness: results are similar under a ‘stability’-based alternative to truth-telling — Appendix.)",
  ],
  "Formally, the ranked lists give a standard exploded-logit likelihood, which we estimate with an EM algorithm to handle the unobserved preference types. That yields control-function terms, and plugging them into the outcome regression gives selection-corrected value-added. Reassuringly, an alternative assumption on how applicants rank schools leaves the results essentially unchanged."));

content = content.concat(slide(13, "Prior Distribution  [trim-able]",
  "Sets up the hierarchical/empirical-Bayes layer: individual value-added estimates are noisy, so you model the population (prior) they’re drawn from.",
  [
    "The individual estimates θ̂ⱼ are **noisy** (sampling variance Ω̂ⱼ). Assume the truth θⱼ is drawn from a **normal prior** whose mean depends on observables zⱼ and type τⱼ.",
    "Estimate the prior mean μ(·) and variance Σθ by **maximum likelihood**, effectively **deconvolving** the estimation noise from true dispersion.",
    "This prior is doing two jobs later: it is **what principals are assumed to know** before the interview, and it is the input to the shrunken (best-estimate) value-added.",
  ],
  "Individual value-added estimates are noisy, so we don’t use them raw. Instead we model the population they come from: true effectiveness is drawn from a normal prior whose mean depends on the teacher’s observables and type. We estimate that prior by maximum likelihood, which strips out estimation noise. This prior plays a double role: it’s our best summary of what a principal could know from observables before meeting the candidate, and it’s the anchor for the shrunken estimates."));

content = content.concat(slide(14, "Estimates of the Prior Mean (Table 1)",
  "Reports the coefficients of the prior-mean function — how predicted effectiveness moves with the teacher’s observables and latent type. Rows are the three pieces of effectiveness (ATE, match with prior score, match with gender); columns (1)–(3) are type-specific intercepts, (4)–(8) loadings on teacher observables.",
  [
    "Reading a cell: ATE × Test score = **0.096 (0.024)** ⇒ a 1σ-higher exam score predicts ~0.096σ higher average effectiveness (t≈4).",
    "**What predicts overall quality (ATE row)**: test score (0.096, sig.), private-sector experience (0.065, sig.), female (0.057, borderline). Public-sector experience is **not** significant.",
    "**Match effects barely predictable**: in the ‘Lagged score’ and ‘Female’ rows the observable loadings are tiny and mostly insignificant — you essentially can’t read comparative advantage off a CV.",
    "**Latent type matters**: the three baseline columns differ a lot for the ATE (−0.036 / 0.005 / −0.122), and since types come from job preferences, teachers’ revealed preferences carry real information about quality.",
  ],
  "Table 1 is the recipe that turns a CV into a predicted effectiveness. Read one cell: a one-sigma higher test score predicts about 0.10 sigma higher value-added — strongly significant. Across the top ‘ATE’ row, the credentials that genuinely predict quality are the exam score, private-sector experience, and — borderline — being female; tenure in the public sector does not. But look at the match-effect rows: observables are essentially useless for predicting who’s better with which students. And the three ‘baseline’ columns — the latent types — differ a lot, which tells us that teachers’ own revealed preferences over jobs encode information about how good they are."));

content = content.concat(slide(15, "Evidence of Misalignment Between School Preferences and TVA (Table 3)",
  "Each column = the characteristics of the candidate ranked first under a rule, as a deviation from random selection (column 1 = base rate). This slide compares what schools do pre-interview (col 2) with the value-added-optimal ranking, ‘Prior TVA’ (col 3, red).",
  [
    "Setup line: column (1) is the average candidate; columns (2)–(3) say how the top-ranked candidate differs from that average under the pre-interview ranking vs. a ranking on predicted value-added.",
    "Pre-interview rankings **over-weight** public-sector experience and internal candidates and **under-weight** test scores, women, and private experience — the near-mirror image of what value-added-optimal selection (col 3) would do.",
    "Punchline row — **Shrunken VA**: pre-interview ranking selects **no higher** value-added than the prior would (**0.010 vs. 0.015σ**). So deviations from the prior are **not** driven by superior, productivity-relevant information.",
    "Conclusion: the misalignment looks like **agency frictions** (other objectives), not principals knowing something we don’t.",
  ],
  "Same table format I’ll use twice. Column 1 is the average candidate; the other columns show how the person ranked first differs from that average under a given rule. Here I compare what schools actually do before the interview to what they’d do if they ranked on predicted value-added. The two are almost mirror images: schools love public-sector experience and insiders, and underweight test scores, women, and private experience — exactly the opposite of what maximizing value-added implies. And the key row: the pre-interview ranking selects no more value-added than the prior itself. So this isn’t principals using private information we lack — it points to misaligned objectives, an agency friction."));

content = content.concat(slide(16, "Estimates of the Prior Variance (Table 2)",
  "The variance-covariance of true effectiveness, net of observables and type. Column (1) is the standard deviation of each dimension; columns (2)–(3) are correlations between dimensions.",
  [
    "**ATE SD = 0.383σ** (tightly estimated): huge residual variation in overall quality among teachers who look identical on paper.",
    "Match effects also vary: **0.151σ** (prior score) and **0.108σ** (gender).",
    "Correlations across dimensions are **small and statistically insignificant** — overall quality and comparative advantage are largely separate.",
    "Interpretation: large unexplained variance = **a lot the CV doesn’t capture** = room for the interview to be informative (the empirical question answered later).",
  ],
  "Table 2 is the spread, not the prediction. The headline is the top-left number: even among teachers with identical CVs and type, the standard deviation of true effectiveness is about 0.38 sigma — teachers matter, and most of what makes them differ isn’t on paper. Comparative advantages vary too, though less. The cross-dimension correlations are basically zero. The takeaway for the rest of the talk: there is a lot the credentials miss — which is precisely the room an informative interview could fill.",
  [
    label("Honest caveat (for Q&A)"),
    body("The current draft’s prose describes these cross-dimension correlations as **positive**, but the estimated correlations are **negative and insignificant**. Lean on ‘essentially zero / imprecise’ rather than asserting a sign — and flag that the text is being updated."),
  ]));

content = content.concat(slide(17, "Empirical Bayes Shrinkage  [trim-able]",
  "Defines the ‘shrunken value-added’ used as the best estimate of true effectiveness and, later, as the disclosed signal in the policy counterfactual.",
  [
    "The shrunken estimate θ̂ⱼ* = a **precision-weighted blend** of the teacher’s own noisy estimate and the prior mean — noisy estimates get pulled toward the prior.",
    "It is the **posterior mean** a Bayesian who observed θ̂ⱼ would hold, and gives **MSE-optimal** predictions of effectiveness.",
    "This is the object the policy experiment later **hands to schools** in place of the interview.",
  ],
  "When we want the single best guess of a teacher’s effectiveness, we don’t use the raw estimate — we shrink it toward the prior, weighting each by how precise it is. Think of a hitter who goes four-for-four: you don’t believe they’re a thousand hitter, you pull them toward the population. That shrunken estimate is our best predictor of true quality, and later it’s exactly what we imagine disclosing to schools."));

content = content.concat(slide(18, "Evidence of Learning about Effectiveness (Table 3)",
  "Same Table 3, now comparing pre-interview (col 2) with post-interview (col 3, red). Because the interview is the only event in between, the change identifies what the interview teaches.",
  [
    "After the interview, the top candidate is selected **less on observable credentials** (e.g. test-score advantage shrinks 0.068 → 0.026) — the fingerprint of **Bayesian learning**.",
    "But two dimensions move on traits **unrelated to productivity**: the top candidate becomes **more likely male** (0.004 → −0.025) and **more likely internal** (0.014 → 0.043).",
    "Punchline — **Shrunken VA rises 0.010 → 0.022**: the post-interview pick is genuinely higher value-added, so the interview **does** convey real (if small) productivity information.",
    "Bridge: descriptively we can’t separate ‘learned about quality’ from ‘bias against women’ from ‘taste for insiders’ — **that is what the structural model disentangles** (γ vs. b(z) vs. v(z), ξ).",
  ],
  "Same table, now before versus after the interview — so this isolates what the interview adds. Two patterns. First, post-interview rankings lean less on observable credentials like the test score — the signature of learning from a direct signal. Second, and importantly, the value-added of the selected candidate actually rises, from 0.010 to 0.022 — the interview carries real information about who’s effective. The catch: it also tilts the top spot toward men and insiders, on dimensions unrelated to productivity. The interview informs and distorts at the same time — and separating those forces is exactly what the model does next."));

// ---------- SECTION: Model ----------
content.push(h1("A Model of Signal Extraction in Hiring"));

content = content.concat(slide(19, "Beliefs Updating",
  "First building block of the model: how principals’ beliefs about a candidate’s value-added evolve from prior to posterior across the interview.",
  [
    "Before the interview, principals hold a **common prior** on value-added qᵢⱼ (centered on the estimated prior mean).",
    "At the interview they receive a **noisy signal** νᵢⱼ and update by Bayes’ rule; the **weight on the signal** rises with prior uncertainty and falls with signal noise exp(γᵢ).",
    "Two key heterogeneous objects: **γᵢ = signal precision** (how good a principal is at extracting information — ‘the right tail can really read people’), and **b(zⱼ) = biased interpretation** (a candidate type, e.g. women, systematically mis-read).",
  ],
  "The first block is belief updating. Principals start with a common prior about a candidate’s value-added — basically the prior mean we just estimated. The interview delivers a noisy signal, and they update toward it, putting more weight on the signal when they’re uncertain and less when the signal is noisy. Two things vary across principals and will do a lot of work: gamma, how precisely a given principal reads the interview, and b, a systematic bias in how the signal is interpreted for certain candidate types — for instance, women."));

content = content.concat(slide(20, "School Preferences",
  "Second building block: the payoff that determines rankings, allowing for value-added plus other motives.",
  [
    "Expected value of hiring j: Vᵢⱼ = **δᵢ·E[value-added] + v(zⱼ) + ξᵢⱼ + εᵢⱼ**, evaluated on the information set before (g=1) or after (g=2) the interview.",
    "**δᵢ = weight on value-added** (alignment with maximizing achievement; log-normal, so heterogeneous).",
    "**v(zⱼ) = taste for observable types** (e.g. gender discrimination); **ξᵢⱼ = taste for fixed unobserved traits**; **εᵢⱼ = transitory shock**.",
    "This is what lets the model express ‘some principals care about value-added, others about other things’ — and to separate **taste** discrimination (v) from **biased learning** (b from the previous slide).",
  ],
  "The second block is preferences. A principal’s payoff from a candidate is a weight delta times expected value-added, plus a taste for observable characteristics like gender, plus idiosyncratic terms. Delta varies across principals — that’s how aligned they are with maximizing student achievement. The v term captures taste-based discrimination. Notice we now have two distinct gender channels: v, a taste against women in preferences, and b from the last slide, a bias in how their interview signal is read. Keeping those separate is central to the paper."));

content = content.concat(slide(21, "Identification",
  "Why the before/after design identifies the parameters. This is the conceptual payoff slide — worth slowing down even in the short version.",
  [
    "Assumptions: principals rank by Vᵢⱼ with **no strategic motives**, and shortlist composition is **orthogonal** to the structural shocks (applicants don’t know schools’ private tastes/signals).",
    "The **pre-interview** ranking identifies the distribution of preferences: the weight on value-added δᵢ and the taste term v(zⱼ).",
    "The **change** in ranking after the interview identifies the **learning** parameters: signal precision γᵢ, the unobserved-trait taste ξ, and the interpretation bias b(zⱼ).",
    "In one line: **what they want** is identified before the interview; **what they learn** is identified by how rankings move after it.",
  ],
  "Here’s why the design works. Under the assumption that principals rank by expected payoff and don’t game the system, the ranking before the interview reveals their preferences — how much they weight value-added, and any taste for particular types. Then the way the ranking changes after the interview reveals the learning technology — how precisely they read the signal, and whether they read it in a biased way. Preferences from the ‘before,’ learning from the ‘before-to-after’ change. That separation is the methodological core of the paper."));

content = content.concat(slide(22, "Estimation  [trim-able]",
  "How the model is taken to data. Present at a high level.",
  [
    "Both stages’ rankings enter a **rank-ordered logit** likelihood, conditional on the heterogeneous parameters.",
    "Maximize the **simulated joint likelihood**, drawing the interview signal νᵢⱼ from its distribution **conditional on the estimated value-added** θ̂ⱼ.",
    "Conditioning the signal draws on actual value-added is what gives the model traction to identify the **learning** parameters.",
  ],
  "We estimate by maximum simulated likelihood: both the pre- and post-interview rankings enter a rank-ordered logit, and we integrate over the principal-specific parameters and the interview signals. The trick is that we draw those signals conditional on the candidate’s estimated value-added, which is what lets the data speak to how much principals actually learn."));

// ---------- SECTION: Estimates & Counterfactuals ----------
content.push(h1("Estimates and Counterfactuals"));
content.push(body("Reminder: the estimates and counterfactuals in this block are from a **preliminary** draft (the paper’s results/counterfactual sections are still being finalized). Present them as current best estimates."));

content = content.concat(slide(23, "School Preferences (estimates)",
  "Estimated preference parameters. Mean and SD of the value-added weight δ, plus the gender taste term.",
  [
    "**Value-added weight δ: mean 0.847, SD 0.709** — principals do put weight on value-added, but with **enormous heterogeneity** (some far more aligned than others).",
    "**Female taste term: −0.030, insignificant** — **no evidence of taste-based gender discrimination** in preferences.",
    "Implied **rank correlation** between value-added and post-interview preferences: **0.46**, vs. a full-information benchmark of **0.62** — aligned, but well short of optimal.",
  ],
  "Turning to estimates: principals do value value-added — the average weight is positive and sizable — but the spread is large, so some principals are much more aligned with student achievement than others. The gender taste term is essentially zero: we find no evidence of taste-based discrimination against women in preferences. Overall, the rank correlation between what principals want and true value-added is about 0.46, against a full-information benchmark of 0.62 — they’re partly aligned, but leaving a lot on the table."));

content = content.concat(slide(24, "Learning (estimates)",
  "Estimated learning parameters: signal precision and the gender interpretation bias.",
  [
    "**Signal precision γ: mean 1.421, SD 0.649** — on average the interview is **weakly informative**, but with **strong heterogeneity**: a right tail of principals extracts real information.",
    "**Bias against women: −3.184 (large, significant)** — the interview signal is read in a way that **systematically penalizes female candidates**.",
    "Key contrast with the previous slide: the gender penalty operates through **biased learning (b)**, NOT through preferences (v) — so it’s a **belief**, not a **taste**, problem.",
  ],
  "Now the learning side. On average the interview is only weakly informative — but again with big heterogeneity: there’s a right tail of principals who genuinely read candidates well. And here is where the gender story lives: the interview signal is interpreted in a way that systematically penalizes women. Put the two slides together and you get a sharp result — the gender penalty is not a taste for hiring men, it’s a bias in how women’s interviews are read. That distinction matters enormously for policy."));

content = content.concat(slide(25, "Learning: distribution of signal weights (Figure)",
  "Histogram of the weight principals place on the interview signal relative to the prior. Visual of the heterogeneity from the previous slide.",
  [
    "**Most principals place a weight below 0.1** on the interview signal — i.e. they barely move off the prior.",
    "But the distribution has a **long right tail**: a minority extract substantial information.",
    "This is the picture behind ‘little learning on average, large heterogeneity’ — and it’s what makes ‘**identify and leverage the good evaluators**’ a sensible policy direction.",
  ],
  "This histogram makes the heterogeneity concrete: it’s the weight principals put on the interview signal relative to their prior. The mass is below 0.1 — most principals essentially ignore the signal — but there’s a real right tail of skilled evaluators. So the average hides a lot, and it suggests a policy angle: find and lean on the principals who can actually read candidates."));

content = content.concat(slide(26, "Decomposing Frictions (design)  [trim-able]",
  "Sets up the counterfactual decomposition: how the two frictions each affect the value-added of the hired teacher.",
  [
    "Simulate counterfactual worlds: **no information frictions** (schools observe value-added) and **no agency frictions** (schools fully aligned with maximizing value-added).",
    "Implementation: draw value-added and the principal parameters from their posteriors (conditional on the observed rankings), draw signals and shocks, and re-construct the pre/post rankings under each scenario.",
  ],
  "To quantify the cost of each friction, we simulate counterfactual worlds. In one, we remove the information friction — schools simply observe value-added. In another, we remove the agency friction — schools care only about value-added. We draw the relevant parameters from their estimated posteriors, rebuild the rankings, and read off the value-added of whoever ends up on top."));

content = content.concat(slide(27, "Decomposing Frictions (results)",
  "The decomposition table: value-added of the top-ranked candidate under status quo and under each friction removed.",
  [
    "Removing **information frictions** raises selected value-added by ~**0.11σ**.",
    "Removing **agency frictions** raises it by ~**0.09σ** — the two frictions are of **similar magnitude**.",
    "Removing **both** yields ~**0.21σ** — slightly more than the sum, i.e. the frictions are **complements** (each makes the other costlier).",
    "Anchor for scale: the actual interview moves selected value-added only ~**0.01σ** — so the achievable gains are an **order of magnitude** larger than what the status-quo interview delivers.",
  ],
  "Here’s the payoff. If schools could see value-added, the teacher they pick would be about 0.11 sigma better. If instead they simply maximized value-added with the information they have, about 0.09 sigma better. The two are of similar size, and together they deliver about 0.21 — slightly more than the sum, so the frictions reinforce each other. For scale, remember the interview itself only buys about 0.01 sigma. The room for improvement is roughly an order of magnitude larger than what current discretion achieves."));

content = content.concat(slide(28, "Policy Experiment (design)  [trim-able]",
  "Motivates the concrete, implementable policy: replace the interview with disclosed value-added estimates.",
  [
    "Two levers in principle: give schools **more accurate information**, or **change incentives** to seek effective teachers and avoid bias.",
    "The experiment targets the first: **eliminate the interview** and instead **disclose the shrunken value-added estimate** to schools.",
    "This **reduces information frictions while sidestepping biased learning** (the gender penalty rode on the interview signal).",
  ],
  "Can we design something implementable? The cleanest lever is information. So we consider replacing the interview with a disclosed value-added estimate — the shrunken estimate from earlier. Mechanically, this gives schools better information and, because the gender bias was riding on the interview signal, it removes that channel at the same time."));

content = content.concat(slide(29, "Policy Experiment (results)",
  "Counterfactual table: characteristics and value-added of the top-ranked candidate under the status-quo post-interview ranking vs. the disclosure policy.",
  [
    "Disclosing value-added achieves **slightly higher value-added gains** than the status-quo interview (0.018 vs. 0.015σ on this metric).",
    "And it **eliminates the gender penalty**: the female gap at the top flips from −0.023 (status quo) to **+0.005** (counterfactual).",
    "Message: a simple, scalable information policy **matches or beats** discretionary interviewing on efficiency **and** improves equity.",
  ],
  "And it works. Disclosing a value-added estimate does at least as well as the interview on efficiency, and it removes the gender penalty — the under-selection of women at the top disappears. So a simple, cheap, scalable information policy dominates the status-quo interview on both efficiency and equity. That doesn’t mean ‘abolish discretion’ — there’s a right tail of skilled interviewers — but it does mean better information is a free lunch here."));

content = content.concat(slide(30, "Conclusion",
  "Wrap up: what you did, what you found, why it matters.",
  [
    "**Design + structural model** of teacher recruiting in Peru: schools form priors about value-added and update after the interview; rankings before and after **separately identify preferences from learning**.",
    "**Findings**: substantial heterogeneity in preferences; little learning from the interview on average; the two frictions together cost ~**0.21σ** of student value-added; the gender penalty is a **belief**, not a taste.",
    "**Policy**: disclosing value-added estimates matches the interview’s gains and removes the bias — and, more broadly, the **screening ability of managers** is a dispersed, largely unmeasured input worth measuring and selecting for.",
  ],
  "To wrap up: we use rich data and a structural model to open the black box of discretionary hiring. The before/after-interview design lets us separately recover what principals want and what they learn. We find wide heterogeneity, a near-uninformative interview on average, two frictions of similar size that together cost about a fifth of a standard deviation of student learning, and a gender penalty that runs through biased beliefs rather than tastes. The policy upshot is encouraging: simply disclosing value-added estimates is as effective as the interview and fairer. More broadly, the ability to screen well is a real but unmeasured managerial skill — and centralized hiring platforms now make it possible to measure it. Thank you."));

// ---------- build document ----------
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Calibri", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 30, bold: true, color: BLUE, font: "Calibri" },
        paragraph: { spacing: { before: 320, after: 160 }, outlineLevel: 0,
          border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: BLUE, space: 4 } } } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 25, bold: true, color: "000000", font: "Calibri" },
        paragraph: { spacing: { before: 260, after: 80 }, outlineLevel: 1 } },
    ],
  },
  numbering: {
    config: [
      { reference: "bul", levels: [
        { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 460, hanging: 260 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "–", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 920, hanging: 260 } } } },
      ] },
    ],
  },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
      children: [new TextRun({ text: "Signal Extraction in Hiring — Speaker Notes", color: GREY, size: 18 })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: "Page ", size: 18, color: GREY }), new TextRun({ children: [PageNumber.CURRENT], size: 18, color: GREY })] })] }) },
    children: content,
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("Speaker_Notes_Signal_Extraction.docx", buf);
  console.log("written:", buf.length, "bytes");
});
