# Program Name:  Measles_metrics_25_26
# Author:        Mikhail Hoskins
# Edits:
# Date Created:  01/19/2026
# Date Modified: 02/12/2026 <-- updated for RMD, combined contact tracing and events
# Description:   Contact tracing metrics from RedCap, confines to variables we need and produces summary stats by RESPONSE county.
#                Daily cadence. Pull data ~11:00am
#
# Inputs:       All_Models_Identified_Cases_and_Contacts_Line_List_by_Event_Create_Date_DATESTAMP.xls
#
# Output:       measles_metrics_raw_R
# Notes:        Use extract with LABELS, ex: StatewideMeaslesResp_DATA_LABELS_2026-01-19_1535.csv
#               Ease of use fix: Updated pathways 01/22/2026 to group df's into a list and point to output paths and single .xlsx export.
#               Revamped RMD output, clean and professional --> use cosmo theme
#
#               Annotations are at # (between /* in SAS) to help guide.

library(dplyr) # data cleaning
library(tidyr) ##tidy data
#library(readxl) ##excel
library(openxlsx) ##excel
library(lubridate) ##date
library(ggplot2) ##Plots
library(janitor)
library(rvest) ## reading HTML tables
library(rio) ##data import and export
#library(skimr) ##data summary
library(sqldf) ##SQL
library(gtsummary) ##tables
library(webshot2) ## save gt tables as images
#library(kableExtra) ##tables
#library(knitr) ##rmd
#library(biostats) ##descriptive stats
library(tigris) ##maps
library(stringr) ##strings
library(gt) ##table to png
library(MMWRweek) ##MMWR year and week


## 1. Import EDSS data sources

base_path = normalizePath(
  "T:\\VPDs\\Measles\\Cases, Clusters, and Outbreaks\\Dec 2025 - Jan 2026 Outbreak",
  winslash = "\\",
  mustWork = FALSE
)

linelist <- html_table(html_nodes(
  read_html(file.path(
    base_path,
    "\\Data\\Linelists\\All_Models_Identified_Cases_and_Contacts_Line_List_by_Event_Create_Date_20260212103045.xls"
  )),
  "table"
))[[1]]
linelist <- clean_names(linelist)

# vaccine info
vaccine <- read.csv(file.path(
  base_path,
  "\\Data\\Linelists\\Case_Information_Extract_Excel_CSV_20260212102709.xls"
))

#rash date
rash <- read.csv(file.path(
  base_path,
  "\\Data\\Linelists\\Case_Information_Extract_Excel_CSV_20260212102826.xls"
))

## 2. Create the main linelist dataframe

linelist_vaccine <- linelist |>
  mutate(
    age_group = case_when(
      age < 5 ~ "<5",
      age >= 5 & age < 18 ~ "5???17",
      age >= 18 ~ "18+",
      TRUE ~ "Unknown"
    ),

    # make blanks become NA
    across(where(is.character), ~ na_if(., "")),
    earliest_id_date = coalesce(
      symptom_onset_date,
      specimen_date,
      date_initial_report_to_ph,
      create_date
    ),
    hispanic_labels = case_when(
      hispanic == "Yes" ~ "Hispanic",
      hispanic == "No" ~ "Non-Hispanic",
      hispanic == "" ~ "Unknown"
    ),
    # NA become Unknown
    across(
      c(race, gender, hispanic),
      ~ case_when(
        is.na(.) ~ "Unknown",
        TRUE ~ .
      )
    ),
    county_2 = case_when(
      event_id == 104297925 ~ "Johnston County",
      TRUE ~ county
    ),

    county_coalesce = coalesce(county_2, reporting_county),
    Month = month(mdy(earliest_id_date), label = TRUE),
    week_symptom = ceiling_date(mdy(earliest_id_date), unit = "week") - days(1),
    day_symptom = ceiling_date(mdy(earliest_id_date), unit = "day"),
    Year = year(mdy(earliest_id_date)),
    id = row_number()
  ) |>
  left_join(
    rash |>
      select(CaseID, SS_SKIN_RASH_ONSET_DATE),
    by = c("event_id" = "CaseID")
  ) |>
  left_join(
    vaccine |>
      select(CaseID, VACCINE_NUMBER_DOSES),
    by = c("event_id" = "CaseID")
  )
