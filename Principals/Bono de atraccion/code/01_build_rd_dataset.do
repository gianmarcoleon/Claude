*==============================================================================*
* BONO DE ATRACCION - RD ANALYSIS
* 01_build_rd_dataset.do
* Builds the winner-level RD dataset for concursos 2015, 2017, 2018, 2019:
*   - merges bono de atraccion beneficiary lists (by DNI) with ganadores
*   - defines per-concurso cutoffs and the centered running variable
*   - adds applicant covariates (sex, birth date, PUN score) and
*     decentralized-stage information (assigned school, rurality, bonuses)
* Author: Claude (for Gianmarco Leon-Ciliotta)
*==============================================================================*
version 19
clear all
set more off

* Roots (read-only source data; all output goes to the Claude project folder)
global tp      "/Users/u90397/Dropbox/research projects/Teachers Peru/Data"
global bono    "$tp/bono_atraccion"
global conc    "$tp/concursos/clean"
global proj    "/Users/u90397/Dropbox/research projects/Claude/Principals/Bono de atraccion"
global data    "$proj/data"
global logs    "$proj/logs"

capture log close
log using "$logs/01_build_rd_dataset.log", replace text

*------------------------------------------------------------------------------*
* 1. Import bono beneficiary lists (2015-2019 rounds only; 2022/2024 lack
*    concurso microdata for now)
*------------------------------------------------------------------------------*
* 2015: puntaje_final + orden_merito
import delimited "$bono/bono_atraccion_2015.csv", clear varnames(1) stringcols(_all)
gen concurso = 2015
destring puntaje_final orden_merito, replace
rename puntaje_final pje_bono_list
tempfile b2015
save `b2015'

* 2017: puntaje_concurso (with law bonuses) and puntaje_bono (raw, used for ranking)
import delimited "$bono/bono_atraccion_2017.csv", clear varnames(1) stringcols(_all)
gen concurso = 2017
destring puntaje_concurso puntaje_bono, replace
rename puntaje_bono     pje_bono_list
rename puntaje_concurso pje_concurso_list
tempfile b2017
save `b2017'

* 2018 & 2019: puntaje_total
foreach y in 2018 2019 {
    import delimited "$bono/bono_atraccion_`y'.csv", clear varnames(1) stringcols(_all)
    gen concurso = `y'
    destring puntaje_total, replace
    rename puntaje_total pje_bono_list
    tempfile b`y'
    save `b`y''
}

use `b2015', clear
append using `b2017' `b2018' `b2019'
keep dni concurso pje_bono_list pje_concurso_list orden_merito region
rename region region_bonolist

* Clean DNI: keep digits, pad to 8
gen documento = ustrregexra(dni, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento=="" | documento=="."
duplicates report documento concurso
duplicates drop documento concurso, force
gen byte bono = 1
tempfile bonolists
save `bonolists'

*------------------------------------------------------------------------------*
* 2. Ganadores del concurso de nombramiento (the RD sample)
*------------------------------------------------------------------------------*
use "$conc/ganadores_nombramiento.dta", clear
* Clean DNI the same way
replace documento = ustrregexra(documento, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
duplicates report documento concurso
duplicates drop documento concurso, force

merge 1:1 documento concurso using `bonolists'
tab concurso _merge
* _merge==2: on the bono list but not in ganadores (should be tiny)
count if _merge==2
drop if _merge==2
replace bono = 0 if bono==.
drop _merge

*------------------------------------------------------------------------------*
* 3. Running variable and cutoffs
*    The bono ranks winners by the UNBONIFIED final score (PUN + decentralized,
*    excluding law bonuses). For matched 2017 recipients pje_bono_list is that
*    raw score; check correspondence with pje_final from ganadores.
*------------------------------------------------------------------------------*
gen diff_check = pje_final - pje_bono_list if bono==1
sum diff_check, detail
count if abs(diff_check)>0.01 & diff_check<.
di as res "Bono recipients where ganadores pje_final != bono-list score: " r(N)
tab concurso if abs(diff_check)>0.01 & diff_check<.
* NOTE: these gaps are exactly the law-mandated bonuses (disability, armed
* forces) recorded in etapa_desc (pje_bonif_*); the bono ranking uses the
* UNBONIFIED score. The unbonified running variable is built in section 5b,
* after merging the etapa descentralizada bonus components.

* Cutoff: minimum bono-list score per concurso (the marginal recipient)
bysort concurso: egen cutoff = min(cond(bono==1, pje_bono_list, .))
tab concurso, sum(cutoff)


*------------------------------------------------------------------------------*
* 4. Covariates from the applicant registry
*------------------------------------------------------------------------------*
preserve
use "$conc/list_applicants_wide.dta", clear
replace documento = ustrregexra(documento, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
duplicates drop documento, force
keep documento sexo fecha_nac pje_pun_*
tempfile applicants
save `applicants'
restore

merge m:1 documento using `applicants', keep(master match)
rename _merge m_applicants
gen pje_pun = .
foreach y in 2015 2017 2018 2019 {
    replace pje_pun = pje_pun_`y' if concurso==`y'
}
drop pje_pun_*
capture confirm string variable sexo
if !_rc {
    gen female = (upper(sexo)=="MUJER" | upper(sexo)=="FEMENINO" | upper(sexo)=="F") if sexo!=""
}
else {
    tab sexo
    tab sexo, nolabel
    decode sexo, gen(sexo_s)
    gen female = (upper(sexo_s)=="MUJER" | upper(sexo_s)=="FEMENINO" | upper(sexo_s)=="F") if sexo_s!=""
}
gen birth_year = year(fecha_nac)
gen age_concurso = concurso - birth_year

