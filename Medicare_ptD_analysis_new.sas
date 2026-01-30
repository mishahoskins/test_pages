/*
 *------------------------------------------------------------------------------
 * Program Name:  Medicare_ptD_analysis_new.sas 
 * Author:        Mikhail Hoskins
 * Date Created:  10/21/2025
 * Date Modified: 
 * Description:   Revised from Meg Sredl's code to create a look at Medicare part D antibiotic prescribing practices in NC. 
 *				  				  
 *
 * Inputs:       C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\Data all data grouped by year.
 * Output:       
 * Notes:        
 *					
 *------------------------------------------------------------------------------
 */



/*Macros for dates and disease*/

	/*update these*/
%let mindate = 01Jan2025; /*Minimum date you want to view (usually start of the year for monthly graphs). We also use this for the year max to make sure we're displaying non-complete data for the most recent year*/
%let maxmonth = 01Sep2025;/*Same as above but most recent month 1-denorm table month*/

%let datapath = C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\Data\;
%let outpath = C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\Output\;

libname analysis 'C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\sasdata';/*output path for sas7bdat file*/




/*SKP THIS UNLESS PULLING IN NEW DATA; GO TO 'START HERE'*/

/*Import all datasets: macro because lazy*/
%macro import  (year=,);
proc import datafile="&datapath.Medicare_Part_D_Prescribers_by_Provider_&year..csv"
            out=medD_&year
            dbms=csv replace;
			getnames=yes;
			datarow=2;
run;
/*Add year variable for annual grouping*/
data medD_&year._clean;
set medD_&year;

	year_var = &year;
run;

proc sql;
create table medD_&year._clean_2 as
select

	year_var,
	prscrbr_type, 
	antbtc_tot_clms as abx_tot_clms, 
	antbtc_tot_benes as abx_tot_benes, 
	tot_clms, 
	tot_benes as tot_benes, 
	prscrbr_npi as npi, 
	prscrbr_crdntls,
	Prscrbr_St1,/*provider address*/
	Prscrbr_RUCA_Desc /*Rurality*/


from medD_&year._clean
;
quit;

%mend;

%import(year=2023);
%import(year=2022);
%import(year=2021);
%import(year=2020);
%import(year=2019);
%import(year=2018);


proc contents data=medD_2023_clean_2 order=varnum;run;


/*2023 being a pain in the butt with a character value for total beneficiaries, recode to numeric*/
proc sql;
create table medD_2023_clean_3 as
select 

	year_var,
	prscrbr_type, 
	put(abx_tot_clms, 3.) as abx_tot_clms, 
	put (abx_tot_benes, 3.) as abx_tot_benes, 
	tot_clms, 
	tot_benes,
	npi, 
	prscrbr_crdntls,
	Prscrbr_St1,
	Prscrbr_RUCA_Desc

from medD_2023_clean_2
;
quit;

/*Merge them all together, one big Medicare pt D 2018-2023 dataset*/
data medD_all;
	set medD_2018_clean_2 medD_2019_clean_2 medD_2020_clean_2 medD_2021_clean_2 medD_2022_clean_2 medD_2023_clean_3;

run;



/*Save to SAS dataset folder*/
data analysis.medD_2018_2023;
	set medD_all;
run;



/*START HERE*/


/*Make variables numeric where needed*/
proc sql;
create table medD_prep as
select

	year_var,
	prscrbr_type, 
	input(abx_tot_clms, best.) as abx_tot_clms, 
	input(abx_tot_benes, best.) as abx_tot_benes, 
	tot_clms, 
	tot_benes, 
	npi, 
	prscrbr_crdntls,
	Prscrbr_St1,
	Prscrbr_RUCA_Desc,
	prscrbr_type,

		case when prscrbr_type in ("Dentist") then "Dentist"
	 	 when prscrbr_type in ("Internal Medicine") then "Internal Medicine"
	 	 when prscrbr_type in ("Nurse Practitioner") then "Nurse Practitioner"
		 when prscrbr_type in ("Physician Assistant") then "Physician Assistant"
		 when prscrbr_type in ("Urology") then "Urology"
		 when prscrbr_type like '%Family%' then "Family Practice"
		 when prscrbr_type not in ("Dentist", "Internal Medicine", "Nurse Practitioner", "Physician Assistant", "Urology" , "Family") then "Other"

	else "" end as type_new

