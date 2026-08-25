*************DATA ANALYSIS******************************************************
********************************************************************************

**********TITLE:Does type and duration of life course non-employment differentially predict dementia risk and cognitive decline? A novel application of sequence analysis
**********Date last modified: January 16, 2024
**********Author: Lucia Pacca
**********Code Reviewer: Amina Gaye
**********Project Description

**********This .do file (Data Cleaning) includes:
**********1)Obtain and clean outcome (dementia probability scores and memory scores from Wu) - lines 18-54
**********2)Define exclusion/inclusion criteria (lines 55-68)
**********3)Identify people who died or dropped out during the study period; save final file with analytic sample (lines 70-165) 
**********4)Merge outcome file with employment trajectory clusters (obtained in the "Sequence Analysis" file) - lines 167-237
**********5)Create covariates and other variables for the analysis (lines 223-268)
**********6)Main results: association between employment clusters (obtained with Optimal Matching)

*************
*************OUTCOME: Wu measure for cognitive outcome
*use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/WuEtAl1995_2018_cogoutcomes_longformat.dta", clear
*capture drop wave
*gen wave=4 if year==1998
*replace wave=5 if year==2000
*replace wave=6 if year==2002
*replace wave=7 if year==2004
*replace wave=8 if year==2006
*replace wave=9 if year==2008
*replace wave=10 if year==2010
*replace wave=11 if year==2012
*replace wave=12 if year==2014
*replace wave=13 if year==2016
*replace wave=14 if year==2018
*save, replace

***
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/WuEtAl1995_2018_cogoutcomes_longformat.dta", clear
drop if ms==. & demprob==.
bysort hhidpn: gen num_assessments= _n

***Define practice effect=having already taken the test before
***We ended up not using practice effects in the final analyses, since it applied to a small percentage of the sample, but I am keeping it in the final dataset in case reviewers ask for it.
gen practice_effect=1
replace practice_effect=0 if num_assessments==1
tab practice_effect if age_sas>=70 //10% of people took their first assessment at 70 or older
sort hhid wave
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_practiceeffect.dta", replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/WuEtAl1995_2018_cogoutcomes_longformat.dta", clear

sort hhidpn wave
capture drop _merge
merge hhidpn wave using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_practiceeffect.dta", keep (num_assessments practice_effect)
tab _merge
drop _merge
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_cogoutcomes_longformat_mid.dta", replace

***Define Exclusion/Inclusion Criteria
***Merge with Life History Mail Survey (LHMS), since we have complete employment trajectories only for LHMS participants
capture drop key
gen key=hhidpn
sort key
merge m:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/lhms1517a_r.dta", keepusing(lhms lhmswind) //6 people did not merge
drop if _merge==2
bysort hhidpn:egen mean_ms=mean(ms)
gen lhms_sample=1 if lhms!=. //These people completed LHMS
tab lhms_sample if num_assessments==1 //Completed LHMS (2017 or 2015) AND had at least one outcome assessment = 11,738 people
gen age_outcome=age_sas if ms!=.
bysort hhidpn: egen max_age_outcome=max(age_outcome)
tab lhms_sample if num_assessments==1 & max_age_outcome>=70 // Completed LHMS 2015 or 2017 AND had at least one outcome assessment at 70 years and older = 5,947 people --> ANALYTIC SAMPLE
save, replace

***Get interview status variable from RAND to define inverse probability weights
***This allows identiying respondents who died or dropped out during the study (IPWs account for missingness/selection bias due to death/dropout)
clear
set maxvar 30000
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/randhrs1992_2018v1.dta", clear
keep rahhidpn r*iwstat raddate rabyear
rename r1iwstat iwstat1
rename r2iwstat iwstat2
rename r3iwstat iwstat3
rename r4iwstat iwstat4
rename r5iwstat iwstat5
rename r6iwstat iwstat6
rename r7iwstat iwstat7
rename r8iwstat iwstat8
rename r9iwstat iwstat9
rename r10iwstat iwstat10
rename r11iwstat iwstat11
rename r12iwstat iwstat12
rename r13iwstat iwstat13
rename r14iwstat iwstat14

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/randhrs1992_2018v1_IWSTAT.dta", replace
egen id=group(rahhidpn)
reshape long iwstat, i(id) j(wave)
rename rahhidpn hhidpn 

