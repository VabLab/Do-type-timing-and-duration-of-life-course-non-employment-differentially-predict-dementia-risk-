**********Data Cleaning for Occupation Trajectories Project
**********Author: Lucia Pacca
**********Code Reviewer: Amina Gaye
**********Project Description

**********This .do file (Data Cleaning) includes:
**********1) Selecting variables and datasets from HRS (lines 9-42): tracker, LHM, and individual files from Core Surveys

**********2) Clean job trajectories from individual Core Survey Files: 1992-2018 (lines 44-4003)

**********3)Merge all core survey files together and with tracker (lines 4005-4067)

**********4)Clean LHMS file: education trajectories and lifecourse employment trajectories (lines 4069-4881)

**********5)Merge Core Survey files with LHMS and set rukes to define final employment trajectories (lines 4883-5291)  

clear
cd "C:\Users\lpacca\Box\01 - Occupation Trajectories\data"

use lhms1517a_r, clear
gen key=hhid+pn
sort key

bysort key: gen dup=cond(_N==1, 0, _n)
tab dup //there are no duplicates

save, replace

use trk2018tr_r, clear
gen key=HHID+PN
sort key
save, replace

merge 1:1 key using lhms1517a_r //all observations match (merge=3)
drop _merge

save trk_lhms_merged, replace

*********Extract employment data from HRS Core Surveys
//CHANGE FILES!
clear
set more off
foreach data in W2FA W2FB W2FC W2G W2H A95G_R H96G_R H98G_R H00G_R H02L_R H02J_R H02K_R H04L_R H04J_R H04K_R H06L_R H06J_R H06K_R H08L_R H08J_R H08K_R H10L_R H10J_R H10K_R H12L_R H12J_R H12K_R H14L_R H14J_R H14K_R H16J_R BR21 EMPLOYER{
global path "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS"
infile using "$path/`data'.dct", using("$path/`data'.DA")
save "$path/`data'.dta", replace
clear
}

************1992
//Current/previous jobs + up to three jobs

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/EMPLOYER.dta", clear
keep HHID PN V2701 V2702 V2703 V2704 V2705 V2706 V2707 V2709 V2708 V2711 V2712 V2713 V2714 V2715 V2716 V2717 V2718 V2816 V2834 V3402 V3403 V3418 V3442 V3604 V3607 V3704 V3705 V3804 V3805 V2722 V3408
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1992.dta", replace
****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported

foreach var of varlist V2701 V2702 V2703 V2704 V2705 V2706 V2707 V2708 V2709 V2711 V2712 V2713 V2714 V2715 V2716 V2717 V2718 V2816 V2834 V3402 V3403 V3418 V3442 V3604 V3607 V3704 V3705 V3804 V3805{
replace `var'=. if `var'==0
}

foreach var of varlist V2701 V2702 V2703 V2704 V2705 V2706 V2707 V2708 V2709 V2711 V2712 V2713 V2714 V2715 V2716 V2717 V2718 V2816 V2834 V3402 V3403 V3418 V3442 V3604 V3607 V3704 V3705 V3804 V3805{
replace `var'=. if `var'>=9997
}

foreach var of varlist V2708 V2711 V2715 V3402 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=1992-BIRTHYR

***define age unemployment
gen age_unemployed=V2709-BIRTHYR

***define age retirement
gen age_retired=V2716-BIRTHYR

***define age disabled
gen age_disabled=V2714-BIRTHYR

***define age start temp leave
gen age_temp_leave=V2712-BIRTHYR

***define age start current job
gen age_current_job=V2816-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=V3418-BIRTHYR

gen age_end_previous_job=V3403-BIRTHYR

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=V3604-BIRTHYR if V3604>BIRTHYR

gen age_end_past_job1=V3607-BIRTHYR

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=V3704-BIRTHYR
gen age_end_past_job2=V3705-BIRTHYR

gen age_start_past_job3=V3804-BIRTHYR
gen age_end_past_job3=V3805-BIRTHYR

**Make is consistent so that job3 is more recent than job2
edit age_start_past_job1-age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3

gen age_end_past_job2_corr=age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=V2708-BIRTHMO 
gen diff_month_disabled=V2713-BIRTHMO 
gen diff_month_retired=V2715-BIRTHMO 
gen diff_month_laid_off=V2711-BIRTHMO 

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="temp_leave" if V2703==1
replace current_status="disabled" if V2704==1
replace current_status="retired" if V2705==1
replace current_status="working" if V2701==1

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

*****Look at # hours worked in previous and current job for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if V2722!=0 & V2722<30 

gen previous_job_part_time=0
replace previous_job_part_time=1 if V3408!=0 & V3408<30

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
    replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}


********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1992=rowtotal(state_info16-state_info65)

save, replace

*****************************1993 - AHEAD COHORT
//No current work status or job history information. 
//We olny know whether they are currently working and, if not, their job in the last 2 years.

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/BR21.dta", clear
keep HHID PN V1174 V1175 V1178 V1182 V1183 V1184 V1207 V1208 V1221 V1222 V1223 V1232 V1235 V1186 V1225
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1993.dta", replace
****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist V1174 V1175 V1178 V1182 V1183 V1184 V1207 V1208 V1221 V1222 V1223 V1232 V1235 {
replace `var'=. if `var'>=9997
replace `var'=. if `var'==0
}

foreach var of varlist V1183 V1184 V1222 V1223 {
replace `var'=. if `var'>=97
}

**Define current age
gen current_age=1993-BIRTHYR

***define age start current job
gen age_current_job=V1182-BIRTHYR
replace age_current_job=1994-V1183-BIRTHYR if V1183!=. & V1182==.
replace age_current_job=V1184 if V1184!=. & V1182==.

***define age start and end of previous job
gen age_previous_job=V1221-BIRTHYR
replace age_previous_job=1994-V1222-BIRTHYR if V1222!=.
replace age_previous_job=V1223 if V1223!=.

gen age_end_previous_job=V1208-BIRTHYR

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if V1174==1

*****Look at # hours worked in previous and current job for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if V1186!=0 & V1186<30 

gen previous_job_part_time=0
replace previous_job_part_time=1 if V1225!=0 & V1225<30

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	}
}


***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
}
}

foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
}

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1993=rowtotal(state_info16-state_info65)

save, replace

*****************************1994

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/W2FA.dta", clear
keep HHID PN W3300 W3301 W3302 W3307 W3308 W3310 W3311 W3312 W3313 W3314 W3315 W3316 W3317 W3318 W3319 W3458 W3503 W3504 W3662 W3663 W3617
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FA.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/W2FB.dta", clear
keep HHID PN W4200 W4201 W4327 W4328
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FB.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/W2FC.dta", clear
keep HHID PN W4800 W4801 W4897 W4898
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FC.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/W2G.dta", clear
keep HHID PN W7002 W7003 W7004 W7018 W7019 W7020 W7008
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2G.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/W2H.dta", clear
keep HHID PN W7103 W7104 W7105 W7108 W7109 W7110 W7162 W7163 W7196 W7197
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2H.dta", replace
gen key=HHID+PN
sort key
save, replace
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2G.dta"
drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FC.dta"
drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FB.dta"
drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994_W2FA.dta"
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994.dta", replace


****Merge with tracker for birth dates
capture drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported

foreach var of varlist W3300 W3301 W3302 W3307 W3308 W3310 W3311 W3313 W3314 W3315 W3316 W3317 W3318 W3319 W3458 W3503 W3504 W3662 W3663 W4200 W4201 W4327 W4328 W3311 W4800 W4801 W4897 W4898 W7002 W7003 W7004 W7018 W7019 W7020 W7103 W7104 W7105 W7108 W7109 W7110 W7162 W7163 W7196 W7197 {
replace `var'=. if `var'==0
}

foreach var of varlist W3308 W3310 W3313 W3315 W7002 W3663 W7018 W7103 W7108 W7162 W7163 W7196 W7197{
replace `var'=. if `var'>=9997
}

foreach var of varlist W7004 W7019 W7020 W7019 W7020 W7003 W7004 W7104 W7105 W7109 W7110 W3307 W3312 W3314 W3310 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=1994-BIRTHYR

***define age unemployment
gen age_unemployed=W3308-BIRTHYR

***define age retirement
gen age_retired=W3315-BIRTHYR

***define age disabled
gen age_disabled=W3313-BIRTHYR

***define age start temp leave
gen age_temp_leave=W3311-BIRTHYR

***define age start current job
gen age_current_job=W3663-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=W7018-BIRTHYR
replace age_previous_job=1994-W7019-BIRTHYR if W7019!=.
replace age_previous_job=W7020 if W7020!=.

gen age_end_previous_job=W7002-BIRTHYR
replace age_end_previous_job=1994-W7003-BIRTHYR if W7003!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=W7103-BIRTHYR if W7103>BIRTHYR
replace age_start_past_job1=1994-W7104-BIRTHYR if W7104!=. & W7104<current_age
replace age_start_past_job1=W7105 if W7105!=.

gen age_end_past_job1=W7108-BIRTHYR
replace age_end_past_job1=1994-W7109-BIRTHYR if W7109!=.
replace age_end_past_job1=W7110 if W7110!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=W7162-BIRTHYR
gen age_end_past_job2=W7163-BIRTHYR

gen age_start_past_job3=W7196-BIRTHYR
gen age_end_past_job3=W7197-BIRTHYR

**Make is consistent so that job3 is more recent than job2
edit age_start_past_job1-age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3

gen age_end_past_job2_corr=age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=W3307-BIRTHMO 
gen diff_month_disabled=W3312-BIRTHMO 
gen diff_month_retired=W3314-BIRTHMO 
gen diff_month_laid_off=W3310-BIRTHMO 

*****Look at # hours worked in previous and current job for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if W3617!=0 & W3617<30 

gen previous_job_part_time=0
replace previous_job_part_time=1 if W7008!=0 & W7008<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if W3300==1 & W3301==.
replace current_status="working" if W3300==1 & W3301!=. & age_current_job!=.
replace current_status="working" if W3300==1 & W3301!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if W3301==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if W3301==1 & age_current_job!=.
replace current_status="working" if W3302==1 & age_current_job!=.

replace current_status="retired" if W3300==5 & W3301==.
replace current_status="retired" if W3300==1 & W3301==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if W3300==5 & age_current_job==.
replace current_status="retired" if W3300==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if W3300==6 & W3301==5 & current_status!="working"
replace current_status="retired" if W3300==3 & W3301==5 & age_retired!=.
replace current_status="retired" if W3300==4 & W3301==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if W3300==6 & W3301==4 & W3302==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if W3300==2 & W3301==5 & age_retired!=.
replace current_status="retired" if W3300==7 & W3301==5

replace current_status="disabled" if W3300==4 & W3301==.
replace current_status="disabled" if W3300==4 & W3301!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if W3300==4 & W3301!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if W3300==4 & W3301!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if W3300==6 & W3301==4 & age_disabled!=.
replace current_status="disabled" if W3300==4 & W3301!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if W3300==3 & W3301==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if W3300==7 & W3301==5

replace current_status="unemployed" if W3300==2 & W3301==.
replace current_status="unemployed" if W3300==2 & W3301==3 & W3302==.
replace current_status="unemployed" if W3300==2 & W3301==6 & W3302==.
replace current_status="unemployed" if W3300==2 & W3301==4 & current_status=="."
replace current_status="unemployed" if W3300==2 & W3301!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if W3300==6 & W3301==2
replace current_status="unemployed" if W3300==3 & W3301==2 & age_unemployed!=.
replace current_status="unemployed" if W3300==7 & W3301==2

replace current_status="temp_leave" if W3300==3 & W3301==.
replace current_status="temp_leave" if W3300==3 & W3301==6 & W3302==.
replace current_status="temp_leave" if W3300==3 & W3301==7 & W3302==.
replace current_status="temp_leave" if W3300==1 & W3301==3 & age_temp_leave!=.
replace current_status="temp_leave" if W3300==3 & W3301==1 & age_temp_leave!=.
replace current_status="temp_leave" if W3300==6 & W3301==3 & age_temp_leave!=.
replace current_status="temp_leave" if W3300==3 & W3301==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if W3300==7 & W3301==3

replace current_status="homemaker" if W3300==6 & W3301==. 
replace current_status="homemaker" if W3300==6 & W3301!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if W3300==7 & W3301==6

replace current_status="working" if W3300==7 & W3301==. & age_current_job!=.
replace current_status="working" if W3300==1 & current_status=="."

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
    replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1994=rowtotal(state_info16-state_info65)

save, replace

*****************************1995 - AHEAD COHORT
//No job history information
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/A95G_R.dta", clear
keep HHID PN D2626M1 D2626M2 D2626M3 D2627 D2628 D2633 D2634 D2638 D2639 D2643 D2644 D2651 D2653 D2654 D2655 D2747 D2759 D2760 D2831 D2832 D3188 D3189 D3545 D3546 D3639 D3640 D2836
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1995.dta", replace
****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist D2628 D2634 D2639 D2643 D2832 D2627 D2836 {
replace `var'=. if `var'>=9997
}

foreach var of varlist D2638 D2644 D2633 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=1995-BIRTHYR

***define age unemployment
gen age_unemployed=D2628-BIRTHYR

***define age retirement
gen age_retired=D2643-BIRTHYR

***define age disabled
gen age_disabled=D2639-BIRTHYR

***define age start temp leave
gen age_temp_leave=D2634-BIRTHYR

***define age start current job
gen age_current_job=D2832-BIRTHYR

**Determine year of unemployment, disability, retirement or temp leave based on birth month
gen diff_month_unemployed=D2627-BIRTHMO 
gen diff_month_disabled=D2638-BIRTHMO 
gen diff_month_retired=D2644-BIRTHMO 
gen diff_month_laid_off=D2633-BIRTHMO 

*****Look at # hours worked in current job for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if D2836!=0 & D2836<30 

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if D2626M1==1 & D2626M2==.
replace current_status="working" if D2626M1==1 & D2626M2!=. & age_current_job!=.
replace current_status="working" if D2626M1==1 & D2626M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if D2626M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if D2626M2==1 & age_current_job!=.
replace current_status="working" if D2626M3==1 & age_current_job!=.

replace current_status="retired" if D2626M1==5 & D2626M2==.
replace current_status="retired" if D2626M1==1 & D2626M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if D2626M1==5 & age_current_job==.
replace current_status="retired" if D2626M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if D2626M1==6 & D2626M2==5 & current_status!="working"
replace current_status="retired" if D2626M1==3 & D2626M2==5 & age_retired!=.
replace current_status="retired" if D2626M1==4 & D2626M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if D2626M1==6 & D2626M2==4 & D2626M3==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if D2626M1==2 & D2626M2==5 & age_retired!=.
replace current_status="retired" if D2626M1==7 & D2626M2==5

replace current_status="disabled" if D2626M1==4 & D2626M2==.
replace current_status="disabled" if D2626M1==4 & D2626M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if D2626M1==4 & D2626M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if D2626M1==4 & D2626M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if D2626M1==6 & D2626M2==4 & age_disabled!=.
replace current_status="disabled" if D2626M1==4 & D2626M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if D2626M1==3 & D2626M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if D2626M1==7 & D2626M2==5

replace current_status="unemployed" if D2626M1==2 & D2626M2==.
replace current_status="unemployed" if D2626M1==2 & D2626M2==3 & D2626M3==.
replace current_status="unemployed" if D2626M1==2 & D2626M2==6 & D2626M3==.
replace current_status="unemployed" if D2626M1==2 & D2626M2==4 & current_status=="."
replace current_status="unemployed" if D2626M1==2 & D2626M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if D2626M1==6 & D2626M2==2
replace current_status="unemployed" if D2626M1==3 & D2626M2==2 & age_unemployed!=.
replace current_status="unemployed" if D2626M1==7 & D2626M2==2

replace current_status="temp_leave" if D2626M1==3 & D2626M2==.
replace current_status="temp_leave" if D2626M1==3 & D2626M2==6 & D2626M3==.
replace current_status="temp_leave" if D2626M1==3 & D2626M2==7 & D2626M3==.
replace current_status="temp_leave" if D2626M1==1 & D2626M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if D2626M1==3 & D2626M2==1 & age_temp_leave!=.
replace current_status="temp_leave" if D2626M1==6 & D2626M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if D2626M1==3 & D2626M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if D2626M1==7 & D2626M2==3

replace current_status="homemaker" if D2626M1==6 & D2626M2==. 
replace current_status="homemaker" if D2626M1==6 & D2626M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if D2626M1==7 & D2626M2==6

replace current_status="working" if D2626M1==7 & D2626M2==. & age_current_job!=.
replace current_status="working" if D2626M1==1 & current_status=="."

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	*replace state`j'="start_previous_work" if age_previous_job==`j' 
	*replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	*replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	*replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	*replace state`j'="start_past_work3" if age_start_past_job3==`j'
	*replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	*replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	*replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	*replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" 
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed"
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	*replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	*replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	*replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	*replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	*replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	*replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	*replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
*replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
*replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
*replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
*replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
*replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1995=rowtotal(state_info16-state_info65)