#
# Create tables for external dashboard and addresses
# IMT role person needs to monitor classification in the morning
linelist_vaccine2 <- linelist_vaccine |>
  select(
    event_id,
    earliest_id_date,
    date_initial_report_to_ph,
    day_symptom,
    week_symptom,
    Year,
    classification_status,
    age_group,
    race,
    hispanic_labels,
    county_coalesce,
    hospitalized,
    VACCINE_NUMBER_DOSES,
    SS_SKIN_RASH_ONSET_DATE
  ) |>
  filter(classification_status %in% c("Confirmed", "Probable"))


linelist_vpd <- linelist_vaccine2 |>
  mutate(id = row_number()) |>
  select(
    id,
    event_id,
    classification_status,
    age_group,
    county_coalesce,
    hospitalized,
    earliest_id_date,
    VACCINE_NUMBER_DOSES
  ) |>
  rename(
    `NCEDSS ID` = event_id,
    `Symptom Onset Date` = earliest_id_date,
    `Classification Status` = classification_status,
    `Age Group` = age_group,
    `Hospitalized?` = hospitalized,
    `County New` = county_coalesce
  )


linelist_vaccine2 |>
  mutate(county = str_to_title(str_trim(county_coalesce))) |>
  count(county, name = "n_obs")

epi_prep <- linelist_vaccine2 |>
  mutate(
    Cases = case_when(
      classification_status %in% c('Confirmed', 'Probable') ~ 1,
      TRUE ~ 0
    ),
    count_cases = sum(Cases, na.rm = TRUE),
    vax_stat = case_when(
      VACCINE_NUMBER_DOSES %in% c('0') ~ 'No Evidence of Immunty/ Unknown',
      VACCINE_NUMBER_DOSES %in% c('1') ~ '1 dose of MMR', ##changed from partial to 1 dose
      VACCINE_NUMBER_DOSES %in% c('2') ~ 'Evidence of Full Immunity',
      is.na(VACCINE_NUMBER_DOSES) ~ 'No Evidence of Immunty/ Unknown'
    ),
    county = str_remove(county_coalesce, " County$")
  )
#
tabyl(epi_prep, vax_stat)


# For simplicity's sake I ran this in SQL for just the most basic of tables by week for the external dashboard
table_view <- sqldf(
  "
    select
        week_symptom,
        count (week_symptom) as count_case
        
        from linelist_vaccine2
            group by week_symptom 
            order by week_symptom asc"
)
table_view

# I was having some issues with the cumulative plot so using tidyverse to clean this up:

table_view_clean <- table_view |>
  mutate(week_symptom = floor_date(week_symptom, "week") + days(6)) |>
  filter(!is.na(week_symptom)) |> #weeks with no cases are NA, drop them for cumulative
  group_by(week_symptom) |>
  summarise(count_case = sum(count_case, na.rm = TRUE), .groups = "drop") |>
  arrange(week_symptom) |> #Order properly by date
  mutate(cum_cases = cumsum(count_case)) #cumulative sum


epi_curve_vax <- epi_prep |>
  ggplot(aes(x = county, y = Cases, fill = vax_stat)) +

  geom_col(width = 0.9) +

  scale_fill_manual(values = c("#3B528B", "#E69F00", "#CC79A7")) +

  theme_minimal(base_family = "Arial") +
  theme(
    panel.grid = element_blank(),

    # Legend below the x-axis
    legend.position = "bottom",
    legend.direction = "horizontal", # horizontal layout
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),

    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold")
  ) +

  labs(
    title = "Immune Status of Cases",
    x = "County of Residence",
    y = "Case count",
    fill = "Immune Status"
  ) +

  theme(axis.text.x = element_text(angle = 45, hjust = 1))
epi_curve_vax


#epi curve of cases by MMWR week
epi_data <- linelist_vaccine2 %>%
  mutate(
    # MMWR week info
    MMWR = MMWRweek(day_symptom),
    MMWR_year = MMWR$MMWRyear,
    MMWR_week = MMWR$MMWRweek,
    # Convert MMWR week back to a Date (week start Sunday)
    week_start = MMWRweek2Date(MMWR_year, MMWR_week)
  )
##summarize cases by MMWR week
epi_curve <- epi_data %>%
  group_by(MMWR_year, MMWR_week, week_start) %>%
  summarise(cases = n(), .groups = "drop") %>%
  arrange(MMWR_year, MMWR_week)