*------------------------------------------------------------------------------*
* 5. Decentralized-stage info for winners (assigned plaza and its rurality)
*------------------------------------------------------------------------------*
preserve
use "$conc/etapa_desc_nombramiento.dta", clear
keep if d_ganador==1
replace documento = ustrregexra(documento, "[^0-9]", "")
replace documento = string(real(documento), "%08.0f") if real(documento)<.
drop if documento==""
duplicates drop documento concurso, force
keep documento concurso ruralidad ruralidad_ganador codplaza_ganador cod_mod_ganador ///
     pje_formacion pje_meritos pje_experi~f pje_trayec~a pje_observ~n pje_entrev~a ///
     pje_bonif_* orden_merito modalidad
rename orden_merito orden_merito_ed
tempfile etapa
save `etapa'
restore

merge 1:1 documento concurso using `etapa', keep(master match)
rename _merge m_etapa
tab concurso m_etapa

*------------------------------------------------------------------------------*
* 5b. Unbonified running variable
*     pje_final in ganadores includes law bonuses for ~2% of winners; the bono
*     ranking uses the raw (unbonified) score. Verified: for all 217 recipients
*     with pje_final != list score, the gap equals rowtotal(pje_bonif_*).
*------------------------------------------------------------------------------*
egen bonif_total = rowtotal(pje_bonif_*), missing
replace bonif_total = 0 if bonif_total==.
gen running_raw = pje_final - bonif_total
* Cross-validate against the raw score printed on the bono lists
count if bono==1 & abs(running_raw - pje_bono_list)>0.01
di as res "Recipients where unbonified score != bono-list score: " r(N)
replace running_raw = pje_bono_list if bono==1  // list score is authoritative
gen running = running_raw - cutoff
label var running "Unbonified final score centered at top-third cutoff"

* Compliance around the cutoff
count if bono==0 & running>0
di as res "Winners strictly above cutoff without bono: " r(N)
count if bono==1 & running<0
di as res "Recipients strictly below cutoff: " r(N)

* Flag ties exactly at the cutoff (split by unobserved tie-breaking)
gen byte at_cutoff = (running_raw==cutoff)
tab concurso at_cutoff
tab bono if at_cutoff==1

* Rurality of the assigned school
gen rural_assigned = .
replace rural_assigned = 1 if inlist(ruralidad_ganador,"RURAL 1","RURAL 2","RURAL 3","RURAL")
replace rural_assigned = 0 if inlist(ruralidad_ganador,"URBANO","URBANA","NO RURAL")
tab ruralidad_ganador rural_assigned, missing

*------------------------------------------------------------------------------*
* 6. Save
*------------------------------------------------------------------------------*
label var bono          "On bono de atraccion beneficiary list"
label var cutoff        "Top-third cutoff (unbonified final score)"
label var running_raw   "Unbonified final score"
label var pje_pun       "PUN score (national stage)"
label var female        "Female"
label var age_concurso  "Age at concurso year"
label var rural_assigned "Assigned school is rural"

compress
save "$data/rd_base_winners.dta", replace

* Summary
tab concurso bono
bysort concurso: sum running if bono==1
bysort concurso: sum running if bono==0

log close