save, replace


*****************************1996
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H96G_R.dta", clear
keep HHID PN E2611M1 E2611M2 E2611M3 E2612 E2613 E2616 E2617 E2619 E2620 E2622 E2623 E2627 E2628 E2630 E2631 E2654 E2655 E2667 E2668 E2673M1 E2673M2 E2673M3 E2825 E2826 E3127 E3128 E3129 E3146 E3147 E3148 E3153M1 E3153M2 E3325 E3329 E3330 E3331 E3337 E3338 E3339 E3347M1 E3347M2 E2736 E3135
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1996.dta", replace
****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist E2613 E2617 E2620 E2623 E3127 E3146 E3329 E3337 E2826 {
replace `var'=. if `var'>=9997
}

foreach var of varlist E3148 E3331 E3339 E3128 E3330 E3338 E2612 E2619 	E2622 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=1996-BIRTHYR

***define age unemployment
replace E2613=. if E2613==9998
gen age_unemployed=E2613-BIRTHYR

***define age retirement
replace E2623=. if E2623>=9997
gen age_retired=E2623-BIRTHYR

***define age disabled
replace E2620=. if E2620>=9997
gen age_disabled=E2620-BIRTHYR

***define age start temp leave
replace E2617=. if E2617==9998
gen age_temp_leave=E2617-BIRTHYR

***define age start current job
replace E2826=. if E2826>=9997
gen age_current_job=E2826-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=E3146-BIRTHYR
replace age_previous_job=1996-E3147-BIRTHYR if E3147!=.
replace age_previous_job=E3148 if E3148!=.

gen age_end_previous_job=E3127-BIRTHYR
replace age_end_previous_job=1996-E3128-BIRTHYR if E3128!=.
replace age_end_previous_job=E3129 if E3129!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job>=5 years
gen age_start_past_job1=E3329-BIRTHYR
replace age_start_past_job1=1996-E3330-BIRTHYR if E3330!=.
replace age_start_past_job1=E3331 if E3331!=.

gen age_end_past_job1=E3337-BIRTHYR
replace age_end_past_job1=1996-E3338-BIRTHYR if E3338!=.
replace age_end_past_job1=E3339 if E3339!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

//1996 ONLY HAS ONE PAST JOB - NO JOBS # 2 and 3

**Determine year of unemployment, disability, retirement or temp leave based on birth month
gen diff_month_unemployed=E2612-BIRTHMO 
gen diff_month_disabled=E2619-BIRTHMO 
gen diff_month_retired=E2622-BIRTHMO 
gen diff_month_laid_off=E2616-BIRTHMO 

*****Look at # hours worked in previous and current job for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if E2736!=0 & E2736<30 

gen previous_job_part_time=0
replace previous_job_part_time=1 if E3135!=0 & E3135<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if E2611M1==1 & E2611M2==.
replace current_status="working" if E2611M1==1 & E2611M2!=. & age_current_job!=.
replace current_status="working" if E2611M1==1 & E2611M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if E2611M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if E2611M2==1 & age_current_job!=.
replace current_status="working" if E2611M3==1 & age_current_job!=.

replace current_status="retired" if E2611M1==5 & E2611M2==.
replace current_status="retired" if E2611M1==1 & E2611M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if E2611M1==5 & age_current_job==.
replace current_status="retired" if E2611M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if E2611M1==6 & E2611M2==5 & current_status!="working"
replace current_status="retired" if E2611M1==3 & E2611M2==5 & age_retired!=.
replace current_status="retired" if E2611M1==4 & E2611M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if E2611M1==6 & E2611M2==4 & E2611M3==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if E2611M1==2 & E2611M2==5 & age_retired!=.
replace current_status="retired" if E2611M1==7 & E2611M2==5

replace current_status="disabled" if E2611M1==4 & E2611M2==.
replace current_status="disabled" if E2611M1==4 & E2611M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if E2611M1==4 & E2611M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if E2611M1==4 & E2611M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if E2611M1==6 & E2611M2==4 & age_disabled!=.
replace current_status="disabled" if E2611M1==4 & E2611M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if E2611M1==3 & E2611M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if E2611M1==7 & E2611M2==5

replace current_status="unemployed" if E2611M1==2 & E2611M2==.
replace current_status="unemployed" if E2611M1==2 & E2611M2==3 & E2611M3==.
replace current_status="unemployed" if E2611M1==2 & E2611M2==6 & E2611M3==.
replace current_status="unemployed" if E2611M1==2 & E2611M2==4 & current_status=="."
replace current_status="unemployed" if E2611M1==2 & E2611M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if E2611M1==6 & E2611M2==2
replace current_status="unemployed" if E2611M1==3 & E2611M2==2 & age_unemployed!=.
replace current_status="unemployed" if E2611M1==7 & E2611M2==2

replace current_status="temp_leave" if E2611M1==3 & E2611M2==.
replace current_status="temp_leave" if E2611M1==3 & E2611M2==6 & E2611M3==.
replace current_status="temp_leave" if E2611M1==3 & E2611M2==7 & E2611M3==.
replace current_status="temp_leave" if E2611M1==1 & E2611M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if E2611M1==3 & E2611M2==1 & age_temp_leave!=.
replace current_status="temp_leave" if E2611M1==6 & E2611M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if E2611M1==3 & E2611M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if E2611M1==7 & E2611M2==3

replace current_status="homemaker" if E2611M1==6 & E2611M2==. 
replace current_status="homemaker" if E2611M1==6 & E2611M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if E2611M1==7 & E2611M2==6

replace current_status="working" if E2611M1==7 & E2611M2==. & age_current_job!=.
replace current_status="working" if E2611M1==1 & current_status=="."

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	*replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	*replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	*replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	*replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	*replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	*replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

*replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
*replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
*replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
*replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

*replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
*replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}


foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1996=rowtotal(state_info16-state_info65)

save, replace

**************************************************************************1998
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H98G_R.dta", clear
keep HHID PN F3115M1 F3115M2 F3115M3 F3116 F3117 F3120 F3121 F3123 F3124 F3126 F3127 F3131 F3132 F3134 F3135 F3158 F3166 F3188 F3189 F3348 F3349 F3644 F3645 F3647 F3664 F3665 F3666 F3811 F3834 F3835 F3836 F3842 F3843 F3844 F3903_1 F3903_2 F3904_1 F3904_2 F3259 F3653 F3847
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1998.dta", replace

****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist F3117 F3127 F3124 F3121 F3349 F3349 F3644 F3664 F3811 F3834 F3842 F3903_1 F3903_2 F3904_1 F3904_2 {
replace `var'=. if `var'>=9997
}

foreach var of varlist F3836 F3844 F3645 F3835 F3843 F3116 F3123 F3126 F3115* F3665 F3666 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=1998-BIRTHYR

***define age unemployment
gen age_unemployed=F3117-BIRTHYR

***define age retirement
gen age_retired=F3127-BIRTHYR

***define age disabled
gen age_disabled=F3124-BIRTHYR

***define age start temp leave
gen age_temp_leave=F3121-BIRTHYR

***define age start current job
gen age_current_job=F3349-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=F3664-BIRTHYR
replace age_previous_job=1998-F3665-BIRTHYR if F3665!=.
replace age_previous_job=F3666 if F3666!=. 

gen age_end_previous_job=F3811-BIRTHYR

*There are some obs where end of job 1<start of job 1 - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=.
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=F3834-BIRTHYR
replace age_previous_job=1998-F3835-BIRTHYR if F3835!=.
replace age_previous_job=F3836 if F3836!=. 

gen age_end_past_job1=F3842-BIRTHYR
replace age_end_past_job1=1998-F3843-BIRTHYR if F3843!=.
replace age_end_past_job1=F3844 if F3844!=. 

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=F3903_1-BIRTHYR
gen age_end_past_job2=F3904_1-BIRTHYR

gen age_start_past_job3=F3903_2-BIRTHYR
gen age_end_past_job3=F3904_2-BIRTHYR

**Make it consistent so that job3 is more recent than job2
gen age_end_past_job2_corr=age_end_past_job3 if F3115M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if F3115M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if F3115M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if F3115M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.

drop age_end_past_job2_corr age_start_past_job2_corr

**Determine year of unemployment, disability, retirement or temp leave based on birth month
gen diff_month_unemployed=F3116-BIRTHMO 
gen diff_month_disabled=F3123-BIRTHMO 
gen diff_month_retired=F3126-BIRTHMO 
gen diff_month_laid_off=F3120-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if F3259!=0 & F3259<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if F3653!=0 & F3653<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if F3847!=0 & F3847<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if F3115M1==1 & F3115M2==.
replace current_status="working" if F3115M1==1 & F3115M2!=. & age_current_job!=.
replace current_status="working" if F3115M1==1 & F3115M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if F3115M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if F3115M2==1 & age_current_job!=.
replace current_status="working" if F3115M3==1 & age_current_job!=.

replace current_status="retired" if F3115M1==5 & F3115M2==.
replace current_status="retired" if F3115M1==1 & F3115M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if F3115M1==5 & age_current_job==.
replace current_status="retired" if F3115M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if F3115M1==6 & F3115M2==5 & current_status!="working"
replace current_status="retired" if F3115M1==3 & F3115M2==5 & age_retired!=.
replace current_status="retired" if F3115M1==4 & F3115M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if F3115M1==2 & F3115M2==5 & age_retired!=.
replace current_status="retired" if F3115M1==7 & F3115M2==5
replace current_status="retired" if F3115M1==2 & F3115M2==3 & F3115M3==5 & age_retired>age_unemployed & age_retired<=current_age

replace current_status="disabled" if F3115M1==4 & F3115M2==.
replace current_status="disabled" if F3115M1==4 & F3115M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if F3115M1==4 & F3115M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if F3115M1==4 & F3115M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if F3115M1==6 & F3115M2==4 & age_disabled!=.
replace current_status="disabled" if F3115M1==4 & F3115M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if F3115M1==3 & F3115M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if F3115M1==7 & F3115M2==4

replace current_status="unemployed" if F3115M1==2 & F3115M2==.
replace current_status="unemployed" if F3115M1==2 & F3115M2==3 & F3115M3==.
replace current_status="unemployed" if F3115M1==2 & F3115M2==4 & current_status=="."
replace current_status="unemployed" if F3115M1==2 & F3115M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if F3115M1==6 & F3115M2==2
replace current_status="unemployed" if F3115M1==3 & F3115M2==2 & age_unemployed!=.
replace current_status="unemployed" if F3115M1==7 & F3115M2==2

replace current_status="temp_leave" if F3115M1==3 & F3115M2==.
replace current_status="temp_leave" if F3115M1==3 & F3115M2==6 & F3115M3==.
replace current_status="temp_leave" if F3115M1==3 & F3115M2==7 & F3115M3==.
replace current_status="temp_leave" if F3115M1==1 & F3115M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if F3115M1==6 & F3115M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if F3115M1==3 & F3115M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if F3115M1==7 & F3115M2==3

replace current_status="homemaker" if F3115M1==6 & F3115M2==. 
replace current_status="homemaker" if F3115M1==6 & F3115M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if F3115M1==7 & F3115M2==6

replace current_status="working" if F3115M1==7 & F3115M2==. & age_current_job!=.
replace current_status="working" if F3115M1==1 & current_status=="."

*edit state* age* MJ00* current_age if F3115M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
    replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}


********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_1998=rowtotal(state_info16-state_info65)

save, replace

*******************
*******************2000

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H00G_R.dta", clear

keep HHID PN G3365M1 G3365M2 G3365M3 G3366 G3367 G3370 G3371 G3373 G3374 G3376 G3377 G3381 G3382 G3384 G3385 G3416 G3437 G3438 G3607 G3608 G3954 G3955 G3957 G3974 G3975 G3976 G4080 G4096 G4097 G4098 G4104 G4105 G4106 G4176_1 G4176_2 G4177_1 G4177_2 G3509 G3963 G4109
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2000.dta", replace

****Merge with tracker for birth dates
gen key=HHID+PN
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist G3367 G3370 G3371 G3373 G3374 G3376 G3377 G3381 G3382 G3384 G3385 G3416 G3437 G3438 G3607 G3608 G3954 G3955 G3957 G3974 G3975 G3976 G4080 G4096 G4097 G4098 G4104 G4105 G4106 G4176_1 G4176_2 G4177_1 G4177_2  {
replace `var'=. if `var'>=9997
}

foreach var of varlist G4098 G3955 G4097 G4105 G3366 G3373 G3376 G3975 G3976 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=2000-BIRTHYR

***define age unemployment
gen age_unemployed=G3367-BIRTHYR

***define age retirement
gen age_retired=G3377-BIRTHYR

***define age disabled
gen age_disabled=G3374-BIRTHYR

***define age start temp leave
gen age_temp_leave=G3371-BIRTHYR

***define age start current job
gen age_current_job=G3608-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=G3974-BIRTHYR
replace age_previous_job=2000-G3975-BIRTHYR if G3975!=.
replace age_previous_job=G3976 if G3976!=. 

gen age_end_previous_job=G4080-BIRTHYR

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=G4096-BIRTHYR
replace age_start_past_job1=2000-G4097-BIRTHYR if G4097!=.
replace age_start_past_job1=G4098 if G4098!=. 

gen age_end_past_job1=G4104-BIRTHYR
replace age_end_past_job1=2000-G4105-BIRTHYR if G4105!=.
replace age_end_past_job1=G4106 if G4106!=. 

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=G4176_1-BIRTHYR
gen age_end_past_job2=G4177_1-BIRTHYR

gen age_start_past_job3=G4176_2-BIRTHYR
gen age_end_past_job3=G4177_2-BIRTHYR

**Make it consistent so that job3 is more recent than job2
gen age_end_past_job2_corr=age_end_past_job3 if G3365M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if G3365M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if G3365M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if G3365M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.

drop age_end_past_job2_corr age_start_past_job2_corr

**Determine year of unemployment, disability, retirement or temp leave based on birth month
gen diff_month_unemployed=G3366-BIRTHMO 
gen diff_month_disabled=G3373-BIRTHMO 
gen diff_month_retired=G3376-BIRTHMO 
gen diff_month_laid_off=G3370-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if G3509!=0 & G3509<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if G3963!=0 & G3963<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if G4109!=0 & G4109<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if G3365M1==1 & G3365M2==.
replace current_status="working" if G3365M1==1 & G3365M2!=. & age_current_job!=.
replace current_status="working" if G3365M1==1 & G3365M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if G3365M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if G3365M2==1 & age_current_job!=.
replace current_status="working" if G3365M3==1 & age_current_job!=.

replace current_status="retired" if G3365M1==5 & G3365M2==.
replace current_status="retired" if G3365M1==1 & G3365M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if G3365M1==5 & age_current_job==.
replace current_status="retired" if G3365M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if G3365M1==6 & G3365M2==5 & current_status!="working"
replace current_status="retired" if G3365M1==3 & G3365M2==5 & age_retired!=.
replace current_status="retired" if G3365M1==4 & G3365M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if G3365M1==2 & G3365M2==5 & age_retired!=.
replace current_status="retired" if G3365M1==7 & G3365M2==5
replace current_status="retired" if G3365M1==2 & G3365M2==3 & G3365M3==5 & age_retired>age_unemployed & age_retired<=current_age

replace current_status="disabled" if G3365M1==4 & G3365M2==.
replace current_status="disabled" if G3365M1==4 & G3365M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if G3365M1==4 & G3365M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if G3365M1==4 & G3365M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if G3365M1==6 & G3365M2==4 & age_disabled!=.
replace current_status="disabled" if G3365M1==4 & G3365M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if G3365M1==3 & G3365M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if G3365M1==7 & G3365M2==4

replace current_status="unemployed" if G3365M1==2 & G3365M2==.
replace current_status="unemployed" if G3365M1==2 & G3365M2==3 & G3365M3==.
replace current_status="unemployed" if G3365M1==2 & G3365M2==4 & current_status=="."
replace current_status="unemployed" if G3365M1==2 & G3365M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if G3365M1==6 & G3365M2==2
replace current_status="unemployed" if G3365M1==3 & G3365M2==2 & age_unemployed!=.
replace current_status="unemployed" if G3365M1==7 & G3365M2==2

replace current_status="temp_leave" if G3365M1==3 & G3365M2==.
replace current_status="temp_leave" if G3365M1==3 & G3365M2==6 & G3365M3==.
replace current_status="temp_leave" if G3365M1==3 & G3365M2==7 & G3365M3==.
replace current_status="temp_leave" if G3365M1==1 & G3365M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if G3365M1==6 & G3365M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if G3365M1==3 & G3365M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if G3365M1==7 & G3365M2==3

replace current_status="homemaker" if G3365M1==6 & G3365M2==. 
replace current_status="homemaker" if G3365M1==6 & G3365M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if G3365M1==7 & G3365M2==6

replace current_status="working" if G3365M1==7 & G3365M2==. & age_current_job!=.
replace current_status="working" if G3365M1==1 & current_status=="."

*edit state* age* MJ00* current_age if G3365M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.


***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
    replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}


foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}


