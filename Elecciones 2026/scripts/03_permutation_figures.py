#!/usr/bin/env python3
"""
03_permutation_figures.py — Randomization inference for the next-day treatment
and figures for the report.

RI design: within the three affected districts (SJM, Lurin, Pachacamac),
treatment was assigned at the locale level (13 treated locales). We permute
the treated-locale labels stratified by district (3 SJM / 7 Lurin / 3 Pach),
recompute the mesa-level mean difference, and report two-sided p-values.
"""
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT = "/Users/u90397/Dropbox/research projects/Claude/Elecciones 2026/outputs"
rng = np.random.default_rng(20260412)

df = pd.read_csv(f"{OUT}/mesas_analysis.csv", low_memory=False)
df["dturnout"] = df.turnout2 - df.turnout1

# ---------------- permutation test ----------------
sur3 = df[(df.limametro == 1) & (df.late6 == 0) &
          df.ubigeo3.isin(["SAN JUAN DE MIRAFLORES", "LURÍN", "PACHACÁMAC"])].copy()
outcomes = ["turnout1", "blanknull1", "sh161", "sh81", "sh101", "sh351", "sh141", "dturnout"]
locs = sur3.groupby(["ubigeo3", "locid"]).nextday.max().reset_index()
n_treat = locs.groupby("ubigeo3").nextday.sum().to_dict()
print("locales per district (treated):",
      locs.groupby("ubigeo3").agg(n=("locid", "count"), t=("nextday", "sum")).to_dict("index"))

obs = {y: sur3[sur3.nextday == 1][y].mean() - sur3[sur3.nextday == 0][y].mean()
       for y in outcomes}
B = 5000
perm = {y: np.empty(B) for y in outcomes}
for b in range(B):
    treated_ids = []
    for d, g in locs.groupby("ubigeo3"):
        treated_ids += list(rng.choice(g.locid.values, size=int(n_treat[d]), replace=False))
    t = sur3.locid.isin(treated_ids)
    for y in outcomes:
        perm[y][b] = sur3.loc[t, y].mean() - sur3.loc[~t, y].mean()
ri = pd.DataFrame({
    "outcome": outcomes,
    "obs_diff": [obs[y] for y in outcomes],
    "ri_p": [np.mean(np.abs(perm[y]) >= abs(obs[y])) for y in outcomes],
})
ri.to_csv(f"{OUT}/ri_pvalues.csv", index=False)
print(ri.round(3).to_string(index=False))

# ---------------- figure style ----------------
C_CTRL, C_TREAT, C_LATE = "#8a8f98", "#c2452d", "#3b6fb6"
plt.rcParams.update({"font.size": 9, "font.family": "sans-serif",
                     "axes.spines.top": False, "axes.spines.right": False,
                     "axes.grid": True, "grid.alpha": .25, "grid.linewidth": .5,
                     "figure.dpi": 200})

# --- Fig 1: locale-level timing distribution, Lima Metro ---
lm = df[df.limametro == 1]
loc = lm.groupby("locid").agg(hrs=("loc_med_hrs", "first"), nextday=("nextday", "max"),
                              d=("ubigeo3", "first")).reset_index()
sur = loc.d.isin(["VILLA EL SALVADOR", "SAN JUAN DE MIRAFLORES", "LURÍN", "PACHACÁMAC"])
fig, ax = plt.subplots(figsize=(6.2, 3.2))
bins = np.arange(0, 84, 2)
ax.hist(loc[~sur].hrs.clip(upper=82), bins=bins, color=C_CTRL, alpha=.85,
        label="Rest of Lima Metro (locales)")
ax.hist(loc[sur & (loc.nextday == 0)].hrs.clip(upper=82), bins=bins, color=C_LATE, alpha=.85,
        label="VES / SJM / Lurín / Pachacámac")
ax.hist(loc[loc.nextday == 1].hrs.clip(upper=82), bins=bins, color=C_TREAT,
        label="13 next-day locales (JNE list)")
ax.axvline(6, color="k", lw=.8, ls="--")
ax.text(6.5, ax.get_ylim()[1]*.75, "late proxy\nthreshold (6h)", fontsize=7.5)
ax.set_yscale("log")
ax.set_xlabel("Hours from normal close (5pm Apr 12) to first acta event, locale median")
ax.set_ylabel("Locales (log scale)")
ax.legend(frameon=False, fontsize=8)
fig.tight_layout()
fig.savefig(f"{OUT}/fig1_timing.pdf")

# --- Fig 2: turnout in R1 and R2, next-day vs same-district controls ---
grp = sur3.groupby("nextday")[["turnout1", "turnout2"]].agg(["mean", "sem"])
fig, ax = plt.subplots(figsize=(4.4, 3.0))
x = np.array([0, 1])
for t, c, lab in [(0, C_CTRL, "Control mesas, same 3 districts"),
                  (1, C_TREAT, "Next-day mesas (13 locales)")]:
    m = [grp.loc[t, ("turnout1", "mean")], grp.loc[t, ("turnout2", "mean")]]
    s = [grp.loc[t, ("turnout1", "sem")], grp.loc[t, ("turnout2", "sem")]]
    ax.errorbar(x, m, yerr=[1.96*e for e in s], color=c, marker="o", ms=5,
                capsize=3, lw=1.6, label=lab)
    ax.annotate(f"{m[0]:.1f}", (0, m[0]), textcoords="offset points",
                xytext=(-28, -3), color=c, fontsize=8)
    ax.annotate(f"{m[1]:.1f}", (1, m[1]), textcoords="offset points",
                xytext=(8, -3), color=c, fontsize=8)
ax.set_xticks(x, ["First round\n(Apr 12–13)", "Second round\n(Jun 7)"])
ax.set_xlim(-0.45, 1.45)
ax.set_ylabel("Turnout (% of registered voters)")
ax.legend(frameon=False, fontsize=8, loc="lower right")
fig.tight_layout()
fig.savefig(f"{OUT}/fig2_turnout.pdf")

# --- Fig 3: R1 vote shares, next-day vs same-district controls ---
labels = {"sh81": "Fujimori (FP)", "sh101": "Sánchez (JP)", "sh351": "López Aliaga (RP)",
          "sh161": "Nieto (PBG)", "sh141": "Belmont (Obras)", "blanknull1": "Blank + null*"}
means = sur3.groupby("nextday")[list(labels)].mean()
sems = sur3.groupby("nextday")[list(labels)].sem()
order = list(labels)
fig, ax = plt.subplots(figsize=(5.6, 3.2))
yy = np.arange(len(order))[::-1]
for t, c, lab, off in [(0, C_CTRL, "Control mesas, same 3 districts", -0.12),
                       (1, C_TREAT, "Next-day mesas (13 locales)", 0.12)]:
    ax.errorbar(means.loc[t, order], yy + off, xerr=1.96*sems.loc[t, order],
                fmt="o", ms=5, color=c, capsize=2.5, lw=1.2, label=lab)
for y, o in zip(yy, order):
    d = means.loc[1, o] - means.loc[0, o]
    ax.annotate(f"{d:+.1f}pp", (max(means.loc[0, o], means.loc[1, o]) + 2.4, y),
                fontsize=7.5, va="center",
                color=C_TREAT if abs(d) > 2 else "#555")
ax.set_yticks(yy, [labels[o] for o in order])
ax.set_xlim(0, means.values.max() + 9)
ax.set_xlabel("First-round share (% of valid votes; *blank+null: % of votes cast)")
ax.legend(frameon=False, fontsize=8, loc="lower right")
fig.tight_layout()
fig.savefig(f"{OUT}/fig3_shares.pdf")
print("figures written")