format raddate %d
gen yrdeath=year(raddate)
sort hhidpn wave
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/randhrs1992_2018v1_IWSTAT.dta", replace

****Merge outcome file with interview status and death date from RAND
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_mid.dta", clear
sort hhidpn wave
capture drop _merge
merge hhidpn wave using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/randhrs1992_2018v1_IWSTAT.dta"
tab _merge
drop if _merge==2
drop if age_sas<70 //We are only measuring outcome starting at age 70
tsset id wave

bysort id: egen min_age=min(age_sas)
gen wave_min=wave if age_sas==min_age
bysort id: egen mean_wave_min=mean(wave_min)
replace wave_min=mean_wave_min if wave_min==.

drop if age_sas==. & wave<wave_min
drop if demprob==. & ms==. & iwstat==1 //keep missing values for dropouts or dead people only
drop if hhidpn=="052444010" & wave<12
drop if hhidpn=="041028040" & wave<9

bysort id: gen timeidxvar= _n //denotes outcome assessment # starting at age 70

capture drop mean_ms
bysort hhidpn:egen mean_ms=mean(ms)
edit hhidpn year wave yrdeath mean_ms if mean_ms==. & timeidxvar==1 //people who didn't have any outcome measurement = 23,242
edit hhidpn year wave yrdeath mean_ms if mean_ms!=. & timeidxvar==1 //people who had at least one outcome measurement = 18,991

keep if mean_ms!=. //drop those who died or dropped out before turning 70, and therefore have no outcome measurement
keep if lhms_sample==1
capture drop _merge
sort key
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_cogoutcomes_longformat_final.dta", replace //THIS IS OUR ANALYTIC SAMPLE
tab yrdeath if timeidxvar==1 //401 participants died during the study period

*************Add exact date of interviews
clear
clear matrix
clear mata
set maxvar 30000 //5000 not enough to store RAND file
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/randhrs1992_2018v1.dta", clear
keep rahhidpn r*iwend //month and year of interview end at each wave
drop r1iwend-r3iwend reiwend
egen id=group(rahhidpn)
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/RAND_iwend.dta", replace
rename r4iwend riwend4
rename r5iwend riwend5
rename r6iwend riwend6
rename r7iwend riwend7
rename r8iwend riwend8
rename r9iwend riwend9
rename r10iwend riwend10
rename r11iwend riwend11
rename r12iwend riwend12
rename r13iwend riwend13
rename r14iwend riwend14
reshape long riwend, i(id) j(wave)
format riwend %d
gen key=rahhidpn
sort key wave
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/RAND_iwend.dta", replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_final.dta", clear
sort key wave
merge key wave using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/RAND_iwend.dta"
tab _merge
drop if _merge==2
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_cogoutcomes_longformat_final.dta", replace

**************MERGE OUTCOME with OCCUPATION CLUSTERS and CONFOUNDERS
**************We are also making sure we don't create duplicate obs while merging the data
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/WuEtAl1998_2018_cogoutcomes_longformat_final.dta", clear
sort key
capture drop _merge
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", keepusing (DEGREE GENDER BIRTHYR RACE SCHLYRS) //these will be used as covariates
sort key
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
drop if _merge==2
capture drop _merge
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/data/bp_analysis_dataset.dta", keepusing(medu fedu missing_medu missing_fedu race bplace) //Additional covariates - I had already cleaned these for the education&BP project 
drop if _merge==2
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
sort key
capture drop _merge
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_women.dta", keepusing(om_11_women_new) //for main analysis - women
sort key
capture drop _merge
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
sort key
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_men.dta", keepusing(om_10_men_new) //for main analysis - men
sort key
capture drop _merge
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
sort key
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_women.dta", keepusing(dh_hamming_11_women_new) //dynamic hamming for for sensitivity analysis - women
sort key
capture drop _merge
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
sort key
merge m:m key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_men.dta", keepusing(dh_hamming_7_men_new) //dynamic hamming for for sensitivity analysis - men
sort key
capture drop _merge
capture drop dup
bysort key wave: gen dup=cond(_N==1,0,_n)
tab dup
drop if dup>1
sort key
capture drop _merge
save "//Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/data/States_sq_RESULTS.dta", replace