********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2000=rowtotal(state_info16-state_info65)

save, replace


*******************
*******************2002
*******************Here job info is split between 3 different files

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H02L_R.dta", clear
keep HHID PN HL078_1 HL078_2 HL079_1 HL079_2 HL009 HL010 HL011 HL016 HL017 HL018 HL020 //past job # 1
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002_L.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H02K_R.dta", clear
keep HHID PN HK002 HK018 HK019 HK020 HK003 HK004 HK008 //previous job
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002_K.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H02J_R.dta", clear
keep HHID PN HJ005M1 HJ005M2 HJ005M3 HJ005M4 HJ005M5 HJ007 HJ008 HJ011 HJ012 HJ014 HJ015 HJ017 HJ018 HJ020 HJ021 HJ023 HJ249 HJ172 //current job
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002_J.dta", replace
gen key=HHID+PN
sort key
save, replace
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002_K.dta"
drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002_L.dta"
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002.dta", replace

******merge with tracker
sort key
drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist HJ008 HJ012 HJ015 HJ018 HK002 HK018 HL009 HL016 HL078_1 HL079_1 HL078_2 HL079_2 HJ249 {
replace `var'=. if `var'>=9997
}

foreach var of varlist HK020 HL011 HL018 HK003 HL010 HL017 HJ007 HJ014 HJ017 {
replace `var'=. if `var'>=98
}

**Define current age
gen current_age=2002-BIRTHYR

***define age unemployment
gen age_unemployed=HJ008-BIRTHYR

***define age retirement
gen age_retired=HJ018-BIRTHYR

***define age disabled
gen age_disabled=HJ015-BIRTHYR

***define age start temp leave
gen age_temp_leave=HJ012-BIRTHYR

***define age start current job
gen age_current_job=HJ249-BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=HK018-BIRTHYR
replace age_previous_job=2002-HK019-BIRTHYR if HK019!=.
replace age_previous_job=HK020 if HK020!=.

gen age_end_previous_job=HK002-BIRTHYR

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=HL009-BIRTHYR
replace age_start_past_job1=2002-HL010-BIRTHYR if HL010!=.
replace age_start_past_job1=HL011 if HL011!=.

gen age_end_past_job1=HL016-BIRTHYR
replace age_end_past_job1=2002-HL017-BIRTHYR if HL017!=.
replace age_end_past_job1=HL018 if HL018!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=HL078_1-BIRTHYR
gen age_end_past_job2=HL079_1-BIRTHYR

gen age_start_past_job3=HL078_2-BIRTHYR
gen age_end_past_job3=HL079_2-BIRTHYR

**Make it consistent so that job3 is more recent than job2
gen age_end_past_job2_corr=age_end_past_job3 if HJ005M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if HJ005M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if HJ005M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if HJ005M1==1 & age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.

drop age_end_past_job2_corr age_start_past_job2_corr

**Determine year of unemployment, disability, retirement or temp leave based on birth month
gen diff_month_unemployed=HJ007-BIRTHMO 
gen diff_month_disabled=HJ014-BIRTHMO 
gen diff_month_retired=HJ017-BIRTHMO 
gen diff_month_laid_off=HJ011-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if HJ172!=0 & HJ172<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if HK008!=0 & HK008<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if HL020!=0 & HL020<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if HJ005M1==1 & HJ005M2==.
replace current_status="working" if HJ005M1==1 & HJ005M2!=. & age_current_job!=.
replace current_status="working" if HJ005M1==1 & HJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if HJ005M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if HJ005M2==1 & age_current_job!=.
replace current_status="working" if HJ005M3==1 & age_current_job!=.

replace current_status="retired" if HJ005M1==5 & HJ005M2==.
replace current_status="retired" if HJ005M1==1 & HJ005M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if HJ005M1==5 & age_current_job==.
replace current_status="retired" if HJ005M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if HJ005M1==6 & HJ005M2==5 & current_status!="working"
replace current_status="retired" if HJ005M1==6 & HJ005M2==4 & HJ005M3==5 & age_disabled==. & age_retired!=.
replace current_status="retired" if HJ005M1==3 & HJ005M2==5 & age_retired!=.
replace current_status="retired" if HJ005M1==4 & HJ005M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if HJ005M1==2 & HJ005M2==5 & age_retired!=.
replace current_status="retired" if HJ005M1==7 & HJ005M2==5
replace current_status="retired" if HJ005M1==2 & HJ005M2==3 & HJ005M3==5 & age_retired>age_unemployed & age_retired<=current_age

replace current_status="disabled" if HJ005M1==4 & HJ005M2==.
replace current_status="disabled" if HJ005M1==4 & HJ005M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if HJ005M1==4 & HJ005M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if HJ005M1==4 & HJ005M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if HJ005M1==6 & HJ005M2==4 & age_disabled!=.
replace current_status="disabled" if HJ005M1==4 & HJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if HJ005M1==3 & HJ005M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if HJ005M1==7 & HJ005M2==4

replace current_status="unemployed" if HJ005M1==2 & HJ005M2==.
replace current_status="unemployed" if HJ005M1==2 & HJ005M2==3 & HJ005M3==.
replace current_status="unemployed" if HJ005M1==2 & HJ005M2==4 & current_status=="."
replace current_status="unemployed" if HJ005M1==2 & HJ005M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if HJ005M1==6 & HJ005M2==2
replace current_status="unemployed" if HJ005M1==3 & HJ005M2==2 & age_unemployed!=.
replace current_status="unemployed" if HJ005M1==7 & HJ005M2==2

replace current_status="temp_leave" if HJ005M1==3 & HJ005M2==.
replace current_status="temp_leave" if HJ005M1==3 & HJ005M2==6 & HJ005M3==.
replace current_status="temp_leave" if HJ005M1==3 & HJ005M2==7 & HJ005M3==.
replace current_status="temp_leave" if HJ005M1==1 & HJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if HJ005M1==6 & HJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if HJ005M1==3 & HJ005M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if HJ005M1==7 & HJ005M2==3

replace current_status="homemaker" if HJ005M1==6 & HJ005M2==. 
replace current_status="homemaker" if HJ005M1==6 & HJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if HJ005M1==7 & HJ005M2==6

replace current_status="working" if HJ005M1==7 & HJ005M2==. & age_current_job!=.
replace current_status="working" if HJ005M1==1 & current_status=="."

*edit state* age* MJ00* current_age if HJ005M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.


***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
    replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement or temp leave
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="work" if strpos(`var', "work")
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2002=rowtotal(state_info16-state_info65)

save, replace

***********2004-2014
***********Data have the same structure between 2004 and 2014. Replace the year code and the wave specific letter
**2004:J, 2006:K, 2008:L, 2010:M 
**for 2004 *L034a and *L034b, in othey years *L034A and *L034B. Same for *L035.
**Go to complete file "2004_2014 Core Files Cleaning" if we want to run all the years consecutively
*****************************2004
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H04L_R.dta", clear
keep HHID PN JL034a JL034b JL034b JL035a JL035b JL009 JL010 JL011 JL016 JL017 JL018 JL020 //past job # 1
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004_L.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H04K_R.dta", clear
keep HHID PN JK004 JK005 JK008 JK022 JK023 JK024 JK011 //previous work
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004_K.dta", replace
gen key=HHID+PN
sort key
save, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H04J_R.dta", clear
keep HHID PN JJ005M* JJ007 JJ008 JJ011 JJ012 JJ014 JJ015 JJ017 JJ018 JJ020 JJ021 JJ023 JJ249 JJ172 //current work
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004_J.dta", replace
gen key=HHID+PN
sort key
save, replace
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004_K.dta"
drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004_L.dta"
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004.dta", replace

******merge with tracker
sort key
drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported
foreach var of varlist JJ008 JJ012 JJ015 JJ018 JK004 JK022 JL009 JL016 JL034a JL034b JL035a JL035b JJ249 {
replace `var'=. if `var'>=9997
}

foreach var of varlist JK024 JL011 JL018 JK005 JK023 JL010 JL017 JJ007 JJ014 JJ017 {
replace `var'=. if `var'>=98
}

capture drop current_age age_*

**Define current age
gen current_age=2004-BIRTHYR

***define age unemployment
gen age_unemployed=JJ008-BIRTHYR if JJ008>BIRTHYR

***define age retirement
gen age_retired=JJ018-BIRTHYR if JJ018>BIRTHYR

***define age disabled
gen age_disabled=JJ015-BIRTHYR if JJ015>=BIRTHYR

***define age start temp leave
gen age_temp_leave=JJ012-BIRTHYR if JJ012>BIRTHYR

***define age start current job
gen age_current_job=JJ249-BIRTHYR if JJ249>BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=JK022-BIRTHYR if JK022>BIRTHYR
replace age_previous_job=2004-JK023-BIRTHYR if JK023!=.
replace age_previous_job=JK024 if JK024!=.

gen age_end_previous_job=JK004-BIRTHYR
replace age_end_previous_job=2004-JK005-BIRTHYR if JK004==. & JK005!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=JL009-BIRTHYR if JL009>BIRTHYR
replace age_start_past_job1=2004-JL010-BIRTHYR if JL010!=. & JL010<current_age
replace age_start_past_job1=JL011 if JL011!=.

gen age_end_past_job1=JL016-BIRTHYR
replace age_end_past_job1=2004-JL017-BIRTHYR if JL017!=.
replace age_end_past_job1=JL018 if JL018!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 and 3 (>= 5 years)
gen age_start_past_job2=JL034a-BIRTHYR
gen age_end_past_job2=JL035a-BIRTHYR

gen age_start_past_job3=JL034b-BIRTHYR
gen age_end_past_job3=JL035b-BIRTHYR

**Make is consistent so that job3 is more recent than job2
edit age_start_past_job1-age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3

gen age_end_past_job2_corr=age_end_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
gen age_start_past_job2_corr=age_start_past_job3 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job3=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_start_past_job3=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job3
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=JJ007-BIRTHMO 
gen diff_month_disabled=JJ014-BIRTHMO 
gen diff_month_retired=JJ017-BIRTHMO 
gen diff_month_laid_off=JJ011-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if JJ172!=0 & JJ172<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if JK011!=0 & JK011<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if JL020!=0 & JL020<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if JJ005M1==1 & JJ005M2==.
replace current_status="working" if JJ005M1==1 & JJ005M2!=. & age_current_job!=.
replace current_status="working" if JJ005M1==1 & JJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if JJ005M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if JJ005M2==1 & age_current_job!=.
replace current_status="working" if JJ005M3==1 & age_current_job!=.

replace current_status="retired" if JJ005M1==5 & JJ005M2==.
replace current_status="retired" if JJ005M1==1 & JJ005M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if JJ005M1==5 & age_current_job==.
replace current_status="retired" if JJ005M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if JJ005M1==6 & JJ005M2==5 & current_status!="working"
replace current_status="retired" if JJ005M1==3 & JJ005M2==5 & age_retired!=.
replace current_status="retired" if JJ005M1==4 & JJ005M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if JJ005M1==2 & JJ005M2==5 & age_retired!=.
replace current_status="retired" if JJ005M1==7 & JJ005M2==5

replace current_status="disabled" if JJ005M1==4 & JJ005M2==.
replace current_status="disabled" if JJ005M1==4 & JJ005M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if JJ005M1==4 & JJ005M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if JJ005M1==4 & JJ005M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if JJ005M1==6 & JJ005M2==4 & age_disabled!=.
replace current_status="disabled" if JJ005M1==4 & JJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if JJ005M1==3 & JJ005M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if JJ005M1==7 & JJ005M2==4

replace current_status="unemployed" if JJ005M1==2 & JJ005M2==.
replace current_status="unemployed" if JJ005M1==2 & JJ005M2==3 & JJ005M3==.
replace current_status="unemployed" if JJ005M1==2 & JJ005M2==6 & JJ005M3==.
replace current_status="unemployed" if JJ005M1==2 & JJ005M2==4 & current_status=="."
replace current_status="unemployed" if JJ005M1==2 & JJ005M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if JJ005M1==6 & JJ005M2==2
replace current_status="unemployed" if JJ005M1==3 & JJ005M2==2 & age_unemployed!=.
replace current_status="unemployed" if JJ005M1==7 & JJ005M2==2

replace current_status="temp_leave" if JJ005M1==3 & JJ005M2==.
replace current_status="temp_leave" if JJ005M1==3 & JJ005M2==6 & JJ005M3==.
replace current_status="temp_leave" if JJ005M1==3 & JJ005M2==7 & JJ005M3==.
replace current_status="temp_leave" if JJ005M1==1 & JJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if JJ005M1==6 & JJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if JJ005M1==3 & JJ005M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if JJ005M1==7 & JJ005M2==3

replace current_status="homemaker" if JJ005M1==6 & JJ005M2==. 
replace current_status="homemaker" if JJ005M1==6 & JJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if JJ005M1==7 & JJ005M2==6

replace current_status="working" if JJ005M1==7 & JJ005M2==. & age_current_job!=.
replace current_status="working" if JJ005M1==1 & current_status=="."

*edit state* age* JJ00* current_age if JJ005M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement, temp leave or homemaker
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job2 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}


********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2004=rowtotal(state_info16-state_info65)

save, replace

**************************************************************************2016
********************************************************************************All in one file

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H16J_R.dta", clear
keep HHID PN PJ005M* PJ007 PJ008 PJ011 PJ012 PJ014 PJ015 PJ017 PJ018 PJ020 PJ021 PJ023 PJ249 PJK004 PJK005 PJK006 PJK022 PJK023 PJK024 PJL009_1 PJL009_2 PJL010_1 PJL010_2 PJL011_1 PJL011_2 PJL016_* PJL017_1 PJL017_2 PJL018_1 PJL018_2 PJ172 PJK011 PJL020_1
gen key=HHID+PN
sort key
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2016.dta", replace

******merge with tracker
sort key
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported

foreach var of varlist PJ008 PJ012 PJ015 PJ018 PJK004 PJK022 PJL009* PJL016_* PJL017_2 PJ249 {
replace `var'=. if `var'>=9997
}

foreach var of varlist PJ005M* PJK024 PJ011 PJL011_* PJL018_* PJK005 PJK023 PJL010_* PJL017_* PJ007 PJ014 PJ017 {
replace `var'=. if `var'>=98
}

foreach var of varlist PJ172 PJK011 PJL020_1 {
replace `var'=. if `var'>=998
}

capture drop current_age age_*

**Define current age
gen current_age=2016-BIRTHYR

***define age unemployment
gen age_unemployed=PJ008-BIRTHYR if PJ008>BIRTHYR

***define age retirement
gen age_retired=PJ018-BIRTHYR if PJ018>BIRTHYR

***define age disabled
gen age_disabled=PJ015-BIRTHYR if PJ015>=BIRTHYR

***define age start temp leave
gen age_temp_leave=PJ012-BIRTHYR if PJ012>BIRTHYR

***define age start current job
gen age_current_job=PJ249-BIRTHYR if PJ249>BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=PJK022-BIRTHYR if PJK022>BIRTHYR
replace age_previous_job=2016-PJK023-BIRTHYR if PJK023!=.
replace age_previous_job=PJK024 if PJK024!=.

gen age_end_previous_job=PJK004-BIRTHYR
replace age_end_previous_job=2016-PJK005-BIRTHYR if PJK004==. & PJK005!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=PJL009_1-BIRTHYR if PJL009_1>BIRTHYR
replace age_start_past_job1=2016-PJL010_1-BIRTHYR if PJL010_1!=. & PJL010_1<current_age
replace age_start_past_job1=PJL011_1 if PJL011_1!=.

gen age_end_past_job1=PJL016_1-BIRTHYR
replace age_end_past_job1=2016-PJL017_1-BIRTHYR if PJL017_1!=.
replace age_end_past_job1=PJL018_1 if PJL018_1!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 (Longest held job)
gen age_start_past_job2=PJL009_2-BIRTHYR if PJL009_2>BIRTHYR
replace age_start_past_job2=2016-PJL010_2-BIRTHYR if PJL010_2!=. & PJL010_2<current_age
replace age_start_past_job2=PJL011_2 if PJL011_2!=.

gen age_end_past_job2=PJL016_2-BIRTHYR
replace age_end_past_job2=2016-PJL017_2-BIRTHYR if PJL017_2!=.
replace age_end_past_job2=PJL018_2 if PJL018_2!=.

*There are some obs where end of job 2<start of job 2 - invert values
gen age_start_past_job2_corr=age_end_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
gen age_end_past_job2_corr=age_start_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
replace age_end_past_job2=age_end_past_job2_corr if age_start_past_job2_corr!=.
drop age_start_past_job2_corr age_end_past_job2_corr

**Make it consistent so that job1 is more recent than job2

