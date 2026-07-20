*==============================================================================*
* BONO DE ATRACCION - RD ANALYSIS
* 06_school_attrs.do
* (a) Adds assigned-plaza attributes (ruralidad URBANO/RURAL1-3, bilingue,
*     frontera, VRAEM) for ALL cohorts from plazas_nombramiento.dta --
*     the concurso plaza database used to set allowances (100% coverage,
*     replaces the etapa_desc rurality that was missing for 2015/2019).
* (b) Builds a school-level rurality lookup from the full plaza database and
*     constructs a new outcome: teaching (nombrado) in a RURAL school at t+k.
* Overwrites data/rd_analysis.dta (re-runnable).
*==============================================================================*
version 19
clear all
set more off

global tp      "/Users/u90397/Dropbox/research projects/Teachers Peru/Data"
global conc    "$tp/concursos/clean"
global nexus   "$tp/nexus/clean"
global proj    "/Users/u90397/Dropbox/research projects/Claude/Principals/Bono de atraccion"
global data    "$proj/data"
global logs    "$proj/logs"

capture log close
log using "$logs/06_school_attrs.log", replace text

*------------------------------------------------------------------------------*
* 1. Winner-level plaza attributes from the concurso plaza database
*------------------------------------------------------------------------------*
use documento concurso ganador ruralidad bilingue frontera vraem cod_mod ///
    using "$conc/plazas_nombramiento.dta", clear
keep if ganador==1
decode ruralidad, gen(rur_s)
gen byte rural_full = inlist(rur_s,"RURAL 1","RURAL 2","RURAL 3") if rur_s!=""
gen byte rural_deg  = 0 if rur_s=="URBANO"
replace  rural_deg  = 1 if rur_s=="RURAL 1"
replace  rural_deg  = 2 if rur_s=="RURAL 2"
replace  rural_deg  = 3 if rur_s=="RURAL 3"
decode bilingue, gen(b_s)
decode frontera, gen(f_s)
decode vraem,    gen(v_s)
gen byte bilingue_d = b_s=="SI"
gen byte frontera_d = f_s=="SI"
gen byte vraem_d    = v_s=="SI"
label var rural_full "Assigned school rural (plaza DB, all cohorts)"
label var rural_deg  "Rurality degree of assigned school (0=urban .. 3)"

replace documento = ustrregexra(documento, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
duplicates drop documento concurso, force
keep documento concurso rural_full rural_deg bilingue_d frontera_d vraem_d
tempfile attrs
save `attrs'

*------------------------------------------------------------------------------*
* 2. School-level rurality lookup (mode across all plazas of the school)
*------------------------------------------------------------------------------*
use cod_mod ruralidad concurso using "$conc/plazas_nombramiento.dta", clear
decode ruralidad, gen(rur_s)
drop if rur_s=="" | cod_mod==""
gen cm = ustrregexra(cod_mod, "[^0-9]", "")
replace cm = string(real(cm), "%07.0f") if real(cm)<.
gen byte rural_sch = inlist(rur_s,"RURAL 1","RURAL 2","RURAL 3")
* latest classification per school; break remaining ties towards rural
gsort cm -concurso -rural_sch
collapse (first) rural_sch, by(cm)
count
tempfile schoolrur
save `schoolrur'

*------------------------------------------------------------------------------*
* 3. Outcome: nombrado in a rural school at t+k (from NEXUS)
*------------------------------------------------------------------------------*
use "$data/rd_analysis.dta", clear
keep documento concurso
duplicates drop
tempfile rdids
save `rdids'

use numdocum y situacion cod_mod using "$nexus/nexus_digedd_2015_2021.dta", clear
keep if situacion=="NOMBRADO"
drop if numdocum==""
gen documento = ustrregexra(numdocum, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
gen cm = ustrregexra(cod_mod, "[^0-9]", "")
replace cm = string(real(cm), "%07.0f") if real(cm)<.
joinby documento using `rdids'
merge m:1 cm using `schoolrur', keep(master match)
gen byte rural_now = rural_sch==1 & _merge==3
drop _merge
* teacher-year: in any rural school as nombrado (max across plazas)
collapse (max) rural_now, by(documento concurso y)
gen k = y - concurso
keep if k>=1 & k<=6
drop y
rename rural_now inrural
reshape wide inrural, i(documento concurso) j(k)
tempfile ruralout
save `ruralout'

*------------------------------------------------------------------------------*
* 4. Merge everything into the analysis file
*------------------------------------------------------------------------------*
use "$data/rd_analysis.dta", clear
capture drop rural_full rural_deg bilingue_d frontera_d vraem_d inrural*
merge 1:1 documento concurso using `attrs', keep(master match)
di "=== attrs merge ==="
tab concurso _merge
drop _merge
merge 1:1 documento concurso using `ruralout', keep(master match)
drop _merge

* Winners never nombrado in year t+k get 0 (consistent with other outcomes),
* respecting the payroll horizon
forvalues k=1/6 {
    capture confirm variable inrural`k'
    if _rc gen inrural`k' = .
    replace inrural`k' = 0 if inrural`k'==. & (concurso + `k' <= 2021)
    replace inrural`k' = . if concurso + `k' > 2021
}

* Validation: new rurality vs old etapa_desc measure where both exist
tab rural_assigned rural_full, missing
tab concurso, sum(rural_full)

compress
save "$data/rd_analysis.dta", replace
log close
