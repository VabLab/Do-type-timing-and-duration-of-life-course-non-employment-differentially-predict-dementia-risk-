*************SEQUENCE ANALYSIS******************************************************
********************************************************************************

**********TITLE:Does type and duration of life course non-employment differentially predict dementia risk and cognitive decline? A novel application of sequence analysis
**********Date last modified: January 16, 2024
**********Author: Lucia Pacca
**********Code Reviewer: Amina Gaye

**********This .do file (Sequence Analysis) includes:
**********1)Sequence Analysis and cluster analysis for men's subsample, using Dynamic Hamming algorithm (lines 13-89)
**********2)Sequence Analysis and cluster analysis for men's subsample, using Dynamic Hamming algorithm (lines 90-170)

*******************************************************SENSITIVITY ANALYSIS******************************************************************
********************************************************
*************SEQUENCE ANALYSIS - DYNAMIC HAMMING FOR MEN
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_final.dta", clear
sort key
capture drop _merge
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", clear
capture drop _merge
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_final.dta"
tab _merge
keep if GENDER==1 & _merge==3
capture label drop state_new
label define state_new 1 "WORK" 2 "UNEMPLOYMENT" 3 "RETIRED" 4 "DISABLED" 5 "FAMILY" 6 "SCHOOL" 7 "PART TIME" 8 "UNREPORTED"
label values state_new state_new

sort id age

keep id age state_new key lhms* BIRTHYR DEGREE GENDER RACE SCHLYRS

reshape wide state_new, i(id) j(age)

dynhamming state_new18-state_new65, pwdist(dist_hamming)

clustermat wards dist_hamming, name(hamming_cl) add

dudahart, dist(dist_hamming) id(id) ngroups(20)	//Goal is to have high Je(2)/Je(1) and low pseudo-T-squared
cluster gen dh_hamming_7_men = groups(7)

*************Modal Plots for clusters
reshape long state_new, i(id) j(age)
sqset state_new id age
sqindexplot,  color (gold ebblue cyan eltblue navy cranberry sand dkorange)
sqmodalplot, by(dh_hamming_7) color (gold cyan eltblue cranberry sand dkorange)

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_men.dta", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_men.dta", clear

sqmodalplot, by(dh_hamming_7) color (gold cyan eltblue cranberry sand dkorange)

***********Reorganize Trajectories
gen dh_hamming_7_men_new=1 if dh_hamming_7_men==4
replace dh_hamming_7_men_new=2 if dh_hamming_7_men==7
replace dh_hamming_7_men_new=3 if dh_hamming_7_men==5
replace dh_hamming_7_men_new=4 if dh_hamming_7_men==2
replace dh_hamming_7_men_new=5 if dh_hamming_7_men==6
replace dh_hamming_7_men_new=6 if dh_hamming_7_men==3
replace dh_hamming_7_men_new=7 if dh_hamming_7_men==1

capture label drop work_trajectories_hamming_mennew
label define work_trajectories_hamming_mennew 1 "PREDOMINANTLY WORK" 2 "DISABILITY GAP" 3 "WORK AFTER COLLEGE" 4 "PART TIME WORK" 5 "EARLY RETIREMENT" 6 "UNREPORTED UNTIL ≈ 30" 7 "UNREPORTED UNTIL ≈ 50"
label values dh_hamming_7_men_new  work_trajectories_hamming_mennew

sqmodalplot, by(dh_hamming_7_men_new) color (gold cyan eltblue cranberry sand dkorange)

save, replace

*************Combined index plots
sqindexplot if dh_hamming_7_men_new==1, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(100) legend(off) title("Predominantly work") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_1.gph"
sqindexplot if dh_hamming_7_men_new==2, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(120) legend(off) title("Disability gap") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_2.gph", replace
sqindexplot if dh_hamming_7_men_new==3, color (gold ebblue cyan eltblue navy cranberry sand dkorange) rbar legend(off) title("Work after college") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_3.gph"
sqindexplot if dh_hamming_7_men_new==4, color (gold ebblue cyan eltblue cranberry sand dkorange) rbar legend(off) title("Part time work") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_4.gph"
sqindexplot if dh_hamming_7_men_new==5, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(120) legend(off) title("Early retirement") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_5.gph", replace
sqindexplot if dh_hamming_7_men_new==6, color (gold ebblue cyan eltblue cranberry sand dkorange) rbar legend(off) title("Unreported until ≈30") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_6.gph"
sqindexplot if dh_hamming_7_men_new==7, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(150) legend(off) title("Unreported until ≈50")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_7.gph"

graph combine "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_1.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_2.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_3.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_4.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_5.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_6.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_men_7.gph" 

