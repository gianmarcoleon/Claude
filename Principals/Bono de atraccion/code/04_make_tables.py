#!/usr/bin/env python3
"""
BONO DE ATRACCION - RD ANALYSIS
04_make_tables.py
Reads the results CSVs produced by 03_analysis.do and writes LaTeX table
fragments plus a nums.tex file with \newcommand macros used in the prose,
so the working document always reflects the latest estimates.
"""
import csv
import os
import re

PROJ = "/Users/u90397/Dropbox/research projects/Claude/Principals/Bono de atraccion"
TABS = os.path.join(PROJ, "output", "tables")
DOC = os.path.join(PROJ, "doc")
os.makedirs(DOC, exist_ok=True)


def read(fname):
    with open(os.path.join(TABS, fname), newline="") as f:
        return list(csv.DictReader(f))


def fnum(x, d=3):
    try:
        return f"{float(x):.{d}f}"
    except (TypeError, ValueError):
        return ""


def stars(p):
    try:
        p = float(p)
    except (TypeError, ValueError):
        return ""
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.1:
        return "*"
    return ""


def pct(x, d=1):
    return f"{100*float(x):.{d}f}"


fs = read("res_firststage.csv")
out = read("res_outcomes.csv")
val = read("res_validity.csv")
rob = read("res_robust.csv")
het = read("res_hetero.csv")

# ---------------------------------------------------------------- first stage
rows5 = {r["sample"]: r for r in fs if float(r["h"]) == 5}
rows10 = {r["sample"]: r for r in fs if float(r["h"]) == 10}
order = ["2015", "2017", "2018", "2019", "Pooled"]
with open(os.path.join(DOC, "tab_firststage.tex"), "w") as f:
    f.write("\\begin{tabular}{lccccc}\n\\toprule\n")
    f.write(" & 2015 & 2017 & 2018 & 2019 & Pooled \\\\\n\\midrule\n")
    for h, rows in ((5, rows5), (10, rows10)):
        f.write(f"\\multicolumn{{6}}{{l}}{{\\emph{{Bandwidth $\\pm{h}$ points}}}} \\\\\n")
        f.write("RD estimate")
        for s in order:
            f.write(f" & {fnum(rows[s]['coef'])}")
        f.write(" \\\\\n")
        f.write("")
        for s in order:
            f.write(f" & ({fnum(rows[s]['se'])})")
        f.write(" \\\\\n")
        f.write("Obs.\\ left/right")
        for s in order:
            f.write(f" & {int(float(rows[s]['nl']))}/{int(float(rows[s]['nr']))}")
        f.write(" \\\\\n")
        if h == 5:
            f.write("\\midrule\n")
    f.write("\\bottomrule\n\\end{tabular}\n")

# ------------------------------------------------------------------- outcomes
LBL = {
    "accept": "Nombrado in payroll, $t+1$ (acceptance)",
    "retain2": "Nombrado, $t+2$",
    "retain3": "Nombrado, $t+3$",
    "retain4": "Nombrado, $t+4$",
    "anywork1": "In payroll (any status), $t+1$",
    "anywork2": "In payroll (any status), $t+2$",
    "anywork3": "In payroll (any status), $t+3$",
    "samesch1": "Nombrado in assigned school, $t+1$",
    "samesch2": "Nombrado in assigned school, $t+2$",
    "samesch3": "Nombrado in assigned school, $t+3$",
    "director_ever": "Ever director/directivo by 2021",
    "promoted_2021": "Escala 2+ by 2021 (2015/17 cohorts)",
    "nombrado5": "Nombrado, $t+5$",
    "nombrado6": "Nombrado, $t+6$",
}
pooled = [r for r in out if r["sample"] in ("Pooled", "1517")]
with open(os.path.join(DOC, "tab_outcomes.tex"), "w") as f:
    f.write("\\begin{tabular}{lcccccc}\n\\toprule\n")
    f.write(" & \\multicolumn{2}{c}{Reduced form} & \\multicolumn{2}{c}{Fuzzy RD} & & Control \\\\\n")
    f.write("\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}\n")
    f.write("Outcome & Estimate & (SE) & Estimate & (SE) & $N$ (bw) & mean \\\\\n\\midrule\n")
    for r in pooled:
        name = LBL.get(r["outcome"], r["outcome"])
        n = int(float(r["nl"]) + float(r["nr"]))
        f.write(
            f"{name} & {fnum(r['rf_b'])}{stars(r['rf_pv'])} & ({fnum(r['rf_se'])}) & "
            f"{fnum(r['fz_b'])}{stars(r['fz_pv'])} & ({fnum(r['fz_se'])}) & "
            f"{n:,} & {fnum(r['mean0'])} \\\\\n"
        )
    f.write("\\bottomrule\n\\end{tabular}\n")

