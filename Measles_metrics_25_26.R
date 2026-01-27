# Program Name:  Measles_metrics_25_26
# Author:        Mikhail Hoskins
# Edits:        
# Date Created:  01/19/2026
# Date Modified: 01/22/2026
# Description:   Contact tracing metrics from RedCap, confines to variables we need and produces summary stats by RESPONSE county NO PHI IN THIS DATASET/SCRIPT. 
#                Daily cadence. Pull data ~11:00am 
#
# Inputs:       All_Models_Identified_Cases_and_Contacts_Line_List_by_Event_Create_Date_DATESTAMP.xls
#               
# Output:       measles_metrics_raw_R
# Notes:        Use extract with LABELS, ex: THISISDATAWITH_**LABELS**.csv
#               Ease of use fix: Updated pathways 01/22/2026 to group df's into a list and point to output paths and single .xlsx export. 
#
#               Annotations are at # (between /* in SAS) to help guide.

#onetime installs
usethis::use_git()


tinytex::install_tinytex(force = TRUE)

# load libraries
pacman::p_load(dplyr, tidyr, rvest, lubridate, rio, skimr, sqldf, gtsummary, openxlsx, ggplot2, kableExtra, knitr, biostats, tigris, stringr)


# set working directory (if you haven't already) and output path
setwd("C:/Data/Measles/Data")
contacttracing <- paste0("C:/Data/Measles" , Sys.Date(), ".xlsx")


# Read in data
    # Import from NCEDSS delete excess headers and save as CSV
# reading in case info
working_redcap <- read.csv( "./StatewideMeaslesResp_DATA_LABELS_2026-01-27_1507.csv") # Update file name here 



# Confine to only what we need
working_redcap_2 <- working_redcap |> 
    select(Record.ID, This.field.will.display..Yes..if.the.contact.answered.Yes.to.having.an.MMR.record, Is.the.contact.considered.immune., Is.contact.lost.to.follow.up.,
           Calculate.most.recent.exposure.date, Quarantine.start.date, Calculated.quarantine.end.date.., Specify.Response, Repeat.Instrument, Data.Access.Group, Is.quarantine.needed., Monitoring.Need, 
           Call.outcome, Call.outcome.1, Call.outcome.2, Call.outcome.3, Call.outcome.4, Record.Status.., Complete., Date.of.interview) |> 
    
            filter(Repeat.Instrument %in% c(""))

# 
# mutate(across(
#         where(is.character),
#         ~ na_if(trimws(.x), "")))




# Rename longer vars for simplicity
working_redcap_2 <- working_redcap_2 |>
    rename(text_mmr = This.field.will.display..Yes..if.the.contact.answered.Yes.to.having.an.MMR.record,

           immunity = Is.the.contact.considered.immune.,
           ltfu = Is.contact.lost.to.follow.up.,
           calc_recent_exposure_date = Calculate.most.recent.exposure.date,
           date_quarantine_start = Quarantine.start.date,
           quarantine = Is.quarantine.needed.,
           specify_response = Specify.Response,
           calc_monitor_need = Monitoring.Need,
           record_status = Record.Status..,
           quar_end = Calculated.quarantine.end.date..,
           status = Complete.,
           int_date = Date.of.interview)

# Dates. ugh.
working_redcap_2$calc_recent_exposure_date <- ymd(working_redcap_2$calc_recent_exposure_date)
working_redcap_2$quar_end <- ymd(working_redcap_2$quar_end)
working_redcap_2$int_date <- ymd(working_redcap_2$int_date)

# 
# #        sniff test for variables if necessary:
#             
#         class(working_redcap$Calculated.quarantine.end.date)
#         levels(working_redcap_2$Calculated.quarantine.end.date)
# 

# SAS SQL but in R for everyone
response_calcs <- working_redcap_3 |>
    mutate(
        today_date = today(),
        
        # Week of contact
        
        week_int = ceiling_date(mdy(int_date), unit = "week") - days(1),
        
        # Calculate response_county_1
        response_county_1 = case_when(
            specify_response == 'Buncombe County contact investigation January 5, 2026' ~ 'Buncombe',
            specify_response == 'Rutherford County contact investigation January 8, 2026' ~ 'Rutherford',
            specify_response == 'Cabarrus County contact investigation January 8, 2026' ~ 'Cabarrus',
            specify_response == 'Polk County contact investigation December 31, 2025' ~ 'Polk',
            specify_response == 'Mecklenburg County contact investigation January 22, 2026' ~ 'Mecklenburg',
            
            Record.ID == '469' ~ 'Polk',
            Record.ID == '470' ~ 'Buncombe',
            TRUE ~ ''),
        
        # contact interview
        interview_stat = if_else(
            Call.outcome %in% c('Called - full interview completed', 'Called - partial interview completed') |
            Call.outcome.1 %in% c('Called - full interview completed', 'Called - partial interview completed') | Call.outcome.2 %in% c('Called - full interview completed', 'Called - partial interview completed') | 
            Call.outcome.3 %in% c('Called - full interview completed', 'Called - partial interview completed') | Call.outcome.4 %in% c('Called - full interview completed', 'Called - partial interview completed'), 
            1, 0), 
        interview_stat_new = case_when(
                    interview_stat == 1 ~ "Interviewed",
                    interview_stat == 0 ~ "No/Unable to Contact"),
        
        # Exposure time
        exp_time = as.numeric(today_date - calc_recent_exposure_date)) |> 

        # Responding county
        mutate(response_county_1 = na_if(response_county_1, ""),
                Data.Access.Group   = na_if(Data.Access.Group, ""),
                responding_county = coalesce(response_county_1, Data.Access.Group ),
                
        
        # Polk vs polk... can be use for future misspellings too
        responding_county_final = case_when(
            responding_county %in% c('Polk', 'polk') ~ 'Polk',
            TRUE ~ responding_county),
        
        #Loss to follow up
        ltfu_new = if_else(ltfu =='Yes', "Yes","No"),
        
        ltfu = case_when(
            ltfu == "" ~ "No",
            TRUE ~ ltfu),
  
        #immunity 
        immunity = case_when(
            immunity == ""  ~ "Unknown",
            TRUE ~ immunity),
        
        # Quarantine current and total: if quarantine denoted 'Yes' in Redcap AND quarantine date greater than today then 1 else 0 (we can denote unknown later if necessary)
        curr_quarantined = if_else((quar_end > today_date) & quarantine == 'Yes', 'Yes', 'No')) |>
    
        # Replace blanks with NA for total all time quarantined for table
            mutate(quarantine = na_if(quarantine, ""), 
        
        # Active monitoring 
        active_mon = if_else(calc_monitor_need == "Active", 1, 0),
        
        curr_active_mon = if_else((exp_time <= 21| is.na(exp_time)) & active_mon == 1 & record_status != 'Closed', 1, 0),
        
        end_actmon_dt = if_else(
            active_mon == 1, 
            calc_recent_exposure_date + days(21), 
            as.Date(NA)))

        # SQL but make it even R-y'er
        linelist_final <- response_calcs |> select(
            Record.ID,
            responding_county_final,
            responding_county,
            response_county_1,
            week_int,
            Data.Access.Group,
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
            end_actmon_dt)