*****Create variables for final analysis
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/data/States_sq_RESULTS.dta", clear
capture drop *98
*****Create standardized memory scores
egen mean_ms98=mean(ms) if year==1998
egen sd_ms98=sd(ms) if year==1998
egen mean_ms98_mean=mean(mean_ms98)
egen mean_sd_ms98=mean(sd_ms98) //carry forward the calculated 1998 mean and sd

capture drop ms_98
gen ms_98=(ms-mean_ms98_mean)/mean_sd_ms98 //standardize memory score

*****************Confounder: Completed HS (yes/no)
gen completed_hs=1
replace completed_hs=0 if DEGREE<2
save, replace

*************base age
bysort hhidpn: egen base_age=min(age_sas)
save, replace

**************
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/data/States_sq_RESULTS.dta", clear
replace raddate=. if raddate==.x
replace bplace=3 if bplace==. //"not specified" birthplace as one category so that we don't drop people
label define bplace 0 "us not south" 1 "southern us" 2 "immigrant" 3 "not specified", replace
label values bplace bplace

**************create "interview date" variable
gen iwdate= riwend
replace iwdate=raddate-15 if raddate!=.x & yrdeath==year //set the "hypothetical date" 15 days before death date
format %d iwdate
ipolate iwdate wave, gen(iwdate_ipo)
format %d iwdate_ipo
replace iwdate=iwdate_ipo if iwdate==.
replace raddate=iwdate-15 if iwstat==5 & raddate==.

//Time variable for memory decline
bysort id: gen time=wave-wave_min

*************baseline age
capture drop base_age_round base_age_centered_70
gen base_age_round=round(base_age)
gen base_age_centered_70=base_age_round-70

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", replace

*************MAIN RESULTS
**************OM RESULTS FOR WOMEN (N=3,540)
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear

**Dementia Probability
**We are using generalized estimating equations (GEE) to estimate the association between employment clusters and dementia probability
xtset id wave

//The xtrccipw first estimates theinverse probability weights, and then a weighted generalized estimating equations model with the IPWs
//See manual here: https://pubmed.ncbi.nlm.nih.gov/29755297/
xtrccipw demprob if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_11_women_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs) glmfamily(binomial) glmlink(logit)
estimate store demprob_women_om

outreg2 using demprob_om_women.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label

**For revision: predictive margins
margins om_11_women_new, atmeans

capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

**Memory Decline
//we are using "xtrccipw" to calculate the inverse probability weights, then linear mixed effects model to estimate the association between employment clusters and memory decline 
capture drop xtrccipw_ms_98-regerrorcode_xtrccipwRi

xtrccipw ms_98 if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_11_women_new time i.om_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs) glmfamily(gaussian) //we are not using thsese results, this is just to calculate the ipws

//Linear mixed effects model
mixed ms_98 i.om_11_women_new time i.om_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs [pweight=ipw]|| id: wave, cov(un) 
estimate store mdecline_women_lme

outreg2 using memdecline_om_women_lme.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

**For revision: predictive margins
margins om_11_women_new, at(time=0) 

