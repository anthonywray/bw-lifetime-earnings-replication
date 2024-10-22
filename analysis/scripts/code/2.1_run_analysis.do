************
* SCRIPT: 2.1_run_analysis.do
* PURPOSE: Run the main analysis
************

************
* Code begins
************

*************************************
* Settings for figures

set scheme plotplainblind

***********************************************************
// Figure 1: Plot of Male P(Survival through Age 30) *****
***********************************************************

use "analysis/processed/intermediate/cdc/survivorship_rates.dta", clear

gen year = birth_cohort + age
gen survival_rate = survivors/100000

twoway (scatter survival_rate birth_cohort if race==1 & age==30 & inrange(birth_cohort,1900,1970), msymbol(O) mcolor(turquoise) msize(medium)) ///
	   (scatter survival_rate birth_cohort if race==2 & age==30 & inrange(birth_cohort,1900,1970), msymbol(Dh) mcolor(orangebrown) msize(medium)), ///
			legend(order(1 "White" 2 "Black") size(5) bmargin(0 120 40 0) position(0)) ///
			title("Male P(Survival through Age 30)", size(5) pos(11)) /// 
			xtitle("Birth Year", size(5) height(7)) ///
			ytitle("") ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%9.2f)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
		
graph export "analysis/output/figures/figure_1_survivorship_age30_by_race.pdf", replace			


**************************************************
// Figure 2: Plots of infant mortality rates *****
**************************************************

use "analysis/processed/intermediate/cdc/survivorship_rates.dta" if age == 1 & mod(birth_cohort,10) == 0, clear
merge 1:1 race birth_cohort using "analysis/processed/data/cdc/birth_counts.dta", keep(3) nogen keepusing(n_births_cdc)

gen p_imr = 1 - survivors/100000
gen infant_deaths = p_imr*n_births_cdc
gen imr = infant_deaths*1000/n_births_cdc

twoway (connected imr birth_cohort if race == 2, lwidth(0.5) lcolor(turquoise) msymbol(Dh) mcolor(turquoise) msize(medium)) ///
	   (connected imr birth_cohort if race == 1, lp(longdash) lwidth(0.5) lcolor(sky) msymbol(O) mcolor(sky) msize(medium)) , ///
			legend(order(1 "Black" 2 "White") size(5) bmargin(0 0 40 0) position(0)) ///
			title("Infant mortality rate per 1,000 live births", size(5) pos(11)) ///
			xtitle("Birth Year", size(5) height(7)) ///
			ytitle("") ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 

graph export "analysis/output/figures/figure_2_infant_mortality_by_race.pdf", replace


***********************************************************
// Figure 3: Plot of Life Expectancy *****
***********************************************************

// Construct dataset of life expectancy by birth year and race
	* This data is from https://data.cdc.gov/NCHS/NCHS-Death-rates-and-life-expectancy-at-birth/w9j2-ggv5

import delim using "analysis/raw/nchs/nchs_death_rates_and_life_expectancy_at_birth.csv", clear

rename averagelifeexpectancyyears life_expectancy
rename year birth_cohort
rename race race_string

keep if sex == "Male" & inlist(race_string,"Black","White")
gen race = race_string == "White"
replace race = 2 if race_string == "Black"

keep birth_cohort race life_expectancy
sort race birth_cohort

keep if inrange(birth_cohort,1900,1970)

// Graph life expectancy by birth cohort and race
twoway (connected life_expectancy birth_cohort if race == 1, lp(longdash) lwidth(0.5) lcolor(turquoise) msymbol(O) mcolor(turquoise) msize(medium)) ///
	   (connected life_expectancy birth_cohort if race == 2, lwidth(0.5) lcolor(orangebrown) msymbol(Dh) mcolor(orangebrown) msize(medium)), ///
			legend(order(1 "White" 2 "Black") size(5) bmargin(0 120 40 0) position(0)) ///
			title("Average Male Life Expectancy (in Years)", size(5) pos(11)) /// 
			xtitle("Birth Year", size(5) height(7)) ///
			ytitle("") ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
			
graph export "analysis/output/figures/figure_3_life_expectancy_by_race.pdf", replace


********************************************************************************************
// Figure 4b: White-to-Black Ratio of Average Earnings, By Birth Year for 3 Cohorts ********
********************************************************************************************

// Read in raw earnings data
use "analysis/processed/data/earnings/census_earnings.dta", clear
rename racesing race

// Construct white-black earnings ratio by birth cohort and age

