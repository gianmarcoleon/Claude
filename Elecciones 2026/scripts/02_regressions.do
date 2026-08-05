* ============================================================
* Project: Elecciones 2026 - late/next-day mesa opening effects
* Author:  Gianmarco + Claude
* Input:   outputs/mesas_analysis.csv (from 01_build_dataset.py)
* Output:  outputs/results.csv (one row per spec x outcome)
*          outputs/mesas_analysis.dta
* ============================================================
version 19
clear all
set more off

global root   "/Users/u90397/Dropbox/research projects/Claude/Elecciones 2026"
global out    "$root/outputs"

import delimited "$out/mesas_analysis.csv", clear encoding(utf-8) case(preserve)

* --- variables ---
egen locnum  = group(locid)
egen distnum = group(ubigeo1 ubigeo2 ubigeo3)
gen limasur3 = inlist(ubigeo3, "SAN JUAN DE MIRAFLORES", "LURÍN", "PACHACÁMAC") & limametro == 1

* within-mesa round differences (diff-in-diff across rounds)
gen dturnout   = turnout2   - turnout1
gen dblanknull = blanknull2 - blanknull1
gen dsh8       = sh82  - sh81
gen dsh10      = sh102 - sh101

label var turnout1   "Turnout R1 (%)"
label var blanknull1 "Blank+null R1 (% emitted)"
save "$out/mesas_analysis.dta", replace

* --- results collector ---
tempname H
postfile `H' str12 spec str12 treat str12 outcome double(b se p N cmean) using "$out/results_post.dta", replace

local outcomes electores1 emitidos1 turnout1 blanknull1 sh81 sh101 sh351 sh161 sh141 ///
               turnout2 blanknull2 sh82 sh102 dturnout dblanknull dsh8 dsh10

* spec definitions:  name | treatvar | sample condition | FE (0/1)
* LATE proxy specs exclude next-day mesas; NEXTDAY specs exclude late-proxy mesas
capture program drop runspec
program define runspec
    args H spec treat cond fe
    foreach y of global YLIST {
        quietly summarize `y' if `treat' == 0 & (`cond'), meanonly
        local cm = r(mean)
        if (`fe' == 0) {
            capture quietly reg `y' `treat' if (`cond'), vce(cluster locnum)
        }
        else {
            capture quietly reghdfe `y' `treat' if (`cond'), absorb(distnum) vce(cluster locnum)
        }
        if (_rc == 0) {
            local b  = _b[`treat']
            local se = _se[`treat']
            local p  = 2 * ttail(e(df_r), abs(`b'/`se'))
            post `H' ("`spec'") ("`treat'") ("`y'") (`b') (`se') (`p') (e(N)) (`cm')
        }
    }
end

global YLIST `outcomes'

* ---- LATE (proxy) ----
runspec `H' L1_nat   late6 "domestic == 1 & nextday == 0" 0
runspec `H' L2_lima  late6 "limametro == 1 & nextday == 0" 0
runspec `H' L3_limaFE late6 "limametro == 1 & nextday == 0" 1

* ---- LATE robustness: stricter 12h proxy ----
runspec `H' R2_lima  late12 "limametro == 1 & nextday == 0" 0
runspec `H' R3_limaFE late12 "limametro == 1 & nextday == 0" 1

* ---- NEXT DAY ----
runspec `H' N1_nat    nextday "domestic == 1 & late6 == 0" 0
runspec `H' N2_lima   nextday "limametro == 1 & late6 == 0" 0
runspec `H' N3_limaFE nextday "limametro == 1 & late6 == 0" 1
runspec `H' N4_sur3   nextday "limasur3 == 1 & late6 == 0" 0

postclose `H'

use "$out/results_post.dta", clear
export delimited "$out/results.csv", replace
display "DONE - results exported"