gen age_end_past_job2_corr=age_end_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
gen age_start_past_job2_corr=age_start_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job1=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_start_past_job1=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=PJ007-BIRTHMO 
gen diff_month_disabled=PJ014-BIRTHMO 
gen diff_month_retired=PJ017-BIRTHMO 
gen diff_month_laid_off=PJ011-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if PJ172!=0 & PJ172<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if PJK011!=0 & PJK011<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if PJL020_1!=0 & PJL020_1<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if PJ005M1==1 & PJ005M2==.
replace current_status="working" if PJ005M1==1 & PJ005M2!=. & age_current_job!=.
replace current_status="working" if PJ005M1==1 & PJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if PJ005M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if PJ005M2==1 & age_current_job!=.
replace current_status="working" if PJ005M3==1 & age_current_job!=.

replace current_status="retired" if PJ005M1==5 & PJ005M2==.
replace current_status="retired" if PJ005M1==1 & PJ005M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if PJ005M1==5 & age_current_job==.
replace current_status="retired" if PJ005M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if PJ005M1==6 & PJ005M2==5 & current_status!="working"
replace current_status="retired" if PJ005M1==3 & PJ005M2==5 & age_retired!=.
replace current_status="retired" if PJ005M1==4 & PJ005M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if PJ005M1==2 & PJ005M2==5 & age_retired!=.
replace current_status="retired" if PJ005M1==7 & PJ005M2==5

replace current_status="disabled" if PJ005M1==4 & PJ005M2==.
replace current_status="disabled" if PJ005M1==4 & PJ005M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if PJ005M1==4 & PJ005M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if PJ005M1==4 & PJ005M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if PJ005M1==6 & PJ005M2==4 & age_disabled!=.
replace current_status="disabled" if PJ005M1==4 & PJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if PJ005M1==3 & PJ005M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if PJ005M1==7 & PJ005M2==4

replace current_status="unemployed" if PJ005M1==2 & PJ005M2==.
replace current_status="unemployed" if PJ005M1==2 & PJ005M2==3 & PJ005M3==.
replace current_status="unemployed" if PJ005M1==2 & PJ005M2==5 & age_unemployed!=. & age_retired==.
replace current_status="unemployed" if PJ005M1==2 & PJ005M2==3 & PJ005M3==4 & age_unemployed!=.
replace current_status="unemployed" if PJ005M1==2 & PJ005M2==6 & PJ005M3==.
replace current_status="unemployed" if PJ005M1==2 & PJ005M2==4 & current_status=="."
replace current_status="unemployed" if PJ005M1==2 & PJ005M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if PJ005M1==6 & PJ005M2==2
replace current_status="unemployed" if PJ005M1==3 & PJ005M2==2 & age_unemployed!=.
replace current_status="unemployed" if PJ005M1==7 & PJ005M2==2

replace current_status="temp_leave" if PJ005M1==3 & PJ005M2==.
replace current_status="temp_leave" if PJ005M1==3 & PJ005M2==6 & PJ005M3==.
replace current_status="temp_leave" if PJ005M1==3 & PJ005M2==7 & PJ005M3==.
replace current_status="temp_leave" if PJ005M1==1 & PJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if PJ005M1==6 & PJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if PJ005M1==3 & PJ005M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if PJ005M1==7 & PJ005M2==3

replace current_status="homemaker" if PJ005M1==6 & PJ005M2==. 
replace current_status="homemaker" if PJ005M1==6 & PJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if PJ005M1==7 & PJ005M2==6

replace current_status="working" if PJ005M1==7 & PJ005M2==. & age_current_job!=.
replace current_status="working" if PJ005M1==1 & current_status=="."

*edit state* age* PJ00* current_age if PJ005M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	*replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	*replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	*replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement, temp leave or homemaker
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_end_past_job1!=. & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job2 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

*replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2016=rowtotal(state_info16-state_info65) //

save, replace

**************************************************************************2018
********************************************************************************All in one file
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H18J_R.dta", clear
keep hhid pn QJ005M* QJ007 QJ008 QJ011 QJ012 QJ014 QJ015 QJ017 QJ018 QJ020 QJ021 QJ023 QJ249 QJK004 QJK005 QJK006 QJK022 QJK023 QJK024 QJL009_1 QJL009_2 QJL010_1 QJL010_2 QJL011_1 QJL011_2 QJL016_* QJL017_1 QJL017_2 QJL018_1 QJL018_2 QJ172 QJK011 QJL020_1
gen key=hhid+pn
sort key
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2018.dta", replace

******merge with tracker
sort key
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported

foreach var of varlist QJ008 QJ012 QJ015 QJ018 QJK004 QJK022 QJL009* QJL016_* QJL017_2 QJ249 {
replace `var'=. if `var'>=9997
}

foreach var of varlist QJ005M* QJK024 QJ011 QJL011_* QJL018_* QJK005 QJK023 QJL010_* QJL017_* QJ007 QJ014 QJ017 {
replace `var'=. if `var'>=98
}

foreach var of varlist QJ172 QJK011 QJL020_1 {
replace `var'=. if `var'>=998
}

capture drop current_age age_*

**Define current age
gen current_age=2016-BIRTHYR

***define age unemployment
gen age_unemployed=QJ008-BIRTHYR if QJ008>BIRTHYR

***define age retirement
gen age_retired=QJ018-BIRTHYR if QJ018>BIRTHYR

***define age disabled
gen age_disabled=QJ015-BIRTHYR if QJ015>=BIRTHYR

***define age start temp leave
gen age_temp_leave=QJ012-BIRTHYR if QJ012>BIRTHYR

***define age start current job
gen age_current_job=QJ249-BIRTHYR if QJ249>BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=QJK022-BIRTHYR if QJK022>BIRTHYR
replace age_previous_job=2016-QJK023-BIRTHYR if QJK023!=.
replace age_previous_job=QJK024 if QJK024!=.

gen age_end_previous_job=QJK004-BIRTHYR
replace age_end_previous_job=2016-QJK005-BIRTHYR if QJK004==. & QJK005!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=QJL009_1-BIRTHYR if QJL009_1>BIRTHYR
replace age_start_past_job1=2016-QJL010_1-BIRTHYR if QJL010_1!=. & QJL010_1<current_age
replace age_start_past_job1=QJL011_1 if QJL011_1!=.

gen age_end_past_job1=QJL016_1-BIRTHYR
replace age_end_past_job1=2016-QJL017_1-BIRTHYR if QJL017_1!=.
replace age_end_past_job1=QJL018_1 if QJL018_1!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 (Longest held job)
gen age_start_past_job2=QJL009_2-BIRTHYR if QJL009_2>BIRTHYR
replace age_start_past_job2=2016-QJL010_2-BIRTHYR if QJL010_2!=. & QJL010_2<current_age
replace age_start_past_job2=QJL011_2 if QJL011_2!=.

gen age_end_past_job2=QJL016_2-BIRTHYR
replace age_end_past_job2=2018-QJL017_2-BIRTHYR if QJL017_2!=.
replace age_end_past_job2=QJL018_2 if QJL018_2!=.

*There are some obs where end of job 2<start of job 2 - invert values
gen age_start_past_job2_corr=age_end_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
gen age_end_past_job2_corr=age_start_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
replace age_end_past_job2=age_end_past_job2_corr if age_start_past_job2_corr!=.
drop age_start_past_job2_corr age_end_past_job2_corr

**Make it consistent so that job1 is more recent than job2

gen age_end_past_job2_corr=age_end_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
gen age_start_past_job2_corr=age_start_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job1=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_start_past_job1=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=QJ007-BIRTHMO 
gen diff_month_disabled=QJ014-BIRTHMO 
gen diff_month_retired=QJ017-BIRTHMO 
gen diff_month_laid_off=QJ011-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if QJ172!=0 & QJ172<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if QJK011!=0 & QJK011<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if QJL020_1!=0 & QJL020_1<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if QJ005M1==1 & QJ005M2==.
replace current_status="working" if QJ005M1==1 & QJ005M2!=. & age_current_job!=.
replace current_status="working" if QJ005M1==1 & QJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if QJ005M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if QJ005M2==1 & age_current_job!=.
replace current_status="working" if QJ005M3==1 & age_current_job!=.

replace current_status="retired" if QJ005M1==5 & QJ005M2==.
replace current_status="retired" if QJ005M1==1 & QJ005M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if QJ005M1==5 & age_current_job==.
replace current_status="retired" if QJ005M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if QJ005M1==6 & QJ005M2==5 & current_status!="working"
replace current_status="retired" if QJ005M1==3 & QJ005M2==5 & age_retired!=.
replace current_status="retired" if QJ005M1==4 & QJ005M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if QJ005M1==2 & QJ005M2==5 & age_retired!=.
replace current_status="retired" if QJ005M1==7 & QJ005M2==5

replace current_status="disabled" if QJ005M1==4 & QJ005M2==.
replace current_status="disabled" if QJ005M1==4 & QJ005M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if QJ005M1==4 & QJ005M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if QJ005M1==4 & QJ005M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if QJ005M1==6 & QJ005M2==4 & age_disabled!=.
replace current_status="disabled" if QJ005M1==4 & QJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if QJ005M1==3 & QJ005M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if QJ005M1==7 & QJ005M2==4

replace current_status="unemployed" if QJ005M1==2 & QJ005M2==.
replace current_status="unemployed" if QJ005M1==2 & QJ005M2==3 & QJ005M3==.
replace current_status="unemployed" if QJ005M1==2 & QJ005M2==5 & age_unemployed!=. & age_retired==.
replace current_status="unemployed" if QJ005M1==2 & QJ005M2==3 & QJ005M3==4 & age_unemployed!=.
replace current_status="unemployed" if QJ005M1==2 & QJ005M2==6 & QJ005M3==.
replace current_status="unemployed" if QJ005M1==2 & QJ005M2==4 & current_status=="."
replace current_status="unemployed" if QJ005M1==2 & QJ005M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if QJ005M1==6 & QJ005M2==2
replace current_status="unemployed" if QJ005M1==3 & QJ005M2==2 & age_unemployed!=.
replace current_status="unemployed" if QJ005M1==7 & QJ005M2==2

replace current_status="temp_leave" if QJ005M1==3 & QJ005M2==.
replace current_status="temp_leave" if QJ005M1==3 & QJ005M2==6 & QJ005M3==.
replace current_status="temp_leave" if QJ005M1==3 & QJ005M2==7 & QJ005M3==.
replace current_status="temp_leave" if QJ005M1==1 & QJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if QJ005M1==6 & QJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if QJ005M1==3 & QJ005M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if QJ005M1==7 & QJ005M2==3

replace current_status="homemaker" if QJ005M1==6 & QJ005M2==. 
replace current_status="homemaker" if QJ005M1==6 & QJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if QJ005M1==7 & QJ005M2==6

replace current_status="working" if QJ005M1==7 & QJ005M2==. & age_current_job!=.
replace current_status="working" if QJ005M1==1 & current_status=="."

*edit state* age* QJ00* current_age if QJ005M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	*replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	*replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	*replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement, temp leave or homemaker
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_end_past_job1!=. & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job2 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

*replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2018=rowtotal(state_info16-state_info65) //

save, replace

********************************************************************************2020

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/H20J_R.dta", clear
rename *, upper
keep HHID PN RJ005M* RJ007 RJ008 RJ011 RJ012 RJ014 RJ015 RJ017 RJ018 RJ020 RJ021 RJ023 RJ249 RJK004 RJK005 RJK006 RJK022 RJK023 RJK024 RJL009_1 RJL009_2 RJL010_1 RJL010_2 RJL011_1 RJL011_2 RJL016_* RJL017_1 RJL017_2 RJL018_1 RJL018_2 RJ172 RJK011 RJL020_1
gen key=HHID+PN
sort key
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2020.dta", replace

******merge with tracker
sort key
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r", keepusing(BIRTHMO BIRTHYR)
drop if _merge==1
drop if _merge==2
drop _merge
save, replace

**Set missing values when year is not  reported

foreach var of varlist RJ008 RJ012 RJ015 RJ018 RJK004 RJK022 RJL009* RJL016_* RJL017_2 RJ249 {
replace `var'=. if `var'>=9997
}

foreach var of varlist RJ005M* RJK024 RJ011 RJL011_* RJL018_* RJK005 RJK023 RJL010_* RJL017_* RJ007 RJ014 RJ017 {
replace `var'=. if `var'>=98
}

foreach var of varlist RJ172 RJK011 RJL020_1 {
replace `var'=. if `var'>=998
}

capture drop current_age age_*

**Define current age
gen current_age=2020-BIRTHYR

***define age unemployment
gen age_unemployed=RJ008-BIRTHYR if RJ008>BIRTHYR

***define age retirement
gen age_retired=RJ018-BIRTHYR if RJ018>BIRTHYR

***define age disabled
gen age_disabled=RJ015-BIRTHYR if RJ015>=BIRTHYR

***define age start temp leave
gen age_temp_leave=RJ012-BIRTHYR if RJ012>BIRTHYR

***define age start current job
gen age_current_job=RJ249-BIRTHYR if RJ249>BIRTHYR

***define age start and end of previous job (if not currently employed)
gen age_previous_job=RJK022-BIRTHYR if RJK022>BIRTHYR
replace age_previous_job=2020-RJK023-BIRTHYR if RJK023!=.
replace age_previous_job=RJK024 if RJK024!=.

gen age_end_previous_job=RJK004-BIRTHYR
replace age_end_previous_job=2020-RJK005-BIRTHYR if RJK004==. & RJK005!=.

*There are some obs where end of previous job<start of previous job - invert values
gen age_previous_job_corr=age_end_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
gen age_end_previous_job_corr=age_previous_job if age_previous_job>age_end_previous_job & age_previous_job!=. & age_end_previous_job>0
replace age_previous_job=age_previous_job_corr if age_previous_job_corr!=.
replace age_end_previous_job=age_end_previous_job_corr if age_previous_job_corr!=.
drop age_previous_job_corr age_end_previous_job_corr

***define age start and end of past job # 1 - the most recent
gen age_start_past_job1=RJL009_1-BIRTHYR if RJL009_1>BIRTHYR
replace age_start_past_job1=2020-RJL010_1-BIRTHYR if RJL010_1!=. & RJL010_1<current_age
replace age_start_past_job1=RJL011_1 if RJL011_1!=.

gen age_end_past_job1=RJL016_1-BIRTHYR
replace age_end_past_job1=2020-RJL017_1-BIRTHYR if RJL017_1!=.
replace age_end_past_job1=RJL018_1 if RJL018_1!=.

*There are some obs where end of job 1<start of job 1 - invert values
gen age_start_past_job1_corr=age_end_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
gen age_end_past_job1_corr=age_start_past_job1 if age_start_past_job1>age_end_past_job1 & age_start_past_job1!=.
replace age_start_past_job1=age_start_past_job1_corr if age_start_past_job1_corr!=.
replace age_end_past_job1=age_end_past_job1_corr if age_start_past_job1_corr!=.
drop age_start_past_job1_corr age_end_past_job1_corr

***define age start and end of past job # 2 (Longest held job)
gen age_start_past_job2=RJL009_2-BIRTHYR if RJL009_2>BIRTHYR
replace age_start_past_job2=2020-RJL010_2-BIRTHYR if RJL010_2!=. & RJL010_2<current_age
replace age_start_past_job2=RJL011_2 if RJL011_2!=.

gen age_end_past_job2=RJL016_2-BIRTHYR
replace age_end_past_job2=2020-RJL017_2-BIRTHYR if RJL017_2!=.
replace age_end_past_job2=RJL018_2 if RJL018_2!=.

*There are some obs where end of job 2<start of job 2 - invert values
gen age_start_past_job2_corr=age_end_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
gen age_end_past_job2_corr=age_start_past_job2 if age_start_past_job2>age_end_past_job2 & age_start_past_job2!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
replace age_end_past_job2=age_end_past_job2_corr if age_start_past_job2_corr!=.
drop age_start_past_job2_corr age_end_past_job2_corr

**Make it consistent so that job1 is more recent than job2

gen age_end_past_job2_corr=age_end_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
gen age_start_past_job2_corr=age_start_past_job1 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job1=age_end_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_start_past_job1=age_start_past_job2 if age_start_past_job2!=. & age_start_past_job2> age_start_past_job1
replace age_end_past_job2=age_end_past_job2_corr if age_end_past_job2_corr!=.
replace age_start_past_job2=age_start_past_job2_corr if age_start_past_job2_corr!=.
drop age_end_past_job2_corr age_start_past_job2_corr

**
gen diff_month_unemployed=RJ007-BIRTHMO 
gen diff_month_disabled=RJ014-BIRTHMO 
gen diff_month_retired=RJ017-BIRTHMO 
gen diff_month_laid_off=RJ011-BIRTHMO 

*****Look at # hours worked in previous, current job and past_job1 for part time vs. full time
gen current_job_part_time=0
replace current_job_part_time=1 if RJ172!=0 & RJ172<30   

gen previous_job_part_time=0
replace previous_job_part_time=1 if RJK011!=0 & RJK011<30

gen past_job1_part_time=0
replace previous_job_part_time=1 if RJL020_1!=0 & RJL020_1<30

***Create rules on current status //TO DISCUSS
capture drop current_status
gen current_status="."
replace current_status="working" if RJ005M1==1 & RJ005M2==.
replace current_status="working" if RJ005M1==1 & RJ005M2!=. & age_current_job!=.
replace current_status="working" if RJ005M1==1 & RJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="working" if RJ005M2==1 & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.