from analysis.medD_2018_2023
	/*optional year statement
	where year_var in (2023)*/
;
quit;

proc freq data=medD_prep order=freq; tables prscrbr_type / norow nocol nopercent nocum; where type_new in ("Other");run;


proc print data=medD_prep_1 noobs;run;
proc print data=specialty_90 noobs;run;



/*Creating two separate 90th percentile thresholds. First is for each year across ALL specialties. Second is by specialty aggregated from 2018-2023, so 90th percentile for Dentists using all ABX claims from 2018-2023 for example*/
/*Annual threshold*/
proc sort data=medD_prep;
	by year_var;
run;

proc univariate data=medD_prep noprint;
	var abx_tot_clms;
	by year_var;
	output out=medD_prep_1 p90=p90 p10=p10 median=median mean=mean;
		where abx_tot_clms ge (11);
run;

/*Specialty type threshold*/
proc sort data=medD_prep;
	by type_new;
run;

proc univariate data=medD_prep noprint;
	var abx_tot_clms;
	by type_new; /*can add year_var in here too for type by year*/
	output out=specialty_90 p90=p90 p10=p10 median=median mean=mean;
		where abx_tot_clms ge (11);
run;


proc print data=medD_prep_1 noobs;run;
proc print data=specialty_90 noobs;run;

/*Begin prepping tables*/

proc sql;
create table medD_prep_2 as
select 
	*,
/*Take our univariate values for each year's 90th percentile and flag high prescribers*/
	case when year_var in (2018, 2019) and abx_tot_clms GE 189 then 1
		 when year_var in (2020) and abx_tot_clms GE 163 then 1
		 when year_var in (2021) and abx_tot_clms GE 155 then 1
		 when year_var in (2022) and abx_tot_clms GE 168 then 1
		 when year_var in (2023) and abx_tot_clms GE 174 then 1
	
	else 0 end as p90_flag,

	(abx_tot_clms / tot_benes) * 1000 as rate "Prescribing Rate per 1000 Beneficiaries",

/*Take our univariate values for each specialty's 90th percentile and flag high prescribers*/
	case when type_new in ("Internal Medicine") and abx_tot_clms GE 278 then 1
		 when type_new in ("Nurse Practitioner") and abx_tot_clms GE 179 then 1
		 when type_new in ("Physician Assistant") and abx_tot_clms GE 175 then 1
		 when type_new in ("Urology") and abx_tot_clms GE 542 then 1
		 when type_new in ("Family Practice") and abx_tot_clms GE 278 then 1
		 when type_new in ("Dentist") and abx_tot_clms GE 120 then 1
		 when type_new in ("Other") and abx_tot_clms GE 101 then 1
	
	else 0 end as p90_flag_spec

from medD_prep;


create table _90th_ as
select

	year_var "Year",
	mean "Mean Prescrip. per Year",
	median "Median Prescrip. Per Year",
	p90 "90th Percentile Threshold by Year"

from medD_prep_1;

create table _90th_spec as
select

	type_new "Specialty",
	mean "Mean Prescrip. by Specialty",
	median "Median Prescrip. by Specialty",
	p90 "90th Percentile Threshold by Specialty"

from specialty_90;


quit;


/*Analysis*/
/*To replicate CDC analysis in NC, run a non-parametric wilcoxon rank sum*/

proc npar1way data=medD_prep_2 wilcoxon plots(only)=(normalboxplot scores=data);
title "Nonparametric test to compare median abx claims rate by provider level (high volume vs. not high volume)";
	class p90_flag; /*yearly 90th percentile*/
	var rate; /*Use the rate to account for some providers having many more patients ie. family practice more than dental surgery see Gouin et a. (2019)*/

			where  abx_tot_clms ge (10);

run;
/*Do it again for specialty as our class (highest volume prescribers by year)*/
proc npar1way data=medD_prep_2 wilcoxon plots(only)=(normalboxplot scores=data);
title "Nonparametric test to compare median abx claims rate by provider level (high volume vs. not high volume)";
	class p90_flag_spec;
	var rate; /*Use the rate to account for some providers having many more patients ie. family practice more than dental surgery see Gouin et a. (2019)*/

			where  abx_tot_clms ge (10);

run;
/*High volume prescriber prescribe a statistically higher rate of abx versus not-high volume prescribers.... shocker...*/

