# Program Name:  Measles_metrics_25_26
# Author:        Mikhail Hoskins
# Edits:
# Date Created:  01/19/2026
# Date Modified: 01/22/2026
# Description:   Contact tracing metrics from RedCap, confines to variables we need and produces summary stats by RESPONSE county.
#                Daily cadence. Pull data ~11:00am
#
# Inputs:       All_Models_Identified_Cases_and_Contacts_Line_List_by_Event_Create_Date_DATESTAMP.xls
#
# Output:       measles_metrics_raw_R
# Notes:        Use extract with LABELS, ex: StatewideMeaslesResp_DATA_LABELS_2026-01-19_1535.csv
#               Ease of use fix: Updated pathways 01/22/2026 to group df's into a list and point to output paths and single .xlsx export.
#
#               Annotations are at # (between /* in SAS) to help guide.

# #onetime installs
# tinytex::install_tinytex(force = TRUE)
#install.packages("pacman")

# load libraries
#pacman::p_load(dplyr, tidyr, rvest, lubridate, rio, skimr, sqldf, gtsummary, openxlsx, ggplot2, kableExtra, knitr, biostats, tigris, stringr)
pacman::p_load(
  dplyr,
  tidyr,
  rvest,
  lubridate,
  rio,
  skimr,
  sqldf,
  gtsummary,
  openxlsx,
  ggplot2,
  kableExtra,
  knitr,
  janitor,
  biostats,
  tigris,
  stringr,
  gtsummary
)


# set working directory (if you haven't already) and output path
setwd(
  "T:/VPDs/Measles/Cases, Clusters, and Outbreaks/Dec 2025 - Jan 2026 Outbreak"
)
contacttracing <- paste0(
  "./Outputs/contract_tracing_linelist_internal_dashboard_",
  Sys.Date(),
  ".xlsx"
)


# Read in data
# Import from NCEDSS delete excess headers and save as CSV
# reading in case info
working_redcap <- read.csv(
  "T:\\VPDs\\Measles\\Cases, Clusters, and Outbreaks\\Dec 2025 - Jan 2026 Outbreak\\Data\\StatewideMeaslesResp_DATA_LABELS_2026-02-06_1655.csv",
  check.names = FALSE
) # Update file name here


# Confine to only what we need
#working_redcap_2 <- working_redcap |>
#select(X...Record.ID, This.field.will.display..Yes..if.the.contact.answered.Yes.to.having.an.MMR.record, Is.the.contact.considered.immune., Is.contact.lost.to.follow.up.,
#Calculate.most.recent.exposure.date, Quarantine.start.date, Calculated.quarantine.end.date, Specify.Response, Repeat.Instrument, Data.Access.Group, Is.quarantine.needed., Monitoring.Need,
#Call.outcome, Call.outcome.1, Home.County.., Call.outcome.2, Call.outcome.3, Call.outcome.4, Record.Status..., Complete., Date.of.interview) |>

# filter(Repeat.Instrument %in% c(""))

# Confine to only what we need
##clean column names
working_redcap <- working_redcap %>%
  janitor::clean_names()

##check column names
colnames(working_redcap)
##select columns
working_redcap_2 <- working_redcap %>%
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
#
#
# head(working_redcap2, n=10) ##check columns

#
# mutate(across(
#         where(is.character),
#         ~ na_if(trimws(.x), "")))

# Rename longer vars for simplicity
#working_redcap_2 <- working_redcap_2 |>
#rename(text_mmr = This.field.will.display..Yes..if.the.contact.answered.Yes.to.having.an.MMR.record,

#immunity = Is.the.contact.considered.immune.,
#ltfu = Is.contact.lost.to.follow.up.,
#calc_recent_exposure_date = Calculate.most.recent.exposure.date,
#date_quarantine_start = Quarantine.start.date,
#quarantine = Is.quarantine.needed.,
#specify_response = Specify.Response,
#calc_monitor_need = Monitoring.Need,
#record_status = Record.Status...,
#quar_end = Calculated.quarantine.end.date,
#status = Complete.,
#int_date = Date.of.interview,
#home_county = Home.County..,
#Record.ID = X...Record.ID)

# Rename longer vars for simplicity
working_redcap_2 <- working_redcap_2 %>%
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

# Dates. ugh. <-- This literally switches every time. Is it mdy or ymd, double check every day.
##check date formats
head(working_redcap_2$calc_recent_exposure_date)
head(working_redcap_2$quar_end)
head(working_redcap_2$int_date)

working_redcap_2$calc_recent_exposure_date <- ymd(
  working_redcap_2$calc_recent_exposure_date
)
working_redcap_2$quar_end <- ymd(working_redcap_2$quar_end)
working_redcap_2$int_date <- ymd(working_redcap_2$int_date)


#
# #        sniff test for variables if neccessary:
#
#         class(working_redcap$Calculated.quarantine.end.date)
#         levels(working_redcap_2$Calculated.quarantine.end.date)

