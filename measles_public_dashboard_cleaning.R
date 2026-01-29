# Program Name:  measles_public dashboard_cleaning
# Author:        Deen Gu
# Edits:         Mikhail Hoskins
# Date Created:  01/1/2025
# Date Modified: 01/20/2026 *added dates to exports, cleaned up variable list
#
# Description:   Pulls vaccination and case packages from NCEDSS and runs metrics for public dashboard.
#                Tuesday and Friday cadence beginning 1/14
#
# Inputs:       All_Models_Identified_Cases_and_Contacts_Line_List_by_Event_Create_Date_DATESTAMP.xls
#               Case_Information_Extract_Excel_CSV_DATESTAMP.xls
# Output:       .
# Notes:        Program uses case and vaccination files to create simple metrics for public facing dashboard. Cadence is Wednesday by noon until further notice.
#
#
#               Annotations are at # (between /* in SAS) to help guide.


# load libraries
pacman::p_load(dplyr, tidyr, rvest, lubridate, rio, skimr, sqldf, gtsummary, openxlsx, ggplot2, kableExtra, knitr, biostats, tigris, stringr)

# set working directory (if you haven't already) and output paths
setwd("T:/VPDs/Measles/Cases, Clusters, and Outbreaks/Dec 2025 - Jan 2026 Outbreak")
wastewaterfile <- paste0("./wastewater/CASE_address_wastewater_" , Sys.Date(), ".xlsx")
vaxstat <- paste0("./Outputs/CASE_vax status_NCEDSS_" , Sys.Date(), ".xlsx")
    
# Read in data
   
# reading in case info
linelist <- read.csv( "./Data/Linelists/All_Models_Identified_Cases_and_Contacts_Line_List_by_Date_for_Reporting_20260128084925.csv") # Update file names here 
# reading in vaccine info
vaccine <- read.csv("./Data/Linelists/Case_Information_Extract_Excel_CSV_20260128085114.csv")# Update file names here 



# # mutating

#   mutate(`Age Group` = case_when(
#     Age >= 18 ~ "Age 18+",
#     Age < 18 ~ "Age 0-17",
#     .default = "Unknown"
#   ),
linelist_vaccine <- linelist |>  
    mutate(`Age Group` = case_when(
        Age < 5~ "Age 0-4",
        4 < Age & Age < 12 ~ "Age 5-11",
        11 < Age & Age < 18 ~ "Age 12-17",
        17 < Age & Age < 30 ~ "Age 18-29",
        29 < Age & Age <50 ~ "Age 30-49",
        
        Age > 49 ~ "Age 50+"
    ),
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
  day_symptom = ceiling_date(mdy(earliest_id_date), unit = "day"),
  Year = year(mdy(earliest_id_date)),
  Event.ID,
  id = row_number()
  ) |> left_join(
    vaccine |> 
      select(CaseID, VACCINE_NUMBER_DOSES), by = c("Event.ID" = "CaseID"))
  
# Create tables for external dashboard and addresses

# IMT role person needs to monitor classification in the morning
linelist_vaccine2 <- linelist_vaccine |> 
  select(Event.ID, earliest_id_date, day_symptom, Date.Initial.Report.to.PH, week_symptom, Year, Classification.Status, Age, `Age Group`, `County New`, Hospitalized., VACCINE_NUMBER_DOSES) |> 
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