proc sort data=medD_prep_2;
	by  p90_flag_spec;

run;


proc univariate data=medD_prep_2 noprint;
	var rate;
	by p90_flag_spec;
	output out=medD_prep_3 q1=Q1 q3=Q3 median=median mean=mean;
		where abx_tot_clms ge (11);
run;

proc print data=medD_prep_3;run;




/*Now we'll merge tables into one to have one table with ONLY what we want to depict*/
/*Counts*/
proc sql;
create table final_table_part_I as
select

	type_new "Specialty",

	sum (case when p90_flag_spec in (1) then 1 else . end) as hi_volume "Higher-volume Prescribers (top 10%)" format comma10.0,
		sum (case when p90_flag in (1) then abx_tot_clms else 0 end) as Hnum_abx "Number of Prescriptions from High Volume Prescribers" format comma10.0,
		median(case when p90_flag_spec in (1) then rate else . end) as Hmed_claims format comma10.0 label="Median Number of Prescriptions from High Volume Prescribers per 1,000 Beneficiaries",

	sum (case when p90_flag_spec in (0) then 1 else . end) as lo_volume "Lower-volume Prescribers (bottom 90%)" format comma10.0,
		sum (case when p90_flag in (0) then abx_tot_clms else 0 end) as Lnum_abx "Number of Prescriptions from Lower Volume Prescribers" format comma10.0,
		median(case when p90_flag_spec in (0) then rate else . end) as Lmed_claims format comma10.0 label="Median Number of Prescriptions from Lower Volume Prescribers per 1,000 Beneficiaries",

	sum (case when p90_flag_spec in (0,1) then 1 else . end) as all_volume "Total Prescribers" format comma10.0,
		sum (case when p90_flag in (0,1) then abx_tot_clms else 0 end) as all_num_abx "Number of Total Prescriptions" format comma10.0,
		median(case when p90_flag_spec in (0,1) then rate else . end) as all_med_claims format comma10.0 label="Median Number of Prescriptions per 1,000 Beneficiaries"

from medD_prep_2
where abx_tot_clms ge (11)
	group by type_new
;

/*Percentages*/
create table final_table_part_II as
select

	type_new "Specialty",
	hi_volume,
	(hi_volume / all_volume) as pct_hi_vol "Percent Higher-volume Prescribers" format percent10.1,
	Hnum_abx,
	(Hnum_abx / all_num_abx) as pct_hi_presc "Percent of Prescriptions from Higher-volume Prescribers" format percent10.1,
	Hmed_claims,

	lo_volume,
	(lo_volume / all_volume) as pct_lo_vol "Percent Lower-volume Prescribers" format percent10.1,
	Lnum_abx,
	(Lnum_abx / all_num_abx) as pct_lo_presc "Percent of Prescriptions from Lower-volume Prescribers" format percent10.1,
	Lmed_claims,

	all_volume,
	all_num_abx,
	all_med_claims


from final_table_part_I
	order by type_new
;

create table final_table_part_III as
select


	sum (case when p90_flag_spec in (1) then 1 else . end) as hi_volume "Higher-volume Prescribers (top 10%)" format comma10.0,
		sum (case when p90_flag in (1) then abx_tot_clms else 0 end) as Hnum_abx "Number of Prescriptions from High Volume Prescribers" format comma10.0,
		median(case when p90_flag_spec in (1) then rate else . end) as Hmed_claims format comma10.0 label="Median Number of Prescriptions from High Volume Prescribers per 1,000 Beneficiaries",

	sum (case when p90_flag_spec in (0) then 1 else . end) as lo_volume "Lower-volume Prescribers (bottom 90%)" format comma10.0,
		sum (case when p90_flag in (0) then abx_tot_clms else 0 end) as Lnum_abx "Number of Prescriptions from Lower Volume Prescribers" format comma10.0,
		median(case when p90_flag_spec in (0) then rate else . end) as Lmed_claims format comma10.0 label="Median Number of Prescriptions from Lower Volume Prescribers per 1,000 Beneficiaries",

	sum (case when p90_flag_spec in (0,1) then 1 else . end) as all_volume "Total Prescribers" format comma10.0,
		sum (case when p90_flag in (0,1) then abx_tot_clms else 0 end) as all_num_abx "Number of Total Prescriptions" format comma10.0,
		median(case when p90_flag_spec in (0,1) then rate else . end) as all_med_claims format comma10.0 label="Median Number of Prescriptions per 1,000 Beneficiaries"

