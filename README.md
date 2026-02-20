# _Data Science Introduction_
## Work in progress -- some extended codes [here](https://github.com/mishahoskins/Portfolio/tree/main)


Mikhail Hoskins
## Contact
 (919) 357-5145 | mishahoskins@gmail.com ; mhoskins@tulane.edu 

[LinkedIn](https://www.linkedin.com/in/mikhail-hoskins/) | [GitHub](https://github.com/mishahoskins)

## Professional Summary
Healthcare data scientist and infectious disease epidemiologist with 6+ years of experience designing analytics solutions across EHR, claims, and surveillance data. Specialized in statistical modeling, risk stratification, and production ETL pipelines to support clinical, operational, and policy decisions. Unstructered and semistructured data --> usable analysis.

## Education

- Dr.PH., Social and Behavioral Sciences, Tulane University (_May 2025_) 
- MPH., Epidemiology, The University of North Carolina at Charlotte (_May 2022_) 
- B.A., International Studies, North Carolina State University (_May 2013_) 
  - Spanish Language, International Relations Field Study, Universidad Nacional, Costa Rica (_June 2012_) 

## Work Experience

- Senior Epidemiologist Healthcare Data Scientist CDC Foundation (North Carolina) | Jun 2024 – Present
- Population Health Analyst III (Claims & Predictive Analytics) North Carolina Department of Health Benefits | Jan 2024 – Jun 2024
- Epidemiologist Applied Data Science & Population Health Analytics CDC Foundation (North Carolina) | Nov 2021 – Jan 2024
- Epidemiologist NC Department of Health & Human Services | May 2019 – Nov 2021

## Projects
### North Carolina Medicare Prescribing Practices 2018-2023
Code highlight: [Analysis](https://github.com/mishahoskins/Portfolio/blob/22e05426f16fe639bc0698f3e9baff9ac16adde3/Medicare_ptD_analysis_new.sas#L400-L706) | [Visualization](https://github.com/mishahoskins/test_pages/blob/3644ba59410818e8c0c58df6b502ccca7ad18cba/Medicare_ptD_tables_29JAN26.pdf)

Created a transferable quantile regression model to assess prescribing practices across presriber types and locations in North Carolina from semi structured Medicare data. The model, building and adding to prior publications and implemented using **SQL**, expands on the existing body of work.  

**Tech stack:** SQL, SAS

**Methods:** Quantile regression modeling, risk modeling

### North Carolina Measles Response Pipleline (_any values simulated_)
Code highlight: [Markdown Organization](https://github.com/mishahoskins/test_pages/blob/65aad58d2e5b4da08b832aec4c4a8be4b89d8c68/Measles_metrics_25_26_markdown_output.Rmd#L15-L137)

Built internal **R**-based script to inform public health response to measles activity in North Carolina from scratch. Results are presented in a visually appealing **R Markdown** HTML report including hover over maps, epidemiological curves, and tables. 

**Tech stack:** R, R Markdown

### EHR Engineering and Antibiogram Visualization of NHSN Unstructured Antibiotic Susceptibility Data
Code highlight: [Looping through ALL drug classes](https://github.com/mishahoskins/Portfolio/blob/dfca56eb42aee6bd7f0b1305369dd2080d00f9f0/antibiogram_condensed.sas#L253-L297)

Developed a structured data workflow using unstructured data to analyze antimicrobial resistance by grouping treatments by drug class and susceptibility. Implemented  processing using **SAS** macros and **SQL**, with reproducible outputs designed for downstream analysis in **R** and **Python**.

**Tech stack:** R, SQL, SAS, Microsoft SQL Server

### Group A Invasive Streptococcus (GAS) Test for Trend Increase North Carolina 2018-2024
Code highlight: [Vizualization example MK trend](https://github.com/mishahoskins/Portfolio/blob/0d305fefeacdd6ec86f1fed76b56e589960ac659/GAS_MK%20analysis.R#L39-L58)

Built statistical models to assess whether increases in invasive Group A Streptococcus incidence exceeded expected trends across risk-factor cohorts. Leveraged Cochran–Armitage and Mann–Kendall tests for linear and non-linear trend detection, using **MSSQL**, **SAS**, and **R** to process and analyze large-scale unstructured EHR data.

**Tech stack:** R, SQL, SAS, Microsoft SQL Server

**Methods:** Trend analysis, regression modeling, cohort analysis

### Multidrug Resistant Organism Standardized Infection Ratio Sample Model
Code highlight: [Data prototype prep](https://github.com/mishahoskins/Portfolio/blob/b16a81dee01eac2ad50f2731199b11f071cbd694/MDRO_SIR_estimate.sas#L258-L299) 

Created a transferable regression modeling framework to assess whether observed health events exceed expected levels based on population demographics. The model, informed by CDC methods and implemented using **SQL**, was applied to simulated carbapenem-resistant Enterobacteriaceae data for statewide risk scoring.

**Tech stack:** SQL, SAS, Microsoft SQL Server

**Methods:** Regression modeling

### Simulated Cancer Relational Data Evaluation
Code highlight: [Load data to server](https://github.com/mishahoskins/Portfolio/blob/ecc7e24bcaa7554a66ef955f04dd271f23117b98/MSSQL_File%20Upload.R#L26-L57) | [Visualization](https://github.com/mishahoskins/Portfolio/blob/77a91c5a3381a891c1a56483d8e2160cd995fa4e/External_eval_R_practice.R#L356-L391)

Developed a reproducible end-to-end analysis using sample healthcare data to evaluate cancer incidence, staging, and treatment timelines. Implemented relational joins, analysis, and visualization in **R**, with outputs delivered via **R Markdown**.

**Tech stack:** R, SQL, Python, R Markdown

## Publications
- [Health Care-Associated Infections in North Carolina, 2024](https://www.dph.ncdhhs.gov/epidemiology/communicable-disease/2024annualreportfinalpdf/open)
- [Health Care-Associated Infections in North Carolina, 2023](https://www.dph.ncdhhs.gov/epidemiology/communicable-disease/2023-hai-annual-report/open)
- [Application of a life table approach to assess duration of BNT162b2 vaccine-derived immunity by age using COVID-19 case surveillance data during the Omicron variant period](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0291678)
- [Trends in Laboratory-Confirmed SARS-CoV-2 Reinfections and Associated Hospitalizations and Deaths Among Adults Aged ≥18 Years — 18 U.S. Jurisdictions, September 2021–December 2022](https://www.cdc.gov/mmwr/volumes/72/wr/mm7225a3.htm?s_cid=mm7225a3_w)
- [COVID-19 Incidence and Mortality Among Unvaccinated and Vaccinated Persons Aged ≥12 Years by Receipt of Bivalent Booster Doses and Time Since Vaccination — 24 U.S. Jurisdictions, October 3, 2021–December 24, 2022](https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm?s_cid=mm7206a3_w)
- [Monitoring Incidence of COVID-19 Cases, Hospitalizations, and Deaths, by Vaccination Status — 13 U.S. Jurisdictions, April 4–July 17, 2021](https://www.cdc.gov/mmwr/volumes/70/wr/mm7037e1.htm?s_cid=mm7037e1_w)
- [Effect of Inadequate Sleep on Frequent Mental Distress](https://pubmed.ncbi.nlm.nih.gov/34138697/)

