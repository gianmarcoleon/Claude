#!/usr/bin/env python3
"""
01_build_dataset.py — Build mesa-level analysis dataset, Peru 2026 general elections.

Inputs : ONPE mesa-level JSONL extracts (primera/segunda vuelta), pre-parsed to CSV
         by extract.py (kept in scratchpad; re-run against the raw JSONL in
         'Bases de datos/Elecciones y outcomes distritales/Eleccciones 2026' if needed).
Output : outputs/mesas_analysis.csv  (one row per mesa, both rounds merged)

Treatment definitions:
  nextday : mesa in one of the 13 locales JNE authorized to vote on Mon Apr 13
            (3 SJM, 7 Lurin, 3 Pachacamac; 187 mesas, 55,261 electores —
            matches official figures).
  late6   : PROXY for late opening. Locale (local de votacion) in Lima Metro
            whose median first acta event (digitization/transmission) occurred
            >= 6h after the normal 5pm close (i.e., >= 11pm on Apr 12),
            excluding the 13 next-day locales. 2,949 mesas — close to the
            2,750 mesas Stanford DAL measured opening after 10am from the
            actual installation actas.
  late12  : stricter proxy, threshold 12h (>= 5am Apr 13). Robustness.
"""
import json
import pandas as pd
import numpy as np

SCRATCH = ("/private/tmp/claude-502/-Users-u90397-Dropbox-research-projects-"
           "Teachers-Peru-Data-bono-atraccion/3bfcc9ae-0344-4734-90d6-f5b023c17b09/scratchpad")
OUT = "/Users/u90397/Dropbox/research projects/Claude/Elecciones 2026/outputs"

r1 = pd.read_csv(f"{SCRATCH}/primera_vuelta_mesa.csv", low_memory=False)
r2 = pd.read_csv(f"{SCRATCH}/segunda_vuelta_mesa.csv", low_memory=False)

# --- timing (round 1) -------------------------------------------------------
tscols = ['ts_T', 'ts_D', 'ts_C', 'ts_H', 'arch_1', 'arch_2', 'arch_3', 'arch_4']
for c in tscols:
    r1[c + '_dt'] = pd.to_datetime(r1[c], unit='ms', utc=True).dt.tz_convert('America/Lima')
r1['first_event'] = r1[[c + '_dt' for c in tscols]].min(axis=1)
ref = pd.Timestamp('2026-04-12 17:00', tz='America/Lima')
r1['hrs_r1'] = (r1['first_event'] - ref).dt.total_seconds() / 3600

# --- geography --------------------------------------------------------------
overseas = ['AMÉRICA', 'EUROPA', 'ÁFRICA', 'ASIA', 'OCEANÍA']
r1['domestic'] = (~r1.ubigeo1.isin(overseas)).astype(int)
r1['limametro'] = (((r1.ubigeo1 == 'LIMA') & (r1.ubigeo2 == 'LIMA')) |
                   (r1.ubigeo1 == 'CALLAO')).astype(int)
r1['locid'] = (r1.ubigeo1 + '|' + r1.ubigeo2 + '|' + r1.ubigeo3 + '|' +
               r1.local.fillna(''))

# --- treatment: next-day (official JNE list, El Peruano 13-Apr-2026) --------
ND = {
    'SAN JUAN DE MIRAFLORES': ['IE PARROQUIAL VIRGEN DE LA ASUNCION',
                               'IE 6041 ALFONSO UGARTE', 'IE 6151 SAN LUIS GONZAGA'],
    'LURÍN': ['IE 7078 VIRGEN DE CHAPI', 'IE 7098 RODRIGO LARA BONILLA',
              'IE 7104 RAMIRO PRIALE PRIALE', 'IE 6023 JULIO C. TELLO ROJAS',
              'IE 7239 SANTISIMO SALVADOR', 'IE 7267 SEÑOR DE LOS MILAGROS',
              'IE 6026 VIRGEN DE FATIMA'],
    'PACHACÁMAC': ['IE 7261 SANTA ROSA DE COLLANAC', 'IEP EL UNIVERSO DE CESAR VALLEJO',
                   'IE PARROQUIAL VIRGEN DEL ROSARIO'],
}
r1['nextday'] = 0
for d, locs in ND.items():
    r1.loc[(r1.limametro == 1) & (r1.ubigeo3 == d) & (r1.local.isin(locs)), 'nextday'] = 1
assert r1.nextday.sum() == 187, r1.nextday.sum()

# --- treatment: late-opening proxy ------------------------------------------
med = r1.groupby('locid')['hrs_r1'].median().rename('loc_med_hrs')
r1 = r1.merge(med, on='locid', how='left')
r1['late6'] = ((r1.limametro == 1) & (r1.nextday == 0) & (r1.loc_med_hrs >= 6)).astype(int)
r1['late12'] = ((r1.limametro == 1) & (r1.nextday == 0) & (r1.loc_med_hrs >= 12)).astype(int)
r1['vessjm'] = ((r1.limametro == 1) &
                r1.ubigeo3.isin(['VILLA EL SALVADOR', 'SAN JUAN DE MIRAFLORES'])).astype(int)

# --- outcomes, round 1 ------------------------------------------------------
def shares(df, codes, suffix):
    df = df.copy()
    df[f'turnout{suffix}'] = 100 * df.emitidos / df.electores
    df[f'blanknull{suffix}'] = np.where(df.emitidos > 0,
                                        100 * (df.v_80.fillna(0) + df.v_81.fillna(0)) / df.emitidos,
                                        np.nan)
    for c in codes:
        df[f'sh{c}{suffix}'] = np.where(df.validos > 0,
                                        100 * df[f'v_{c}'].fillna(0) / df.validos, np.nan)
    return df

r1 = shares(r1, [8, 10, 35, 16, 14], '1')   # FP, JP, RP, PBG, Obras
r2 = shares(r2, [8, 10], '2')               # FP, JP

keep1 = ['codigo_mesa', 'ubigeo1', 'ubigeo2', 'ubigeo3', 'local', 'locid',
         'domestic', 'limametro', 'nextday', 'late6', 'late12', 'vessjm',
         'hrs_r1', 'loc_med_hrs', 'electores', 'emitidos', 'validos',
         'turnout1', 'blanknull1', 'sh81', 'sh101', 'sh351', 'sh161', 'sh141']
keep2 = ['codigo_mesa', 'electores', 'emitidos', 'validos',
         'turnout2', 'blanknull2', 'sh82', 'sh102']
df = (r1[keep1]
      .rename(columns={'electores': 'electores1', 'emitidos': 'emitidos1',
                       'validos': 'validos1'})
      .merge(r2[keep2].rename(columns={'electores': 'electores2',
                                       'emitidos': 'emitidos2', 'validos': 'validos2'}),
             on='codigo_mesa', how='outer', indicator=True))
print(df._merge.value_counts())
df = df.drop(columns='_merge')
df.to_csv(f"{OUT}/mesas_analysis.csv", index=False)
print(f"wrote {len(df)} mesas | nextday={df.nextday.sum()} late6={df.late6.sum()} "
      f"late12={df.late12.sum()} | domestic={df.domestic.sum()}")
print("late6 locales by district:")
print(df[df.late6 == 1].groupby('ubigeo3').locid.nunique().sort_values(ascending=False).head(12))