# per-cohort table
with open(os.path.join(DOC, "tab_cohorts.tex"), "w") as f:
    f.write("\\begin{tabular}{lcccc}\n\\toprule\n")
    f.write(" & 2015 & 2017 & 2018 & 2019 \\\\\n\\midrule\n")
    for v, lbl in (("accept", "Nombrado, $t+1$"), ("retain2", "Nombrado, $t+2$")):
        f.write(f"{lbl}")
        ses = []
        for y in ["2015", "2017", "2018", "2019"]:
            r = next(x for x in out if x["outcome"] == v and x["sample"] == y)
            f.write(f" & {fnum(r['rf_b'])}{stars(r['rf_pv'])}")
            ses.append(fnum(r["rf_se"]))
        f.write(" \\\\\n")
        f.write(" & (" + ") & (".join(ses) + ") \\\\\n")
    # long horizons
    f.write("\\midrule\n")
    for v, lbl in (("retain4", "Nombrado, $t+4$"), ("nombrado5", "Nombrado, $t+5$"),
                   ("nombrado6", "Nombrado, $t+6$")):
        f.write(f"{lbl}")
        ses = []
        for y in ["2015", "2017", "2018", "2019"]:
            r = next((x for x in out if x["outcome"] == v and x["sample"] == y), None)
            if r is None:
                f.write(" & --")
                ses.append("--")
            else:
                f.write(f" & {fnum(r['rf_b'])}{stars(r['rf_pv'])}")
                ses.append("(" + fnum(r["rf_se"]) + ")")
        f.write(" \\\\\n")
        f.write(" & " + " & ".join(ses) + " \\\\\n")
    f.write("\\bottomrule\n\\end{tabular}\n")

# ------------------------------------------------------------------- validity
BALLBL = {
    "bal_female": "Female",
    "bal_age_concurso": "Age at concurso",
    "bal_rural_assign": "Assigned school rural",
    "bal_contratado_b": "Contract teacher, concurso year",
    "bal_inpayroll_ba": "In payroll, concurso year",
}
with open(os.path.join(DOC, "tab_validity.tex"), "w") as f:
    f.write("\\begin{tabular}{lcc}\n\\toprule\n")
    f.write(" & Statistic / RD estimate & $p$-value \\\\\n\\midrule\n")
    f.write("\\multicolumn{3}{l}{\\emph{Density tests (rddensity)}} \\\\\n")
    for r in val:
        if r["test"] == "density":
            f.write(f"\\quad Concurso {r['sample']} & {fnum(r['stat'],2)} & {fnum(r['pv'],2)} \\\\\n")
    f.write("\\midrule\n\\multicolumn{3}{l}{\\emph{Covariate balance (rdrobust, donut)}} \\\\\n")
    for r in val:
        if r["test"].startswith("bal_"):
            f.write(f"\\quad {BALLBL.get(r['test'], r['test'])} & {fnum(r['stat'])} & {fnum(r['pv'],2)} \\\\\n")
    f.write("\\bottomrule\n\\end{tabular}\n")

# ----------------------------------------------------------------- robustness
SPECLBL = {
    "baseline donut": "Baseline (donut, MSE-optimal bw)",
    "with ties fuzzy": "Including ties, fuzzy RD",
    "half bw": "Half bandwidth",
    "double bw": "Double bandwidth",
    "quadratic": "Local quadratic",
}
vs = ["accept", "retain2", "samesch1"]
with open(os.path.join(DOC, "tab_robust.tex"), "w") as f:
    f.write("\\begin{tabular}{lccc}\n\\toprule\n")
    f.write(" & Nombrado $t+1$ & Nombrado $t+2$ & Same school $t+1$ \\\\\n\\midrule\n")
    for spec in SPECLBL:
        f.write(SPECLBL[spec])
        ses = []
        for v in vs:
            r = next((x for x in rob if x["outcome"] == v and x["spec"] == spec), None)
            if r is None:
                f.write(" & --")
                ses.append("--")
            else:
                f.write(f" & {fnum(r['b'])}{stars(r['pv'])}")
                ses.append("(" + fnum(r["se"]) + ")")
        f.write(" \\\\\n & " + " & ".join(ses) + " \\\\\n")
    f.write("\\bottomrule\n\\end{tabular}\n")

