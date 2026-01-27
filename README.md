# _Data Science Introduction_

Mikhail Hoskins
## Contact
 (919) 357-5145 | mishahoskins@gmail.com ; mhoskins@tulane.edu 

[LinkedIn](https://www.linkedin.com/in/mikhail-hoskins/) | [GitHub](https://github.com/mishahoskins)

## Professional Summary
Healthcare data scientist and infectious disease epidemiologist with 6+ years of experience designing analytics solutions across EHR, claims, and surveillance data. Specialized in statistical modeling, risk stratification, and production ETL pipelines to support clinical, operational, and policy decisions. Unstructered and semistructured data :arrow_right: usable analysis.

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
### North Carolina Measles Response Pipleline (_all values simulated_)
Development of internal metrics for the state of North Carolina to facilitate data processes from interviews conducted with exposed individuals using **R**. This was driven by the need for evaluating unstructured survey data and presenting internal outputs characterizing the scope of measles exposure in North Carolina from December 2025 through early 2026. All data included here is simulated and _does not_ reflect real world counts or figures. I created an HTML output using **R Markdown** for ease of transfer, including full script. 
### EHR Engineering and Antibiogram Visualization of NHSN Unstructured Antibiotic Susceptibility Data
Drug resistance poses an increasing threat to the range and power of current antibiotics and anti-fungal pharmaceutical interventions in the United States and globaly. Using semi-structured data I created a method to group treatment by class and susceptibility to visualize susceptibility trends in treatment options. By leveraging macros in **SAS**, I was able to quickly assess large swaths of treatments grouped by type (Penicillins, Cephalosporins, Macrolides, Tetracyclines, Fluoroquinolones, Aminoglycosides, and Carbapenems) and level of susceptibility (susceptible, intermediate, resistant). Extensive usage of **SQL** creates reproduciblity in **Python**  and **R** packages. 
### Group A Invasive Streptococcus (GAS) Test for Trend Increase North Carolina 2018-2024
Group A invasive Streptococcus has [increased in the United States](https://ncconnect-my.sharepoint.com/personal/mikhail_hoskins_dhhs_nc_gov/Documents/Microsoft%20Teams%20Chat%20Files/jama_gregory_2025_oi_250004_1743516783.03422.pdf) since the mid-2000's. To assess whether this trend was beyond what an expected increase may explain, I created a model to assess whether the increased trend is beyond the expected level of increase. By leveraging a combination of tests including Cochran-Armitage Trend Test and Mann-Kendall Test depending on specific linear and non-linear increases among risk factor cohorts, I was able to create trends to evaluate if specific groups may be seeing an increase beyond expected values. Unstructured EHR data was extracted and transformed using **SQL** and **SAS** with analysis and vizualization performed in **SAS** and **R**. Because of the cohort risk factor size, I utilized **Microsoft SQL Server** and leveraged **MSSQL** to pass initial extraction through the server. 
### Multidrug Resistant Organism Standardized Infection Ratio Sample Model
The Centers for Disease Control and Prevention (CDC) utilizes a [logistic regression model](https://www.cdc.gov/nhsn/pdfs/ps-analysis-resources/nhsn-sir-guide.pdf) (and negative binomial model) to assess the likelihood of an event. Using this model as a basis, I created, from scratch, a regression model that scores the probablility of an event in each individual in North Carolina. For this project, I used Carbapenem resistant enterobacteriaceae as my event and scored each simulation individual based on population characteristics mapped to state population proportions. The objective is to create a scaleable and transferable model to quickly determine if any event is occuring more than we would expect based on our known demographic trends. Using **SQL** allows for inter-programibility. 
### Simulated Cancer Relational Data Evaluation
Using sample data, I created a relational database (combining treatment, patient demographics, and diagnosis files) to evaluate trends in cancer type, stage, diagnosis date, and treatment date using **R** for cleaning, analysis, and vizualization. To facilitate ease of interpretation, I created an **R Markdown** output with full code for full clarity.

## Publications
- [Health Care-Associated Infections in North Carolina, 2024](https://www.dph.ncdhhs.gov/epidemiology/communicable-disease/2024annualreportfinalpdf/open)
- [Health Care-Associated Infections in North Carolina, 2023](https://www.dph.ncdhhs.gov/epidemiology/communicable-disease/2023-hai-annual-report/open)
- [Application of a life table approach to assess duration of BNT162b2 vaccine-derived immunity by age using COVID-19 case surveillance data during the Omicron variant period](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0291678)
- [Trends in Laboratory-Confirmed SARS-CoV-2 Reinfections and Associated Hospitalizations and Deaths Among Adults Aged ≥18 Years — 18 U.S. Jurisdictions, September 2021–December 2022](https://www.cdc.gov/mmwr/volumes/72/wr/mm7225a3.htm?s_cid=mm7225a3_w)
- [COVID-19 Incidence and Mortality Among Unvaccinated and Vaccinated Persons Aged ≥12 Years by Receipt of Bivalent Booster Doses and Time Since Vaccination — 24 U.S. Jurisdictions, October 3, 2021–December 24, 2022](https://www.cdc.gov/mmwr/volumes/72/wr/mm7206a3.htm?s_cid=mm7206a3_w)
- [Monitoring Incidence of COVID-19 Cases, Hospitalizations, and Deaths, by Vaccination Status — 13 U.S. Jurisdictions, April 4–July 17, 2021](https://www.cdc.gov/mmwr/volumes/70/wr/mm7037e1.htm?s_cid=mm7037e1_w)
- [Effect of Inadequate Sleep on Frequent Mental Distress](https://pubmed.ncbi.nlm.nih.gov/34138697/)