#plot cases
epi_curve_plot <- ggplot(epi_curve, aes(x = week_start, y = cases)) +
  geom_col(fill = "steelblue") +

  labs(
    x = "MMWR Week",
    y = "Case Count"
  ) +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +

  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.x = element_text(size = 14, ),
    axis.title.y = element_text(size = 14),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )


# Map for Cases:
#Step 1: Count cases per county
case_counts <- linelist_vaccine2 |>
  mutate(county = str_to_title(str_trim(county_coalesce))) |>
  count(county, name = "n_obs")
# Drop "County" from name (extra step for this map)
case_counts_new <- case_counts |>
  mutate(county = str_remove(county, " County$"))

# Had this in a prior map, don't know why, kept it. (explanation here: https://cran.r-project.org/web/packages/tigris/refman/tigris.html, didn't read it)
options(tigris_use_cache = TRUE)
#
#Step 2: Get counties from TIGRIS package
nc_counties <- counties(
  state = "NC",
  cb = TRUE,
  year = 2023
) |>
  mutate(
    county = str_to_title(NAME)
  )


#Step 3: Merge and make NAs 0, R and NA's vs 0 vs BLANK is annoying
nc_cases <- nc_counties |>
  left_join(case_counts_new, by = "county") |>
  mutate(n_obs = replace_na(n_obs, 0))


case_label <- paste0("Number cases by county ", Sys.Date())
#
#Step 4: Heat map white for zero then darkish blue for highest counts. borders are black, text color is red, bold, and 4.5 font
cases_heatmap <- ggplot(nc_cases) +
  geom_sf(aes(fill = n_obs), color = "white", linewidth = 0.2) +

  geom_sf_text(
    data = dplyr::filter(nc_cases, n_obs > 0),
    aes(label = n_obs),
    color = "red",
    size = 4.5,
    fontface = "bold"
  ) +

  scale_fill_gradient(
    low = "lightgray",
    high = "#1f4e79", # matte blue
    name = "Contacts"
  ) +

  theme_minimal() +

  theme(
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none"
  ) + #No legend, we can add it back in but for now we just want to see the county breakdown

  labs(title = case_label, subtitle = "North Carolina")


# Epi curves
epi_curve_week_county <- epi_prep |>
  mutate(
    day_symptom = floor_date(day_symptom, "day", week_start = 1) + days(7)
  ) |>

  ggplot(aes(x = day_symptom, y = Cases, fill = county)) +

  geom_col(width = .9, ) +
  scale_fill_manual(
    values = c(
      'darkorange2',
      'mediumorchid4',
      '#f49cd5',
      'olivedrab4',
      'darkblue',
      'slateblue4',
      'slategray3',
      'goldenrod3',
      'darkorange4'
    )
  ) +

  scale_y_continuous(limits = c(0, 8), breaks = seq(0, 8, by = 2)) +

  theme_minimal() +
  theme(
    panel.grid = element_blank(),

    legend.position = "top",
    legend.direction = "horizontal" # horizontal layout
  ) +
  labs(
    title = "Cases by County of Residence",
    x = "Date Symptom onset",
    y = "Case count",
    fill = "County of Residence"
  ) +
  scale_x_date(date_breaks = "3 day", date_labels = "%d- '%y")

epi_curve_week_county

#Cumulative epi curve
epi_curve_cum <- ggplot(
  table_view_clean,
  aes(x = week_symptom, y = cum_cases)
) +
  geom_step(
    linewidth = 1,
    color = "#1f4e79"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank()) +
  scale_x_date(
    date_breaks = "1 week",
    date_labels = "%b %d",
    expand = c(0, 0)
  ) +
  labs(
    x = "Week of symptom onset",
    y = "Cumulative cases"
  )


#REDCap contacts
redcap <- read.csv(
  "T:\\VPDs\\Measles\\Cases, Clusters, and Outbreaks\\Dec 2025 - Jan 2026 Outbreak\\Data\\StatewideMeaslesResp_DATA_LABELS_2026-02-12_1523.csv",
  check.names = FALSE
)
# Contacts info
contacttracing <- paste0(
  "./Outputs/contract_tracing_linelist_internal_dashboard_",
  Sys.Date(),
  ".xlsx"
)
##clean column names
redcap <- redcap %>%
  janitor::clean_names()
