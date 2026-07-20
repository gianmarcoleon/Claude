*==============================================================================*
* BONO DE ATRACCION - RD ANALYSIS
* 02_build_outcomes.do
* Constructs teacher-year outcomes from the NEXUS payroll (annual Nov/Dec
* extractions, 2015-2021) for the RD sample of concurso winners:
*   - acceptance: appears as NOMBRADO in the payroll the year after the concurso
*   - retention: still NOMBRADO in t+2, t+3, ... (any school / same school)
*   - career: pay scale (escala) progression, director positions
*==============================================================================*
version 19
clear all
set more off

global tp      "/Users/u90397/Dropbox/research projects/Teachers Peru/Data"
global nexus   "$tp/nexus/clean"
global proj    "/Users/u90397/Dropbox/research projects/Claude/Principals/Bono de atraccion"
global data    "$proj/data"
global logs    "$proj/logs"

capture log close
log using "$logs/02_build_outcomes.log", replace text

*------------------------------------------------------------------------------*
* 1. RD sample DNIs (with assigned school for same-school outcomes)
*------------------------------------------------------------------------------*
use "$data/rd_base_winners.dta", clear
keep documento concurso cod_mod cod_mod_ganador
* Normalize assigned-school code to 7 digits (codigo modular)
gen cm_assigned = ustrregexra(cod_mod_ganador, "[^0-9]", "")
replace cm_assigned = ustrregexra(cod_mod, "[^0-9]", "") if cm_assigned==""
replace cm_assigned = string(real(cm_assigned), "%07.0f") if real(cm_assigned)<.
keep documento concurso cm_assigned
tempfile rdids
save `rdids'

*------------------------------------------------------------------------------*
* 2. NEXUS payroll rows for these teachers, 2015-2021
*------------------------------------------------------------------------------*
use numdocum y situacion codcatrem descargo cod_mod using "$nexus/nexus_digedd_2015_2021.dta", clear
drop if numdocum==""
gen documento = ustrregexra(numdocum, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
* keep only RD-sample teachers (joinby duplicates over concursos as intended)
joinby documento using `rdids'

gen cm_nexus = ustrregexra(cod_mod, "[^0-9]", "")
replace cm_nexus = string(real(cm_nexus), "%07.0f") if real(cm_nexus)<.

gen byte nombrado   = situacion=="NOMBRADO"
gen byte contratado = situacion=="CONTRATADO"
gen byte designado  = situacion=="DESIGNADO"
gen byte samesch    = (cm_nexus==cm_assigned & cm_assigned!="") * nombrado
gen byte director   = strpos(descargo,"DIRECT")>0
gen escala = real(codcatrem)
replace escala = . if escala<1 | escala>8

collapse (max) nombrado contratado designado samesch director escala, ///
    by(documento concurso y)

*------------------------------------------------------------------------------*
* 3. Reshape to one row per winner x concurso, outcomes by relative year
*------------------------------------------------------------------------------*
gen k = y - concurso
keep if k>=0 & k<=6
drop y
reshape wide nombrado contratado designado samesch director escala, ///
    i(documento concurso) j(k)

tempfile outcomes
save `outcomes'

*------------------------------------------------------------------------------*
* 4. Merge back to the RD base; absent from payroll = 0
*------------------------------------------------------------------------------*
use "$data/rd_base_winners.dta", clear
merge 1:1 documento concurso using `outcomes'
tab concurso _merge
drop _merge

* k horizons observable per cohort given payroll through 2021
* 2015: k=1..6 | 2017: k=1..4 | 2018: k=1..3 | 2019: k=1..2
forvalues k=0/6 {
    gen byte obs_k`k' = (concurso + `k' <= 2021)
    foreach v in nombrado contratado designado samesch director {
        capture confirm variable `v'`k'
        if !_rc {
            replace `v'`k' = 0 if `v'`k'==. & obs_k`k'==1
            replace `v'`k' = . if obs_k`k'==0
        }
    }
    capture confirm variable escala`k'
    if !_rc replace escala`k' = . if obs_k`k'==0
}

* Headline outcomes
gen byte accept      = nombrado1
gen byte retain2     = nombrado2
gen byte retain3     = nombrado3
gen byte retain4     = nombrado4
label var accept  "Nombrado in public payroll, year t+1"
label var retain2 "Nombrado, t+2"
label var retain3 "Nombrado, t+3"
label var retain4 "Nombrado, t+4"

* Career progression: promoted beyond entry scale by 2021 (needs >=1 ascenso)
gen escala_2021 = .
forvalues k=0/6 {
    replace escala_2021 = escala`k' if concurso + `k' == 2021
}
* Promoted = at escala>=2 in 2021; teachers absent from the 2021 payroll count as 0
gen byte promoted_2021 = (escala_2021>=2 & escala_2021<.)
gen byte director_ever = 0
forvalues k=1/6 {
    replace director_ever = 1 if director`k'==1 & obs_k`k'==1
}

compress
save "$data/rd_analysis.dta", replace

* Quick summary: outcome means by bono status and cohort
foreach v in accept retain2 retain3 retain4 {
    di as res _n "=== `v' ==="
    tab concurso bono if `v'<., sum(`v') nofreq means
}

log close
