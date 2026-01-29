# Program Name:  measles_public dashboard_cleaning
# Author:        Deen Gu
# Edits:         Mikhail Hoskins
# Date Created:  01/1/2025
# Date Modified: 01/20/2026 *added dates to exports, cleaned up variable list
#
# Description:   Pulls vaccination and case packages from NCEDSS and runs metrics for public dashboard.
#                Tuesday and Friday cadence beginning 1/14
#
# Inputs:       EVENT DATA
#               VACCINATION DATA
# Output:       .
# Notes:        Program uses case and vaccination files to create simple metrics for public facing dashboard. Cadence is Wednesday by noon until further notice.
#
#
#               Annotations are at # (between /* in SAS) to help guide.


# load libraries
pacman::p_load(dplyr, rvest, lubridate, rio, skimr, sqldf, gtsummary, openxlsx, EpiCurve, ggsurveillance)

# set working directory (if you haven't already) and output paths
setwd("T:/VPDs/Measles/Cases, Clusters, and Outbreaks/Dec 2025 - Jan 2026 Outbreak")
wastewaterfile <- paste0("./wastewater/CASE_address_wastewater_" , Sys.Date(), ".xlsx")
vaxstat <- paste0("./Outputs/CASE_vax status_NCEDSS_" , Sys.Date(), ".xlsx")
    
# Read in data
   
# reading in case info
linelist <- read.csv( "./Data/Linelists/All_Models_Identified_Cases_and_Contacts_Line_List_by_Date_for_Reporting_20260123083704.csv") # Update file names here 
# reading in vaccine info
vaccine <- read.csv("./Data/Linelists/Case_Information_Extract_Excel_CSV_20260123083852.csv")# Update file names here 



# mutating
linelist_vaccine <- linelist |> 
  mutate(`Age Group` = case_when(
    Age >= 18 ~ "Age 18+",
    Age < 18 ~ "Age 0-17",
    .default = "Unknown"
  ),
  mutate (`Age Group 2` = ), # age groups smaller
  # make blanks become NA
  across(where(is.character), ~na_if(., "")),
  earliest_id_date = coalesce(
    Symptom.Onset.Date,
    Specimen.Date,
    Date.Initial.Report.to.PH,
    Create.Date
  ),
  Hispanic = case_when(
    Hispanic == "Yes" ~ "Hispanic",
    Hispanic == "No" ~ "Non-Hispanic",
    Hispanic == "" ~ "Unknown"
  ),
  # blanks become Unknown
  across(
    c(Race, Gender, Hispanic),
    ~ case_when(
      is.na(.) ~ "Unknown",
      TRUE     ~ .
    )
  ),
  `County New` = coalesce(Reporting.County, County),
  Month = month(mdy(earliest_id_date), label = TRUE),
  
  week_symptom = ceiling_date(mdy(earliest_id_date), unit = "week") - days(1),
  Year = year(mdy(earliest_id_date)),
  Event.ID,
  id = row_number()
  ) |> left_join(
    vaccine |> 
      select(CaseID, VACCINE_NUMBER_DOSES), by = c("Event.ID" = "CaseID"))
  

# Create tables for external dashboard and addresses

# IMT role person needs to monitor classification in the morning
linelist_vaccine2 <- linelist_vaccine |> 
  select(Event.ID, earliest_id_date, Date.Initial.Report.to.PH, week_symptom, Year, Classification.Status, Age, `Age Group`, `County New`, Hospitalized., VACCINE_NUMBER_DOSES) |> 
  filter(Classification.Status %in% c("Confirmed", "Probable"))

# For simplicity's sake I ran this in SQL for just the most basic of tables by week for the external dashboard
table_view <- sqldf("
    select
        week_symptom,
        count (week_symptom) as count_case
        
        from linelist_vaccine2
            group by week_symptom 
            order by week_symptom asc")


#Addresses for wastewater monitoring
case_address <- linelist_vaccine |>
    select(Event.ID, Street, earliest_id_date, Date.Initial.Report.to.PH, Age, `County New`, Zip, State, Disease, Classification.Status) |>
    filter(Classification.Status %in% c("Confirmed", "Probable"))
             
      
     
# send to wastewaterfolder 
write.xlsx(x = case_address, file = wastewaterfile)


# Make a list for a single export for linelist
vaccination_stat_combine <- list("linelist" = linelist_vaccine2, "weekly count" = table_view)
# send to working directory 
write.xlsx(x = vaccination_stat_combine, file = vaxstat)

epi_curve_1 <- table_view |>
    mutate(week_symptom = floor_date(week_symptom, unit = "week")) |>
    ggplot(aes(x = week_symptom, y = count_case)) +
    geom_col()


epi_curve_cum <- table_view |>
    arrange(week_symptom) |>
    mutate(cum_cases = cumsum(count_case)) |>
    ggplot(aes(x = week_symptom, y = cum_cases)) +
    geom_step() +
    labs(y = "Cumulative cases")

epi_curve_1
epi_curve_cum
