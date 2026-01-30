




ods graphics /noborder;
title; footnote;

/*Set your output pathway here*/ 

ods pdf file="&outpath.Medicare_ptD_tables_&sysdate..pdf" 
/*Named a generic overwriteable name so we can continue to reproduce and autopopulate a template;
style=journal */startpage=never;

options number nodate;
ods pdf text= "Antibiotic Prescribing Claims by Volume, North Carolina 2018-2023";
proc print data=final_table_part_IV noobs label 
/*General styling to fit a portrait orientation*/
style(table)=[cellpadding=4 cellspacing=0 borderwidth=0 frame=void rules=none width=100%];

var hi_volume pct_hi_vol Hnum_abx pct_hi_presc Hmed_claims lo_volume pct_lo_vol Lnum_abx pct_lo_presc Lmed_claims all_volume all_num_abx all_med_claims   
    / 
/*Specific "table 1" styling*/
    /* Header: top and bottom borders only */
    style(header)=[
        font_weight=bold 
        backgroundcolor=white 
        just=center 
        borderbottomcolor=black borderbottomwidth=1 
        bordertopcolor=black bordertopwidth=1 
        borderleftwidth=0 borderrightwidth=0]

    /* Data: center everything, don't bold anything but headers*/
    style(data)=[
        just=center 
        fontsize=9pt 
        bordercolor=white borderwidth=0];


run;
title;

proc print data=final_table_part_II noobs label 
/*General styling to fit a portrait orientation*/
style(table)=[cellpadding=4 cellspacing=0 borderwidth=0 frame=void rules=none width=100%];

var type_new hi_volume pct_hi_vol Hnum_abx pct_hi_presc Hmed_claims lo_volume pct_lo_vol Lnum_abx pct_lo_presc Lmed_claims all_volume all_num_abx all_med_claims 
    / 
/*Specific "table 1" styling*/
    /* Header: top and bottom borders only */
    style(header)=[
        font_weight=bold 
        backgroundcolor=white 
        just=center 
        borderbottomcolor=black borderbottomwidth=1 
        bordertopcolor=black bordertopwidth=1 
        borderleftwidth=0 borderrightwidth=0]

    /* Data: center everything, don't bold anything but headers*/
    style(data)=[
        just=center 
        fontsize=9pt 
        bordercolor=white borderwidth=0];


run;
title;

proc print data=final_table_part_V noobs label
style(table)=[cellpadding=4 cellspacing=0 borderwidth=0 frame=void rules=none width=100%];

var p90_flag_spec mean Q3 median Q1 
    / 
/*Specific "table 1" styling*/
    /* Header: top and bottom borders only */
    style(header)=[
        font_weight=bold 
        backgroundcolor=white 
        just=center 
        borderbottomcolor=black borderbottomwidth=1 
        bordertopcolor=black bordertopwidth=1 
        borderleftwidth=0 borderrightwidth=0]

    /* Data: center everything, don't bold anything but headers*/
    style(data)=[
        just=center 
        fontsize=9pt 
        bordercolor=white borderwidth=0];


run;


title;footnote;
ods graphics noborder;
/*Plot by density and abx count only (right skew: median < mean)*/
proc sgplot data=model_quant noborder;
title height=10pt "Antibiotic prescribing rate and IQR by specialty type, North Carolina 2018-2023";
    vbox rate / category=type_new nooutliers
        fillattrs=(color=lightgray) 
        meanattrs=(symbol=circlefilled color=black size=8)
		medianattrs=(color=black pattern=dash thickness=2)
        whiskerattrs=(thickness=1 color=black)
			displaystats=(median mean) ;

    xaxis label="Specialty" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


    yaxis min=0 max=2000 label="Antibiotic Prescription Rate per 1,000 Beneficiaries" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);

    format density_cat densityfmt. density_binary_reversed density_binary_reversed.;

		where abx_tot_clms ge (10);


run;
title;

/*Plot and group by specialty type*/
proc format;
    value densityfmt
        0 = "Metropolitan"
        1 = "Micropolitan"
        2 = "Small Town"
		3 = "Rural";


run;

ods graphics noborder;
proc sgplot data=analysis_medD noborder;
title height=10pt "Antibiotic prescribing rate and IQR by specialty type, location North Carolina 2018-2023";
    vbox rate / category=density_cat group=type_new nooutliers
        /*fillattrs=(color=CX80B1D3) */
        meanattrs=(symbol=circlefilled color=red size=8)
		medianattrs=(color=red)
        whiskerattrs=(thickness=1 color=black);

    xaxis label="Population Density Category" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


    yaxis min=0 max=2000 label="Antibiotic Prescription Rate per 1,000 Patients" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


	format density_cat density_cat.;
		keylegend / title="Specialty Type" location=outside position=bottom noborder titleattrs= (family="Arial" size=8 weight=bold) valueattrs= (family="Arial" size=8);

		where abx_tot_clms ge (10);