from medD_prep_2
	where abx_tot_clms ge (11)
;

create table final_table_part_IV as
select

	hi_volume,
	(hi_volume / all_volume) as pct_hi_vol "Percent Higher-volume Prescribers" format percent10.1,
	Hnum_abx,
	(Hnum_abx / all_num_abx) as pct_hi_presc "Percent of Prescriptions from Higher-volume Prescribers" format percent10.1,
	Hmed_claims,

	lo_volume,
	(lo_volume / all_volume) as pct_lo_vol "Percent Lower-volume Prescribers" format percent10.1,
	Lnum_abx,
	(Lnum_abx / all_num_abx) as pct_lo_presc "Percent of Prescriptions from Lower-volume Prescribers" format percent10.1,
	Lmed_claims,

	all_volume,
	all_num_abx,
	all_med_claims


from final_table_part_III
;
create table final_table_part_V as
select
	
	p90_flag_spec '90th %-tile among Specialty 1=Yes',
	mean 'Mean Prescription Rate' format 10.1, 
	median 'Median Prescription Rate' format 10.1, 
	Q1 'Lower Quartile Prescription Rate' format 10.1, 
	Q3  'Upper Quartile Prescription Rate' format 10.1

from medD_prep_3; 
quit;



proc print data=final_table_part_IV noobs label;run;
proc print data=final_table_part_II noobs label;run;

proc print data=final_table_part_V noobs label;run;



/*ANALYSIS*/
/*Create density groups*/
proc sql;
create table analysis_medD as
select

	*,
/*Population density dense --> rural*/	
	case when Prscrbr_RUCA_Desc like '%Metropolitan%' then 0 /*Metro*/
		 when Prscrbr_RUCA_Desc like '%Micropolitan%' then 1 /*Micro*/
		 when Prscrbr_RUCA_Desc like '%Small town%' then 2 /*Small Town*/
		 when Prscrbr_RUCA_Desc like '%Rural%' or Prscrbr_RUCA_Desc like '%Secondary%' then 3 /*Rural*/

	else . end as density_cat "Population density",


/*Population density binary, rural or not rural*/	
	case when Prscrbr_RUCA_Desc like '%Metropolitan%' or Prscrbr_RUCA_Desc like '%Micropolitan%' or Prscrbr_RUCA_Desc like '%Small town%' then 0 /*non-rural*/
		 when Prscrbr_RUCA_Desc like '%Rural%' or Prscrbr_RUCA_Desc like '%Secondary%' then 1 /*Rural*/

	else . end as density_binary "Population density (binary)",

	median(abx_tot_clms) as med_abx 



from medD_prep_2
	group by NPI
;
quit;





/*Save to SAS datasets and tables folder*/
data analysis.analysis_medD_2023;
	set analysis_medD;
run;

data analysis.final_table_part_IV;
	set final_table_part_IV;
run;

data analysis.final_table_part_II;
	set final_table_part_II;
run;

data analysis.final_table_part_V;
	set final_table_part_V;
run;



/*Univariate to look at normality (it's not)*/
proc univariate data=analysis_medD ;
var rate;
histogram rate / normal;

	where abx_tot_clms ge (10) and rate LE (1600);
run;
	/*i. qq plot to look at normality (still not normal but when we eliminate outliers it's not the worst thing*/
proc univariate data=analysis_medD normal; 
	qqplot rate /Normal(mu=est sigma=est color=red l=1);
	var rate;
where p90_flag_spec not in (1) and rate LE (1600);
run;

/*clear all your other terrible results*/
dm 'odsresults; clear';

ods graphics noborder;

/*Label numeric density groups*/
proc format;
    value density_cat
        0 = 'Metropolitan'
        1 = 'Micropolitan'
        2 = 'Small Town'
        3 = 'Rural';


run;
/*I like the categorical approach here. Looking at each category of population density grouped by "most urban (metropolitan)" to "least urban (rural)."
Each group is more likely to be  high prescriber as compared to the reference group (metropolitan), but there are some interesting trends when looking
at less urban groups compared to each other. For ex: micropolitan specialties (group 1) are less likely to be be high prescribers as compared to small town
categorized specialties (group 2). However, group 1 is more likely to be a high presciber as compared to their rural (group 3) counterparts.*/