replace current_status="working" if RJ005M2==1 & age_current_job!=.
replace current_status="working" if RJ005M3==1 & age_current_job!=.

replace current_status="retired" if RJ005M1==5 & RJ005M2==.
replace current_status="retired" if RJ005M1==1 & RJ005M2==5 & age_current_job==. & age_retired!=. //discuss
replace current_status="retired" if RJ005M1==5 & age_current_job==.
replace current_status="retired" if RJ005M1==5 & age_current_job!=. & current_status!="working"
replace current_status="retired" if RJ005M1==6 & RJ005M2==5 & current_status!="working"
replace current_status="retired" if RJ005M1==3 & RJ005M2==5 & age_retired!=.
replace current_status="retired" if RJ005M1==4 & RJ005M2==5 & age_retired!=. & age_disabled==.
replace current_status="retired" if RJ005M1==2 & RJ005M2==5 & age_retired!=.
replace current_status="retired" if RJ005M1==7 & RJ005M2==5

replace current_status="disabled" if RJ005M1==4 & RJ005M2==.
replace current_status="disabled" if RJ005M1==4 & RJ005M2!=. & age_current_job==. & current_status!="working"
replace current_status="disabled" if RJ005M1==4 & RJ005M2!=. & age_current_job!=. & age_disabled>age_current_job & current_status!="working" //they worked and then at some point got disabled (?)
replace current_status="disabled" if RJ005M1==4 & RJ005M2!=. & age_current_job!=. & age_disabled<=age_current_job & current_status!="working" //they were disabled and not working, then got a job, then stopped working again
replace current_status="disabled" if RJ005M1==6 & RJ005M2==4 & age_disabled!=.
replace current_status="disabled" if RJ005M1==4 & RJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==.
replace current_status="disabled" if RJ005M1==3 & RJ005M2==4 //we assume that they are on temp leave because they are disabled
replace current_status="disabled" if RJ005M1==7 & RJ005M2==4

replace current_status="unemployed" if RJ005M1==2 & RJ005M2==.
replace current_status="unemployed" if RJ005M1==2 & RJ005M2==3 & RJ005M3==.
replace current_status="unemployed" if RJ005M1==2 & RJ005M2==5 & age_unemployed!=. & age_retired==.
replace current_status="unemployed" if RJ005M1==2 & RJ005M2==3 & RJ005M3==4 & age_unemployed!=.
replace current_status="unemployed" if RJ005M1==2 & RJ005M2==6 & RJ005M3==.
replace current_status="unemployed" if RJ005M1==2 & RJ005M2==4 & current_status=="."
replace current_status="unemployed" if RJ005M1==2 & RJ005M2!=. & age_current_job==. & age_unemployed!=.
replace current_status="unemployed" if RJ005M1==6 & RJ005M2==2
replace current_status="unemployed" if RJ005M1==3 & RJ005M2==2 & age_unemployed!=.
replace current_status="unemployed" if RJ005M1==7 & RJ005M2==2

replace current_status="temp_leave" if RJ005M1==3 & RJ005M2==.
replace current_status="temp_leave" if RJ005M1==3 & RJ005M2==6 & RJ005M3==.
replace current_status="temp_leave" if RJ005M1==3 & RJ005M2==7 & RJ005M3==.
replace current_status="temp_leave" if RJ005M1==1 & RJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if RJ005M1==6 & RJ005M2==3 & age_temp_leave!=.
replace current_status="temp_leave" if RJ005M1==3 & RJ005M2==5 & age_temp_leave!=. & age_retired==.
replace current_status="temp_leave" if RJ005M1==7 & RJ005M2==3

replace current_status="homemaker" if RJ005M1==6 & RJ005M2==. 
replace current_status="homemaker" if RJ005M1==6 & RJ005M2!=. & age_current_job==. & age_retired==. & age_disabled==. & age_temp_leave==. & age_unemployed==. & current_status!="working"
replace current_status="homemaker" if RJ005M1==7 & RJ005M2==6

replace current_status="working" if RJ005M1==7 & RJ005M2==. & age_current_job!=.
replace current_status="working" if RJ005M1==1 & current_status=="."

*edit state* age* RJ00* current_age if RJ005M2==1 & age_current_job!=. & age_retired<age_current_job //these people are working, but it looks like they were retired for a while before starting working again

*****replace start retirement, unemployment, disability or temp leave based on birth month
replace age_unemployed=age_unemployed+1 if diff_month_unemployed>6 & diff_month_unemployed!=.
replace age_retired=age_retired+1 if diff_month_retired>6 & diff_month_retired!=.
replace age_disabled=age_disabled+1 if diff_month_disabled>6 & diff_month_disabled!=.
replace age_temp_leave=age_temp_leave+1 if diff_month_laid_off>6 & diff_month_laid_off!=.

***********************************************************
****define states
****Gen states
capture drop state*
forval j = 1/110 {
    generate state`j'="."
	foreach var of varlist state* {
	replace state`j'="current_work" if current_age==`j' & current_status=="working"
	replace state`j'="start_current_work" if age_current_job==`j' & age_current_job<=current_age
	replace state`j'="start_previous_work" if age_previous_job==`j' 
	replace state`j'="previous_work" if age_end_previous_job==`j' & age_previous_job!=age_end_previous_job & age_previous_job<current_age
	replace state`j'="start_past_work1" if age_start_past_job1==`j' & age_start_past_job1!=age_end_previous_job & age_start_past_job1<current_age
	replace state`j'="start_past_work2" if age_start_past_job2==`j' 
	*replace state`j'="start_past_work3" if age_start_past_job3==`j'
	replace state`j'="past_work1" if age_end_past_job1==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1<=current_age
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2<=age_end_past_job1 & age_start_past_job2!=age_end_past_job2
	replace state`j'="past_work2" if age_end_past_job2==`j' & age_end_past_job2>age_end_past_job1 & age_start_past_job2>age_start_past_job1 & age_start_past_job2!=age_end_past_job2 //NEW
	*replace state`j'="past_work3" if age_end_past_job3==`j' & age_end_past_job3>=age_end_past_job2 & age_start_past_job3!=age_end_past_job3
	replace state`j'="current_unemployed" if current_age==`j' & current_status=="unemployed"
	replace state`j'="current_temp_leave" if current_age==`j' & current_status=="temp_leave"
	replace state`j'="current_disabled" if current_age==`j' & current_status=="disabled"
	replace state`j'="current_retired" if current_age==`j' & current_status=="retired"
	replace state`j'="current_homemaker" if current_age==`j' & current_status=="homemaker"
	
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired!=age_previous_job & age_retired!=age_start_past_job1
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_previous_job & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="retired" & age_retired==age_start_past_job1 & age_retired==current_age
	replace state`j'="start_retired" if age_retired==`j' & current_status=="disabled" & age_retired<age_disabled & age_retired==current_age

	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="unemployed" & age_unemployed==age_previous_job & age_unemployed==current_age
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="disabled" & age_unemployed<age_disabled & age_unemployed!=age_previous_job
	replace state`j'="start_unemployed" if age_unemployed==`j' & current_status=="retired" & age_unemployed<age_retired & age_unemployed!=age_previous_job
	
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="disabled" & age_disabled==age_previous_job & age_disabled==current_age
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="retired" & age_disabled<age_retired & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="working" & age_disabled<age_current_job & age_disabled!=age_previous_job 
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="unemployed" & age_disabled<age_unemployed & age_disabled!=age_previous_job
	replace state`j'="start_disabled" if age_disabled==`j' & current_status=="temp_leave" & age_disabled<age_temp_leave & age_disabled!=age_previous_job
	
	replace state`j'="start_temp_leave" if age_temp_leave==`j' & current_status=="temp_leave"
	}
}

foreach var of varlist state* {
forval j = 2/110 {
replace state`=`j' - 1'="past_work1" if state`=`j' - 1'=="." & current_age==`j' & age_start_past_job1!=age_end_past_job1 & age_end_past_job1>current_age & age_end_past_job1!=. & age_start_past_job1<current_age
replace state`=`j' - 1'="previous_work" if state`=`j' - 1'=="." & current_age==`j' & age_previous_job!=age_end_previous_job & age_end_previous_job>current_age & age_end_previous_job!=. & age_previous_job<current_age
}
}

//RULE: If start of previous job or past job is set after current age, we delete it

//RULE: if past work is indicated to finish after current age, set end one year before current age 

//CHECK WHEN START OF PREVIOUS JOB=START OF RETIREMENT, DISABILITY ETC.

//Delete starts if they interrupt work trajectories
forval j = 1/110 {
	foreach var of varlist state* {
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job1>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_previous_work" & age_end_past_job2>age_previous_job & age_previous_job!=. & age_previous_job>age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1>age_previous_job & age_start_past_job1<age_end_previous_job & age_previous_job!=. & age_start_past_job1!=.
	replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job2 & age_start_past_job2<age_start_past_job1 //NEW
	*replace state`j'="." if state`j'=="start_past_work1" & age_start_past_job1<age_end_past_job3 & age_start_past_job3<age_start_past_job1 //NEW
	replace state`j'="." if state`j'=="start_past_work2" & age_start_past_job2<age_end_past_job1 & age_start_past_job1<age_start_past_job2 //NEW
	replace state`j'="." if state`j'=="start_current_work" & age_current_job<age_end_past_job1 & age_start_past_job1<age_current_job //NEW
	replace state`j'="." if state`j'=="start_disabled" & age_disabled>age_retired & age_disabled!=. & current_status=="retired" //NEW: if retirement starts before disability, we will consider the person retired rather than disabled.
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1>age_previous_job & age_end_past_job1>age_retired //if start of retirement interrupts a work trajectory, delete it //NEW
	replace state`j'="." if state`j'=="start_retired" & age_start_past_job1!=. & age_start_past_job1<age_retired & age_end_past_job1>age_retired 
	replace state`j'="." if state`j'=="start_retired" & age_end_previous_job>age_retired & age_previous_job<age_retired & age_end_previous_job!=. //if previous job ends after reported start of retirement, we consider the person to be working 
	replace state`j'="." if state`j'=="start_disabled" &  age_disabled<age_end_previous_job & age_disabled>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	replace state`j'="." if state`j'=="start_unemployed" & age_unemployed<age_end_previous_job & age_unemployed>age_previous_job & age_end_previous_job!=. //delete if it interrupts a work trajectory
	*replace state`j'="." if state`j'=="start_past_work3" & age_start_past_job3>age_start_past_job2 & age_start_past_job3<age_end_past_job2 & age_end_past_job2!=.
	*replace state`j'="." if state`j'=="start_past_work3" & age_current_job<age_end_past_job3 & age_current_job>age_start_past_job3 & age_end_past_job3!=.
	}
}

*NEW: set end of past jobs/previous job one year earlier if it coincides with start of unemployment, retirement, temp leave or homemaker
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="past_work1" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job1 & age_unemployed!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job1 & age_retired!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job1 & age_disabled!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job1 & age_end_past_job1!=. & age_temp_leave!=. & state`j'=="." & age_end_past_job1!=age_start_past_job1 & age_start_past_job1<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job1 & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job1==current_age & age_end_past_job1!=age_start_past_job2 & age_start_past_job1!=.

replace state`j'="past_work2" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job2 & age_unemployed!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job2 & age_retired!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job2 & age_disabled!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job2 & age_temp_leave!=. & state`j'=="." & age_end_past_job2!=age_start_past_job2 & age_start_past_job2<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.
replace state`j'="past_work2" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job2==current_age & age_end_past_job2!=age_start_past_job2 & age_start_past_job2!=.

*replace state`j'="past_work3" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_past_job3 & age_unemployed!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_past_job3 & age_retired!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_past_job3 & age_disabled!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_past_job3 & age_temp_leave!=. & state`j'=="." & age_end_past_job3!=age_start_past_job3 & age_start_past_job3<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_past_job3==current_age & age_end_past_job3!=age_start_past_job3 & age_start_past_job3!=.

replace state`j'="previous_work" if state`=`j' + 1'=="start_unemployed" & age_unemployed<=age_end_previous_job & age_unemployed!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_unemployed|state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_retired" & age_retired<=age_end_previous_job & age_retired!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_retired|state`=`j' + 1'=="current_retired" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_disabled" & age_disabled<=age_end_previous_job & age_disabled!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_disabled|state`=`j' + 1'=="current_disabled" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="start_temp_leave" & age_temp_leave<=age_end_previous_job & age_temp_leave!=. & state`j'=="." & age_end_previous_job!=age_previous_job & age_previous_job<=age_temp_leave|state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
replace state`j'="previous_work" if state`=`j' + 1'=="current_homemaker" & state`j'=="." & age_end_previous_job==current_age & age_end_previous_job!=age_previous_job & age_previous_job!=.
}
}

//QUESTION: What should we do when a job has a start and not end? Carry forward? Look at total number of years worked?

***********Fill the gaps and create work trajectories
foreach var of varlist state* {
forval j = 1/109 {
replace state`j'="current_work" if state`=`j' + 1'=="current_work" & state`j'=="." & age_current_job!=. & age_current_job<=current_age
replace state`j'="current_disabled" if state`=`j' + 1'=="current_disabled" & state`j'=="." & age_disabled!=. & age_disabled<=current_age
replace state`j'="current_retired" if state`=`j' + 1'=="current_retired" & state`j'=="." & age_retired!=. & age_retired<=current_age
replace state`j'="current_temp_leave" if state`=`j' + 1'=="current_temp_leave" & state`j'=="." & age_temp_leave!=. & age_temp_leave<=current_age
replace state`j'="current_unemployed" if state`=`j' + 1'=="current_unemployed" & state`j'=="." & age_unemployed!=. & age_unemployed<=current_age
replace state`j'="previous_work" if state`=`j' + 1'=="previous_work" & state`j'=="." & age_previous_job!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & state`j'=="." & age_start_past_job1!=.
replace state`j'="past_work1" if state`=`j' + 1'=="past_work1" & age_start_past_job1==. & age_end_past_job1!=. & age_end_past_job1>age_previous_job & age_end_previous_job!=. & state`j'=="."
replace state`j'="past_work2" if state`=`j' + 1'=="past_work2" & state`j'=="." & age_start_past_job2!=.
*replace state`j'="past_work3" if state`=`j' + 1'=="past_work3" & state`j'=="." & age_start_past_job3!=.
}
}

*NEW: edit age_current_job age_start_past_job1 state* if age_current_job<age_start_past_job1 & age_start_past_job1!=.
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & age_current_job<age_start_past_job1 & age_start_past_job1!=. //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_temp_leave  //fill gaps if current job is reported to start before past job
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age==age_unemployed 
replace state`j'="start_current_work" if state`=`j' - 1'=="start_current_work" & state`j'=="." & current_age<=age_retired & `j'<=current_age
}
}

***********Fill in blanks for disabled and retired
foreach var of varlist state* {
forval j = 2/110 {
replace state`j'="start_disabled" if state`=`j' - 1'=="start_disabled" & state`j'=="." & `j'<current_age
replace state`j'="start_retired" if state`=`j' - 1'=="start_retired" & state`j'=="." & `j'<current_age
replace state`j'="start_unemployed" if state`=`j' - 1'=="start_unemployed" & state`j'=="." & `j'<current_age
replace state`j'="start_temp_leave" if state`=`j' - 1'=="start_temp_leave" & state`j'=="." & `j'<current_age
}
}

**********Update part time status
foreach var of varlist state* {
replace `var'="current_work_part_time" if `var'=="current_work" & current_job_part_time==1 	
replace `var'="start_current_work_part_time" if `var'=="start_current_work" & current_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="previous_work_part_time" if `var'=="previous_work" & previous_job_part_time==1 	
replace `var'="start_previous_work_part_time" if `var'=="start_previous_work" & previous_job_part_time==1 	
}

foreach var of varlist state* {
replace `var'="past_work1_part_time" if `var'=="past_work1" & past_job1_part_time==1 	
replace `var'="start_past_work1_part_time" if `var'=="start_past_work1" & current_job_part_time==1 	
}

********************************************************************************
**LAST STEP: Simplify names of states
foreach var of varlist state* {
replace `var'="part_time" if strpos(`var', "part_time")
replace `var'="work" if strpos(`var', "work")
replace `var'="disabled" if strpos(`var', "disabled")
replace `var'="retired" if strpos(`var', "retired")
replace `var'="temp_leave" if strpos(`var', "temp_leave")
replace `var'="unemployed" if strpos(`var', "unemployed")
replace `var'="homemaker" if strpos(`var', "homemaker")
}

save, replace

forval j = 16/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
}

egen total_state_info_2020=rowtotal(state_info16-state_info65) //

save, replace

*******QUESTION: what should we do with people who reported getting retired early (e.g. before age 40)?

*******QUESTION: if someone is reitired but there is no retirement start date, should we assume that they retired at a certain age, let's say 67? Not realistic to say they they worked until they were 80 or older?
* edit state* age* MJ00* current_age current_status if current_status=="retired" & age_retired==. & age_current_job!=.

