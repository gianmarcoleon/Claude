*==============================================================================*
* BONO DE ATRACCION - RD ANALYSIS
* 03_analysis.do
* First-stage, reduced-form and fuzzy RD estimates and graphs; validity tests.
* Requires rdrobust, rddensity (SSC).
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
log using "$logs/03_analysis.log", replace text

use "$data/rd_analysis.dta", clear

* MAIN SPECIFICATION SAMPLE: donut excluding the exact-cutoff score value.
* The lowest recipient score (running==0) is a mass point where treatment is
* decided by unobserved tie-breaking (mostly treated in 2015, mostly untreated
* in 2018); dropping it makes assignment essentially deterministic:
* P(bono)=~0.995 just above, 0 below. Full-sample (with ties) estimates are
* reported as robustness.
gen byte tie0 = (running==0)
tab concurso bono if tie0==1

* Any-payroll outcomes (nombrado, contratado or designado)
forvalues k=1/6 {
    capture confirm variable nombrado`k'
    if !_rc {
        gen byte anywork`k' = max(nombrado`k', contratado`k', designado`k') ///
            if nombrado`k'<.
    }
}
* Baseline (concurso-year) payroll status: predetermined employment
gen byte contratado_base = contratado0
replace contratado_base = 0 if contratado_base==.
gen byte inpayroll_base = max(nombrado0, contratado0, designado0)
replace inpayroll_base = 0 if inpayroll_base==.

*------------------------------------------------------------------------------*
* 1. FIRST-STAGE GRAPHS: P(bono) vs centered unbonified final score
*------------------------------------------------------------------------------*
capture program drop fsplot
program define fsplot
    args cond fname title
    preserve
    keep if `cond' & abs(running)<=25 & tie0==0
    * half-point bins (the score grid)
    gen bin = floor(running*2)/2
    collapse (mean) bono (count) n=bono, by(bin)
    twoway (scatter bono bin if bin<0,  mcolor(navy)   msize(small)) ///
           (scatter bono bin if bin>=0, mcolor(maroon) msize(small)), ///
        xline(0, lcolor(gs8) lpattern(dash)) ///
        ytitle("Share awarded bono de atracción") ///
        xtitle("Final score (centered at top-third cutoff)") ///
        title("`title'", size(medium)) ylabel(0(.2)1, format(%3.1f)) ///
        legend(off) graphregion(color(white)) bgcolor(white)
    graph export "$figs/`fname'.pdf", replace
    restore
end

foreach y in 2015 2017 2018 2019 {
    fsplot "concurso==`y'" "fig_fs_`y'" "Concurso `y'"
}
fsplot "concurso<." "fig_fs_pooled" "Pooled, concursos 2015-2019"

* First-stage estimates: local linear with fixed bandwidths.
* (rdrobust's data-driven bandwidth fails here because compliance is
*  essentially deterministic: bono==0 for everyone below the cutoff.)
gen byte above = running>=0
gen run_above = running*above
tempname fsres
postfile `fsres' str12 sample double(h coef se nl nr) using "$data/res_firststage.dta", replace
foreach hh in 5 10 {
    foreach y in 2015 2017 2018 2019 {
        quietly reg bono above running run_above if concurso==`y' & abs(running)<=`hh' & tie0==0, robust
        quietly count if concurso==`y' & running>=-`hh' & running<0 & tie0==0
        local nl = r(N)
        quietly count if concurso==`y' & running>=0 & running<=`hh' & tie0==0
        local nr = r(N)
        post `fsres' ("`y'") (`hh') (_b[above]) (_se[above]) (`nl') (`nr')
    }
    quietly reg bono above running run_above if abs(running)<=`hh' & tie0==0, robust
    quietly count if running>=-`hh' & running<0 & tie0==0
    local nl = r(N)
    quietly count if running>=0 & running<=`hh' & tie0==0
    local nr = r(N)
    post `fsres' ("Pooled") (`hh') (_b[above]) (_se[above]) (`nl') (`nr')
}
postclose `fsres'

*------------------------------------------------------------------------------*
* 2. OUTCOME GRAPHS (pooled, reduced form)
*------------------------------------------------------------------------------*
capture program drop rfplot
program define rfplot
    args var fname title ymin ymax ystep
    preserve
    keep if `var'<. & abs(running)<=25 & tie0==0
    gen bin = floor(running/1.5)*1.5 + 0.75   // 1.5-point bins for smoother means
    collapse (mean) m=`var' (count) n=`var', by(bin)
    twoway (scatter m bin if bin<0,  mcolor(navy)   msize(small)) ///
           (scatter m bin if bin>=0, mcolor(maroon) msize(small)) ///
           (lfit m bin if bin<0  [aw=n], lcolor(navy)) ///
           (lfit m bin if bin>=0 [aw=n], lcolor(maroon)), ///
        xline(0, lcolor(gs8) lpattern(dash)) ///
        ytitle("`title'") ///
        xtitle("Final score (centered at top-third cutoff)") ///
        ylabel(`ymin'(`ystep')`ymax', format(%4.2f)) ///
        legend(off) graphregion(color(white)) bgcolor(white)
    graph export "$figs/`fname'.pdf", replace
    restore