proc logistic data=analysis_medD plots(only)=(oddsratio(range=0.5, 2.75)); /*plotting OR each density compared to others*/
	class p90_flag_spec (param=ref ref='0') density_cat (param=ref ref='Metropolitan') type_new (param=ref ref='Family Practice');
	/*multivariate model using both density and specialty type*/
	model p90_flag_spec = density_cat type_new/ noor parmlabel;/*no ODDS ratio (noor) to simplyfy output we don't need this OR, we want the comprehensive one next*/
/*Display all comparisons of ORs*/
	oddsratio density_cat;
		where abx_tot_clms ge (10);
		format density_cat density_cat.;

run;



proc logistic data=analysis_medD plots(only)=(oddsratio(range=0.5, 2.5)); /*plotting OR each type compared to internal medicine*/
	class p90_flag_spec (param=ref ref='0') type_new (param=ref ref='Internal Medicine');
	/*univariate model using  specialty type*/
	model p90_flag_spec = type_new/ parmlabel;/*no ODDS ratio (noor) to simplyfy output we don't need this OR, we want the comprehensive one next*/
/*Display all comparisons of ORs
	oddsratio type_new;*/
		where abx_tot_clms ge (10);
		format density_cat density_cat.;

run;

/*ANOVA: independent still density category, but dependent is # of abx. (can try claim rate too) ANOVA takes each group (density categories) and compares the mean of each outcome (abx perscriptions), are they more different than we would expect? 
		I.e.: are we seeing higher mean abx prescrbiing practices in more rural(small town, micro etc.) as compared to their metropolitan counterparts (reference group)? F-statistic, pull those textbooks out and brush off
			  the dust, the F-statistic is the ratio of variance between groups compared to the ratio within each group. How much does each individual group vary and how does that compare between groups. It's tricky but I
			  feel adds value here. 



			Fstat= Within-group variance / Between-group variance

*/


/*Here's an interpretation: There were (statistically) significant differences in the mean number of antibiotic claims across density categories and across practice specialty types.*/

title;
/*ANOVA model*/

		/*So this isn't exactly normal, however when we eliminate outliers (90th percentile and above), we observe somewhat more normal distribution (still meh.) so we'll go with an ANOVA but with acknowledged loss of power*/

/*ANOVA, but with two independent (specialty type, and population density). We'll assess those against each other and against the number of claims while elminating the ouliers above the 90th percentile.*/
proc glm data=analysis_medD;
/*Measuring both density and specialty type as independent categorical variables*/
    class density_cat type_new;
/*abx claims are continuous dependent. Looking at density and specialty AND (key point here), the interaction between density and specialty as it affects the mean number of claims*/
    model rate=density_cat type_new density_cat*type_new;

		where p90_flag_spec not in (1) and abx_tot_clms ge (10) ;		
run;

/*Because it's not actually normal we'll also run a Wilcoxon rank-sum test to compare non-parametric median prescribing (and med. rate) across densities

https://www.cdc.gov/mmwr/volumes/71/wr/mm7106a3.htm

Basically using this method but across pop. density: Is the median abx prescription claim rate different across population density?*/
ods html style=journal; 
proc npar1way data=analysis_medD wilcoxon plots(only)=(normalboxplot scores=data);
title "Nonparametric test to compare median abx claims rate by provider and population density of provider location";
	class density_cat;
	var rate; /*Use the rate to account for some providers having many more patients ie. family practice more than dental surgery see Gouin et a. (2019)*/

			where p90_flag_spec not in (1) and abx_tot_clms ge (10);

			format density_cat density_cat.;

run;


/*For quantile regression in SAS we need to reverse our groups. Quantreg as a procedure takes the highest category and uses it as a reference (not entirely true we can format, and order=formatted but initially it wasn't quite working as intended).
  Since we have "old" SAS, we don't have the full class statementment with parameters (param=ref) and reference (ref=0) statements. */
data model_quant;
set analysis_medD;
length year_char $4.;
    density_binary_reversed = 1 - density_binary;

	density_cat_reversed = .;

		if density_cat = 0 then density_cat_reversed = 3;
		if density_cat = 1 then density_cat_reversed = 2;
		if density_cat = 2 then density_cat_reversed = 1;
		if density_cat = 3 then density_cat_reversed = 0 /*Rural*/;

	year_char = '';
		
		if year_var = 2018 then year_char = "2018";
		if year_var = 2019 then year_char = "2019";
		if year_var = 2020 then year_char = "2020";
		if year_var = 2021 then year_char = "2021";
		if year_var = 2022 then year_char = "2022";
		if year_var = 2023 then year_char = "2023";