# ---------------------------------------------------------------- heterogeneity
HETGROUPS = [
    ("All", "All winners"),
    ("Rural assigned", "\\quad Rural"),
    ("Urban assigned", "\\quad Urban"),
    ("Rural 1", "\\quad Rural 1 (least remote)"),
    ("Rural 2", "\\quad Rural 2"),
    ("Rural 3", "\\quad Rural 3 (most remote)"),
    ("Bilingual", "\\quad Bilingual school"),
    ("VRAEM", "\\quad VRAEM school"),
    ("Frontera", "\\quad Border school"),
    ("Female", "\\quad Female"),
    ("Male", "\\quad Male"),
    ("Younger", "\\quad Below median age"),
    ("Older", "\\quad Above median age"),
    ("In payroll t0", "\\quad In payroll at $t_0$"),
    ("New entrant t0", "\\quad New entrant at $t_0$"),
    ("Inicial", "\\quad Inicial"),
    ("Primaria", "\\quad Primaria"),
    ("Secundaria", "\\quad Secundaria"),
]
HETPANEL = {
    "Rural assigned": "\\emph{Rurality of assigned school}",
    "Rural 1": "\\emph{Degree of rurality}",
    "Bilingual": "\\emph{Other hardship categories}",
    "Female": "\\emph{Sex}",
    "Younger": "\\emph{Age}",
    "In payroll t0": "\\emph{Baseline employment}",
    "Inicial": "\\emph{Teaching level}",
}
HOUT = ["accept", "retain2", "samesch1", "samesch2", "inrural2"]
with open(os.path.join(DOC, "tab_hetero.tex"), "w") as f:
    f.write("\\begin{tabular}{lccccc}\n\\toprule\n")
    f.write(" & Nombrado & Nombrado & Same school & Same school & Rural school \\\\\n")
    f.write(" & $t+1$ & $t+2$ & $t+1$ & $t+2$ & $t+2$ \\\\\n\\midrule\n")
    for g, lbl in HETGROUPS:
        if g in HETPANEL:
            f.write("\\addlinespace\n" + HETPANEL[g] + " \\\\\n")
        f.write(lbl)
        ses = []
        for v in HOUT:
            r = next((x for x in het if x["outcome"] == v and x["group"] == g), None)
            if r is None:
                f.write(" & --")
                ses.append("--")
            else:
                f.write(f" & {fnum(r['b'])}{stars(r['pv'])}")
                ses.append("(" + fnum(r["se"]) + ")")
        f.write(" \\\\\n & " + " & ".join(ses) + " \\\\\n")
    f.write("\\bottomrule\n\\end{tabular}\n")


def gethet(outcome, group):
    return next(r for r in het if r["outcome"] == outcome and r["group"] == group)


# ------------------------------------------------------------ macros for prose
def getout(outcome, sample="Pooled"):
    return next(r for r in out if r["outcome"] == outcome and r["sample"] == sample)


def texsafe(name):
    return name