*************SEQUENCE ANALYSIS - DYNAMIC HAMMING FOR WOMEN
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", clear
capture drop _merge
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_final.dta"
tab _merge
keep if GENDER==2 & _merge==3 //matching with our analytic sample
capture label drop state_new
label define state_new 1 "WORK" 2 "UNEMPLOYMENT" 3 "RETIRED" 4 "DISABLED" 5 "FAMILY" 6 "SCHOOL" 7 "PART TIME" 8 "UNREPORTED"
label values state_new state_new

sort id age

keep id age state_new key lhms* BIRTHYR DEGREE GENDER RACE SCHLYRS

reshape wide state_new, i(id) j(age)

dynhamming state_new18-state_new65, pwdist(dist_hamming)

clustermat wards dist_hamming, name(hamming_cl) add

dudahart, dist(dist_hamming) id(id) ngroups(30)	//Goal is to have high Je(2)/Je(1) and low pseudo-T-squared

cluster gen dh_hamming_11_women = groups(11)

*************Modal Plots for clusters
reshape long state_new, i(id) j(age)
sqset state_new id age
sqindexplot,  color (gold ebblue cyan eltblue navy cranberry sand dkorange)
sqmodalplot, by(dh_hamming_11_women) color (gold ebblue cyan eltblue navy cranberry sand dkorange)

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_women.dta", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_hamming_women.dta", replace

************Reorganize trajectories
capture drop dh_hamming_11_women_new
gen dh_hamming_11_women_new=1 if dh_hamming_11_women==3
replace dh_hamming_11_women_new=2 if dh_hamming_11_women==2
replace dh_hamming_11_women_new=3 if dh_hamming_11_women==6
replace dh_hamming_11_women_new=4 if dh_hamming_11_women==4
replace dh_hamming_11_women_new=5 if dh_hamming_11_women==7
replace dh_hamming_11_women_new=6 if dh_hamming_11_women==9
replace dh_hamming_11_women_new=7 if dh_hamming_11_women==5
replace dh_hamming_11_women_new=8 if dh_hamming_11_women==1
replace dh_hamming_11_women_new=9 if dh_hamming_11_women==8
replace dh_hamming_11_women_new=10 if dh_hamming_11_women==11
replace dh_hamming_11_women_new=11 if dh_hamming_11_women==10


label define work_trajectories_hamming_wnew 1 "PREDOMINANTLY WORK" 2 "DISABILITY GAP" 3 "UNEMPLOYMENT/PART-TIME GAP" 4 "FAMILY GAP, GO BACK FULL TIME" 5 "FAMILY GAP, GO BACK PART-TIME" 6 "LONG FAMILY GAP" 7 "FAMILY GAP, NO REPORTED WORK" 8 "RETIRED BEFORE 60" 9 "VERY EARLY RETIREMENT" 10 "UNREPORTED UNTIL BEFORE 40" 11 "UNREPORTED UNTIL 50-60"
label values dh_hamming_11_women_new work_trajectories_hamming_wnew

sqmodalplot, by(dh_hamming_11_women_new) color (gold ebblue cyan eltblue navy cranberry sand dkorange)
save, replace

//Index plots by cluster for combined graphs
sqindexplot if dh_hamming_11_women_new==1, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(120) legend(off) title("Predominantly work") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_1.gph"
sqindexplot if dh_hamming_11_women_new==2, color (gold ebblue cyan eltblue navy cranberry sand dkorange) rbar legend(off) title("Disability gap") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_2.gph"
sqindexplot if dh_hamming_11_women_new==3, color (gold ebblue cyan eltblue navy cranberry sand dkorange) rbar legend(off) title("Unemployment/part-time gap") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_3.gph"
sqindexplot if dh_hamming_11_women_new==4, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(120) legend(off) title("Family gap, go back full-time") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_4.gph"
sqindexplot if dh_hamming_11_women_new==5, color (gold ebblue cyan eltblue navy cranberry sand dkorange) rbar legend(off) title("Family gap, go back part-time") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_5.gph"
sqindexplot if dh_hamming_11_women_new==6, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(150) legend(off) title("Long family gap")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_6.gph"
sqindexplot if dh_hamming_11_women_new==7, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(200) legend(off) title("Family gap, unreported work")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_7.gph"
sqindexplot if dh_hamming_11_women_new==8, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(150) legend(off) title("Retired before 60")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_8.gph"
sqindexplot if dh_hamming_11_women_new==9, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(200) legend(off) title("Very early retirement")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_9.gph"
sqindexplot if dh_hamming_11_women_new==10, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(170) legend(off) title("Unreported until ≈ 40"")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_10.gph"
sqindexplot if dh_hamming_11_women_new==11, color (gold ebblue cyan eltblue navy cranberry sand dkorange) overplot(170) legend(off) title("Unreported until 50-60"")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_11.gph"

graph combine "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_1.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_2.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_3.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_4.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_5.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_6.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_7.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_8.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_9.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_10.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_dh_hamming_women_11.gph"