run;

/*Plot predicted values*/

ods graphics noborder;
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


ods pdf close;

			/*------------------------------------------------------------------------------------------------------------------------------------------------------*/
			/*------------------------------------------------------------------------IMAGES------------------------------------------------------------------------*/
			/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*Images*/
ods graphics on / imagename="density_oddsratio" imagefmt=png;
ods listing gpath="C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\images";


proc logistic data=analysis_medD plots(only)=(oddsratio(range=0.5, 2.58)); /*plotting OR each density compared to others*/
	class p90_flag_spec (param=ref ref='0') density_cat (param=ref ref='Metropolitan') type_new (param=ref ref='Family Practice');
	/*multivariate model using both density and specialty type*/
	model p90_flag_spec = density_cat type_new/ noor parmlabel;/*no ODDS ratio (noor) to simplyfy output we don't need this OR, we want the comprehensive one next*/
/*Display all comparisons of ORs*/
	oddsratio density_cat;
where abx_tot_clms ge (10);
		format density_cat density_cat.;

run;

ods graphics on / imagename="quant_reg_binary" imagefmt=png;
ods listing gpath="C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\images";

/*Full model, add and subtract from the class and model statements to look at different independent variables predicting rate.
  Use by statement to view by year*/
proc quantreg data=model_quant;
/*group by year*/
by year_char;
/*Class is our predictor*/
class density_binary_reversed type_new year_char;
    model rate = density_binary_reversed type_new year_char/ quantile= 0.05 to 0.95 by 0.05 plot=quantplot(density_binary_reversed);

	*where abx_tot_clms ge (10) and year_var in (2023);

	output out = predictionmodel_18 p = predquant;
	label density_binary_reversed = "Density:" type_new = "Specialty" year_char = "Year";

		format density_binary_reversed density_binary_reversed. type_new $type_new.;

run;


ods graphics on / imagename="quant_reg_categorical" imagefmt=png;
ods listing gpath="C:\Users\mhoskins1\Desktop\Work Files\Medicaid Data Request\Medicare pt D analysis\images";

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




			/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
		   /*------------------------------------------------------------------------Full long-version outputs-------------------------------------------------------------------------*/
		  /*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/


/*Final output for all these fun visuals in one place, I chose RTF but feel free to edit*/
/*clear all your other terrible results*/
dm 'odsresults; clear';

ods graphics /noborder;
title; footnote;

/*Set your output pathway here*/ 

ods rtf file="&outpath.Medicare_ptD_tables_&sysdate..rtf" 
/*Named a generic overwriteable name so we can continue to reproduce and autopopulate a template;
style=journal */startpage=never;

options number nodate;


ods rtf text= "Antibiotic Prescribing Claims by Volume, North Carolina 2018-2023";
proc print data=final_table_part_IV noobs label 
/*General styling to fit a portrait orientation*/
style(table)=[cellpadding=4 cellspacing=0 borderwidth=0 frame=void rules=none width=100%];

var hi_volume pct_hi_vol Hnum_abx pct_hi_presc Hmed_claims lo_volume pct_lo_vol Lnum_abx pct_lo_presc Lmed_claims all_volume all_num_abx all_med_claims   
    / 
/*Specific "table 1" styling*/
    /* Header: top and bottom borders only */
    style(header)=[
        font_weight=bold 
        backgroundcolor=white 
        just=center 
        borderbottomcolor=black borderbottomwidth=1 
        bordertopcolor=black bordertopwidth=1 
        borderleftwidth=0 borderrightwidth=0]

    /* Data: center everything, don't bold anything but headers*/
    style(data)=[
        just=center 
        fontsize=9pt 
        bordercolor=white borderwidth=0];


run;
title;

ods rtf text= "Antibiotic Prescribing Claims by Volume, North Carolina 2018-2023";
proc print data=final_table_part_II noobs label 
/*General styling to fit a portrait orientation*/
style(table)=[cellpadding=4 cellspacing=0 borderwidth=0 frame=void rules=none width=100%];

var type_new hi_volume pct_hi_vol Hnum_abx pct_hi_presc Hmed_claims lo_volume pct_lo_vol Lnum_abx pct_lo_presc Lmed_claims all_volume all_num_abx all_med_claims 
    / 