#Summary stats

county_sumstats <- linelist_final |>
    select(interview_stat_new, immunity, ltfu_new, quarantine, curr_quarantined, active_mon, curr_active_mon, responding_county_final) |>
    tbl_summary(by = responding_county_final,   missing = "no", type = list(ltfu_new~ "categorical"),
                label = list(
                    interview_stat_new ~ "Status of interview",
                    immunity ~ "Up to date immunity status",
                    ltfu_new ~ "Lost to follow-up",
                    quarantine ~ "Quarantined total",
                    curr_quarantined ~ "Currently quarantined",
                    active_mon ~ "Active monitoring total",
                    curr_active_mon ~ "Currently in active monitoring"))

state_sumstats <- linelist_final |>   
    select(interview_stat_new, immunity, ltfu_new, quarantine, curr_quarantined, active_mon, curr_active_mon) |>
    tbl_summary( missing = "no", type = list(ltfu_new~ "categorical"),
                 label = list(
                     interview_stat_new ~ "Status of interview",
                     immunity ~ "Up to date immunity status",
                     ltfu_new ~ "Lost to follow-up",
                     quarantine ~ "Quarantined total",
                     curr_quarantined ~ "Currently quarantined",
                     active_mon ~ "Active monitoring total",
                     curr_active_mon ~ "Currently in active monitoring"))

# print sum stats (column %'s)
county_sumstats
state_sumstats

# Make a list for a single export
combine_metrics <- list("linelist" = linelist_final, "county" = county_sumstats, "state" = state_sumstats)


#Map:

#Step 1: Count cases per county
county_counts <- linelist_final |>
    mutate(county = str_to_title(str_trim(Data.Access.Group))) |> 
    count(county, name = "n_obs")

# Had this in a prior map, don't know why, kept it.
options(tigris_use_cache = TRUE)

#Step 2: Get counties from TIGRIS package
nc_counties <- counties(
    state = "NC",
    cb = TRUE,     
    year = 2023) |>
    mutate(
    county = str_to_title(NAME))


#Step 3: Merge and make NAs 0
nc_map_data <- nc_counties |>
    left_join(county_counts, by = "county") |> mutate(n_obs = replace_na(n_obs, 0))

#Step 4: Heat map white for zero then darkish blue for highest counts. borders are black, text color is red
county_heatmap <- ggplot(nc_map_data) + geom_sf(aes(fill = n_obs), color = "black", linewidth = 0.2) +
  
  geom_sf_text(
    data = dplyr::filter(nc_map_data, n_obs > 0),
    aes(label = n_obs),
    color = "red",
    size = 4.5,
    fontface = "bold") +
  
  scale_fill_gradient(
    low  = "white",
    high = "#1f4e79",   # same matte blue you used earlier
    name = "Contacts") +

  theme_minimal() +
  
  theme(panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    legend.position = "none") + #No legend, we can add it back in but for now we just want to see the county breakdown
  
  labs(title = "Number of known exposed contacts by county",
    subtitle = "North Carolina")

#Print heatmap
county_heatmap


#Workaround, output not working, no idea how this works pulled it from stack and some data science website

wb <- createWorkbook()

# Sheet 1: linelist
addWorksheet(wb, "linelist")
writeData(wb, "linelist", combine_metrics$linelist)

# Sheet 2: county metrics (extract table)
addWorksheet(wb, "county")
writeData(wb, "county", as_tibble(combine_metrics$county))

# Sheet 3: state metrics (extract table)
addWorksheet(wb, "state")
writeData(wb, "state", as_tibble(combine_metrics$state))

saveWorkbook(wb, contacttracing, overwrite = TRUE)

# fin

# 
# # Other frequency tables replace select() with what you want to see for data checks, validation, curiosity, etc.
# sumstats_freqs <- working_redcap_2 |>
#     
#     select(Data.Access.Group, specify_response, status) |>
#     tbl_summary()
# 
# sumstats_freqs
# 