end

rfplot accept   "fig_rf_accept"   "Nombrado in payroll, t+1" 0.95 1 0.01
rfplot retain2  "fig_rf_retain2"  "Nombrado in payroll, t+2" 0.95 1 0.01
rfplot retain3  "fig_rf_retain3"  "Nombrado in payroll, t+3" 0.95 1 0.01
rfplot retain4  "fig_rf_retain4"  "Nombrado in payroll, t+4" 0.95 1 0.01
rfplot samesch1 "fig_rf_samesch1" "Nombrado in assigned school, t+1" 0.5 1 0.1
rfplot samesch3 "fig_rf_samesch3" "Nombrado in assigned school, t+3" 0.5 1 0.1
rfplot promoted_2021 "fig_rf_promoted" "Reached escala 2+ by 2021" 0 0.5 0.1
rfplot director_ever "fig_rf_director" "Ever director/directivo (by 2021)" 0 0.3 0.1

*------------------------------------------------------------------------------*
* 3. RD ESTIMATES: reduced form and fuzzy
*------------------------------------------------------------------------------*
capture postclose hres
postfile hres str16 outcome str10 sample double(rf_b rf_se rf_pv fz_b fz_se fz_pv h nl nr mean0) ///
    using "$data/res_outcomes.dta", replace

capture program drop rdrow
program define rdrow
    args var sample cond
    quietly {
        count if `var'<. & `cond'
        if r(N)<200 exit
        * control mean just below cutoff
        sum `var' if `cond' & running>=-5 & running<0
        local m0 = r(mean)
        rdrobust `var' running if `cond', all
        local rb  = e(tau_cl)
        local rse = e(se_tau_cl)
        local rpv = e(pv_rb)
        local h   = e(h_l)
        local nl  = e(N_h_l)
        local nr  = e(N_h_r)
        capture rdrobust `var' running if `cond', fuzzy(bono) all
        if !_rc {
            local fb  = e(tau_cl)
            local fse = e(se_tau_cl)
            local fpv = e(pv_rb)
        }
        else {
            local fb = .
            local fse = .
            local fpv = .
        }
    }
    post hres ("`var'") ("`sample'") (`rb') (`rse') (`rpv') (`fb') (`fse') (`fpv') (`h') (`nl') (`nr') (`m0')
end

foreach v in accept retain2 retain3 retain4 anywork1 anywork2 anywork3 ///
             samesch1 samesch2 samesch3 director_ever {
    rdrow `v' "Pooled" "concurso<. & tie0==0"
}
* promotion only meaningful for cohorts with 4+ years to 2021
rdrow promoted_2021 "1517" "inlist(concurso,2015,2017) & tie0==0"
* per-cohort acceptance and retention
foreach y in 2015 2017 2018 2019 {
    rdrow accept  "`y'" "concurso==`y' & tie0==0"
    rdrow retain2 "`y'" "concurso==`y' & tie0==0"
}
* longer horizons for early cohorts
rdrow nombrado5 "2015" "concurso==2015 & tie0==0"
rdrow nombrado6 "2015" "concurso==2015 & tie0==0"
rdrow retain4   "2015" "concurso==2015 & tie0==0"
rdrow retain4   "2017" "concurso==2017 & tie0==0"
postclose hres