/*Specific "table 1" styling*/
    /* Header: top and bottom borders only */
    style(header)=[
        font_weight=bold 
        backgroundcolor=white 
        just=center 
        borderbottomcolor=black borderbottomwidth=1 
        bordertopcolor=black bordertopwidth=1 
        borderleftwidth=0 borderrightwidth=0]

    /* Data: center everything, don't bold anything but headers*/
    style(data)=[
        just=center 
        fontsize=9pt 
        bordercolor=white borderwidth=0];


run;
title;




ods rtf text=  "Analysis 1: Odds Ratio, high prescriber likelihood by density accounting for specialty";
proc format;
    value density_cat
        0 = 'Metropolitan'
        1 = 'Micropolitan'
        2 = 'Small Town'
        3 = 'Rural';


run;


proc logistic data=analysis_medD plots(only)=(oddsratio(range=0.5, 2.58)); /*plotting OR each density compared to others*/
	class p90_flag_spec (param=ref ref='0') density_cat (param=ref ref='Metropolitan') type_new (param=ref ref='Family Practice');
	/*multivariate model using both density and specialty type*/
	model p90_flag_spec = density_cat type_new/ noor parmlabel;/*no ODDS ratio (noor) to simplyfy output we don't need this OR, we want the comprehensive one next*/
/*Display all comparisons of ORs*/
	oddsratio density_cat;
where abx_tot_clms ge (10);
		format density_cat density_cat.;

run;


ods rtf text=  "Analysis 2: Wilcoxon rank sum, mean/median distribution by density and specialty";

proc npar1way data=analysis_medD wilcoxon plots(only)=(median scores=databoxplot);
title "Nonparametric test to compare median abx claims rate by provider and population density of provider location";
	class density_cat;
	var rate; /*Use the rate to account for some providers having many more patients ie. family practice more than dental surgery see Gouin et a. (2019)*/
	
			where p90_flag_spec not in (1) and abx_tot_clms ge (10);

			format density_cat density_cat.;

run;

title;footnote;
ods graphics noborder;

proc format;
    value densityfmt
        0 = "Metropolitan"
        1 = "Micropolitan"
        2 = "Small Town"
		3 = "Rural";


run;
/*Plot by density and abx count only (right skew: median < mean)*/
proc sgplot data=model_quant noborder;
title height=10pt "Antibiotic prescribing rate and IQR by specialty type, North Carolina 2018-2023";
    vbox rate / category=type_new nooutliers
        fillattrs=(color=lightgray) 
        meanattrs=(symbol=circlefilled color=black size=8)
		medianattrs=(color=black pattern=dash thickness=2)
        whiskerattrs=(thickness=1 color=black)
			displaystats=(median mean) ;

    xaxis label="Specialty" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


    yaxis min=0 max=2000 label="Antibiotic Prescription Rate per 1,000 Beneficiaries" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);

    format density_cat densityfmt. density_binary_reversed density_binary_reversed.;

		where abx_tot_clms ge (10);


run;
title;
/*Plot and group by specialty type*/
proc sgplot data=analysis_medD noborder;
    vbox rate / category=density_cat group=type_new nooutliers
        /*fillattrs=(color=CX80B1D3) */
        meanattrs=(symbol=circlefilled color=red size=8)
		medianattrs=(color=red)
        whiskerattrs=(thickness=1 color=black);

    xaxis label="Population Density Category" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


    yaxis min=0 max=2000 label="Antibiotic Prescription Rate per 1,000 Patients" valueattrs= (family="Arial" size=8)
		labelattrs= (family="Arial" weight=bold size=8);


	format density_cat densityfmt.;
		keylegend / title="Specialty Type" location=outside position=bottom noborder titleattrs= (family="Arial" size=8 weight=bold) valueattrs= (family="Arial" size=8);

		where abx_tot_clms ge (10);
run;



ods rtf text=  "Full Quantile Regression Model: ABX Claims per 1,000 Beneficiaries by specialty, population density, and year (BINARY)";
/*Full model, add and subtract from the class and model statements to look at different independent variables predicting rate.
  Use by statement to view by year*/
proc quantreg data=model_quant;
/*group by year*/
by year_char;
/*Class is our predictor*/
class density_binary_reversed type_new year_char;
    model rate = density_binary_reversed type_new year_char/ quantile= 0.05 to 0.95 by 0.05 plot=quantplot(density_binary_reversed);

	*where abx_tot_clms ge (10) and year_var in (2023);

	output out = predictionmodel_18 p = predquant;
	label density_binary_reversed = "Density:" type_new = "Specialty" year_char = "Year";

		format density_binary_reversed density_binary_reversed. type_new $type_new.;

run;


ods rtf text=  "Full Quantile Regression Model: ABX Claims per 1,000 Beneficiaries by specialty, population density, and year (CATEGORICAL)";
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

ods rtf close;





title;