macros = {}
macros["FSpooledFive"] = fnum(rows5["Pooled"]["coef"])
macros["FSpooledTen"] = fnum(rows10["Pooled"]["coef"])
a = getout("accept")
macros["AcceptRF"] = pct(a["rf_b"])
macros["AcceptSE"] = pct(a["rf_se"])
macros["AcceptP"] = fnum(a["rf_pv"], 2)
macros["AcceptMean"] = pct(a["mean0"])
r2 = getout("retain2")
macros["RetainTwoRF"] = pct(r2["rf_b"])
macros["RetainTwoP"] = fnum(r2["rf_pv"], 2)
r4 = getout("retain4")
macros["RetainFourRF"] = pct(r4["rf_b"])
macros["RetainFourP"] = fnum(r4["rf_pv"], 2)
d = getout("director_ever")
macros["DirectorRF"] = pct(d["rf_b"])
macros["DirectorP"] = fnum(d["rf_pv"], 2)
macros["DirectorMean"] = pct(d["mean0"])
s1 = getout("samesch1")
macros["SameschRF"] = pct(s1["rf_b"])
macros["SameschSE"] = pct(s1["rf_se"])
macros["SameschMean"] = pct(s1["mean0"])
pr = getout("promoted_2021", "1517")
macros["PromotedRF"] = pct(pr["rf_b"])
macros["PromotedP"] = fnum(pr["rf_pv"], 2)
a15 = getout("accept", "2015")
macros["AcceptFifteenRF"] = pct(a15["rf_b"])
macros["AcceptFifteenP"] = fnum(a15["rf_pv"], 2)
r215 = getout("retain2", "2015")
macros["RetainTwoFifteenRF"] = pct(r215["rf_b"])
macros["RetainTwoFifteenP"] = fnum(r215["rf_pv"], 2)
n6 = getout("nombrado6", "2015")
macros["NombSixFifteenRF"] = pct(n6["rf_b"])
macros["NombSixFifteenP"] = fnum(n6["rf_pv"], 2)
dens = next(r for r in val if r["test"] == "density" and r["sample"] == "Pooled")
macros["DensityPooledP"] = fnum(dens["pv"], 2)

import math
def diffmacro(outcome):
    r = gethet(outcome, "Rural assigned")
    u = gethet(outcome, "Urban assigned")
    d = float(r["b"]) - float(u["b"])
    se = math.sqrt(float(r["se"])**2 + float(u["se"])**2)
    return d, se

d1, dse1 = diffmacro("samesch1")
macros_extra = {}
macros_extra["RuralUrbanDiff"] = f"{100*d1:.1f}"
macros_extra["RuralUrbanDiffSE"] = f"{100*dse1:.1f}"
macros_extra["RuralUrbanDiffT"] = f"{d1/dse1:.1f}"
ir = gethet("inrural2", "Rural assigned")
macros_extra["InruralRuralRF"] = pct(ir["b"])
macros_extra["InruralRuralP"] = fnum(ir["pv"], 2)
macros_extra["InruralRuralMean"] = pct(ir["mean0"])
ur = gethet("retain2", "Urban assigned")
macros_extra["UrbanRetainRF"] = pct(ur["b"])
macros_extra["UrbanRetainP"] = fnum(ur["pv"], 2)
rr = gethet("retain2", "Rural assigned")
macros_extra["RuralRetainTwoRF"] = pct(rr["b"])
r1 = gethet("samesch1", "Rural 1")
macros_extra["RuralOneSameschRF"] = pct(r1["b"])
macros_extra["RuralOneSameschP"] = fnum(r1["pv"], 2)

rs1 = gethet("samesch1", "Rural assigned")
macros["RuralSameschRF"] = pct(rs1["b"])
macros["RuralSameschSE"] = pct(rs1["se"])
macros["RuralSameschP"] = fnum(rs1["pv"], 2)
rs2 = gethet("samesch2", "Rural assigned")
macros["RuralSameschTwoRF"] = pct(rs2["b"])
macros["RuralSameschTwoP"] = fnum(rs2["pv"], 2)
us1 = gethet("samesch1", "Urban assigned")
macros["UrbanSameschRF"] = pct(us1["b"])
rr2 = gethet("retain2", "Rural assigned")
macros["RuralRetainRF"] = pct(rr2["b"])
macros["RuralRetainP"] = fnum(rr2["pv"], 2)
pa = gethet("accept", "Primaria")
macros["PrimAcceptRF"] = pct(pa["b"])
macros["PrimAcceptP"] = fnum(pa["pv"], 2)
pr2 = gethet("retain2", "Primaria")
macros["PrimRetainRF"] = pct(pr2["b"])
macros["PrimRetainP"] = fnum(pr2["pv"], 2)
fr2 = gethet("retain2", "Female")
macros["FemRetainRF"] = pct(fr2["b"])
macros["FemRetainP"] = fnum(fr2["pv"], 2)
macros.update(macros_extra)

with open(os.path.join(DOC, "nums.tex"), "w") as f:
    for k, v in macros.items():
        f.write(f"\\newcommand{{\\{k}}}{{{v}}}\n")

print("Wrote", len(macros), "macros and 5 tables to", DOC)
