#!/usr/bin/env python3
"""04_make_tables.py — LaTeX tables + headline numbers for the report."""
import pandas as pd
import numpy as np

OUT = "/Users/u90397/Dropbox/research projects/Claude/Elecciones 2026/outputs"
res = pd.read_csv(f"{OUT}/results.csv")
ri = pd.read_csv(f"{OUT}/ri_pvalues.csv").set_index("outcome")
df = pd.read_csv(f"{OUT}/mesas_analysis.csv", low_memory=False)

LBL = {
    "electores1": r"Registered voters (mesa size)",
    "emitidos1": r"Votes cast, R1",
    "turnout1": r"Turnout R1 (\%)",
    "blanknull1": r"Blank + null R1 (\% of cast)",
    "sh81": r"Fujimori -- FP (\% valid)",
    "sh101": r"S\'anchez -- JP (\% valid)",
    "sh351": r"L\'opez Aliaga -- RP (\% valid)",
    "sh161": r"Nieto -- PBG (\% valid)",
    "sh141": r"Belmont -- Obras (\% valid)",
    "turnout2": r"Turnout R2 (\%)",
    "blanknull2": r"Blank + null R2 (\% of cast)",
    "sh82": r"Fujimori -- FP, R2 (\% valid)",
    "sh102": r"S\'anchez -- JP, R2 (\% valid)",
    "dturnout": r"$\Delta$ Turnout (R2$-$R1)",
    "dblanknull": r"$\Delta$ Blank + null (R2$-$R1)",
    "dsh8": r"$\Delta$ Fujimori share (R2$-$R1)",
    "dsh10": r"$\Delta$ S\'anchez share (R2$-$R1)",
}
PANELS = [
    ("Panel A: First round", ["electores1", "turnout1", "blanknull1",
                              "sh81", "sh101", "sh351", "sh161", "sh141"]),
    ("Panel B: Second round", ["turnout2", "blanknull2", "sh82", "sh102"]),
    ("Panel C: Within-mesa change", ["dturnout", "dblanknull", "dsh8", "dsh10"]),
]

def stars(p):
    return "***" if p < .01 else "**" if p < .05 else "*" if p < .1 else ""

def cell(r):
    if r is None:
        return "", ""
    return (f"{r.b:.2f}{stars(r.p)}", f"({r.se:.2f})")

def get(spec, y):
    m = res[(res.spec == spec) & (res.outcome == y)]
    return None if m.empty else m.iloc[0]

def build_table(specs, colheads, fname, cmean_spec, ri_col=False):
    ncol = len(specs) + 2 + (1 if ri_col else 0)
    lines = [r"\begin{tabular}{l" + "c" * (ncol - 1) + "}", r"\toprule"]
    heads = ["", r"\shortstack{Control\\mean}"] + colheads + \
            ([r"\shortstack{RI\\$p$-value}"] if ri_col else [])
    lines.append(" & ".join(heads) + r" \\")
    lines.append(" & ".join([""] + [f"({i})" for i in range(1, ncol)]) + r" \\")
    lines.append(r"\midrule")
    for pname, ys in PANELS:
        lines.append(rf"\multicolumn{{{ncol}}}{{l}}{{\emph{{{pname}}}}} \\")
        for y in ys:
            cm = get(cmean_spec, y)
            cmtxt = f"{cm.cmean:.1f}" if cm is not None else ""
            row1, row2 = [LBL[y], cmtxt], ["", ""]
            for s in specs:
                b, se = cell(get(s, y))
                row1.append(b); row2.append(se)
            if ri_col:
                row1.append(f"{ri.loc[y, 'ri_p']:.3f}" if y in ri.index else "")
                row2.append("")
            lines.append(" & ".join(row1) + r" \\")
            lines.append(" & ".join(row2) + r" \\[1pt]")
        lines.append(r"\addlinespace")
    lines.append(r"\midrule")
    ns = ["Observations", ""] + [f"{int(get(s,'turnout1').N):,}" for s in specs] + ([""] if ri_col else [])
    lines.append(" & ".join(ns) + r" \\")
    lines += [r"\bottomrule", r"\end{tabular}"]
    with open(f"{OUT}/{fname}", "w") as f:
        f.write("\n".join(lines))
    print("wrote", fname)

build_table(["L1_nat", "L2_lima", "L3_limaFE", "R2_lima", "R3_limaFE"],
            [r"\shortstack{National\\(6h proxy)}", r"\shortstack{Lima Metro\\(6h proxy)}",
             r"\shortstack{Lima Metro\\+ distr.\ FE\\(6h proxy)}",
             r"\shortstack{Lima Metro\\(12h proxy)}",
             r"\shortstack{Lima Metro\\+ distr.\ FE\\(12h proxy)}"],
            "tab_late.tex", "L2_lima")

build_table(["N1_nat", "N2_lima", "N3_limaFE", "N4_sur3"],
            [r"National", r"Lima Metro", r"\shortstack{Lima Metro\\+ distr.\ FE}",
             r"\shortstack{3 affected\\districts}"],
            "tab_nextday.tex", "N4_sur3", ri_col=True)

# ---- descriptives table ----
dom = df[df.domestic == 1]
rows = []
for name, m in [("Next-day mesas (13 locales, JNE list)", dom.nextday == 1),
                ("Late-locale proxy, 6h (excl.\\ next-day)", dom.late6 == 1),
                ("Late-locale proxy, 12h (excl.\\ next-day)", dom.late12 == 1),
                ("Rest of Lima Metro", (dom.limametro == 1) & (dom.nextday == 0) & (dom.late6 == 0)),
                ("Rest of Peru (domestic)", dom.limametro == 0)]:
    s = dom[m]
    rows.append([name, f"{len(s):,}", f"{s.locid.nunique():,}",
                 f"{int(s.electores1.sum()):,}", f"{s.turnout1.mean():.1f}",
                 f"{s.turnout2.mean():.1f}"])
hdr = [r"\begin{tabular}{lrrrrr}", r"\toprule",
       r"Group & Mesas & Locales & Registered & \shortstack{Turnout\\R1 (\%)} & \shortstack{Turnout\\R2 (\%)} \\",
       r"\midrule"]
body = [" & ".join(r) + r" \\" for r in rows]
with open(f"{OUT}/tab_desc.tex", "w") as f:
    f.write("\n".join(hdr + body + [r"\bottomrule", r"\end{tabular}"]))
print("wrote tab_desc.tex")

# ---- back-of-envelope: votes displaced ----
print("\n--- Back-of-envelope: national JP-RP gap and implied vote shifts ---")
gap = 2015114 - 1993904
print(f"national JP-RP gap: {gap:,}")
for treat, base in [("nextday", "N4_sur3"), ("late6", "L3_limaFE")]:
    t = dom[dom[treat] == 1]
    V = t.validos1.sum()
    E = t.emitidos1.sum()
    reg = t.electores1.sum()
    b_rp = get(base, "sh351").b / 100
    b_jp = get(base, "sh101").b / 100
    b_to = get(base, "turnout1").b / 100
    print(f"{treat}: mesas={len(t):,} valid={V:,} cast={E:,} reg={reg:,} | "
          f"implied dRP={b_rp*V:,.0f} dJP={b_jp*V:,.0f} d(JP-RP)={(b_jp-b_rp)*V:,.0f} | "
          f"missing votes (turnout eff x reg)={-b_to*reg:,.0f}")