***************************************RENAME STATES IN EACH FILE
foreach data in job_history_1992 job_history_1993 job_history_1994 job_history_1995 job_history_1996 job_history_1998 job_history_2000 job_history_2002 job_history_2004 job_history_2006 job_history_2008 job_history_2010 job_history_2012 job_history_2014 job_history_2016 job_history_2018 job_history_2020 {
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/`data'", clear
local i = substr("`data'", 13, .)
forval j=1/110 {
rename state`j'=state`j'_`i'
save, replace
}

foreach data in job_history_1992 job_history_1993 job_history_1994 job_history_1995 job_history_1996 job_history_1998 job_history_2000 job_history_2002 job_history_2004 job_history_2006 job_history_2008 job_history_2010 job_history_2012 job_history_2014 job_history_2016 job_history_2018 job_history_2020 {
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/`data'", clear
local i = substr("`data'", 13, .)
forval j=106/110 {
rename state`j'_`i'_`i'_`i' state`j'_`i'
save, replace
}
}

foreach data in job_history_1995 job_history_1996 job_history_1998 job_history_2000 job_history_2002 job_history_2004 job_history_2006 job_history_2008 job_history_2010 job_history_2012 job_history_2014 job_history_2016 job_history_2018 job_history_2020 {
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/`data'", clear
local i = substr("`data'", 13, .)
forval j=16/65 {
rename state_info`j'_`i'_`i' state_info`j'_`i'
save, replace
}
}

***************************************MERGE ALL FILES TOGETHER
***After cleaning all Core Survey files, merge with tracker to see availability
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r"
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2020.dta", keepusing (total_state_info_2020 state*)
drop if _merge==2
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r_MERGED", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r_MERGED"
capture drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2018.dta", keepusing (total_state_info_2018 state*)
drop if _merge==2
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r_MERGED", replace
capture drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2016.dta", keepusing (total_state_info_2016 state*)
drop if _merge==2
capture drop _merge
sort key
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2014.dta", keepusing (total_state_info_2014 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2012.dta", keepusing (total_state_info_2012 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2010.dta", keepusing (total_state_info_2010 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2008.dta", keepusing (total_state_info_2008 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2006.dta", keepusing (total_state_info_2006 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2004.dta", keepusing (total_state_info_2004 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2002.dta", keepusing (total_state_info_2002 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_2000.dta", keepusing (total_state_info_2000 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1998.dta", keepusing (total_state_info_1998 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1996.dta", keepusing (total_state_info_1996 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1995.dta", keepusing (total_state_info_1995 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1994.dta", keepusing (total_state_info_1994 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1993.dta", keepusing (total_state_info_1993 state*)
drop if _merge==2
capture drop _merge
merge 1:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Employment Core HRS/job_history_1992.dta", keepusing (total_state_info_1992 state*)
drop if _merge==2
capture drop _merge
sort key
save, replace

***************CLEAN LHMS DATA
***********************************************************************EDUCATION
********************************************************************************
******Generate states for education - to be matched with job states
**Same way as we generated states for jobs
**We are combining pre high school and post high school education - two different sets of variables in LHMS

foreach var of varlist LH22_*D {
 local suffix = substr("`var'", 6, 3)
  generate school_start`suffix'= `var'
} //Age at the start of each school 

foreach var of varlist LH22_*E {
 local suffix = substr("`var'", 6, 3)
  generate school_end`suffix'= `var'
} //Age at the end of each school 

foreach var of varlist school_* {
replace `var'=. if `var'==96 //"out of range" replaced with missing
}

foreach var of varlist LH35_*A {
 local suffix = substr("`var'", 6, 3)
  generate post_high_school_start`suffix'= `var'-BIRTHYR
  replace post_high_school_start`suffix'= `var'-BIRTHYR+1 if BIRTHMO==1 | BIRTHMO==2
} //Age at the start of each school after HS
//Assuming that school starts in September, people who were born in Jan and Feb were one year older than their classmates for most of the school year

foreach var of varlist LH35_*B {
 local suffix = substr("`var'", 6, 3)
  generate post_high_school_end`suffix'= `var'-BIRTHYR
  replace post_high_school_end`suffix'= `var'-BIRTHYR+1 if BIRTHMO==1 | BIRTHMO==2
}

renvars school_start1D- post_high_school_end7B, postdrop(1)

*****Looking at people who had missing data for some of the school grades - either missing school start or school end
gen missing_start_hl_school=0

forval j=1/10 {
replace missing_start_hl_school=1 if school_start`j'==. & school_end`j'!=.
}

gen missing_end_hl_school=0

forval j=1/10 {
replace missing_end_hl_school=1 if school_start`j'!=. & school_end`j'==.
}

gen missing_start_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

gen missing_end_ph_school=0

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

egen max_hl_school_end=rowmax(school_end1-school_end10) //lh=high school or lower
***Rule: if somebody reports finishing school before 16 yo but having a high school degree, we set 1) end of school=start of post secondary school-1 if started post-secondary school between 15 and 19
**If end of hl is missing but people report finishing 12th grade, we are setting end of high school to 17 or 18 (see rule below)
***2) End of school=17 for anyone else - 18 if born in Jan or Feb.
***3) If people reported finishing high school older than 20, then they probably had non continuous education, or reported post-secondary education under high schoo. We will look at school intervals for these people.

foreach var of varlist LH22_*A LH22_*B {
replace `var'=. if `var'==96    
} //replace grade as missing if=96 ("out of range")

egen max_grade=rowmax(LH22_*B) //highest grade completed

gen end_hl_school=max_hl_school_end

*if end of high school or lower is missing but people reported having completed 12th grade, we set end of high school at 17 or 18
replace end_hl_school=17 if end_hl_school==. & max_grade==12 & DEGREE>=2 & BIRTHMO>2
replace end_hl_school=18 if end_hl_school==. & max_grade==12 & DEGREE>=2 & BIRTHMO<=2

replace end_hl_school=(post_high_school_start1-1) if end_hl_school==. & DEGREE>=2 & post_high_school_start1>15 & post_high_school_start1<=19

**If they have a high school degree but missing end of school, we set it =17 or 18
replace end_hl_school=17 if end_hl_school==. & DEGREE>=2 & BIRTHMO>2 & lhms!=.
replace end_hl_school=18 if end_hl_school==. & DEGREE>=2 & BIRTHMO<=2 & lhms!=.

replace end_hl_school=(post_high_school_start1-1) if max_hl_school_end<16 & DEGREE>=2 & post_high_school_start1>15 & post_high_school_start1<=19
replace end_hl_school=17 if end_hl_school<16 & DEGREE>=2 & BIRTHMO>2
replace end_hl_school=18 if end_hl_school<16 & DEGREE>=2 & BIRTHMO<=2
***for people who have a degree lower than high school, we are keeping end_school<16

edit LH22_*D LH22_*E if end_hl_school>=20 & end_hl_school!=. //There are 121 people who finished high school older than 20
**if they have started post-secondary education younger than 20, we replace end of high school with start of post-secondary education-1
replace end_hl_school=(post_high_school_start1-1) if end_hl_school>=20 & end_hl_school!=. & post_high_school_start1<20

replace end_hl_school=17 if end_hl_school<16 & DEGREE>=2 & BIRTHMO>2 & post_high_school_start1==.
replace end_hl_school=18 if end_hl_school<16 & DEGREE>=2 & BIRTHMO<=2 & post_high_school_start1==.

**if they have missing end of school and degree<2 (lower than high school), we leave school end blank and assume that they ended school younger than 16

*********************************************************************************************
**Now we have to deal with post-secondary school
**Fill gaps for people who didn't list end of post-secondary school
tab DEGREE if missing_end_ph_school==1 //most people in this group have a high school degree, meaning that they didn't complete education. How should we deal with them? For how many years were they in school?

**1) If start of schooling is missing and degree listed as "not completed", we set the start one year before finishing. ???Is this a reasonable assumption?
forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-1) if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==8
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+1) if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==8
}

**2)If degree type is missing and DEGREE=high school, we will count only one year of education 

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j') if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==. & DEGREE==2
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j') if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==. & DEGREE==2
}


**3) If completed bachelor's degree with missing end or start date, we will count 4 years of school

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-3) if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==2  & DEGREE>3
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+3) if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==2  & DEGREE>3
}

**4) If completed associate degree or two years college degree with missing end or start date, we will count 2 years of school

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-1) if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==1|post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==3
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+1) if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==1|post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==3
}


**5) If completed high school equivalency with missing end or start date, we will count 1 year of school (???? reasonable?)

forval j=1/7 {
replace post_high_school_start`j'=post_high_school_end`j' if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==6
}

forval j=1/7 {
replace post_high_school_end`j'=post_high_school_start`j' if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==6
}

**6) If degree type is 7 ("Completed unspecified degree or certification") we will arbitrarily count 2 years of schooling

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-1) if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==7
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+1) if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==7
}

***Redefine missing start and end of high school

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

**7) If they report having a four year college degree or two year college degree (DEGREE=3 or 4) and further education with missing start or end date and unspecified degree, we won't count that education

forval j=2/7 {
replace post_high_school_end`j'=. if post_high_school_start`j'==. & post_high_school_end`j'!=. & post_high_school_start`=`j' - 1'!=. & post_high_school_end`=`j' - 1'!=. & DEGREE>2 & DEGREE<=4 & missing_start_ph_school==1
}

forval j=2/7 {
replace post_high_school_start`j'=. if post_high_school_start`j'!=. & post_high_school_end`j'==. & post_high_school_start`=`j' - 1'!=. & post_high_school_end`=`j' - 1'!=. & DEGREE>2 & DEGREE<=4 & missing_end_ph_school==1
}

forval j=3/7 {
replace post_high_school_end`j'=. if post_high_school_start`j'==. & post_high_school_end`j'!=. & post_high_school_start`=`j' - 2'!=. & post_high_school_end`=`j' - 2'!=. & DEGREE>2 & DEGREE<=4 & missing_start_ph_school==1
}

forval j=3/7 {
replace post_high_school_start`j'=. if post_high_school_start`j'!=. & post_high_school_end`j'==. & post_high_school_start`=`j' - 2'!=. & post_high_school_end`=`j' - 2'!=. & DEGREE>2 & DEGREE<=4 & missing_end_ph_school==1
}

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

**8)If DEGREE<=2 (high school or lower), and further education with no end or start date and unspecified degree, we don't count the additional education

forval j=1/7 {
replace post_high_school_end`j'=. if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==. & DEGREE<=2 & missing_start_ph_school==1
}

forval j=1/7 {
replace post_high_school_start`j'=. if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==. & DEGREE<=2 & missing_end_ph_school==1
}

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}


**9) If DEGREE=4 (four year college degree) and missing start or end date, we will count 4 years of schooling

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-3) if post_high_school_start`j'==. & post_high_school_end`j'!=. & LH35_`j'G==. & DEGREE==4 & missing_start_ph_school==1
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+3) if post_high_school_start`j'!=. & post_high_school_end`j'==. & LH35_`j'G==. & DEGREE==4 & missing_end_ph_school==1
}

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

**10) If they report having a master's degree with two completed stages of post-high school education and further education with missing start or end date and unspecified degree, we won't count the additional incomplete education

forval j=3/7 {
replace post_high_school_end`j'=. if post_high_school_start`j'==. & post_high_school_end`j'!=. & post_high_school_start`=`j' - 2'!=. & post_high_school_end`=`j' - 2'!=. & post_high_school_start`=`j' - 1'!=. & post_high_school_end`=`j' - 1'!=.  & DEGREE==5 & missing_start_ph_school==1
}

forval j=3/7 {
replace post_high_school_start`j'=. if post_high_school_start`j'!=. & post_high_school_end`j'==. & post_high_school_start`=`j' - 2'!=. & post_high_school_end`=`j' - 2'!=. & post_high_school_start`=`j' - 1'!=. & post_high_school_end`=`j' - 1'!=. & DEGREE==5 & missing_end_ph_school==1
}

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

**11) If Ph.D. with missing end date, we will count 5 years in school (Average time to complete a Ph.D. degree after Master's)

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-4) if post_high_school_start`j'==. & post_high_school_end`j'!=. & DEGREE==6 & missing_start_ph_school==1
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+4) if post_high_school_start`j'!=. & post_high_school_end`j'==. & DEGREE==6 & missing_end_ph_school==1
}

drop missing_start_ph_school missing_end_ph_school

gen missing_start_ph_school=0
gen missing_end_ph_school=0

forval j=1/7 {
replace missing_start_ph_school=1 if post_high_school_start`j'==. & post_high_school_end`j'!=.
}

forval j=1/7 {
replace missing_end_ph_school=1 if post_high_school_start`j'!=. & post_high_school_end`j'==.
}

*12) Checking remaining missing school ends/starts - reasonable to assume 2 years of school for each stage
edit post_high_school_start1-post_high_school_end7 DEGREE LH35_1G LH35_2G if missing_end_ph_school==1

forval j=1/7 {
replace post_high_school_start`j'=(post_high_school_end`j'-1) if post_high_school_start`j'==. & post_high_school_end`j'!=. & missing_start_ph_school==1
}

forval j=1/7 {
replace post_high_school_end`j'=(post_high_school_start`j'+1) if post_high_school_start`j'!=. & post_high_school_end`j'==. & missing_end_ph_school==1
}

**There are few observations where start of schooling is higher than end of schooling
**After checking those, it is reasonable to assume that the respondent switched start and end dates by mistake - switch values

forval j=1/7 {
gen difference_start_end`j'=post_high_school_start`j'-post_high_school_end`j'
gen post_high_school_start`j'_switched=post_high_school_end`j'
gen post_high_school_end`j'_switched=post_high_school_start`j'
replace post_high_school_start`j'=post_high_school_start`j'_switched if difference_start_end`j'>0 & difference_start_end`j'<10
replace post_high_school_end`j'=post_high_school_end`j'_switched if difference_start_end`j'>0 & difference_start_end`j'<10
replace post_high_school_start`j'=(post_high_school_end`j'-3) if difference_start_end`j'>10 & difference_start_end`j'!=.
drop difference_start_end`j' post_high_school_end`j'_switched post_high_school_start`j'_switched
}


**********Now that education start/end have been cleaned, we can generate education states
**********High School or lower
capture drop state_edu*
forval j = 1/65 {
    generate state_edu`j'="."
	replace state_edu`j'="school_hl_end" if end_hl_school==`j' & end_hl_school<20
	} //people with continuous high school education

**********People who finished high school later - take account of fragmented education
forval j = 1/65 {
	foreach var of varlist school_end* {
	replace state_edu`j'="school_hl_end" if `var'==`j' & state_edu`j'=="." & end_hl_school>19
	}
}

	forval j = 1/65 {
	foreach var of varlist school_start* {
	replace state_edu`j'=state_edu`j'+"school_hl_start" if `var'==`j' & !(strpos(state_edu`j', "start")) & end_hl_school>19
	}
	}

	gen school_one_year1=.
	replace school_one_year1=school_start1 if school_start1==school_end1
	
	forval k=2/10 {
	gen school_one_year`k'=.
	replace school_one_year`k'=school_start`k' if school_start`k'==school_end`k' & school_end`k'!=school_end`=`k' - 1'
	} //identify cases when start and end of schooling is on the same year
	
	foreach var of varlist state_edu* {
	local j=substr("`var'", 10, .)
	forval k=1/10 {
	replace `var'="school_one_year" if school_one_year`k'==`j' & end_hl_school>19
	}
	}
	
	drop school_one_year*

**********Fill the gaps and create education trajectories
forval j = 1/64 {
replace state_edu`j'="school" if strpos(state_edu`=`j' + 1', "end") & state_edu`j'=="."
}

foreach var of varlist state_edu* {
forval j = 1/64 {
replace state_edu`j'="school" if state_edu`=`j' + 1'=="school" & state_edu`j'=="."
}
}

foreach var of varlist state_edu* {
replace `var'="school_hl" if `var'!="."
}

***********Now do the same for post-high school education
forval j = 1/65 {
	foreach var of varlist post_high_school_end* {
	replace state_edu`j'="school_ph_end" if `var'==`j' & state_edu`j'=="." //ph=post high
	}
}

	forval j = 1/65 {
	foreach var of varlist post_high_school_start* {
	replace state_edu`j'=state_edu`j'+"school_ph_start" if `var'==`j' & state_edu`j'!="school_hl"
	}
	}

	gen school_ph_one_year1=.
	replace school_ph_one_year1=post_high_school_start1 if post_high_school_start1==post_high_school_end1
	
	forval k=2/7 {
	gen school_ph_one_year`k'=.
	replace school_ph_one_year`k'=post_high_school_start`k' if post_high_school_start`k'==post_high_school_end`k' & post_high_school_end`k'!=post_high_school_end`=`k' - 1'
	} //identify cases when start and end of schooling is on the same year
	
	foreach var of varlist state_edu* {
	local j=substr("`var'", 10, .)
	forval k=1/7 {
	replace `var'="school_one_year" if school_ph_one_year`k'==`j'
	}
	}
	
	drop school_ph_one_year*

***********Fill the gaps and create education trajectories for post-high school education
forval j = 1/64 {
replace state_edu`j'="school_ph" if strpos(state_edu`=`j' + 1', "end") & state_edu`j'=="."
}

