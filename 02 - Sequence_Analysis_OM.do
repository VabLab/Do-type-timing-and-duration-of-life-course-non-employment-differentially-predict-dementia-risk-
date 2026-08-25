*************SEQUENCE ANALYSIS******************************************************
********************************************************************************

**********TITLE:Does type and duration of life course non-employment differentially predict dementia risk and cognitive decline? A novel application of sequence analysis
**********Date last modified: January 16, 2024
**********Author: Lucia Pacca
**********Code Reviewer: Amina Gaye

**********This .do file (Sequence Analysis) includes:
**********1)Sequence Analysis and cluster analysis for men's subsample, using Optimal Matching algorithm (lines 13-99)
**********2)Sequence Analysis and cluster analysis for men's subsample, using Optimal Matching algorithm (lines 128-220)

********************************************************
*************SEQUENCE ANALYSIS - OPTIMAL MATCHING FOR MEN
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

************Index Plot for all men
sqset state_new id age
sqindexplot,  color (gold ebblue cyan eltblue navy cranberry dkorange gray)
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Sequence_Index_Plot_Men.gph", replace

sort id age
trans2subs state_new, id(id) subs(smat)
matrix list smat

reshape wide state_new, i(id) j(age)

oma state_new18-state_new65, subsmat(smat) pwdist(dist_om) indel(1.5) length(48)

clustermat wards dist_om, name(om_cl) add

dudahart, dist(dist_om) id(id) ngroups(20)	//Goal is to have high Je(2)/Je(1) and low pseudo-T-squared
cluster gen om_10_men = groups(10) //but we don't want too many clusters for interpretability reasons
cluster gen om_6_men = groups(6) //but we don't want too many clusters for interpretability reasons

*************Index Plots for clusters
reshape long state_new, i(id) j(age)

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_men.dta", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_men.dta", clear

sqindexplot, by(om_6_men) color (gold ebblue cyan eltblue navy cranberry dkorange gray)
sqindexplot, by(om_10_men) color (gold ebblue cyan eltblue navy cranberry dkorange gray)

***********Reorganize Trajectories for 6 clusters
capture drop om_6_men_new
gen om_6_men_new=1 if om_6_men==3
replace om_6_men_new=2 if om_6_men==6
replace om_6_men_new=3 if om_6_men==5
replace om_6_men_new=4 if om_6_men==4
replace om_6_men_new=5 if om_6_men==2
replace om_6_men_new=6 if om_6_men==1

sqindexplot, by(om_6_men_new) color (gold ebblue cyan eltblue navy cranberry dkorange gray)

save, replace

capture label drop work_trajectories_om_mennew
label define work_trajectories_om_mennew 1 "UNINTERRUPTED WORK" 2 "DISABILITY GAP" 3 "PART TIME WORK" 4 "RETIRED AT MIDLIFE" 5 "UNREPORTED UNTIL ≈ 30" 6 "UNREPORTED UNTIL ≈ 50"
label values om_6_men_new  work_trajectories_om_mennew

save, replace

***********Reorganize Trajectories for 10 clusters
capture drop om_10_men_new
gen om_10_men_new=1 if om_10_men==3
replace om_10_men_new=2 if om_10_men==9
replace om_10_men_new=3 if om_10_men==10
replace om_10_men_new=4 if om_10_men==4
replace om_10_men_new=5 if om_10_men==8
replace om_10_men_new=6 if om_10_men==6
replace om_10_men_new=7 if om_10_men==5
replace om_10_men_new=8 if om_10_men==7
replace om_10_men_new=9 if om_10_men==2
replace om_10_men_new=10 if om_10_men==1

sqindexplot, by(om_10_men_new) color (gold ebblue cyan eltblue navy cranberry dkorange gray)

capture label drop work_trajectories_om_mennew10
label define work_trajectories_om_mennew10 1 "PREDOMINANTLY WORK" 2 "DISABILITY AT MIDLIFE" 3 "DISABILITY LATER" 4 "WORK AFTER COLLEGE" 5 "PART-TIME EARLIER" 6 "PART-TIME LATER" 7 "EARLY RETIREMENT" 8 "RETIRED ≈ 60" 9 "UNREPORTED UNTIL ≈ 30" 10 "UNREPORTED UNTIL ≈ 60"
label values om_10_men_new  work_trajectories_om_mennew10

save, replace

*************Combined index plots for 10 clusters
sqindexplot, by(om_10_men_new) color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(100) legend(off)

sqindexplot if om_10_men_new==1, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(100) legend(off) title("Predominantly work") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_1.gph", replace
sqindexplot if om_10_men_new==2, color (gold ebblue cyan eltblue cranberry dkorange gray) rbar legend(off) title("Disability at midlife") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_2.gph", replace
sqindexplot if om_10_men_new==3, color (gold ebblue cyan eltblue navy cranberry dkorange gray) rbar legend(off) title("Disability later") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_3.gph", replace
sqindexplot if om_10_men_new==4, color (gold ebblue cyan eltblue navy cranberry dkorange gray) rbar legend(off) title("Work after college") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_4.gph", replace
sqindexplot if om_10_men_new==5, color (gold ebblue cyan eltblue cranberry dkorange gray) rbar legend(off) title("Part-time earlier") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_5.gph", replace
sqindexplot if om_10_men_new==6, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(120) legend(off) title("Part-time later") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_6.gph", replace
sqindexplot if om_10_men_new==7, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(140) legend(off) title("Early retirement") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_7.gph", replace
sqindexplot if om_10_men_new==8, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(140) legend(off) title("Retired ≈ 60") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_8.gph", replace
sqindexplot if om_10_men_new==9, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(150) legend(off) title("Unreported until ≈ 30") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_9.gph", replace
sqindexplot if om_10_men_new==10, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(150) legend(off) title("Unreported until ≈ 60") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_10.gph", replace