coefplot demprob_women_om, keep(*.om_11_women_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Dementia Probability") xscale(r(-0.4,0.4)) baselevel
coefplot mdecline_women_lme, keep(*.om_11_women_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Baseline Memory") xscale(r(-0.4,0.4)) baselevel
coefplot mdecline_women_lme, keep(time *.om_11_women_new#c.time) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Memory Decline") xscale(r(-0.4,0.4)) baselevel

**Memory decline graphs for R&R&
**First panel: unemployment and disability
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Women_1") firstrow clear
twoway (line memory_uninterr_work time) (rcap low_ci_uninterr_work high_ci_uninterr_work time)||(line memory_disability time) (rcap low_ci_disability high_ci_disability time)||(line memory_unemployment time) (rcap low_ci_unemployment high_ci_unemployment time)

**Second panel: family trajectories
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Women_2") firstrow clear
twoway (line memory_uninterr_work time) (rcap low_ci_uninterr_work high_ci_uninterr_work time)||(line memory_family_ft time) (rcap low_ci_family_ft high_ci_family_ft time)||(line memory_family_pt time) (rcap low_ci_family_pt high_ci_family_pt time)||(line memory_career_exit time) (rcap low_ci_career_exit high_ci_career_exit time)

**Third panel: retirement trajectories 
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Women_3") firstrow clear
twoway (line memory_uninterr_work time) (rcap low_ci_uninterr_work high_ci_uninterr_work time)||(line memory_retired_early time) (rcap low_ci_retired_early high_ci_retired_early time)||(line memory_retired_mid time) (rcap low_ci_retired_mid high_ci_retired_mid time)

****SESNITIVITY ANALYSIS: control for chilhood health
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/childhood_health_HRS.dta"

**Dementia Probability
**We are using generalized estimating equations (GEE) to estimate the association between employment clusters and dementia probability
drop _merge
xtset id wave

//The xtrccipw first estimates theinverse probability weights, and then a weighted generalized estimating equations model with the IPWs
//See manual here: https://pubmed.ncbi.nlm.nih.gov/29755297/
xtrccipw demprob if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_11_women_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs child_health) glmfamily(binomial) glmlink(logit)
estimate store demprob_women_om_chealth

outreg2 using demprob_women_om_chealth.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label

**For revision: predictive margins
margins om_11_women_new, atmeans post
estimate store margins_demprob_wchealth
outreg2 [margins_demprob_wchealth] using margins_demprob_womenchealth.doc

capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

**Memory Decline
//we are using "xtrccipw" to calculate the inverse probability weights, then linear mixed effects model to estimate the association between employment clusters and memory decline 
capture drop xtrccipw_ms_98-regerrorcode_xtrccipwRi

xtrccipw ms_98 if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_11_women_new time i.om_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs child_health) glmfamily(gaussian) //we are not using thsese results, this is just to calculate the ipws

//Linear mixed effects model
mixed ms_98 i.om_11_women_new time i.om_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs child_health [pweight=ipw]|| id: wave, cov(un) 
estimate store mdecline_women_lme

outreg2 using memdecline_om_women_chealth.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

**For revision: predictive margins
margins om_11_women_new, at(time=0) 

coefplot demprob_women_om, keep(*.om_11_women_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Dementia Probability") xscale(r(-0.4,0.4)) baselevel
coefplot mdecline_women_lme, keep(*.om_11_women_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Baseline Memory") xscale(r(-0.4,0.4)) baselevel
coefplot mdecline_women_lme, keep(time *.om_11_women_new#c.time) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Memory Decline") xscale(r(-0.4,0.4)) baselevel

************OM RESULTS FOR MEN (N=2,405)
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear
xtrccipw demprob if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_10_men_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs) glmfamily(binomial) glmlink(logit)
estimate store demprob_men_omz

outreg2 using demprob_om_men_10.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label

margins i.om_10_men_new, atmeans post
estimate store margins_demprob_men
outreg2 [margins_demprob_men] using margins_demprob_men.doc, stats(coef ci pval)

capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

***Memory Decline

xtrccipw ms_98 if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_10_men_new time i.om_10_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs) glmfamily(gaussian)

//Linear mixed effects model 
mixed ms_98 i.om_10_men_new time i.om_10_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs [pweight=ipw] if GENDER==1|| id: wave, cov(un) 
estimate store mdecline_men_lme

coefplot mdecline_men_lme, keep(*.om_10_men_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Baseline Memory") baselevel 
coefplot mdecline_men_lme, keep(time *.om_10_men_new#c.time) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Memory Decline") xscale(r(-0.4,0.4)) baselevel 

outreg2 using memdecline_om_men_lme.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label append

**Predictive margins
margins om_10_men_new, at(time=0) post
estimate store margins_memdecline_men
outreg2 [margins_memdecline_men] using margins_memdecline_men.doc


**Memory decline graphs for R&R&
**First panel: work after college and disability
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Men_1") firstrow clear
twoway (line memory_pred_work time) (rcap low_ci_pred_work hi_ci_pred_work time)||(line memory_disab_mid time) (rcap low_ci_disab_mid hi_ci_disab_mid time)||(line memory_disab_later time) (rcap low_ci_disab_later hi_ci_disab_later time)||(line memory_college time) (rcap low_ci_college hi_ci_college time)

**Second panel: part-time trajectories
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Men_1") firstrow clear
twoway (line memory_pred_work time) (rcap low_ci_pred_work hi_ci_pred_work time)||(line memory_pt_earlier time) (rcap low_ci_pt_earlier hi_ci_pt_earlier time)||(line memory_pt_later time) (rcap low_ci_pt_later hi_ci_pt_later time)

**Third panel: retirement trajectories
import excel "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Marginsplot_clusters.xlsx", sheet("Men_2") firstrow clear
twoway (line memory_pred_work time) (rcap low_ci_pred_work hi_ci_pred_work time)||(line memory_retired_early time) (rcap low_ci_retired_early hi_ci_retired_early time)||(line memory_retired_60 time) (rcap low_ci_retired_60 hi_ci_retired_60 time)

***********SENSITIVITY ANALYSIS ADJUSTING FOR CHILDHOOD HEALTH
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/childhood_health_HRS.dta"

drop _merge
xtrccipw demprob if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_10_men_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs child_health) glmfamily(binomial) glmlink(logit)
estimate store demprob_men_omchealth

outreg2 using demprob_men_omchealth.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label

margins i.om_10_men_new, atmeans

capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

***Memory Decline

xtrccipw ms_98 if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.om_10_men_new time i.om_10_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs child_health) glmfamily(gaussian)

//Linear mixed effects model 
mixed ms_98 i.om_10_men_new time i.om_10_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs child_health [pweight=ipw] if GENDER==1|| id: wave, cov(un) 
estimate store mdecline_men_chealth

outreg2 using  mdecline_men_chealth.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

**Predictive margins
margins om_10_men_new, at(time=0) post
estimate store margins_memdecline_men
outreg2 [margins_memdecline_men] using margins_memdecline_men.doc

*************************************************TABLE 1
*************************************************Summary statistics for overall sample and by cluster 
*************************************************Variables for Table 1
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_men.dta", clear
capture drop disabled* unemployed* homemaker* work* part_time* employed* school*
gen employed=1 if state_new==1
gen unemployed=1 if state_new==2
gen retired=1 if state_new==3
gen disabled=1 if state_new==4
gen family=1 if state_new==5
gen school=1 if state_new==6
gen part_time=1 if state_new==7
gen unreported=1 if state_new==8

foreach var of varlist employed unemployed retired disabled family school part_time unreported {
bysort id: egen total_`var'=total(`var')	
}

baselinetable total_employed(cts) total_unemployed(cts) total_retired(cts) total_disabled(cts) total_family(cts) total_school(cts) total_part_time(cts) total_unreported(cts) if age==18, exportexcel(table1_statesdist_ovearll)

baselinetable total_employed(cts) total_unemployed(cts) total_retired(cts) total_disabled(cts) total_family(cts) total_school(cts) total_part_time(cts) total_unreported(cts) if age==18, by(omv_7_men_new) exportexcel(table1_statesdist)

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Code Review for Amina/data/States_sq_RESULTS.dta", clear

baselinetable age_sas(cts) race(cat) bplace(cat)  medu(cts) fedu(cts) completed_hs(cat) missing_medu(cat) missing_fedu(cat) demprob(cts) ms_98(cts) if timeidxvar==1 & GENDER==1, by(omv_7_men_new) exportexcel(table1_covariates)

baselinetable age_sas(cts) race(cat) bplace(cat)  medu(cts) fedu(cts) completed_hs(cat) missing_medu(cat) missing_fedu(cat) demprob(cts) ms_98(cts) if timeidxvar==1 & GENDER==1, exportexcel(table1_ovmencov)

baselinetable age_sas(cts) race(cat) bplace(cat)  medu(cts) fedu(cts) completed_hs(cat) missing_medu(cat) missing_fedu(cat) demprob(cts) ms_98(cts) if timeidxvar==1 & GENDER==2, by(om_11_wome~w) exportexcel(table1_covariates) maxcatvalues(11)

use "//Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_omv_women.dta", clear
capture drop disabled* unemployed* homemaker* work* part_time* employed* school*
gen employed=1 if state_new==1
gen unemployed=1 if state_new==2
gen retired=1 if state_new==3
gen disabled=1 if state_new==4
gen family=1 if state_new==5
gen school=1 if state_new==6
gen part_time=1 if state_new==7
gen unreported=1 if state_new==8

foreach var of varlist employed unemployed retired disabled family school part_time unreported {
bysort id: egen total_`var'=total(`var')	
}

baselinetable total_employed(cts) total_unemployed(cts) total_retired(cts) total_disabled(cts) total_family(cts) total_school(cts) total_part_time(cts) total_unreported(cts) if age==18, exportexcel(table1_statesdist_OvWomen)

baselinetable total_employed(cts) total_unemployed(cts) total_retired(cts) total_disabled(cts) total_family(cts) total_school(cts) total_part_time(cts) total_unreported(cts) if age==18, by(omv_11_women_new) exportexcel(table1_statesdist_women) maxcatvalues(11)

*************************************************SENSITIVITY ANALYSIS WITH DYNAMIC HAMMING
**************SENSITIVITY ANALYSIS RESULTS FOR WOMEN (N=3,540)
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear

//dementia probability
xtset id wave

xtrccipw demprob if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.dh_hamming_11_women_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs) glmfamily(binomial) glmlink(logit)
estimate store demprob_women_DH

outreg2 using demprob_women_DH.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

*coefplot demprob_women_DH, eform keep(*.dh_hamming_11_women_new) xline(1, lcolor(black) lwidth(thin) lpattern(dash)) title("Dementia Probability, Women") xscale(r(0,5)) baselevel

**Predictive margins
margins i.dh_hamming_11_women_new, atmeans post

//memory decline
capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

xtrccipw ms_98 if GENDER==2, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.dh_hamming_11_women_new time i.dh_hamming_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs) glmfamily(gaussian)
estimate store mdecline_women_DH

