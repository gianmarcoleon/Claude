*==============================================================================*
* BONO DE ATRACCION - RD ANALYSIS
* 05_heterogeneity.do
* Subgroup RD estimates (donut sample): rurality of the assigned school,
* sex, age, baseline payroll status, teaching level. Outcomes: acceptance,
* retention (t+2), same-school retention (t+1, t+2).
*==============================================================================*
version 19
clear all
set more off
graph set window fontface "Helvetica"

global proj    "/Users/u90397/Dropbox/research projects/Claude/Principals/Bono de atraccion"
global data    "$proj/data"
global figs    "$proj/output/figures"
global tabs    "$proj/output/tables"
global logs    "$proj/logs"

capture log close
log using "$logs/05_heterogeneity.log", replace text

use "$data/rd_analysis.dta", clear
gen byte tie0 = (running==0)

*--------------------------------------------------------------- subgroup vars
* Rurality and hardship attributes of the assigned plaza: from the concurso
* plaza database (06_school_attrs.do), available for ALL cohorts.
tab concurso, sum(rural_full)

* Sex, age
sum age_concurso, detail
local agemed = r(p50)
gen byte older = age_concurso>=`agemed' if age_concurso<.

* Baseline payroll status (year of the concurso)
gen byte inpayroll_base = max(nombrado0, contratado0, designado0)
replace inpayroll_base = 0 if inpayroll_base==.

* Teaching level from grupo de inscripcion
gen byte lev_inicial    = strpos(grupo,"INICIAL")>0
gen byte lev_primaria   = strpos(grupo,"PRIMARIA")>0
gen byte lev_secundaria = strpos(grupo,"SECUNDARIA")>0
tab1 lev_*

*----------------------------------------------------------------- estimation
capture postclose hhet
postfile hhet str16 outcome str24 group double(b se pv h n mean0) ///
    using "$data/res_hetero.dta", replace

capture program drop hetrow
program define hetrow
    args var group cond
    quietly {
        count if `var'<. & `cond' & tie0==0
        if r(N)<500 exit
        sum `var' if `cond' & tie0==0 & running>=-5 & running<0
        local m0 = r(mean)
        capture rdrobust `var' running if `cond' & tie0==0, all
        if _rc exit
        local n = e(N_h_l) + e(N_h_r)
    }
    post hhet ("`var'") ("`group'") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb)) ///
        (e(h_l)) (`n') (`m0')
end

foreach v in accept retain2 samesch1 samesch2 inrural2 {
    hetrow `v' "All"            "1==1"
    hetrow `v' "Rural assigned" "rural_full==1"
    hetrow `v' "Urban assigned" "rural_full==0"
    hetrow `v' "Rural 1"        "rural_deg==1"
    hetrow `v' "Rural 2"        "rural_deg==2"
    hetrow `v' "Rural 3"        "rural_deg==3"
    hetrow `v' "Bilingual"      "bilingue_d==1"
    hetrow `v' "VRAEM"          "vraem_d==1"
    hetrow `v' "Frontera"       "frontera_d==1"
    hetrow `v' "Female"         "female==1"
    hetrow `v' "Male"           "female==0"
    hetrow `v' "Younger"        "older==0"
    hetrow `v' "Older"          "older==1"
    hetrow `v' "In payroll t0"  "inpayroll_base==1"
    hetrow `v' "New entrant t0" "inpayroll_base==0"
    hetrow `v' "Inicial"        "lev_inicial==1"
    hetrow `v' "Primaria"       "lev_primaria==1"
    hetrow `v' "Secundaria"     "lev_secundaria==1"
}
postclose hhet

use "$data/res_hetero.dta", clear
export delimited "$tabs/res_hetero.csv", replace

*-------------------------------------------------------------------- figures
use "$data/rd_analysis.dta", clear
gen byte tie0 = (running==0)

capture program drop rfplot2
program define rfplot2
    args var cond fname title ymin ymax ystep
    preserve
    keep if `var'<. & `cond' & abs(running)<=25 & tie0==0
    gen bin = floor(running/2)*2 + 1
    collapse (mean) m=`var' (count) n=`var', by(bin)
    twoway (scatter m bin if bin<0,  mcolor(navy)   msize(small)) ///
           (scatter m bin if bin>=0, mcolor(maroon) msize(small)) ///
           (lfit m bin if bin<0  [aw=n], lcolor(navy)) ///
           (lfit m bin if bin>=0 [aw=n], lcolor(maroon)), ///
        xline(0, lcolor(gs8) lpattern(dash)) ///
        ytitle("") title("`title'", size(medsmall)) ///
        xtitle("Score (centered at cutoff)") ///
        ylabel(`ymin'(`ystep')`ymax', format(%4.2f)) ///
        legend(off) graphregion(color(white)) bgcolor(white) ///
        name(`fname', replace) nodraw
    restore
end

* Same-school retention (t+2) by rurality of the assigned school (all cohorts)
rfplot2 samesch2 "rural_full==1" gr1 "Rural assigned school" 0.85 1 0.05
rfplot2 samesch2 "rural_full==0" gr2 "Urban assigned school" 0.85 1 0.05
graph combine gr1 gr2, cols(2) ycommon graphregion(color(white)) ///
    title("Nombrado in assigned school, t+2", size(medium))
graph export "$figs/fig_het_samesch_rural.pdf", replace

* Retention (t+2) by rurality
rfplot2 retain2 "rural_full==1" gr3 "Rural assigned school" 0.95 1 0.01
rfplot2 retain2 "rural_full==0" gr4 "Urban assigned school" 0.95 1 0.01
graph combine gr3 gr4, cols(2) ycommon graphregion(color(white)) ///
    title("Nombrado in public payroll, t+2", size(medium))
graph export "$figs/fig_het_retain_rural.pdf", replace

* Among rural appointees: still in assigned school vs in ANY rural school (t+2)
rfplot2 samesch2 "rural_full==1" gr5 "Nombrado in assigned school" 0.85 1 0.05
rfplot2 inrural2 "rural_full==1" gr6 "Nombrado in any rural school" 0.85 1 0.05
graph combine gr5 gr6, cols(2) ycommon graphregion(color(white)) ///
    title("Winners assigned to rural schools, t+2", size(medium))
graph export "$figs/fig_het_ruralflows.pdf", replace

log close