###select columns
redcap_2 <- redcap %>%
  select(
    `record_id`,
    `this_field_will_display_yes_if_the_contact_answered_yes_to_having_an_mmr_record`,
    `is_the_contact_considered_immune`,
    `is_contact_lost_to_follow_up`,
    `calculate_most_recent_exposure_date`,
    `quarantine_start_date`,
    `calculated_quarantine_end_date`,
    `specify_response`,
    `repeat_instrument`,
    `data_access_group`,
    `is_quarantine_needed`,
    `monitoring_need`,
    `call_outcome`,
    `call_outcome_2`,
    `call_outcome_3`,
    `call_outcome_4`,
    `record_status`,
    `complete`,
    `date_of_interview`,
    `home_county`,
    `ncedss_id_of_the_case_that_exposed_this_individual`,
    `was_immunoglobulin_administered`,
    `was_an_mmr_vaccine_administered`
  ) %>%
  filter(repeat_instrument %in% c(""))
# Rename longer vars for simplicity
redcap_2 <- redcap_2 %>%
  rename(
    text_mmr = this_field_will_display_yes_if_the_contact_answered_yes_to_having_an_mmr_record,
    immunity = is_the_contact_considered_immune,
    ltfu = is_contact_lost_to_follow_up,
    calc_recent_exposure_date = calculate_most_recent_exposure_date,
    date_quarantine_start = quarantine_start_date,
    quar_end = calculated_quarantine_end_date,
    quarantine = is_quarantine_needed,
    specify_response = specify_response,
    calc_monitor_need = monitoring_need,
    record_status = record_status,
    status = complete,
    int_date = date_of_interview,
    home_county = home_county,
    linked_case = ncedss_id_of_the_case_that_exposed_this_individual,
    pep1 = was_immunoglobulin_administered,
    pep2 = was_an_mmr_vaccine_administered
  )
#check dates
redcap_2$calc_recent_exposure_date <- ymd(redcap_2$calc_recent_exposure_date)
redcap_2$quar_end <- ymd(redcap_2$quar_end)
redcap_2$int_date <- ymd(redcap_2$int_date)