//Linear mixed effects model
mixed ms_98 i.dh_hamming_11_women_new time i.dh_hamming_11_women_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs [pweight=ipw]|| id: wave, cov(un) 
estimate store mdecline_women_lme_DH

outreg2 using memdecline_dh_women_lme.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

**Predictive margins
margins i.dh_hamming_11_women_new, at(time=0) post

coefplot mdecline_women_lme_DH, keep(*.dh_hamming_11_women_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Baseline Memory") xscale(r(-0.6,0.4)) baselevel
coefplot mdecline_women_lme_DH, keep(time *.dh_hamming_11_women_new#c.time) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Memory Decline") xscale(r(-0.6,0.4)) baselevel

**************SENSITIVITY ANALYSIS RESULTS FOR MEN (N=2,405)
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_RESULTS.dta", clear
xtrccipw demprob if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.dh_hamming_7_men_new i.race medu fedu missing_medu missing_fedu i.bplace i.wave age_sas completed_hs) glmfamily(binomial) glmlink(logit)
estimate store demprob_men_DH

outreg2 using demprob_dh_men.doc, dec(2) eform cti(odds ratio) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

*coefplot demprob_men_DH, eform keep(*.dh_hamming_7_men_new) xline(1, lcolor(black) lwidth(thin) lpattern(dash)) title("Dementia Probability, Men") xscale(r(0,5)) baselevel

//marginal predictions
margins i.dh_hamming_7_men_new, atmeans

capture drop xtrccipw_demprob-regerrorcode_xtrccipwRi

xtrccipw ms_98 if GENDER==1, idvar(id) timevar(iwdate) timeidxvar(timeidxvar) generate(ipw) trtimevar(raddate) linkfxn(logit) glmvars(i.dh_hamming_7_men_new time i.om_10_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs) glmfamily(gaussian)

***Linear mixed effects model 
mixed ms_98 i.dh_hamming_7_men_new time i.dh_hamming_7_men_new#c.time base_age_centered_70 i.race medu fedu missing_medu missing_fedu i.bplace i.wave completed_hs [pweight=ipw] if GENDER==1|| id: wave, cov(un) 
estimate store mdecline_men_lme_DH

*coefplot mdecline_men_lme_DH, keep(*.dh_hamming_7_men_new) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Baseline Memory") baselevel 
*coefplot mdecline_men_lme_DH, keep(time *.dh_hamming_7_men_new#c.time) xline(0, lcolor(black) lwidth(thin) lpattern(dash)) title("Memory Decline") xscale(r(-0.2,0.2)) baselevel 

outreg2 using memdecline_dh_men_lme.doc, dec(2) stats(coef ci pval) sideway alpha(0.001, 0.01, 0.05) label replace

//marginal predictions
margins i.dh_hamming_7_men_new, at (time=0) post




