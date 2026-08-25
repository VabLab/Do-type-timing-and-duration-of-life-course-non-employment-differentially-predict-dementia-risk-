# Do-type-timing-and-duration-of-life-course-non-employment-differentially-predict-dementia-risk-
Code for the "Do type, timing and duration of life course non-employment differentially predict dementia risk? An application of sequence analysis" publication

Link to paper: https://www.sciencedirect.com/science/article/abs/pii/S0277953625003065 

# Authors
Lucia Pacca, S. Amina Gaye, Willa D. Brenowitz, Kaori Fujishiro, M. Maria Glymour, Amal Harrati and Anusha M. Vable

# Abstract
Periods out of employment may influence dementia, but characterizing lifecourse employment is difficult and prior research is sparse. This study used sequence and cluster analysis to characterize type, timing, and duration of lifecourse work gaps and estimate associations with dementia risk.

Life History Mail Survey supplement to the U.S. Health Retirement Study participants (N = 5,945, 13.6 % of the Health and Retirement Study sample) reported lifecourse employment (full time or part time) and reasons and age of work gaps (unemployment, schooling, caregiving, or disability). Our exposure was gender-stratified employment trajectories from age 18–65, characterized using sequence analysis and cluster analysis. Our outcomes were algorithmically defined dementia probability scores and memory scores. We estimated the association between employment trajectories and dementia risk using generalized estimating equations and memory decline using linear mixed effect models, adjusted for age, gender, birthplace, and childhood socioeconomic status.

We identified 11 employment trajectories for women (including predominant work, disability, unemployment, caregiving, retirement) and 10 for men (similar, but no caregiving). Compared to “predominant work”, “disability” and “unemployment” trajectories were associated with higher dementia risk for men and women (e.g., disability among women: OR = 3.62; 95 % CI = 2.25, 5.81). Among women who cared for family, those who did not re-enter the labor force full-time had higher dementia risk (e.g. “family gap, go back part time”: OR = 1.79; 95 % CI = 1.15, 2.79) compared to the predominant work cluster. Women who cared for family and returned to full-time work had similar cognitive outcomes to those in the predominant work cluster. Men who had long spells of part-time work also had elevated dementia risk (e.g. part time earlier: OR = 1.64; 95 % CI = 1.16, 2.57). Finally, women and men with long periods of unreported employment status had higher dementia risk than those in the predominant work trajectory.

Results suggest the type, timing and duration of work gaps are differentially associated with dementia risk. Work gaps due to disability, unemployment or unreported employment status predicted higher dementia risk. Permanently leaving full-time work for caregiving predicted worse cognitive outcomes but temporary caregiving-related work interruptions did not.

# Repository Content
**01 - Data_Cleaning.do:** This .do file prepares the HRS analytic data by selecting and merging variables from the Tracker, Life History Mail Survey (LHMS), and 1992–2018 Core Surveys. It cleans job histories from the Core Surveys and education and life-course employment histories from the LHMS, then combines these sources and applies rules to define the final employment trajectories.

**02 - Sequence_Analysis_OM.do:** This .do file conducts sequence and cluster analyses of life-course employment trajectories separately for men and women, using optimal matching to calculate sequence dissimilarities and identify groups with similar employment trajectories (primary approach).

**03 - Sequence_Analysis_DH.do:** This .do file conducts sequence and cluster analyses of life-course employment trajectories separately for men and women, using Dynamic Hamming matching to calculate sequence dissimilarities and identify groups with similar employment trajectories (sensitivity analysis).

**04 - Data_Analysis.do:** This .do file prepares the final analytic dataset and conducts the main analyses. It cleans the dementia probability and memory outcomes, applies the inclusion and exclusion criteria, identifies participants who died or dropped out during follow-up, merges the analytic sample with the employment trajectory clusters derived using optimal matching, creates covariates, and estimates associations between employment trajectory clusters and cognitive outcomes.

Data used in this study are available through the Health and Retirement Study (HRS) public files, including the main HRS survey data and the Life History Mail Survey (LHMS).

# Contact Information
lucia.pacca88@gmail.com