#edit variables
response_calcs <- redcap_2 %>%
  mutate(
    today_date = today(),

    # Week of contact

    week_int = ceiling_date(int_date, unit = "week") - days(1),

    # Calculate response_county_1
    response_county_1 = case_when(
      specify_response ==
        'Buncombe County contact investigation January 5, 2026' ~ 'Buncombe',
      specify_response ==
        'Rutherford County contact investigation January 8, 2026' ~ 'Rutherford',
      specify_response ==
        'Cabarrus County contact investigation January 8, 2026' ~ 'Cabarrus',
      specify_response ==
        'Polk County contact investigation December 31, 2025' ~ 'Polk',
      specify_response ==
        'Mecklenburg County contact investigation January 22, 2026' ~ 'Mecklenburg',
      specify_response ==
        'Lincoln County contact investigation, Jan 27-Feb 2' ~ 'Lincoln',
      record_id == '469' ~ 'Polk',
      record_id == '470' ~ 'Buncombe',
      TRUE ~ NA_character_
    ),

    ##contact interview status (Complete, Pending, No/Unable to Contact)
    interview_stat_new = case_when(
      # INTERVIEWED if any full OR partial interview
      call_outcome %in%
        c(
          "Called - full interview completed",
          "Called - partial interview completed"
        ) |
        call_outcome_2 %in%
          c(
            "Called - full interview completed",
            "Called - partial interview completed"
          ) |
        call_outcome_3 %in%
          c(
            "Called - full interview completed",
            "Called - partial interview completed"
          ) |
        call_outcome_4 %in%
          c(
            "Called - full interview completed",
            "Called - partial interview completed"
          ) ~ "Interviewed",

      #   PENDING if any of the other pending outcomes (interview schedule, left voicemail, voicemail box full, spoke but no interview) **will need to update with TEXT attempts
      call_outcome %in%
        c(
          "Called - scheduled interview",
          "Called - left voicemail",
          "Called - voicemail box full",
          "Called - spoke with contact but no interview"
        ) |
        call_outcome_2 %in%
          c(
            "Called - scheduled interview",
            "Called - left voicemail",
            "Called - voicemail box full",
            "Called - spoke with contact but no interview"
          ) |
        call_outcome_3 %in%
          c(
            "Called - scheduled interview",
            "Called - left voicemail",
            "Called - voicemail box full",
            "Called - spoke with contact but no interview"
          ) |
        call_outcome_4 %in%
          c(
            "Called - scheduled interview",
            "Called - left voicemail",
            "Called - voicemail box full",
            "Called - spoke with contact but no interview"
          ) ~ "Pending",

      # Otherwise
      TRUE ~ "No/Unable to Contact"
    ),

    # Exposure time: if calc_recent_exposure is missing value will return NA
    exp_time = as.numeric(today_date - calc_recent_exposure_date),
    exp_time_new = if_else(
      exp_time > 21,
      "Outside Exposure Window",
      "Inside Exposure Window"
    )
  ) |>

  # Responding county
  mutate(
    response_county_1 = na_if(response_county_1, ""),
    data_access_group = na_if(data_access_group, ""),
    responding_county = coalesce(
      response_county_1,
      data_access_group,
      "Unknown"
    ),

    # Polk vs polk... can be use for future misspellings too
    responding_county_final = case_when(
      responding_county %in% c('Polk', 'polk') ~ 'Polk',
      TRUE ~ responding_county
    ),

    #Loss to follow up
    ltfu_new = if_else(ltfu == 'Yes', "Yes", "No"),

    ltfu = case_when(
      ltfu == "" ~ "No",
      TRUE ~ ltfu
    ),

    #immunity
    immunity = case_when(
      immunity == "" ~ "Unknown",
      TRUE ~ immunity
    ),

    # Quarantine current and total: if quarantine denoted 'Yes' in Redcap AND quarantine date greater than today then 1 else 0 (we can denote unknown later if necessary)
    curr_quarantined = if_else(
      (quar_end >= today_date) & quarantine == 'Yes',
      'Yes',
      'No'
    )
  ) |>

  # Replace blanks with NA for total all time quarantined for table
  mutate(
    quarantine = na_if(quarantine, ""),

    # Active monitoring
    active_mon = if_else(calc_monitor_need == "Active", 1, 0),

    curr_active_mon = if_else(
      (exp_time <= 21 | is.na(exp_time)) &
        active_mon == 1 &
        record_status != 'Closed',
      1,
      0
    ),

    end_actmon_dt = if_else(
      active_mon == 1,
      calc_recent_exposure_date + days(21),
      as.Date(NA)
    ),

    ##pep administered
    pep_admin = if_else(
      coalesce(pep1 == "Yes, within the appropriate time window", FALSE) |
        coalesce(pep2 == "Yes, within the appropriate time window", FALSE),
      1,
      0
    )
  )

##select reporting variables
linelist_final <- response_calcs |>
  select(
    record_id,
    responding_county_final,
    responding_county,
    response_county_1,
    week_int,
    data_access_group,
    specify_response,

    interview_stat_new,
    text_mmr,
    immunity,
    ltfu,
    ltfu_new,
    calc_recent_exposure_date,
    calc_monitor_need,
    quarantine,
    curr_quarantined,
    date_quarantine_start,
    quar_end,
    exp_time,
    exp_time_new,
    active_mon,
    curr_active_mon,
    end_actmon_dt,
    pep_admin
  )


#Summary stats
county_sumstats <- linelist_final |>

  filter(exp_time_new == "Inside Exposure Window") |>
  select(
    interview_stat_new,
    immunity,
    ltfu_new,
    curr_quarantined,
    curr_active_mon,
    exp_time_new,
    responding_county_final
  ) |>
  tbl_summary(
    by = responding_county_final,
    missing = "no",
    type = list(ltfu_new ~ "categorical"),
    label = list(
      interview_stat_new ~ "Status of interview",
      ltfu_new ~ "Lost to follow-up",
      immunity ~ "Immune status",
      curr_quarantined ~ "Currently quarantined",
      curr_active_mon ~ "Currently in active monitoring",
      exp_time_new ~ "Current exposure window status"
    )
  ) |>
  add_overall(last = TRUE, col_label = "Total")