# Reclassify vaccination status in SQL for time's sake. I'll fix this later for the R folks.
epi_curves_1 <- sqldf("
    select 
        `Age Group`,
        case when VACCINE_NUMBER_DOSES in (0)  then 'Zero Doses'
             when VACCINE_NUMBER_DOSES in (1) then 'One Dose' 
             when VACCINE_NUMBER_DOSES in (2) then 'Two Does'
             
             else 'Unknown' end as `Vaccination Status`,
        week_symptom
        
    from linelist_vaccine2
        order by week_symptom
                      ")
sumstats_age_vax <- epi_curves_1 |>

    select(week_symptom, `Age Group`, `Vaccination Status`) |>
    tbl_summary()

sumstats_age_vax



# Epi curves
epi_curve_1 <- table_view |>
    mutate(week_symptom = floor_date(week_symptom, "week", week_start = 1) + days(7)) |>
    ggplot(aes(x = week_symptom, y = count_case)) +
    geom_col(
        width = 0.7,
        fill = "#1f4e79") +
    theme_minimal() +
    theme(panel.grid = element_blank()) + 
    labs(
        x = "Week of symptom onset",
        y = "Case count") +
    scale_x_date(date_breaks = "1 week", date_labels = "%b %d")
    
epi_curve_1

# Cumulative cases
epi_curve_cum <- table_view |>
    arrange(week_symptom) |>
    mutate(week_symptom = floor_date(week_symptom, "week") + days(6),
        cum_cases = cumsum(count_case)) |>
    ggplot(aes(x = week_symptom, y = cum_cases)) +
    geom_step(
        linewidth = 1,
        color = "#1f4e79") +
    theme_minimal() +
    theme(panel.grid = element_blank()) +
    scale_x_date(
        date_breaks = "1 week",
        date_labels = "%b %d",
        expand = c(0, 0)) +
    labs(
        x = "Week of symptom onset",
        y = "Cumulative cases")

epi_curve_cum


# Map for Cases:

#Step 1: Count cases per county
case_counts <- linelist_vaccine2 |>
    mutate(county = str_to_title(str_trim(`County New`))) |>
    count(county, name = "n_obs")
# Drop "County" from name (extra step for this map)
case_counts_new <- case_counts |>
    mutate(county = str_remove(county, " County$"))

# Had this in a prior map, don't know why, kept it. (explaination here: https://cran.r-project.org/web/packages/tigris/refman/tigris.html, didn't read it)
options(tigris_use_cache = TRUE)

#Step 2: Get counties from TIGRIS package
nc_counties <- counties(
    state = "NC",
    cb = TRUE,
    year = 2023) |>
    mutate(
        county = str_to_title(NAME))


#Step 3: Merge and make NAs 0, R and NA's vs 0 vs BLANK is annoying
nc_cases <- nc_counties |>
    left_join(case_counts_new, by = "county") |> mutate(n_obs = replace_na(n_obs, 0))


case_label <- paste0("Number cases by county ", Sys.Date())

#Step 4: Heat map white for zero then darkish blue for highest counts. borders are black, text color is red, bold, and 4.5 font
cases_heatmap <- ggplot(nc_cases) + geom_sf(aes(fill = n_obs), color = "black", linewidth = 0.2) +
    
    geom_sf_text(
        data = dplyr::filter(nc_cases, n_obs > 0),
        aes(label = n_obs),
        color = "red",
        size = 4.5,
        fontface = "bold") +
    
    scale_fill_gradient(
        low  = "white",
        high = "#1f4e79",   # matte blue
        name = "Contacts") +
    
    theme_minimal() +
    
    theme(panel.grid = element_blank(),
          axis.text = element_blank(),
          axis.title = element_blank(),
          legend.position = "none") + #No legend, we can add it back in but for now we just want to see the county breakdown
    
    labs(title = case_label,
         subtitle = "North Carolina")

#Print heatmap
cases_heatmap






# County cases
epi_prep <- linelist_vaccine2 |>
   mutate(Cases = case_when(
        Classification.Status %in% c('Confirmed','Probable') ~ 1,
        TRUE ~ 0),
        count_cases = sum(Cases, na.rm = TRUE),
    vax_stat = case_when(    
    VACCINE_NUMBER_DOSES %in% c('0') ~ 'No Evidence of Immunty/ Unknown',    
    VACCINE_NUMBER_DOSES %in% c('1') ~ 'Evidence of Partial Immunity',
    VACCINE_NUMBER_DOSES %in% c('2') ~ 'Evidence of Full Immunity',
    is.na(VACCINE_NUMBER_DOSES) ~ 'No Evidence of Immunty/ Unknown'
    ),
    county = str_remove(`County New`, " County$"))
        
        
        
        
    

# Epi curves
epi_curve_week_county <- epi_prep |>
    mutate(day_symptom = floor_date(day_symptom, "day", week_start = 1) + days(7)) |>
    
    ggplot(aes(x = day_symptom, y = Cases, fill = `County New`)) +
    
    geom_col(width = .9,) +
    scale_fill_manual(values = c('darkorange2', 'mediumorchid4', 'olivedrab4', 'slateblue4', 'slategray3')) +
    
    theme_minimal() +
    theme(panel.grid = element_blank()) + 
    labs(
        title = "Cases by County of Residence",
        x = "Date Symptom onset",
        y = "Case count",
        fill = "County of Residence") +
    scale_x_date(date_breaks = "3 day", date_labels = "%d- '%y")

epi_curve_week_county

# Vaccination Status
epi_curve_vax <- epi_prep |>
    
    ggplot(aes(x = county, y = Cases, fill = vax_stat)) +
    
    geom_col(width = .9,) +
    scale_fill_manual(values = c('sienna', 'palegreen4', 'slateblue4')) +
    
    theme_minimal() +
    theme(panel.grid = element_blank()) + 
    labs(
        title = "Vaccination Status of Cases",
        x = "County of Residence",
        y = "Case count",
        fill = "Vaccination Status") 

epi_curve_vax




