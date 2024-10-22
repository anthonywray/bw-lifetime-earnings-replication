************
* SCRIPT: 4.1_run_analysis_robustness.do
* PURPOSE: Run the robustness analysis
************

************
* Code begins
************

*************************************
* Settings for figures

set scheme plotplainblind

/////////////////////////////////////////////////////////////
// Lifetime earnings and utility calculations 
/////////////////////////////////////////////////////////////

set scheme plotplainblind

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
	keep if inrange(age,14,89)

	tempfile calibration
	save `calibration', replace
	

	// Read in raw earnings data with kids 
	use "analysis/processed/data/earnings/census_earnings_with_kids.dta", clear
	keep year age racesing inctot birth_cohort inctot n
	rename inctot inctot_kids
	
	tempfile earnings_with_kids
	save `earnings_with_kids', replace
	

	// Read in raw earnings data using 1960 instead of 1950 to impute earnings
	use "analysis/processed/data/earnings/census_earnings_using_1960.dta", clear
	keep year age racesing inctot birth_cohort inctot n
	rename inctot inctot_1960
	
	tempfile earnings_1960
	save `earnings_1960', replace
	

	// Read in raw earnings data by race
	use "analysis/processed/data/earnings/census_earnings_by_race.dta", clear
	keep year age racesing inctot birth_cohort inctot n
	rename inctot inctot_by_race
	
	tempfile earnings_by_race
	save `earnings_by_race', replace
	
	
	
	// Read in raw earnings data
	use "analysis/processed/data/earnings/census_earnings.dta", clear
	
	// Merge in earnings using 1960 instead of 1950 to impute earnings
	merge 1:1 racesing birth_cohort age year using `earnings_1960', assert(3) nogen keepusing(inctot_1960)
	
	// Merge in earnings by race 
	merge 1:1 racesing birth_cohort age year using `earnings_by_race', assert(3) nogen keepusing(inctot_by_race)

	// Merge in earnings with kids (adding age 14-15)
	merge 1:1 racesing birth_cohort age year using `earnings_with_kids', assert(2 3) keepusing(inctot_kids n)
	
	assert age == 14 | age == 15 if _merge == 2
	drop _merge 
	sort racesing birth_cohort age 
	recode incwage inctot incwage_posttax inctot_by_race inctot_1960 (mis = 0)
	
	// Read in occupational income data with kids 
	merge 1:1 year age racesing birth_cohort using "analysis/processed/data/earnings/census_earnings_cwscore_group_with_kids.dta", assert(3) nogen keepusing(cwscore_group)
	rename cwscore_group cwscore_kids
	
	rename racesing race
	
	// Merge in calibration parameters 
	merge 1:1 birth_cohort race age using `calibration', assert(3) nogen 

	// Loop over earnings variables, construct lifetime earnings estimates
	foreach var of varlist incwage inctot incwage_posttax inctot_kids inctot_1960 inctot_by_race cwscore_kids {

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
		inctot_discounted inctot_no_mortality inctot_utility inctot_c_np ///
		inctot_kids_discounted inctot_kids_no_mortality inctot_kids_utility inctot_kids_c_np ///
		inctot_1960_discounted inctot_1960_no_mortality inctot_1960_utility inctot_1960_c_np ///
		inctot_by_race_discounted inctot_by_race_no_mortality inctot_by_race_utility inctot_by_race_c_np ///
		cwscore_kids_discounted cwscore_kids_no_mortality cwscore_kids_utility cwscore_kids_c_np
		
	order birth_cohort race incwage_discounted incwage_no_mortality incwage_lifeexp_bonus incwage_utility incwage_c_np ///
		incwage_posttax_discounted incwage_posttax_no_mortality incwage_posttax_utility incwage_posttax_c_np ///
		inctot_discounted inctot_no_mortality inctot_utility inctot_c_np ///
		inctot_kids_discounted inctot_kids_no_mortality inctot_kids_utility inctot_kids_c_np ///
		inctot_1960_discounted inctot_1960_no_mortality inctot_1960_utility inctot_1960_c_np ///
		inctot_by_race_discounted inctot_by_race_no_mortality inctot_by_race_utility inctot_by_race_c_np ///
		cwscore_kids_discounted cwscore_kids_no_mortality cwscore_kids_utility cwscore_kids_c_np
		
	foreach var of varlist incwage_discounted incwage_no_mortality incwage_lifeexp_bonus incwage_c_np ///
		incwage_posttax_discounted incwage_posttax_no_mortality incwage_posttax_c_np ///
		inctot_discounted inctot_no_mortality inctot_c_np ///
		inctot_kids_discounted inctot_kids_no_mortality inctot_kids_c_np ///
		inctot_1960_discounted inctot_1960_no_mortality inctot_1960_c_np ///
		inctot_by_race_discounted inctot_by_race_no_mortality inctot_by_race_c_np ///
		cwscore_kids_discounted cwscore_kids_no_mortality cwscore_kids_c_np {
		
		replace `var'=`var'/1000
	}

	reshape wide cwscore* inc*, i(birth_cohort) j(race)


	*Now construct the ratio of earnings for each measure. Note that for the bonus
	*	measure, use the VSL from incwage, since that is correctly pegged to the 1970
	*	total white incwage.

	foreach var in "incwage" "inctot" "incwage_posttax" "inctot_by_race" "inctot_1960" "inctot_kids" "cwscore_kids" {
		gen ratio_`var'_discounted=`var'_discounted1/`var'_discounted2
		gen ratio_`var'_no_mort=`var'_no_mortality1/`var'_no_mortality2
		gen ratio_`var'_bonus=(`var'_discounted1+incwage_lifeexp_bonus1)/`var'_discounted2
		gen ratio_`var'_c_np=`var'_c_np1/`var'_c_np2
	}

	label var birth_cohort "\shortstack{Birth Cohort}"

	// Graph all seven actual (and bonus) lifetime earnings ratios by birth cohort
	* Robustness to adding kids 
	
	if `beta' == 1 {
		
		twoway (scatter ratio_inctot_discounted birth_cohort, msymbol(Sh) mcolor(turquoise)) ///
			   (scatter ratio_inctot_by_race_discounted birth_cohort, msymbol(Th) mcolor(red)) ///
			   (scatter ratio_inctot_1960_discounted birth_cohort, msymbol(Oh) mcolor(orange)) ///
			   (scatter ratio_inctot_kids_discounted birth_cohort, msymbol(X) mcolor(purple)) ///
			   (scatter ratio_cwscore_kids_discounted birth_cohort, msymbol(Dh) mcolor(green)), ///
					legend(order(1 "Total (Baseline)" 2 "Total (Imputation by Race)" 3 "Total (1960 for Imputation)" 4 "Total (Adding Ages 14-16)" 5 "Total (Occupational income)") size(5) bmargin(80 0 40 0) position(0)) ///
					title("White/Black Lifetime Earnings", size(5) pos(11)) ///
					xtitle("Birth Year", size(5) height(7)) ytitle("") ///
					xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
					ylab(1(1)4, nogrid labsize(5) angle(0) format(%9.0fc)) ///
					xsize(8) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
					
		graph export "analysis/output/figures/figure_9a_wages_lifetime_gaps_robustness_discount_100.pdf", replace
			
	}
	
	
	if `beta' == 0.96 {
	
		***** Utility gaps *****

		*Finally, graph the gap in white and black utility according to my model, by birth cohort

		gen incwage_u_gap=incwage_utility1-incwage_utility2
		gen incwage_posttax_u_gap=incwage_posttax_utility1-incwage_posttax_utility2
		gen inctot_u_gap=inctot_utility1-inctot_utility2
		
		* Robustness 
		gen inctot_by_race_u_gap = inctot_by_race_utility1 - inctot_by_race_utility2
		gen inctot_1960_u_gap = inctot_1960_utility1 - inctot_1960_utility2
		
		* Robustness to adding kids
		
		gen inctot_kids_u_gap = inctot_kids_utility1-inctot_kids_utility2
		gen cwscore_kids_u_gap = cwscore_kids_utility1 - cwscore_kids_utility2

		twoway (scatter inctot_u_gap birth_cohort, msymbol(Sh) mcolor(sky)) ///
		   (scatter inctot_by_race_u_gap birth_cohort, msymbol(Th) mcolor(red)) ///
		   (scatter inctot_1960_u_gap birth_cohort, msymbol(Oh) mcolor(orange)) ///
		   (scatter inctot_kids_u_gap birth_cohort, msymbol(X) mcolor(purple)) ///
		   (scatter cwscore_kids_u_gap birth_cohort, msymbol(Dh) mcolor(green)), ///
				legend(order(1 "Total (Baseline)" 2 "Total (Imputation by Race)" 3 "Total (1960 for Imputation)" 4 "Total (Adding Ages 14-16)" 5 "Total (Occupational income)") size(5) bmargin(80 0 40 0) position(0)) ///
				title("Utility (white-black)", size(5) pos(11)) ///
				xtitle("Birth Year", size(5) height(7)) ytitle("") ///
				xlab(1900(10)1970, nogrid labsize(5) angle(0)) ///
				ylab(, nogrid labsize(5) angle(0) format(%9.0fc)) ///
				xsize(8) ///
				graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
				
		graph export "analysis/output/figures/figure_9b_utility_gaps_robustness_discount_096.pdf", replace
		
	}
			
}