run;

/*Check to make sure your "new" reveresed variables are the same as the old but in the opposite order or character*/
proc freq data=model_quant; tables density_cat density_cat_reversed year_char/ norow nocol nopercent nocum;run;

proc format;

value density_binary_reversed 
			0= "Rural"
			1= "Urban";

value density_cat_reversed
			0= "Rural"
			1= "Hamlet (Small Town)"
			2= "Micropolitan"
			3= "Metropolitan";

value $type_new

		"Dentist" = "1. Dentist" 
		"Family Practice" = "2. Fam. Prac."  
		"Internal Medicine" = "7. Int. Med."
		"Nurse Practitioner" = "3. NP"
		"Other" = "4. Other"  
		"Physician Assistant" = "6. PA" 
		"Urology" =  "5. Uro"
;

run;
/*Save to folder for R viz*/

data analysis.medD_prep_3;
	set medD_prep_3;
run;

dm 'odsresults;clear';
/*perform quantile regression in a few ways. First plot shows rate by quantile. Each subsequent plot shows the rate diff on the y axis from the first plot and how it changes over quantiles.*/
ods html style=journal; 
title;
proc sort data=model_quant;by year_char;run;
/*Full model, add and subtract from the class and model statements to look at different independent variables predicting rate.
  Use by statement to view by year*/
proc quantreg data=model_quant;
/*group by year
by year_char;*/
/*Class is our predictor*/
class density_binary_reversed type_new year_char;
    model rate = density_binary_reversed type_new year_char/ quantile= 0.05 to 0.95 by 0.05 plot=quantplot(density_binary_reversed);

	*where abx_tot_clms ge (10) and year_var in (2023);

	output out = predictionmodel_binary p = predquant;
	label density_binary_reversed = "Density:" type_new = "Specialty" year_char = "Year";

		format density_binary_reversed density_binary_reversed. type_new $type_new.;

run;


proc quantreg data=model_quant;
/*group by year
by year_char;*/
/*Class is our predictor*/
class density_cat_reversed type_new year_char;
    model rate = density_cat_reversed type_new year_char/ quantile= 0.05 to 0.95 by 0.05 plot=quantplot(density_cat_reversed);

	*where abx_tot_clms ge (10) and year_var in (2023);

	output out = predictionmodel_categorical p = predquant;
	label density_cat_reversed = "Density:" type_new = "Specialty" year_char = "Year";

		format density_cat_reversed density_cat_reversed. type_new $type_new.;

run;


proc print data=predictionmodel_binary (obs=100);run;

/*Create visual for yearly predicted claim rate from model output for easier viewing*/
proc sort data=predictionmodel_binary out=annual_plot;by year_char;run;

proc sql;
create table graphics_year as
select

	year_char,
	median(predquant1) as med_05,
	median(predquant2) as med_10,
	median(predquant4) as med_25,
	median(predquant10) as med_50,
	median(predquant15) as med_75,
	median(predquant18) as med_90,
	median(predquant19) as med_95



from annual_plot
	where density_binary in (1) and type_new not in ('Internal Medicine') /*exclude our two reference groups*/

	group by year_char


;

quit;

proc contents data=predictionmodel_binary order=varnum;run;


ods graphics / noborder labelmax=3700;
ods html style=HTMLBlue; 

proc sgplot data = graphics_year noborder;
title "Predicitve model expected rate of antibiotic prescriptions among non-reference group (non-rural, non internal medicine) providers";
yaxis max=1000 label = "Predicted claim rate per 1,000 beneficiaries";

	series x = year_char y = med_05 / curvelabel = '5 %tile';
	*series x = year_char y = med_10/curvelabel = '10 %tile';
	series x = year_char y = med_25 / curvelabel = '25 %tile';
	series x = year_char y = med_50 / curvelabel = '50 %tile';
	series x = year_char y = med_75 / curvelabel = '75 %tile';
	series x = year_char y = med_90 / curvelabel = '90 %tile' datalabel;
	series x = year_char y = med_95 / curvelabel = '95 %tile' datalabel;

run;


/*So this is cool, but we want to extrapolate across future years*/