foreach var of varlist state_edu* {
forval j = 1/64 {
replace state_edu`j'="school_ph" if state_edu`=`j' + 1'=="school_ph" & state_edu`j'=="."
}
}

foreach var of varlist state_edu* {
replace `var'="school_ph" if `var'!="." & `var'!="school_hl"
}

************CREATED EDUCATION TRAJECTORIES
save Dataset_cleaned, replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Dataset_cleaned.dta", clear
****LHMS JOB HISTORY
************2) Data cleaning
************Look at birth year variable
su BIRTHYR, d

************3)Generate age variables for start and end of each job

foreach var of varlist LH41_*A {
replace `var'=. if `var'==99997
replace `var'=. if `var'==9996
} //Replace to missing when survey was not completed (code =99997)

foreach var of varlist LH41_*B {
replace `var'=. if `var'==99997
replace `var'=. if `var'==9996
} //Replace to missing when survey was not completed (code =99997)

edit if LH41_1A !=. //8660 people of which we have job start/end information 

capture drop job_start* job_end*
foreach var of varlist LH41_*A {
 local suffix = substr("`var'", 6, 3)
  generate job_start`suffix'= `var'-BIRTHYR
  replace job_start`suffix'= `var'-BIRTHYR-1 if BIRTHMO>=6
} //Age at the start of each job
//take birth month into account to define age, e.g. if somebody was born in December 1960 and started a job in 1980, they are more likely to still be 20 when they started.
//Choose 06 birth month as cutoff

foreach var of varlist LH41_*B {
 local suffix = substr("`var'", 6, 3)
  generate job_end`suffix'= `var'-BIRTHYR
  replace job_end`suffix'= `var'-BIRTHYR-1 if BIRTHMO>=6
} //Age at the end of each job

renvars job_start1A-job_end10B, postdrop(1) //rename vars to have job# at the end

foreach var of varlist job_start* job_end* {
replace `var'=. if `var'<=1 //assume that it is a mistake, replace with missing value
}

*****Rename part time job variable - cut last digit so that it has number at the end
	foreach var of varlist LH41_*C {
	renvars "`var'", subst("LH41" "part_time")
	}
	
	foreach var of varlist part_time_*C {
	renvars "`var'", postdrop(1)
	}

*****Generate part_time dummy - used to determine how many part time jobs each person had
	forval i = 1/10 {
	gen part_time_dummy_`i'=0
	replace part_time_dummy_`i'=1 if part_time_`i'==2
	replace part_time_dummy_`i'=. if part_time_`i'==97
	} //part time dummy:0,1 or missing
	egen total_part_time=rowtotal(part_time_dummy_1-part_time_dummy_10)

**************4)generate gaps between jobs

*************CLEAN JOB GAPS VARIABLE
capture drop job_gap*
forval j = 1/9 {
    gen job_gap`j' = job_start`=`j' + 1' - job_end`j' //
	replace job_gap`j'= job_end`j'+1 if job_start`=`j' + 1'==.                                           
}

***************Generate reason for leaving after last job - different from a gap because we don't know when it starts and ends
//START FROM HERE!

capture drop mean_job_gap
egen mean_job_gap=rowmean(job_gap1 job_gap2 job_gap3 job_gap4 job_gap5 job_gap6 job_gap7 job_gap8 job_gap9)
edit if mean_job_gap==0 //these are the poeple with no job gaps

***************Look at jobs with missing start or end dates

gen missing_start_job=0

forval j=1/10 {
replace missing_start_job=1 if job_start`j'==. & job_end`j'!=.
}

gen missing_end_job=0

forval j=1/10 {
replace missing_end_job=1 if job_start`j'!=. & job_end`j'==.
}
****************We need to fix jobs with missing start/end with data from Core interviews

****Code age for start of job gaps
capture drop gap_start*
foreach var of varlist job_gap* {
 local suffix = substr("`var'", 8, .)
 generate gap_start`suffix'=job_end`suffix' if job_gap`suffix'>0 & job_gap`suffix'!=.
}
//rule: gap starts on the same year as job end. E.g. if someone stopped working in 1980 and started working again in 1981, the actual gap could be anywhere from 0 to 2 years. We code the variable so that it is in the middle (in this case, gap=1)

forval j=1/10 {
gen job_number`j'=`j' if job_start`j'!=. //variables that report the number of the job whose start is reported.	
}

egen max_job_number=rowmax(job_number1-job_number10) //this variable tells us which is the job with highest number for each individual.

*************************************GENERATE JOB STATES
***************5)generate "state" variables and code start of each job into the "state" variables
capture drop state1-state65
forval j = 1/65 {
    generate state`j'="."
	foreach var of varlist job_start* { 
	local i = substr("`var'", 10, .) 
	replace state`j'="JOB`i'" if job_start`i'==`j'
	}
}

****************6)
****Insert job gaps into state variables

forval j = 1/65 {
  	foreach var of varlist gap_start* { 
	local i = substr("`var'", 10, .) 
	replace state`j'=state`j'+"GAP`i'" if gap_start`i'==`j' & !strpos(state`j', "GAP'")
	}
}

foreach var of varlist LH41_*DM* {
replace	`var'=. if `var'==997
}

**Classify job gaps
**See Excel file named "UnemplGaps" with gaps combinations - decisions made based on logic and looking at the data.
 
foreach var of varlist state1-state65 {
forval j=1/10 {
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==3
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==2 & LH41_`j'DM3==3 
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==3 & LH41_`j'DM3==4
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==5  
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==9
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==4 
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==7 
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==97
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==6
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==3 & LH41_`j'DM3==9
replace `var'=subinstr(`var', "GAP`j'", "GAPFAMILY`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==3 & LH41_`j'DM3==7

replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==.
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==6
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==9
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==97
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==6 & LH41_`j'DM3==97
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==4
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==4 //RULE: if the person reports havng short term jobs (without specifying job dates) and being unemployed at the same time, we consider them unemployed.
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==2 & LH41_`j'DM3==4
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==4 & LH41_`j'DM3==7
replace `var'=subinstr(`var', "GAP`j'", "GAPUNEMPLOYMENT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==4 & LH41_`j'DM3==97

replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==5 & LH41_`j'DM2==.
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==5
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==5
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==5 & LH41_`j'DM2==6
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==5
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==5 & LH41_`j'DM3==6
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==5 & LH41_`j'DM3==97
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==5 & LH41_`j'DM2==97
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==5 & LH41_`j'DM2==9
replace `var'=subinstr(`var', "GAP`j'", "GAPDISABILITY`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==4 & LH41_`j'DM3==5

replace `var'=subinstr(`var', "GAP`j'", "GAPRETIREMENT`j'", 1) if LH41_`j'DM1==6 & LH41_`j'DM2==.
replace `var'=subinstr(`var', "GAP`j'", "GAPRETIREMENT`j'", 1) if LH41_`j'DM1==6 & LH41_`j'DM2==97

replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==7 & LH41_`j'DM2==.
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==7 & LH41_`j'DM2==97
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==4 & LH41_`j'DM2==7
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==7
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==6 & LH41_`j'DM2==7
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==5 & LH41_`j'DM3==6
replace `var'=subinstr(`var', "GAP`j'", "GAPEDU`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==7 & LH41_`j'DM3==97

//gaps that we cannot classify in one of the other categories
replace `var'=subinstr(`var', "GAP`j'", "GAPELSE`j'", 1) if LH41_`j'DM1==10 & LH41_`j'DM2==. 
replace `var'=subinstr(`var', "GAP`j'", "GAPELSE`j'", 1) if LH41_`j'DM1==6 & LH41_`j'DM2==97
replace `var'=subinstr(`var', "GAP`j'", "GAPELSE`j'", 1) if LH41_`j'DM1==10 & LH41_`j'DM2==97
replace `var'=subinstr(`var', "GAP`j'", "GAPELSE`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==10

replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==. 
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==2 
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==97 
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==9
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==6
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==2 & LH41_`j'DM3==6
replace `var'=subinstr(`var', "GAP`j'", "GAPSHORT`j'", 1) if LH41_`j'DM1==2 & LH41_`j'DM2==8

replace `var'=subinstr(`var', "GAP`j'", "GAPSELF`j'", 1) if LH41_`j'DM1==8 & LH41_`j'DM2==.
replace `var'=subinstr(`var', "GAP`j'", "GAPSELF`j'", 1) if LH41_`j'DM1==1 & LH41_`j'DM2==8
replace `var'=subinstr(`var', "GAP`j'", "GAPSELF`j'", 1) if LH41_`j'DM1==8 & LH41_`j'DM2==97
}
}

//Later, "short term jobs" and "self employment" will be collapsed into "work"
**???? If someone starts working to take care of kids and never reenters the labor force, at which point do we consider them unemployed or retired? We are thinking to stop "caring for family" after 25 years (still have to check how many cases)
	
********SET JOB ENDS
	foreach var of varlist state1-state65 {
forval j = 2/65 {
forval k=1/10 {
replace state`j'="END_JOB`k'" if job_end`k'==`j' & state`j'=="." //set end of jobs within states
}
}
	}
	
***clean trajectories when first job ends before start and end of second job, etc.
*edit state16-state65 if job_start1<job_start2 & job_end1>job_end2 & job_end1!=. & part_time_dummy_1==0
	
*****Code part time job
  	foreach var of varlist state1-state65 { 
	forvalues j = 1/10 {
	replace `var'=subinstr(`var', "JOB`j'", "PART_TIME_JOB`j'", 1) if strpos(`var', "JOB`j'") & part_time_`j'==2 & !strpos(`var', "PART_TIME'")
	}
	}

******CARRY FORWARD JOB STATES
foreach var of varlist state1-state65 {
forval j = 2/65 {
forval k=1/10 {
replace state`j'=state`j'+"+"+state`=`j' - 1' if strpos(state`=`j' - 1', "JOB`k'") & job_end`k'!=. & `j'<job_end`k' & !strpos(state`j', "+")
}
}
}

foreach var of varlist state1-state65 {
replace `var'=subinstr(`var', "+", "", .)
replace `var'=subinstr(`var', ".", "", .) if `var'!="."	
}

******CARRY FORWARD JOB GAPS
foreach var of varlist state1-state65 {
forval j = 2/65 {
forval k=1/10 {
replace state`j'=state`=`j' - 1' if state`j'=="." & strpos(state`=`j' - 1', "GAP") & !(strpos(state`=`j'-1', "END"))
}
}
}

****MERGE JOB STATES WITH EDUCATION STATES (obtained above)

forval j = 16/65 {
  	foreach var of varlist state16-state65 { 
	replace state`j'=state`j'+"school" if strpos(state_edu`j', "school") & !(strpos(state`j', "school"))
	}
	}
	
 save, replace
 
 //Replace gaps where more than one item ("what did you do after leaving that job") was reported 
 
 foreach var of varlist state60-state65 {
 	forval j=1/9 {
 replace `var'=subinstr(`var', "GAPUNEMPLOYMENT`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==6 & LH41_`j'DM2==4 & LH41_`j'DM3==. & gap_start`j'>=60
 replace `var'=subinstr(`var', "GAPUNEMPLOYMENT`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==6 & LH41_`j'DM2==4 & LH41_`j'DM3==97 & gap_start`j'>=60
 replace `var'=subinstr(`var', "GAPSHORT`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==2 & LH41_`j'DM2==6 & gap_start`j'>=60
  replace `var'=subinstr(`var', "GAPFAMILY`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==3 & LH41_`j'DM2==6 & gap_start`j'>=60
    replace `var'=subinstr(`var', "GAPEDU`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==6 & LH41_`j'DM2==7 & gap_start`j'>=60
	replace `var'=subinstr(`var', "GAPSHORT`j'", "GAPRETIREMENT`j'", .)	if LH41_`j'DM1==1 & LH41_`j'DM2==2 & LH41_`j'DM3==6 & gap_start`j'>=60
	replace `var'=subinstr(`var', "GAPFAMILY`j'", "GAPRETIREMENT`j'", .) if LH41_`j'DM1==1 & LH41_`j'DM2==3 & LH41_`j'DM3==6 & gap_start`j'>=60
	}
 }
 
 
 //NEW - after looking at data. If reports being retired after a job and age < 50, assume that they didn't get retired right away and replace with "." (it will be filled with core surveys)
  foreach var of varlist state60-state65 {
 	forval j=1/9 {
	replace `var'=subinstr(`var', "GAPRETIREMENT`j'", ".", .)	if LH41_`j'DM1==6 & LH41_`j'DM2==. & gap_start`j'<=50	
	}
  }
 
 *****Look at data completeness - how much missing data?
 
capture drop state_info*
capture drop total_state_info_LHMS
 forval j = 18/65 {
gen state_info`j'=0
replace state_info`j'=1 if state`j'!="."
replace state_info`j'=0 if state`j'=="GAP1"|state`j'=="GAP2"|state`j'=="GAP3"|state`j'=="GAP4"|state`j'=="GAP5"|state`j'=="GAP6"|state`j'=="GAP7"|state`j'=="GAP8"|state`j'=="GAP9"|state`j'=="GAP10"
}

egen total_state_info_LHMS=rowtotal(state_info18-state_info65)

su total_state_info_LHMS if lhms!=. & BIRTHYR<=1947, d //

save, replace

********************************************************************************
********************************************************************************
****DEFINE FINAL NAMES

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Dataset_cleaned.dta", clear

foreach var of varlist state1-state65 { 
replace `var'=subinstr(`var', "PART_TIME_JOB", "PARTTIME", .)
}

foreach var of varlist state1-state65 { 
replace `var'=subinstr(`var', "END_JOB", "END", .)
}

foreach var of varlist state1-state65 { 
replace `var'=subinstr(`var', "END_PARTTIME", "ENDPT", .)
}

foreach var of varlist state1-state65 { 
forval k=1/10 {
replace `var'=subinstr(`var', "PARTTIME`k'", "", .) if strpos(`var', "PARTTIME`k'") & strpos(`var', "END_PARTTIME`k'")
}
}

foreach var of varlist state1-state65 { 
forval k=1/10 {
replace `var'=subinstr(`var', "PARTTIME`k'", "", .) if strpos(`var', "PARTTIME`k'") & strpos(`var', "ENDPT`k'")
}
}

****"WORK" IF THERE IS AT LEAST ONE FULL TIME JOB
****"Employed" states
foreach var of varlist state1-state65 { 
replace `var'="WORK" if strpos(`var', "JOB") 
replace `var'="PART_TIME" if strpos(`var', "PARTTIME") & !strpos(`var', "JOB") & !strpos(`var', "school")
replace `var'="PART_TIME_SCHOOL" if strpos(`var', "PARTTIME") & !strpos(`var', "JOB") & strpos(`var', "school")
replace `var'="PART_TIME_SCHOOL" if strpos(`var', "PARTTIME") & !strpos(`var', "JOB") & strpos(`var', "school")
}

foreach var of varlist state1-state65 { 
replace `var'="SCHOOL" if strpos(`var', "school") & strpos(`var', "GAP")
replace `var'="SCHOOL" if `var'=="school"
replace `var'="SCHOOL" if `var'==".school"
replace `var'="SCHOOL" if strpos(`var', "GAPEDU")
}

foreach var of varlist state1-state65 { 
replace `var'="TEMP" if strpos(`var', "GAPSHORT")
}

foreach var of varlist state1-state65 { 
replace `var'="FAMILY" if strpos(`var', "FAMILY") 
replace `var'="UNEMPLOYMENT" if strpos(`var', "UNEMPLOYMENT") 
replace `var'="DISABLED" if strpos(`var', "DISABILITY") 
replace `var'="RETIRED" if strpos(`var', "RETIREMENT") 
replace `var'="OTHER" if strpos(`var', "ELSE") 
}

foreach var of varlist state1-state65 { 
replace `var'="PART_TIME" if strpos(`var', "ENDPT")
}

foreach var of varlist state1-state65 { 
replace `var'="WORK" if strpos(`var', "END")
replace `var'="WORK" if strpos(`var', "SELF") //RULE: SELF EMPLOYMENT = FULL TIME WORK
}

foreach var of varlist state1-state65 { 
replace `var'="GAP_OTHER" if strpos(`var', "GAP")
}

save, replace

******************Look at length of family gaps
forval j = 18/65 {
gen state_family`j'=0
replace state_family`j'=1 if state`j'=="FAMILY"
}

egen total_state_family=rowtotal(state_family18-state_family65)

drop state_family*

forval j = 18/65 {
gen state_school`j'=0
replace state_school`j'=1 if state`j'=="SCHOOL"
}

egen total_state_school=rowtotal(state_school18-state_school65)

drop state_school*

**************************************************************
******************MERGE LHMS WITH CORE SURVEYS
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Dataset_cleaned.dta", clear
capture drop _merge
capture drop state1_1992-state110_1992 state1_1993-state110_1993 state1_1994-state110_1994 state1_1995-state110_1995 state1_1996-state110_1996 state1_1998-state110_1998 state1_2000-state110_2000 state1_2002-state110_2002 state1_2004-state110_2004 state1_2006-state110_2006 state1_2008-state110_2008 state1_2010-state110_2010 state1_2012-state110_2012 state1_2014-state110_2014 state1_2016-state110_2016 state1_2018-state110_2018 state1_2020-state110_2020 total_state_info_*
sort key
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r_MERGED.dta"