state_sumstats <- linelist_final |>
  filter(exp_time_new == "Inside Exposure Window") |>
  select(
    interview_stat_new,
    immunity,
    ltfu_new,
    curr_quarantined,
    curr_active_mon,
    exp_time_new
  ) |>
  tbl_summary(
    missing = "no",
    type = list(ltfu_new ~ "categorical"),
    label = list(
      interview_stat_new ~ "Status of interview",
      ltfu_new ~ "Lost to follow-up",
      immunity ~ "Immune",
      curr_quarantined ~ "Currently quarantined",
      curr_active_mon ~ "Currently in active monitoring",
      exp_time_new ~ "Current exposure window status"
    )
  )


#Step 1: Count contacts per county
county_counts <- linelist_final |>
  mutate(county = str_to_title(str_trim(responding_county_final))) |>
  count(county, name = "n_obs")

# Had this in a prior map, don't know why, kept it. (explaination here: https://cran.r-project.org/web/packages/tigris/refman/tigris.html, didn't read it)
options(tigris_use_cache = TRUE)

#Step 2: Get counties from TIGRIS package
nc_counties <- counties(
  state = "NC",
  cb = TRUE,
  year = 2023
) |>
  mutate(
    county = str_to_title(NAME)
  )


#Step 3: Merge and make NAs 0, R and NA's vs 0 vs BLANK is annoying
nc_map_data <- nc_counties |>
  left_join(county_counts, by = "county") |>
  mutate(n_obs = replace_na(n_obs, 0))

contacts_label <- paste0(
  "Number of known exposed contacts by county ",
  Sys.Date()
)
#Step 4: Heat map white for zero then darkish blue for highest counts. borders are white, text color is red, bold, and 4.5 font
contacts_heatmap <- ggplot(nc_map_data) +
  geom_sf(aes(fill = n_obs), color = "white", linewidth = 0.2) +

  geom_sf_text(
    data = dplyr::filter(nc_map_data, n_obs > 0),
    aes(label = n_obs),
    color = "red",
    size = 4.5,
    fontface = "bold"
  ) +

  scale_fill_gradient(
    low = "lightgray",
    high = "#1f4e79", # matte blue
    name = "Contacts"
  ) +

  theme_minimal() +

  theme(
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none"
  ) + #No legend, we can add it back in but for now we just want to see the county breakdown

  labs(title = contacts_label, subtitle = "North Carolina")

#contacts interviewed daily
contacts_daily <- redcap_2 %>%
  filter(!is.na(int_date)) %>% # Make sure interview date exists
  group_by(date = int_date) %>%
  summarise(Contacts = n_distinct(record_id), .groups = "drop")
#cases by notification date
cases_daily <- linelist_vaccine2 %>%
  filter(classification_status %in% c("Confirmed", "Probable")) %>%
  filter(!is.na(earliest_id_date)) %>%
  group_by(date = earliest_id_date) %>%
  summarise(Cases = n_distinct(event_id), .groups = "drop")
#join cases and contacts

cases_daily2 <- cases_daily %>%
  mutate(date = mdy(date))
contacts_daily2 <- contacts_daily %>%
  mutate(date = ymd(date))

epi_data_daily <- full_join(contacts_daily2, cases_daily2, by = "date") %>%
  replace_na(list(Contacts = 0, Cases = 0)) %>%
  arrange(date)
#plot
epi_curve_contacts <- ggplot(epi_data_daily, aes(x = date)) +
  geom_col(aes(y = Contacts, fill = "Contacts"), width = 0.7, color = "white") +
  geom_col(aes(y = Cases, fill = "Cases"), width = 0.35, color = "white") +
  scale_fill_manual(
    name = NULL,
    values = c(
      "Contacts" = "#1f4e79",
      "Cases" = "#FF0000"
    ),
    labels = c(
      "Contacts" = "Contacts by Interview Date",
      "Cases" = "Cases by Earliest Symptom Onset Date"
    )
  ) +
  geom_text(
    aes(y = Contacts, label = ifelse(Contacts > 0, Contacts, "")),
    vjust = -0.5,
    size = 3,
    color = "#1f4e79"
  ) +
  geom_text(
    aes(y = Cases, label = ifelse(Cases > 0, Cases, "")),
    vjust = -0.5,
    size = 3,
    color = "#FF0000"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    title = paste0(
      "Number of known exposed contacts interviewed and Measles notification date ",
      Sys.Date()
    ),
    subtitle = "North Carolina",
    x = "Day",
    y = "Count"
  )