# SAS SQL but in R for everyone
response_calcs <- working_redcap_2 |>
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
      record_id == '469' ~ 'Polk',
      record_id == '470' ~ 'Buncombe',
      TRUE ~ NA_character_
    ),

    # contact interview
    # interview_stat = if_else(
    #    call_outcome %in% c('Called - full interview completed', 'Called - partial interview completed') |
    #   call_outcome_2 %in% c('Called - full interview completed', 'Called - partial interview completed') |
    #   call_outcome_3 %in% c('Called - full interview completed', 'Called - partial interview completed') | call_outcome_4 %in% c('Called - full interview completed', 'Called - partial interview completed'),
    #  1, 0),
    #   interview_stat_new = case_when(
    #             interview_stat == 1 ~ "Interviewed",
    #            interview_stat == 0 ~ "No/Unable to Contact"),

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

    # Exposure time
    exp_time = as.numeric(today_date - calc_recent_exposure_date)
  ) |>

  # Responding county
  mutate(
    response_county_1 = na_if(response_county_1, ""),
    data_access_group = na_if(data_access_group, ""),
    responding_county = coalesce(response_county_1, data_access_group),

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
    ),
    curr_exposure_pd = if_else(
      Sys.Date() - calc_recent_exposure_date >= 21,
      'Not In Exposure Period',
      'In Exposure Period'
    )
  )


# SQL but make it even R-y'er
linelist_final <- response_calcs |>
  select(
    record_id,
    responding_county_final,
    responding_county,
    response_county_1,
    week_int,
    int_date,
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
    active_mon,
    curr_active_mon,
    end_actmon_dt,
    pep_admin,
    curr_exposure_pd
  )

#Summary stats

county_sumstats <- linelist_final |>
  select(
    interview_stat_new,
    immunity,
    ltfu_new,
    curr_quarantined,
    curr_active_mon,
    responding_county_final,
    pep_admin,
    curr_exposure_pd
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
      pep_admin ~ "PEP adminsitered to date",
      curr_exposure_pd ~ "Exposure Period"
    )
  ) |>
  add_overall(last = FALSE, col_label = "Total")


state_sumstats <- linelist_final |>
  select(
    interview_stat_new,
    immunity,
    ltfu_new,
    curr_quarantined,
    curr_active_mon,
    pep_admin,
    curr_exposure_pd
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
      pep_admin ~ "PEP adminsitered to date",
      curr_exposure_pd ~ "Exposure Period"
    )
  )

# print sum stats (column %'s)
print(county_sumstats)
print(state_sumstats)


# Make a list for a single export
combine_metrics <- list(
  "linelist" = linelist_final,
  "county" = county_sumstats,
  "state" = state_sumstats
)

# Map:

#Step 1: Count cases per county
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

#Step 4: Heat map white for zero then darkish blue for highest counts. borders are black, text color is red, bold, and 4.5 font
contacts_heatmap <- ggplot(nc_map_data) +
  geom_sf(aes(fill = n_obs), color = "white", linewidth = 0.3) +

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

#Print heatmap
contacts_heatmap

# send to Outputs folder
#write.xlsx(x = combine_metrics, file = contacttracing)

# SQL again for grouping of interviews conducted by day
contact_view <- sqldf(
  "
    select 
        a.int_date,
        b.day_symptom,
        coalesce (a.int_date, b.day_symptom) as date_final,
        CAST(coalesce (a.int_date, b.day_symptom) AS TEXT) as date_char,
        count (distinct a.record_id) as count_contact,
        count (distinct b.`Event.ID`) as count_case
        
        
        from linelist_final a full join linelist_vaccine2 b
            on a.int_date = b.day_symptom
            group by b.day_symptom , a.int_date
            order by date_final
           "
)


contact_view$date_final <- as.Date(contact_view$date_final)

contacts_epilabel <- paste0(
  "Number of known exposed contacts interviewed and cases by day ",
  Sys.Date()
)


# Epi curves
epi_curve_contacts <- contact_view |>
  mutate(week_int = floor_date(date_final, "week", week_start = 1) + days(7)) |>
  ggplot(aes(x = date_final, y = count_contact)) +

  geom_col(aes(fill = "Contacts"), width = 0.7) +
  geom_col(aes(y = count_case, fill = "Cases"), width = 0.35) +

  scale_fill_manual(
    name = NULL,
    values = c("Contacts" = "#31739b", "Cases" = "#900d61")
  ) +

  scale_y_continuous(limits = c(0, 50), breaks = seq(0, 50, by = 8)) +

  geom_text(
    aes(label = ifelse(count_contact > 0, count_contact, "")),
    vjust = -0.5,
    size = 3,
    color = "#31739b"
  ) +

  geom_text(
    aes(y = count_case, label = ifelse(count_case > 0, count_case, "")),
    vjust = -0.5,
    size = 3,
    color = "#900d61"
  ) +

  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    # Legend below the x-axis
    legend.position = "bottom",
    legend.direction = "horizontal",
  ) +

  labs(x = "Day", y = "Count") +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
  labs(title = contacts_epilabel, subtitle = "North Carolina")

epi_curve_contacts

# fin

#
# # # Other frequency tables replace select() with what you want to see for data checks, validation, curiosity, etc.
# sumstats_freqs <- working_redcap_2 |>
#
#     select(home_county) |>
#     tbl_summary()
#
# sumstats_freqs