*****Label Core Survey states and find the mode (most frequent state between different survey years)

foreach var of varlist state1_1992-state110_1992 state1_1993-state110_1993 state1_1994-state110_1994 state1_1995-state110_1995 state1_1996-state110_1996 state1_1998-state110_1998 state1_2000-state110_2000 state1_2002-state110_2002 state1_2004-state110_2004 state1_2006-state110_2006 state1_2008-state110_2008 state1_2010-state110_2010 state1_2012-state110_2012 state1_2014-state110_2014 state1_2016-state110_2016 state1_2018-state110_2018 state1_2020-state110_2020{
replace `var'="1" if `var'=="work"
replace `var'="2" if `var'=="unemployed"|`var'=="temp_leave" //put unemployed and temp_leave in the same category
replace `var'="3" if `var'=="retired"
replace `var'="4" if `var'=="disabled"
replace `var'="5" if `var'=="homemaker"
replace `var'="7" if `var'=="part_time"
destring `var', replace
}

foreach var of varlist state1_1992-state110_1992 state1_1993-state110_1993 state1_1994-state110_1994 state1_1995-state110_1995 state1_1996-state110_1996 state1_1998-state110_1998 state1_2000-state110_2000 state1_2002-state110_2002 state1_2004-state110_2004 state1_2006-state110_2006 state1_2008-state110_2008 state1_2010-state110_2010 state1_2012-state110_2012 state1_2014-state110_2014 state1_2016-state110_2016 state1_2020-state110_2020{
label define var_label 1 "work" 2 "unemployed" 3 "retired" 4 "disabled" 5 "homemaker" 7 "part_time", replace
label values `var' var_label 
}

save, replace

//THEN FIND THE MODE BETWEEN AVAILABLE YEARS
******need to reshape long

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/Dataset_cleaned.dta", clear

keep HHID PN state* lhms BIRTHYR LH38 LH13
drop state_info*
drop state_edu*

forval j=1/65 {
rename state`j' lhms`j'	
}

gen key=HHID+PN

reshape long state1_ state2_ state3_ state4_ state5_ state6_ state7_ state8_ state9_ state10_ state11_ state12_ state13_ state14_ state15_ state16_ state17_ state18_ state19_ state20_ state21_ state22_ state23_ state24_ state25_ state26_ state27_	state28_ state29_ state30_ state31_ state32_ state33_ state34_ state35_ state36_ state37_ state38_ state39_ state40_ state41_ state42_ state43_ state44_ state45_ state46_ state47_ state48_ state49_ state50_ state51_ state52_ state53_ state54_ state55_ state56_ state57_ state58_ state59_ state60_ state61_ state62_ state63_ state64_ state65_, i(key) j(year)

capture drop state66_2018-state110_1992
capture drop state66_1995-state110_1993
capture drop state66_2020-state110_2020
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_long.dta", replace

sort key year
forval j=1/65 {
bysort key: egen mean`j'=mean(state`j'_)
}

capture drop mode*
forval j=1/65 {
bysort key: egen mode`j'=mode(state`j'_)
}

******
******If there is more than one mode, take the most recent value
renvars state1_-state65_, postdrop(1)

forval j=1/65 {
gen year`j'=year if state`j'!=.
} //lists the years when core survey states are available

forval j=1/65{
bysort key: egen max_year`j'=max(year`j')
} //Identify the most recent year

capture drop state*_max state*_max_mean
forval j=1/65 {
gen state`j'_max=state`j' if max_year`j'==year`j'
bysort key: egen state`j'_max_mean=mean(state`j'_max)
} //Identify most recently reported state

//RULE: Replace mode with most recent state value if there is more than one mode
forval j=1/65 {
replace mode`j'=state`j'_max_mean if mode`j'==. & mean`j'!=.
}

edit key year mode*

******Discordance in states between Core Survey years
******Look at when mode is different from mean 
forval j=1/65 {
gen discordance`j'=0 if lhms!=. & mean`j'!=.
replace discordance`j'=1 if discordance`j'==0 & mean`j'!=mode`j'
}

egen discordance_total=rowtotal(discordance18-discordance65) if year==1992

forval j=1/65 {
gen core_survey_state`j'=1 if lhms!=. & mean`j'!=.
}

egen core_survey_state_total=rowtotal(core_survey_state18-core_survey_state65) if year==1992

*****Rename LHMS states to make them consistent with Core Survey ones [Create new var so that we don't loose information]
*foreach var of varlist lhms1-lhms65{
*replace `var'="." if `var'=="GAP_OTHER"
*} //We consider "GAP OTHER" as missing --> we don't know if they were actually unemployed and why

capture drop lhms_conc*
forval j=1/65 {
gen lhms_conc`j'=lhms`j'
}

foreach var of varlist lhms_conc*{
replace `var'="1" if `var'=="WORK"|`var'=="TEMP"
replace `var'="2" if `var'=="UNEMPLOYMENT" 
replace `var'="3" if `var'=="RETIRED"
replace `var'="4" if `var'=="DISABLED"
replace `var'="5" if `var'=="FAMILY"
replace `var'="7" if `var'=="PART_TIME"|`var'=="PART_TIME_SCHOOL"
replace `var'="." if `var'=="SCHOOL"
replace `var'="." if `var'==".school"
replace `var'="." if `var'=="GAP_OTHER"
replace `var'="." if `var'=="OTHER"
destring `var', replace
}

capture drop discordance_lhms*
forval j=1/65 {
gen discordance_lhms`j'=0 if lhms!=. & mode`j'!=. & lhms_conc`j'!=.
replace discordance_lhms`j'=1 if discordance_lhms`j'==0 & lhms_conc`j'!=mode`j'
}

egen discordance_lhms_total=rowtotal(discordance_lhms18-discordance_lhms65) if year==1992

capture drop core_survey_lhms_state*
forval j=1/65 {
gen core_survey_lhms_state`j'=1 if mode`j'!=. & lhms_conc`j'!=.
}

egen core_survey_lhms_state_total=rowtotal(core_survey_lhms_state18-core_survey_lhms_state65) if year==1992

***********Discordance by individual
gen disc_rate_cs_lhms=discordance_lhms_total/core_survey_lhms_state_total

***********States avalability in LHMS only
capture drop lhms_state*
forval j=1/65 {
gen lhms_state`j'=1 if lhms`j'!="" & lhms`j'!="."
}

egen lhms_state_total=rowtotal(lhms_state18-lhms_state65) if year==1992
gen avail_lhms_rate=lhms_state_total/48

**********Create joint variable LHMS - Core Surveys
**Replace missings from LHMS with Core Surveys values

foreach var of varlist lhms1-lhms65{
replace `var'="1" if `var'=="WORK"
replace `var'="2" if `var'=="UNEMPLOYMENT" 
replace `var'="3" if `var'=="RETIRED"
replace `var'="4" if `var'=="DISABLED"
replace `var'="5" if `var'=="FAMILY"
replace `var'="6" if `var'=="SCHOOL"
replace `var'="6" if `var'==".school"
replace `var'="7" if `var'=="PART_TIME"
replace `var'="8" if `var'=="PART_TIME_SCHOOL"
replace `var'="9" if `var'=="TEMP"
replace `var'="10" if `var'=="OTHER"
replace `var'="11" if `var'=="GAP_OTHER"
destring `var', replace
}

capture drop lhms_cs_joint*
forval j=1/65 {
gen lhms_cs_joint`j'=lhms`j'
replace lhms_cs_joint`j'=mode`j' if mode`j'!=. & lhms_cs_joint`j'==.
}

********Availability for joint data: LHMS+Core Surveys
forval j=1/65 {
gen lhms_cs_joint_state`j'=1 if lhms_cs_joint`j'!=.
}

egen lhms_cs_joint_total=rowtotal(lhms_cs_joint_state18-lhms_cs_joint_state65) if year==1992
gen avail_lhms_cs_joint_rate=lhms_cs_joint_total/48

label define lhms 1 "WORK" 2 "UNEMPLOYMENT" 3 "RETIRED" 4 "DISABLED" 5 "FAMILY" 6 "SCHOOL" 7 "PART_TIME" 8 "PART_TIME_SCHOOL" 9 "TEMP" 10 "OTHER" 11 "GAP_OTHER"
foreach var of varlist lhms1-lhms65{
	label values `var' lhms
}

save, replace

*******START FROM HERE
*******Fill in with Core Survey Mode
*******If there is an alternative from Core Surveys that is not retirement, replace 

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_long.dta", clear

capture drop state66-state110
save, replace

********Further cleaning step: identify early retirees = appear retired between age 18 and age 50
********

gen early_retired=0

foreach var of varlist mode18-mode49 {
replace early_retired=1 if `var'==3
}

capture drop disabled* unemployed* homemaker* work* part_time*
forval j=18/49 {
gen disabled`j'=1 if state`j'==4
gen unemployed`j'=1 if state`j'==2
gen homemaker`j'=1 if state`j'==5
gen work`j'=1 if state`j'==1
gen part_time`j'=1 if state`j'==7
}

egen disabled_18_49=rowtotal(disabled*)
egen unemployed_18_49=rowtotal(unemployed*)
egen homemaker_18_49=rowtotal(homemaker*)
egen work_18_49=rowtotal(work*)
egen part_time_18_49=rowtotal(part_time*)

capture drop max_disabled_18_49 max_unemployed_18_49 max_homemaker_18_49 max_work_18_49 max_part_time_18_49
bysort HHID PN:egen max_disabled_18_49=max(disabled_18_49)
bysort HHID PN:egen max_unemployed_18_49=max(unemployed_18_49)
bysort HHID PN:egen max_homemaker_18_49=max(homemaker_18_49)
bysort HHID PN:egen max_work_18_49=max(work_18_49)
bysort HHID PN:egen max_part_time_18_49=max(part_time_18_49)

save, replace

//RULE: if the person reports early retirement but other surveys show different states between age 18-age 49, replace retirement between age 18-age 49 with missing.
foreach var of varlist state18-state49 {
replace `var'=. if early_retired==1 & `var'==3 & max_disabled_18_49>0|early_retired==1 & `var'==3 & max_unemployed_18_49>0|early_retired==1 & `var'==3 & max_homemaker_18_49>0|early_retired==1 & `var'==3 & max_work_18_49>0
}

**************Recreate the mode after cleaning the early retirement trajectories
capture drop mode*
forval j=1/65 {
bysort key: egen mode`j'=mode(state`j')
}

capture drop year1-year65 max_year*
forval j=1/65 {
gen year`j'=year if state`j'!=.
} //lists the years when core survey states are available

forval j=1/65{
bysort key: egen max_year`j'=max(year`j')
} //Identify the most recent year

capture drop state*_max state*_max_mean
forval j=1/65 {
gen state`j'_max=state`j' if max_year`j'==year`j'
bysort key: egen state`j'_max_mean=mean(state`j'_max)
} //Identify most recently reported state

//RULE: Replace mode with most recent state value if there is more than one mode
forval j=1/65 {
replace mode`j'=state`j'_max_mean if mode`j'==. & mean`j'!=.
}

edit key year mode*

********Make file smaller, keep only core survey mode and LHMS
egen id=group(key)

keep if year==1992
drop year* state* state*_max state*_max_mean max_year* discordance* core_survey* disc_rate_cs_lhms lhms_state* avail_lhms_rate lhms_cs_joint* avail_lhms_cs_joint_rate lhms_conc*

rename lhms lhms_study

reshape long lhms mean mode, i(id) j(age)
drop mean
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_small.dta", replace

use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_small.dta", clear

********RULE: if family gaps last more than 25 years, stop after 25 years
capture drop start_family
gen start_family=.
bysort id:replace start_family=1 if lhms==3 & lhms[_n-1]!=3

capture drop cont_family
gen cont_family=start_family
bysort id:replace cont_family=cont_family[_n-1]+1 if cont_family[_n-1]!=. & lhms==3

replace lhms=. if cont_family>25 & cont_family!=.

********RULE: if continuous schooling lasts more than 30 years, stop after 30 years
capture drop start_edu
gen start_edu=.
bysort id:replace start_edu=1 if lhms==6 & lhms[_n-1]!=6

capture drop cont_edu
gen cont_edu=start_edu
bysort id:replace cont_edu=cont_edu[_n-1]+1 if cont_edu[_n-1]!=. & lhms==6

replace lhms=. if cont_edu>30 & cont_edu!=.

*******Fill gaps for mode
capture drop mode_nogaps
gen mode_nogaps=mode
by id: replace mode_nogaps=mode_nogaps[_n-1] if age>50 & mode_nogaps[_n-1]==mode_nogaps[_n+1] & mode_nogaps==.

*******Merge lhms and core survey mode
capture drop state
gen state=lhms
replace state=mode if lhms==.

*******Merge lhms and core survey mode after filling gaps
capture drop state_nogaps
gen state_nogaps=lhms
replace state_nogaps=mode_nogaps if lhms==.
replace state_nogaps=mode_nogaps if lhms==11 & mode_nogaps!=. //replace "other gaps" 

*******KEEP LHMS sample only
drop if lhms_study==.
save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_small_lhms.dta", replace
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_small_lhms.dta", clear

replace state_nogaps=11 if state_nogaps==. //GAPS "UNSPECIFIED" (or missing)

******RULE: if somebody has no education from LHMS but reports degree or school years from tracker
sort key age
merge key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r.dta", keep (GENDER RACE SCHLYRS DEGREE)
tab _merge
drop if _merge==2

drop if age<16

capture drop school mean_school
gen school=1 if state_nogaps==6
bysort id: egen mean_school=mean(school)

tab DEGREE if mean_school==. & age==18 //there are a few people who have high school or higher degree, and no reported education

//If they have high school diploma but no reported schooling and missing state at age 18, assume that they were in school at age 18
replace state_nogaps=6 if mean_school==. & age==18 & DEGREE>=2 & DEGREE!=9 & DEGREE!=. & state_nogaps==11

**************FINAL DATABASE for sequences
drop if age<18

tab state_nogaps, mis

drop start_family cont_family start_edu cont_edu state mode* lhms*
rename state_nogaps state

label define state 1 "WORK" 2 "UNEMPLOYMENT" 3 "RETIRED" 4 "DISABLED" 5 "FAMILY" 6 "SCHOOL" 7 "PART_TIME" 8 "PART_TIME_SCHOOL" 9 "TEMP_WORK" 10 "OTHER" 11 "MISSING"
label values state state

****************************************************									
*************CLEAN KIDS' FILE
use "/Users/lpacca/Downloads/randhrsfam1992_2014v1_STATA/randhrsfamk1992_2014v1.dta", clear
gen key=hhid+pn
sort key
merge m:1 key using "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/data/trk2018tr_r.dta"
drop if _merge==2

capture drop bdate_firstkid bdate_lastkid
gen birthyear_ownkid=k1byear if karel==1
bysort key: egen bdate_firstkid=min(birthyear_ownkid) //no stepkids
bysort key: egen bdate_lastkid=max(birthyear_ownkid)

gen age_firstkid=bdate_firstkid-BIRTHYR //age at which respondent had their first kid
replace age_lastkid=bdate_lastkid-BIRTHYR

replace age_firstkid=. if age_firstkid<=10
replace age_lastkid=. if age_lastkid<=10|age_firstkid<=10

gen age_lastkid_five=age_lastkid+5

save, replace

**************Characterize spell length 
tsset id age
tsspell state

save "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", replace

**************Merge with kids file to identify kids' ages
use "/Users/lpacca/Library/CloudStorage/Box-Box/01 - Occupation Trajectories/States_sq.dta", clear

capture drop _merge

sort key

merge m:m key using "/Users/lpacca/Downloads/randhrsfam1992_2014v1_STATA/randhrsfamk1992_2014v1.dta", keepusing (age_firstkid age_lastkid_five)

drop if _merge==2

replace age_firstkid=. if age<age_firstkid|age>age_lastkid_five
replace age_lastkid_five=. if age<age_firstkid|age>age_lastkid_five //mark only years when respondents had kids

//ALTERNATIVE STATES WHERE "MISSING" IS REPLACED WITH "FAMILY" FOR WOMEN WITH KIDS 5 OR YOUNGER
capture drop state_new
gen state_new=state
replace state_new=5 if GENDER==2 & state==11 & age_firstkid!=.

bysort id _spell: egen gap_length=max(_seq)
*************
replace state_new=1 if state_new==11 & LH13==age //if they report start age of first job from LH13 variable, add it to the sequence
replace state_new=2 if state_new==11 & gap_length==1 //if gap=1 year, assume unemployment
replace state_new=2 if state_new==10 //"other" (unspecified) gaps --> assume unemployment
replace state_new=7 if state_new==8 //part time school --> same as part time
replace state_new=1 if state_new==9 //temp work -->work
replace state_new=8 if state_new==11 //Missing or "unreported"
save, replace