bys birth_cohort age: egen temp1 = max(incwage*(race == 1)) 
bys birth_cohort age: egen temp2 = max(incwage*(race == 2)) 

gen white_black_ratio = temp1/temp2

keep if inrange(age,25,65)

twoway (scatter white_black_ratio age if race==1 & birth_cohort==1900, msymbol(plus) yscale(range(1 3))) ///
		(scatter white_black_ratio age if race==1 & birth_cohort==1925, msymbol(Oh)) ///
		(scatter white_black_ratio age if race==1 & birth_cohort==1950, msymbol(Sh)) ///
		(scatter white_black_ratio age if race==1 & birth_cohort==1975, msymbol(Dh)), ///
			legend(order(1 "1900" 2 "1925" 3 "1950" 4 "1975") size(5) bmargin(0 120 40 0) position(0)) ///
			title("White/Black Average Earnings", size(5) pos(11)) ///
			xtitle("Age", size(5) height(7)) ytitle("") ///
			xlab(25(5)65, nogrid labsize(5) angle(0)) ///
			ylab(1(0.5)3, nogrid labsize(5) angle(0) format(%3.1f)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
		
graph export "analysis/output/figures/figure_4b_bw_ratio_incwage_by_cohort.pdf", replace

********************************************************************************************
// Figure 4a: White-to-Black Ratio of Average Earnings, By Birth Year for 3 Age Groups *****
********************************************************************************************

keep if inrange(birth_cohort,1900,1970)

gen agebin=.
replace agebin=1 if inrange(age,30,39)
replace agebin=2 if inrange(age,40,49)
replace agebin=3 if inrange(age,50,59)

keep if !missing(agebin) & race==1

collapse (mean) white_black_ratio, by(birth_cohort agebin)

twoway (scatter white_black_ratio birth_cohort if agebin==1, msymbol(plus) ///
			yscale(range(1 3))) ///
		(scatter white_black_ratio birth_cohort if agebin==2, msymbol(Oh)) ///
		(scatter white_black_ratio birth_cohort if agebin==3, msymbol(Sh)), ///
			legend(order(1 "Age 30-39" 2 "Age 40-49" 3 "Age 50-59") size(5) bmargin(0 120 40 0) position(0)) ///
			title("White/Black Average Earnings", size(5) pos(11)) ///
			xtitle("Birth Year", size(5) height(7)) ytitle("") ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(1(0.5)3, nogrid labsize(5) angle(0) format(%3.1fc)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
			
graph export "analysis/output/figures/figure_4a_bw_ratio_incwage_by_age.pdf", replace


************************************************
// Figure 6: Plots of birth counts by race *****
************************************************

use "analysis/processed/data/cdc/birth_counts.dta", clear

replace n_births_cdc = n_births_cdc/1000
replace n_births_med = n_births_med/1000

twoway (scatter n_births_cdc birth_cohort if race == 2 & birth_cohort>1910, msymbol(O) mcolor(ananas) msize(medium)) ///
	   (scatter n_births_med birth_cohort if race == 2, msymbol(Dh) mcolor(orangebrown) msize(medium)), ///
			legend(order(1 "CDC" 2 "Imputed") size(5) bmargin(0 120 40 0) position(0)) ///
			title("Number of Black Male Births by Year (in millions)", size(5) pos(11)) ///
			xtitle("Birth Year", size(5) height(7)) ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
			
graph export "analysis/output/figures/figure_6a_birthcounts_blacks.pdf", replace


twoway (scatter n_births_cdc birth_cohort if race == 1 & birth_cohort>1910, msymbol(O) mcolor(sky) msize(medium)) ///
	   (scatter n_births_med birth_cohort if race == 1, msymbol(Dh) mcolor(turquoise) msize(medium)), ///
			legend(order(1 "CDC" 2 "Imputed") size(5) bmargin(0 120 40 0) position(0)) ///
			title("Number of White Male Births by Year (in millions)", size(5) pos(11)) ///
			xtitle("Birth Year", size(5) height(7)) ///
			xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
			ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
			xsize(8) ///
			graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 

graph export "analysis/output/figures/figure_6b_birthcounts_whites.pdf", replace


*****************************************************************************************
// Table 1: Average White and Black earnings of living 30 year olds, every 10 years *****
*****************************************************************************************

// Read in raw earnings data
use "analysis/processed/data/earnings/census_earnings.dta" if age == 30 & mod(year,10) == 0 & inrange(year,1930,2020), clear
rename racesing race

keep year race incwage incwage_posttax inctot
order year race incwage incwage_posttax inctot

reshape wide incwage incwage_posttax inctot, i(year) j(race)

gen ratio_incwage=incwage1/incwage2
gen ratio_incwage_posttax=incwage_posttax1/incwage_posttax2
gen ratio_inctot=inctot1/inctot2


label var year "Year"
label def YEAR 2020 "2020", add

tabout year using "analysis/output/tables/table_1_wages_living.tex", ///
	c(mean incwage1 mean incwage_posttax1 mean inctot1 mean incwage2 mean ///
		incwage_posttax2 mean inctot2 mean ratio_incwage mean ///
		ratio_incwage_posttax mean ratio_inctot) ///
	h2(& \multicolumn{3}{c}{White Earnings} & \multicolumn{3}{c}{Black Earnings} & \multicolumn{3}{c}{White/Black Earnings} \\) ///
	clab("Labor" "\shortstack{Post-tax}" "Total" "Labor" "\shortstack{Post-tax}" "Total" "Labor" "\shortstack{Post-tax}" "Total") ///
	topstr(15cm) topf("") botf("") ///
	format(0c 0c 0c 0c 0c 0c 2 2 2) style(tex) ///
	cl2(2-4 5-7 8-10) replace oneway sum bt ptotal(none)
	

	
/////////////////////////////////////////////////////////////
// Lifetime earnings and utility calculations 
/////////////////////////////////////////////////////////////

// Construct dataset of life expectancy by birth year and race
	* This data is from https://data.cdc.gov/NCHS/NCHS-Death-rates-and-life-expectancy-at-birth/w9j2-ggv5

import delim using "analysis/raw/nchs/nchs_death_rates_and_life_expectancy_at_birth.csv", clear

rename averagelifeexpectancyyears life_expectancy
rename year birth_cohort
rename race race_string

keep if sex == "Male" & inlist(race_string,"Black","White")
gen race = race_string == "White"
replace race = 2 if race_string == "Black"

keep birth_cohort race life_expectancy
sort race birth_cohort

keep if inrange(birth_cohort,1900,1970)

tempfile lifeexp
save `lifeexp', replace 

// Set discount rates to loop over, and loop over them:
local betas 0.96 1
foreach beta of local betas {
		
	// Construct survivorship probabilities for model
	use "analysis/processed/intermediate/cdc/survivorship_rates.dta", clear

	gen year = birth_cohort + age

	// For model calibration, this is the denominator of c1
	gen temp_c1_den = 0
	
	// Make each term in the sum for the denominator of c1
	replace temp_c1_den = `beta'^(age-1)*survivors/100000 if inrange(age,1,89) 
	
	// Add together all the terms of the sum by birth cohort and race
	bys birth_cohort race (age): egen c1_den = total(temp_c1_den)

	// For model calibration, k1 is a constant we can add to ln(c1)*k2 (explained later) to get utility for a given age
	gen temp_k1 = 0
	
	// Make each term in the sum
	replace temp_k1 = `beta'^age*(survivors/100000)*(age-1)*log(`beta'*1.02) if inrange(age,1,89)

	// For model calibration, k2 is a constant we can multiply ln(c_1) by
	** Adding k1 to k2*ln(c_1) gives us the utility for a given age.
	gen temp_k2 = 0
	
	// Make each term in the sum
	replace temp_k2 = `beta'^age*(survivors/100000) if inrange(age,1,89)

	*Add together all the terms of the sum by birth cohort and race
	bys birth_cohort race: egen k1 = total(temp_k1)
	bys birth_cohort race: egen k2 = total(temp_k2)

	// For model calibration, k3 is a constant that when multiplied by c1 gives 
		**expected lifetime consumption for an age group, the ratio of which (summed 
		**across age by birth_cohort and race) is reported in tables 4-5 and figure 7
		
	gen k3 = 0
	replace k3 = (survivors/100000)*(`beta'*1.02)^(age-1) if inrange(age,1,89)
	
	drop temp*
	
	// Restrict to age range we need 
	keep if inrange(age,16,89)

	tempfile calibration
	save `calibration', replace

	
	// Read in raw earnings data
	use "analysis/processed/data/earnings/census_earnings.dta", clear
	rename racesing race

	
	// Merge in calibration parameters 
	merge 1:1 birth_cohort race age using `calibration', assert(3) nogen 

	// Loop over earnings variables, construct lifetime earnings estimates
	foreach var of varlist incwage inctot incwage_posttax {

		// First, discount all earnings to birth-year using a discount factor equal to beta.
		gen `var'_discounted = `var'*`beta'^age

		// For years after 2014, assume a 1.5% increase in earnings each year
		replace `var'_discounted = `var'_discounted*1.015^(year - 2014) if year > 2014 
		
		// Now construct lifetime earnings by birth cohort * race.
		gen `var'_no_mortality = `var'_discounted
		replace `var'_discounted = `var'_discounted*survivors/100000
		
		// For model calibration, begin constructing consumption each period by constructing c1

		// `var'_c1_num is the numerator of c1.  Begin by making each term of the sum
		gen temp_`var'_c1_num = `var'*(survivors/100000)/(1.02^(age-1))
		
		// Now sum each term of the numerator of c_1 by birth cohort and race
		bys birth_cohort race: egen `var'_c1_num = total(temp_`var'_c1_num)
		egen `var'_c1_den_temp = max(c1_den), by(birth_cohort race) 
		
		drop c1_den temp_`var'_c1_num
		rename `var'_c1_den_temp c1_den

		// Generate c1 from c1_num and c1_den
		gen `var'_c1 = `var'_c1_num/c1_den
		
		// Generate lifetime utility from k1, c1, and k2
		gen `var'_utility = k1 + log(`var'_c1)*k2
		
		// Generate lifetime consumption from c1 and k3 
		gen `var'_c_np = `var'_c1*k3
		
	}

	keep if inrange(birth_cohort,1900,1970)

	collapse (sum) *_no_mortality *_discounted *_c_np (max) *_c1 *_utility, by(birth_cohort race)

	merge 1:1 race birth_cohort using `lifeexp', assert(3) nogen


	*Now calculate gaps in life expectancy and add the value of that gap in VSLs to
	*	white men's earnings so that we can recalculate gaps

	*Note that the standard EPA VSL measure of 7.4 million in 2006 dollars comes
	*	from here: https://www.epa.gov/environmental-economics/mortality-risk-valuation
	*See here for an analysis of VSL and how it varies by age:
	*	https://www.mitpressjournals.org/doi/pdf/10.1162/rest.90.3.573

	*If, instead of 7.4 million, we use the Ashenfelter and Greenstone estimate of 1.5 million in 1997 dollars,
	*	we can similarly adjust and get 2015 dollars of 1.5*1.48=2.22 million dollars
	*Divide that evenly over 68 years which gives us 2.22/68 = $32,647.06 per year of life
	*Which is 32647.06/548006.2=0.05957425 times the lifetime wage earnings of whites for the 1970 birth cohort
	*And which is 32647.06/687874.7=0.04746077 times the lifetime total earnings of whites for the 1970 birth cohort


	// Calculate life gaps by birth cohort:
	bys birth_cohort: egen temp1 = max(life_expectancy*(race == 1))
	bys birth_cohort: egen temp2 = max(life_expectancy*(race == 2))
	gen life_expectancy_gap = temp1 - temp2
	

	*Now generate new measure of white earning-equivalent dollars, giving whites a
	*	'bonus' for their added life expectancy. Scale the bonus by the relative
	*	lifetime labor earnings of whites in each year compared to the 1970 birth cohort
	* Added (`beta'^temp2) discounting assumes life expectancy bonus for whites is delivered in the future at the life expectancy of blacks
	
	sum incwage_discounted if birth_cohort == 1970 & race == 1
	gen incwage_lifeexp_bonus = (`beta'^temp2)*(32647.06/r(mean))*life_expectancy_gap*incwage_discounted if race == 1

	gen incwage_with_bonus = incwage_discounted
	replace incwage_with_bonus = incwage_discounted + incwage_lifeexp_bonus if race == 1

	drop temp1 temp2

	********************************************************************************
	*Construct table of lifetime earnings, according to several measures, and ratio
	*	of white/black lifetime measures, for birth cohorts 1900-1970 (by 5-years).
	********************************************************************************

	keep birth_cohort race incwage_discounted incwage_no_mortality incwage_lifeexp_bonus incwage_utility incwage_c_np ///
		incwage_posttax_discounted incwage_posttax_no_mortality incwage_posttax_utility incwage_posttax_c_np ///
		inctot_discounted inctot_no_mortality inctot_utility inctot_c_np 
		
	order birth_cohort race incwage_discounted incwage_no_mortality incwage_lifeexp_bonus incwage_utility incwage_c_np ///
		incwage_posttax_discounted incwage_posttax_no_mortality incwage_posttax_utility incwage_posttax_c_np ///
		inctot_discounted inctot_no_mortality inctot_utility inctot_c_np 
		
	foreach var of varlist incwage_discounted incwage_no_mortality incwage_lifeexp_bonus incwage_c_np ///
		incwage_posttax_discounted incwage_posttax_no_mortality incwage_posttax_c_np ///
		inctot_discounted inctot_no_mortality inctot_c_np {
		
		replace `var'=`var'/1000
	}

	reshape wide inc*, i(birth_cohort) j(race)


	*Now construct the ratio of earnings for each measure. Note that for the bonus
	*	measure, use the VSL from incwage, since that is correctly pegged to the 1970
	*	total white incwage.

	foreach var in "incwage" "inctot" "incwage_posttax" {
		gen ratio_`var'_discounted=`var'_discounted1/`var'_discounted2
		gen ratio_`var'_no_mort=`var'_no_mortality1/`var'_no_mortality2
		gen ratio_`var'_bonus=(`var'_discounted1+incwage_lifeexp_bonus1)/`var'_discounted2
		gen ratio_`var'_c_np=`var'_c_np1/`var'_c_np2
	}

	label var birth_cohort "\shortstack{Birth Cohort}"

	preserve
	keep if mod(birth_cohort,5)==0

	if `beta' == 1 {
		local t = "2"
		local b = "discount_100"
	}
	else if `beta' == 0.96 {
		local t = "3"
		local b = "discount_096"
	}

	tabout birth_cohort using "analysis/output/tables/table_`t'_wages_lifetime_`b'.tex", ///
		c(mean incwage_discounted1 mean incwage_no_mortality1 ///
		  mean incwage_posttax_discounted1 mean incwage_posttax_no_mortality1 ///
		  mean inctot_discounted1 mean inctot_no_mortality1 ///
		  mean incwage_lifeexp_bonus1 ///
		  mean incwage_discounted2 mean incwage_no_mortality2 ///
		  mean incwage_posttax_discounted2 mean incwage_posttax_no_mortality2 ///
		  mean inctot_discounted2 mean inctot_no_mortality2) ///
		h2(& \multicolumn{7}{c}{Whites} & \multicolumn{6}{c}{Blacks} \\ \cmidrule(l{.75em}){2-8} \cmidrule(l{.75em}){9-14} & \multicolumn{2}{c}{Labor} & \multicolumn{2}{c}{Post-Tax} & \multicolumn{2}{c}{Total} & & \multicolumn{2}{c}{Labor} & \multicolumn{2}{c}{Post-Tax} & \multicolumn{2}{c}{Total} \\) ///
		clab("\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{+VSL_Gap}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{Earnings}" "\shortstack{No_Death}") ///
		topstr(17cm) topf("") botf("") ///
		format(0) style(tex) replace oneway sum bt ptotal(none) ///
		cl2(2-3 4-5 6-7 9-10 11-12 13-14) 
		
	restore
	
		
		
	*Now make a table of these gaps in lifetime earnings over time

	preserve
	keep if mod(birth_cohort,5)==0

	if `beta' == 1 {
		local t = "4"
		local b = "discount_100"
	}
	else if `beta' == 0.96 {
		local t = "5"
		local b = "discount_096"
	}	

	tabout birth_cohort using "analysis/output/tables/table_`t'_wages_lifetime_gaps_`b'.tex", ///
		c(mean ratio_incwage_discounted mean ratio_incwage_no_mort mean ratio_incwage_bonus mean ratio_incwage_c_np ///
		  mean ratio_incwage_posttax_discounted mean ratio_incwage_posttax_no_mort mean ratio_incwage_posttax_bonus mean ratio_incwage_posttax_c_np ///
		  mean ratio_inctot_discounted mean ratio_inctot_no_mort mean ratio_inctot_bonus mean ratio_inctot_c_np) ///
		h2(& \multicolumn{4}{c}{Labor} & \multicolumn{4}{c}{Post-Tax} & \multicolumn{4}{c}{Total} \\) ///
		clab("\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{+VSL_Gap}" "\shortstack{Cnsm.}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{+VSL_Gap}" "\shortstack{Cnsm.}" "\shortstack{Earnings}" "\shortstack{No_Death}" "\shortstack{+VSL_Gap}" "\shortstack{Cnsm.}") ///
		topstr(18cm) topf("") botf("") ///
		format(2) style(tex) replace oneway sum bt ptotal(none) ///
		cl2(2-5 6-9 10-13)

	restore

	
	// Graph all seven actual (and bonus) lifetime earnings ratios by birth cohort

	if `beta' == 1 {
		local t = "5a"
		local b = "discount_100"
	}
	else if `beta' == 0.96 {
		local t = "5b"
		local b = "discount_096"
	}	
	
	twoway (scatter ratio_incwage_bonus birth_cohort, msymbol(Dh) mcolor(sky)) ///
		   (scatter ratio_incwage_posttax_bonus birth_cohort, msymbol(Oh) mcolor(orangebrown)) ///
		   (scatter ratio_inctot_bonus birth_cohort, msymbol(+) mcolor(green)) ///
		   (scatter ratio_incwage_discounted birth_cohort, msymbol(Th) mcolor(sea)) ///
		   (scatter ratio_incwage_posttax_discounted birth_cohort, msymbol(D) mcolor(vermillion)) ///
		   (scatter ratio_inctot_discounted birth_cohort, msymbol(Sh) mcolor(turquoise)) ///
		   (scatter ratio_inctot_c_np birth_cohort, msymbol(X) mcolor(purple)), ///
				legend(order(1 "Labor (+VSL)" 2 "Post-Tax (+VSL)" 3 "Total (+VSL)" 4 "Labor" 5 "Post-Tax" 6 "Total" 7 "Consumption") size(5) bmargin(80 0 40 0) position(0)) ///
				title("White/Black Lifetime Earnings", size(5) pos(11)) ///
				xtitle("Birth Year", size(5) height(7)) ytitle("") ///
				xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
				ylab(1(1)4, nogrid labsize(5) angle(0) format(%9.0fc)) ///
				xsize(8) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
	graph export "analysis/output/figures/figure_`t'_wages_lifetime_gaps_`b'.pdf", replace
	
	
	// Now graph the level of white and black utility according to my model, by birth cohort

	if `beta' == 1 {
		local t = "7a"
		local b = "discount_100"
	}
	else if `beta' == 0.96 {
		local t = "8a"
		local b = "discount_096"
	}	
	
	twoway (scatter incwage_utility1 birth_cohort, msymbol(Sh) mcolor(sky)) ///
		   (scatter incwage_posttax_utility1 birth_cohort, msymbol(O) mcolor(orangebrown)) ///
		   (scatter inctot_utility1 birth_cohort, msymbol(T) mcolor(green)) ///
		   (scatter incwage_utility2 birth_cohort, msymbol(S) mcolor(sea)) ///
		   (scatter incwage_posttax_utility2 birth_cohort, msymbol(Oh) mcolor(vermillion)) ///
		   (scatter inctot_utility2 birth_cohort, msymbol(Th) mcolor(turquoise)), ///
				legend(order(1 "Labor (white)" 2 "Post-Tax (white)" 3 "Total (white)" 4 "Labor (black)" 5 "Post-Tax (black)" 6 "Total (black)") size(5) bmargin(120 0 40 70) position(0)) ///
				title("Utility (net present value of log dollars)", size(5) pos(11)) ///
				xtitle("Birth Year", size(5) height(20)) ytitle("") ///
				xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
				ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
				xsize(8) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
	graph export "analysis/output/figures/figure_`t'_utility_by_race_`b'.pdf", replace


	*Finally, graph the gap in white and black utility according to my model, by birth cohort

	gen incwage_u_gap=incwage_utility1-incwage_utility2
	gen incwage_posttax_u_gap=incwage_posttax_utility1-incwage_posttax_utility2
	gen inctot_u_gap=inctot_utility1-inctot_utility2

	if `beta' == 1 {
		local t = "7b"
		local b = "discount_100"
	}
	else if `beta' == 0.96 {
		local t = "8b"
		local b = "discount_096"
	}
	
	twoway (scatter incwage_u_gap birth_cohort, msymbol(D) mcolor(sky)) ///
		   (scatter incwage_posttax_u_gap birth_cohort, msymbol(Oh) mcolor(orangebrown)) ///
		   (scatter inctot_u_gap birth_cohort, msymbol(Sh) mcolor(green)), ///
				legend(order(1 "Labor" 2 "Post-Tax" 3 "Total") size(5) bmargin(120 0 40 0) position(0)) ///
				title("Utility (white-black)", size(5) pos(11)) ///
				xtitle("Birth Year", size(5) height(7)) ytitle("") ///
				xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
				ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
				xsize(8) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
	graph export "analysis/output/figures/figure_`t'_utility_gaps_`b'.pdf", replace
	
}


* EOF