*------------------------------------------------------------------------------*
* 4. VALIDITY: density tests and covariate balance
*------------------------------------------------------------------------------*
tempname val
postfile `val' str16 test str10 sample double(stat pv) using "$data/res_validity.dta", replace
foreach y in 2015 2017 2018 2019 {
    rddensity running if concurso==`y'
    post `val' ("density") ("`y'") (e(T_q)) (e(pv_q))
}
rddensity running
post `val' ("density") ("Pooled") (e(T_q)) (e(pv_q))

* Balance: predetermined covariates
foreach v in female age_concurso rural_assigned contratado_base inpayroll_base {
    quietly rdrobust `v' running if tie0==0, all
    post `val' ("bal_`v'") ("Pooled") (e(tau_cl)) (e(pv_rb))
}
postclose `val'

* Density plot (pooled)
preserve
keep if abs(running)<=30
gen bin = floor(running*2)/2
collapse (count) n=bono, by(bin)
twoway (bar n bin if bin<0,  barwidth(.5) color(navy%60)) ///
       (bar n bin if bin>=0, barwidth(.5) color(maroon%60)), ///
    xline(0, lcolor(gs8) lpattern(dash)) ///
    ytitle("Number of winners") xtitle("Final score (centered at cutoff)") ///
    legend(off) graphregion(color(white)) bgcolor(white)
graph export "$figs/fig_density_pooled.pdf", replace
restore

* Balance plots (2x2)
capture program drop balplot
program define balplot
    args var title stub
    preserve
    keep if `var'<. & abs(running)<=25 & running!=0
    gen bin = floor(running/1.5)*1.5 + 0.75
    collapse (mean) m=`var' (count) n=`var', by(bin)
    twoway (scatter m bin if bin<0,  mcolor(navy) msize(small)) ///
           (scatter m bin if bin>=0, mcolor(maroon) msize(small)) ///
           (lfit m bin if bin<0  [aw=n], lcolor(navy)) ///
           (lfit m bin if bin>=0 [aw=n], lcolor(maroon)), ///
        xline(0, lcolor(gs8) lpattern(dash)) ///
        ytitle("") title("`title'", size(medsmall)) xtitle("") ///
        legend(off) graphregion(color(white)) bgcolor(white) ///
        name(`stub', replace) nodraw
    restore
end
balplot female         "Female"                     g1
balplot age_concurso   "Age at concurso"            g2
balplot rural_assigned "Assigned school rural"      g3
balplot inpayroll_base "In payroll at concurso year" g4
graph combine g1 g2 g3 g4, cols(2) graphregion(color(white))
graph export "$figs/fig_balance.pdf", replace

*------------------------------------------------------------------------------*
* 5. DYNAMICS: RD coefficient by years since concurso (pooled + 2015 cohort)
*------------------------------------------------------------------------------*
tempname dyn
postfile `dyn' str10 sample k double(b se) using "$data/res_dynamics.dta", replace
forvalues k=1/6 {
    capture confirm variable nombrado`k'
    if _rc continue
    quietly count if nombrado`k'<.
    if r(N)>500 {
        quietly rdrobust nombrado`k' running if running!=0, all
        post `dyn' ("Pooled") (`k') (e(tau_cl)) (e(se_tau_cl))
    }
    quietly count if nombrado`k'<. & concurso==2015
    if r(N)>500 {
        quietly rdrobust nombrado`k' running if concurso==2015 & running!=0, all
        post `dyn' ("2015") (`k') (e(tau_cl)) (e(se_tau_cl))
    }
}
* same-school dynamics (pooled)
forvalues k=1/6 {
    capture confirm variable samesch`k'
    if _rc continue
    quietly count if samesch`k'<.
    if r(N)>500 {
        quietly rdrobust samesch`k' running if running!=0, all
        post `dyn' ("SameschP") (`k') (e(tau_cl)) (e(se_tau_cl))
    }
}
postclose `dyn'

use "$data/res_dynamics.dta", clear
gen lo = b - 1.96*se
gen hi = b + 1.96*se
twoway (rcap lo hi k if sample=="Pooled", lcolor(navy)) ///
       (scatter b k if sample=="Pooled", mcolor(navy)), ///
    yline(0, lcolor(gs8)) ///
    ytitle("RD estimate: nombrado in payroll") xtitle("Years since concurso") ///
    xlabel(1/6) legend(off) graphregion(color(white)) bgcolor(white)
graph export "$figs/fig_dynamics_retention.pdf", replace

twoway (rcap lo hi k if sample=="SameschP", lcolor(navy)) ///
       (scatter b k if sample=="SameschP", mcolor(navy)), ///
    yline(0, lcolor(gs8)) ///
    ytitle("RD estimate: nombrado in assigned school") xtitle("Years since concurso") ///
    xlabel(1/6) legend(off) graphregion(color(white)) bgcolor(white)
graph export "$figs/fig_dynamics_samesch.pdf", replace

*------------------------------------------------------------------------------*
* 6. ROBUSTNESS: donut (drop exact-cutoff ties), bandwidth halved/doubled
*------------------------------------------------------------------------------*
use "$data/rd_analysis.dta", clear
tempname rob
postfile `rob' str16 outcome str16 spec double(b se pv) using "$data/res_robust.dta", replace
foreach v in accept retain2 samesch1 {
    quietly rdrobust `v' running if running!=0, all
    post `rob' ("`v'") ("baseline donut") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb))
    local hh = e(h_l)
    quietly rdrobust `v' running, fuzzy(bono) all
    post `rob' ("`v'") ("with ties fuzzy") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb))
    quietly rdrobust `v' running if running!=0, h(`=`hh'/2') all
    post `rob' ("`v'") ("half bw") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb))
    quietly rdrobust `v' running if running!=0, h(`=`hh'*2') all
    post `rob' ("`v'") ("double bw") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb))
    quietly rdrobust `v' running if running!=0, p(2) all
    post `rob' ("`v'") ("quadratic") (e(tau_cl)) (e(se_tau_cl)) (e(pv_rb))
}
postclose `rob'

*------------------------------------------------------------------------------*
* 7. Export results to CSV for the write-up
*------------------------------------------------------------------------------*
foreach f in res_firststage res_outcomes res_validity res_dynamics res_robust {
    use "$data/`f'.dta", clear
    export delimited "$tabs/`f'.csv", replace
}

log close