graph combine "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_1.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_2.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_3.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_4.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_5.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_6.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_7.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_8.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_9.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_men_10.gph"

********************************************************
*************SEQUENCE ANALYSIS - OPTIMAL MATCHING FOR WOMEN
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", clear
capture drop _merge
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/WuEtAl1998_2018_cogoutcomes_longformat_final.dta"
tab _merge
keep if GENDER==2 & _merge==3
capture label drop state_new
label define state_new 1 "WORK" 2 "UNEMPLOYMENT" 3 "RETIRED" 4 "DISABLED" 5 "FAMILY" 6 "SCHOOL" 7 "PART TIME" 8 "UNREPORTED"
label values state_new state_new

sort id age

keep id age state_new key lhms* BIRTHYR DEGREE GENDER RACE SCHLYRS

************Index Plot for all women
sqset state_new id age
sqindexplot,  color (gold ebblue cyan eltblue navy cranberry dkorange gray)
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/Sequence_Index_Plot_Women.gph", replace

sort id age
trans2subs state_new, id(id) subs(smat)
matrix list smat

reshape wide state_new, i(id) j(age)

oma state_new18-state_new65, subsmat(smat) pwdist(dist_om) indel(1.5) length(48)

clustermat wards dist_om, name(om_cl) add

dudahart, dist(dist_om) id(id) ngroups(20)	//Goal is to have high Je(2)/Je(1) and low pseudo-T-squared
cluster gen om_11_women = groups(11)
cluster gen om_14_women = groups(14)

*************Modal Plots for clusters
reshape long state_new, i(id) j(age)
sqset state_new id age
sqindexplot,  color (gold ebblue cyan eltblue navy cranberry dkorange gray)

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_women.dta", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq_om_women.dta", clear

sqindexplot, by(om_11_women) color (gold ebblue cyan eltblue navy cranberry dkorange gray)
sqindexplot, by(om_14_women) color (gold ebblue cyan eltblue navy cranberry dkorange gray)

***********Reorganize Trajectories
capture drop om_11_women_new
gen om_11_women_new=1 if om_11_women==3
replace om_11_women_new=2 if om_11_women==4
replace om_11_women_new=3 if om_11_women==6
replace om_11_women_new=4 if om_11_women==1
replace om_11_women_new=5 if om_11_women==10
replace om_11_women_new=6 if om_11_women==11
replace om_11_women_new=7 if om_11_women==8
replace om_11_women_new=8 if om_11_women==5
replace om_11_women_new=9 if om_11_women==7
replace om_11_women_new=10 if om_11_women==2
replace om_11_women_new=11 if om_11_women==9

***********Label trajectories
capture label drop work_trajectories_om_womennew
label define work_trajectories_om_womennew 1 "PREDOMINANTLY WORK" 2 "DISABILITY GAP" 3 "UNEMPLOYMENT GAP" 4 "FAMILY GAP, GO BACK FULL TIME" 5 "FAMILY GAP, GO BACK PART TIME" 6 "LONG FAMILY GAP" 7 "FAMILY GAP, NO REPORTED WORK" 8 "RETIRED VERY EARLY" 9 "RETIRED AT MIDLIFE" 10 "UNREPORTED UNTIL ≈ 40" 11 "UNREPORTED UNTIL 50-60"
label values om_11_women_new  work_trajectories_om_womennew

save, replace

//Index plots by cluster for combined graphs
sqindexplot if om_11_women_new==1, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(120) legend(off) title("Predominantly work") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_1.gph", replace
sqindexplot if om_11_women_new==2, color (gold ebblue cyan eltblue navy cranberry dkorange gray) rbar legend(off) title("Disability gap") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_2.gph", replace
sqindexplot if om_11_women_new==3, color (gold ebblue cyan eltblue navy cranberry dkorange gray) rbar legend(off) title("Unemployment") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_3.gph", replace
sqindexplot if om_11_women_new==4, color (gold ebblue cyan eltblue navy cranberry dkorange gray) legend(off) title("Family gap, go back full-time") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_4.gph", replace
sqindexplot if om_11_women_new==5, color (gold ebblue cyan eltblue navy cranberry dkorange gray) rbar legend(off) title("Family gap, go back part-time") 
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_5.gph", replace
sqindexplot if om_11_women_new==6, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(150) legend(off) title("Long family gap")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_6.gph", replace
sqindexplot if om_11_women_new==7, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(200) legend(off) title("Family gap, unreported work")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_7.gph", replace
sqindexplot if om_11_women_new==8, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(150) legend(off) title("Very early retirement")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_8.gph", replace
sqindexplot if om_11_women_new==9, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(200) legend(off) title("Retired before 60")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_9.gph", replace
sqindexplot if om_11_women_new==10, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(170) legend(off) title("Unreported until ≈ 40")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_10.gph", replace
sqindexplot if om_11_women_new==11, color (gold ebblue cyan eltblue navy cranberry dkorange gray) overplot(170) legend(off) title("Unreported until 50-60")
graph save "Graph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_11.gph", replace

graph combine "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_1.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_2.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_3.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_4.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_5.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_6.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_7.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_8.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_9.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_10.gph" "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/graph_om_women_11.gph"

save, replace
