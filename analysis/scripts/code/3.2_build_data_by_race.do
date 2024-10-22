************
* SCRIPT: 3.2_build_data_by_race.do
* PURPOSE: Process the data in preparation for robustness analysis by race
************

* User switches for each section of code

local ipums 		1  	// DEPENDENCIES: none
local earnings		1	// DEPENDENCIES: ipums, construct_tax_rates.R


************
* Code begins
************

*******************************
// Prepare census data *****
*******************************
	
if `ipums' {

	local main_sample_restrictions "inrange(age,16,89) & inrange(bpl,1,56)"
	
	*********************************
	***** Pre-process 1900 data *****
	*********************************
	
	// Choose the most recently created extract (file with the largest number)
	local filelist : dir "analysis/raw/ipums/ipums_1900_100_pct" files "*.dta"
	local numitems : word count `filelist'
		di "`numitems'"
	local file_to_open : word `numitems' of `filelist'
		di "`file_to_open'"
		
	use "analysis/raw/ipums/ipums_1900_100_pct/`file_to_open'" if `main_sample_restrictions', clear
	
	// Restrict to men 
	keep if sex == 1
	
	// Restrict to Blacks and whites
	gen racesing = race
	keep if inrange(racesing,1,2)
	
	save "analysis/processed/temp/ipums_1900.dta", replace
	
	*****************************************
	***** Pre-process 1910 to 1930 data *****
	*****************************************
	
	forval y = 1910(10)1930 {
	
		// Choose the most recently created extract (file with the largest number)
		local filelist : dir "analysis/raw/ipums/ipums_`y'_100_pct" files "*.dta"
		local numitems : word count `filelist'
			di "`numitems'"
		local file_to_open : word `numitems' of `filelist'
			di "`file_to_open'"		
		
		use "analysis/raw/ipums/ipums_`y'_100_pct/`file_to_open'" if `main_sample_restrictions', clear
		
		keep if inrange(racesing,1,2)
			
		tempfile ipums_`y'
		save `ipums_`y'', replace
	}
	
	clear
	forval y = 1910(10)1930 {
		append using `ipums_`y''
	}
	
	// Check that only males in data
	assert sex == 1 
	
	save "analysis/processed/temp/ipums_1910_1930.dta", replace
	
	**************************************
	***** Pre-process 1940 data **********
	**************************************
	
	// Choose the most recently created extract (file with the largest number)
	local filelist : dir "analysis/raw/ipums/ipums_1940_100_pct" files "*.dta"
	local numitems : word count `filelist'
		di "`numitems'"
	local file_to_open : word `numitems' of `filelist'
		di "`file_to_open'"
		
	use "analysis/raw/ipums/ipums_1940_100_pct/`file_to_open'" if `main_sample_restrictions', clear
	
	// Check that only males in data
	assert sex == 1 
	
	gen racesing = race
	keep if inrange(racesing,1,2)
	
	// In 1940, the sample universe for labor income was "Persons age 14+, not institutional inmates"
	* Source: https://usa.ipums.org/usa-action/variables/incwage#universe_section
	* So, in 1940, we replace 1940 wages of institutionalized inmates with zeroes
	replace incwage = 0 if gq == 3 & year == 1940 

	save "analysis/processed/temp/ipums_1940.dta", replace
	
}

*******************************
// Construct earnings data ****
*******************************

if `earnings' {

	local main_sample_restrictions "inrange(age,16,89) & inrange(bpl,1,56)"
	
	**************************************
	***** Pre-process post-1940 data *****
	**************************************
	
	use "analysis/raw/ipums/usa_00064.dta" if `main_sample_restrictions', clear
	
	keep if inrange(racesing,1,2)
	
	// Restrict to post-1940 data
	keep if year > 1940
	
	// Drop 2001-2005 ACS since those years do not contain institutionalized respondents
	tab year gq, m
	drop if inrange(year,2001,2005)

	// In 1970, weights are twice as large as they should be because IPUMS aggregates
	*	two representative samples.

	replace slwt = slwt/2 if year == 1970
	
	// Check for missing values in income here
	tab year if incwage == 999999, m
	tab slwt if incwage == 999999, m
	tab slwt if year == 1950, m
	
	sum incwage if year == 1950 & slwt == 0, d
	sum incwage if year == 1950 & slwt == 330, d

	// For 1950 and beyond, we only need sample-line respondents with non-missing wage income
	drop if slwt == 0
	drop if incwage == 999999
	
	sum incwage, d
	sum inctot, d

	// Add 1940 data
	append using "analysis/processed/temp/ipums_1940.dta"
	
	// Drop variables we will not use
	drop perwt sex hhwt serial race raced bpld racesingd ///
		empstat empstatd labforce occscore sei erscor50 incbusfm incbus incbus00 ///
		incfarm incnonwg incother incearn occ	
	
	// Now inflate incwage to 2015 dollars. Inflation factors from here: https://usa.ipums.org/usa/cpi99.shtml
	foreach x of varlist incwage inctot { 

		// First inflate to 1999 dollars
		replace `x'=`x'*9.976 if year==1930
		replace `x'=`x'*11.986 if year==1940
		replace `x'=`x'*7.000 if year==1950
		replace `x'=`x'*5.725 if year==1960
		replace `x'=`x'*4.540 if year==1970
		replace `x'=`x'*2.295 if year==1980
		replace `x'=`x'*1.344 if year==1990
		replace `x'=`x'*1.000 if year==2000
		replace `x'=`x'*0.941 if year==2001
		replace `x'=`x'*0.926 if year==2002
		replace `x'=`x'*0.905 if year==2003
		replace `x'=`x'*0.882 if year==2004
		replace `x'=`x'*0.853 if year==2005
		replace `x'=`x'*0.826 if year==2006
		replace `x'=`x'*0.804 if year==2007
		replace `x'=`x'*0.774 if year==2008
		replace `x'=`x'*0.777 if year==2009
		replace `x'=`x'*0.764 if year==2010
		replace `x'=`x'*0.741 if year==2011
		replace `x'=`x'*0.726 if year==2012
		replace `x'=`x'*0.715 if year==2013
		replace `x'=`x'*0.704 if year==2014

		// Now inflate to 2015 dollars
		replace `x'=`x'/0.703

	}
	
	// Separate out post-1950 data since we don't need it to impute 1940 non-wage income
	
	preserve
	
		keep if year != 1940 & year != 1950
		save "analysis/processed/temp/ipums_post_1950.dta", replace
	
	restore
	
	keep if year == 1940 | year == 1950
	
	
	// In 1900-1930, there is no earnings information. In 1940, there is no non-wage
	* earnings information. We will impute these values.
	
	
	// First, impute non-wage income from 1950 to 1940, 
	gen inc_nonwg = inctot - incwage
	sum inc_nonwg, d

	* Construct a predictor for whether there was non-negligible non-wage income and
	*	include this predictor in the regressions. Also use the wage income as a
	*	predictor.

	gen nowages = inrange(inc_nonwg,-5,5)
	tab age nowages if year == 1950, m
	
	reg nowages i.racesing i.age##i.racesing i.occ1950##i.racesing i.ind1950##i.racesing i.bpl##i.racesing i.statefip##i.racesing if year == 1950
	predict nowages_predicted if inlist(year,1940,1950)
	gquantiles nowages_predicted_bins = nowages_predicted if inlist(year,1940,1950), xtile n(20) by(racesing)

	gquantiles incwage_bins = incwage if inlist(year,1940,1950), xtile n(20) by(racesing)

	// Now predict non-wage income for 1940
	reg inc_nonwg i.nowages_predicted_bins##i.racesing i.incwage_bins##i.racesing i.racesing i.age##i.racesing ///
		i.occ1950##i.racesing i.ind1950##i.racesing i.bpl##i.racesing i.statefip##i.racesing if year == 1950
	predict inc_nonwg_predicted if inlist(year,1940,1950)

	// And construct new inctot values for 1940 using this imputed wage information
	replace inctot = incwage + inc_nonwg_predicted if year == 1940

	drop nowages* inc_nonwg_predicted
	
	// Now impute wage income and total income for pre-1930 based on 1940 wage and total income.
	append using "analysis/processed/temp/ipums_1910_1930.dta" // Adding this data year since we don't need it earlier
	
	gen unemployed = inrange(incwage,-5,5)
	tab age unemployed if year == 1940

	reg unemployed i.racesing i.age##i.racesing i.occ1950##i.racesing i.ind1950##i.racesing i.bpl##i.racesing i.statefip##i.racesing if year == 1940
	predict unemployed_predicted if inrange(year,1910,1940)
	gquantiles unemployed_predicted_bins = unemployed_predicted, xtile n(20) by(racesing)

	reg incwage i.unemployed_predicted_bins##i.racesing i.racesing i.age##i.racesing i.occ1950##i.racesing i.ind1950##i.racesing i.bpl##i.racesing i.statefip##i.racesing if year == 1940
	predict incwage_predicted if inrange(year,1910,1930)

	reg inctot i.unemployed_predicted_bins##i.racesing i.racesing i.age##i.racesing i.occ1950##i.racesing i.ind1950##i.racesing i.bpl##i.racesing i.statefip##i.racesing if year == 1940
	predict inctot_predicted if inrange(year,1910,1930)

	replace incwage = incwage_predicted if inrange(year,1910,1930)
	replace inctot = inctot_predicted if inrange(year,1910,1930)

	drop unemployed* *predicted
	
		
	// Add post-1950 data
	append using "analysis/processed/temp/ipums_post_1950.dta"
	
	// Deflate 2015 dollars to 1999
	replace incwage = incwage*0.703
	
	// Deflate to current dollars 
	replace incwage=incwage/16.828 if year==1910 // 1913 is first year
	replace incwage=incwage/8.33 if year==1920
	replace incwage=incwage/9.976 if year==1930
	replace incwage=incwage/11.986 if year==1940
	replace incwage=incwage/7.000 if year==1950
	replace incwage=incwage/5.725 if year==1960
	replace incwage=incwage/4.540 if year==1970
	replace incwage=incwage/2.295 if year==1980
	replace incwage=incwage/1.344 if year==1990
	replace incwage=incwage/1.000 if year==2000
	replace incwage=incwage/0.941 if year==2001
	replace incwage=incwage/0.926 if year==2002
	replace incwage=incwage/0.905 if year==2003
	replace incwage=incwage/0.882 if year==2004
	replace incwage=incwage/0.853 if year==2005
	replace incwage=incwage/0.826 if year==2006
	replace incwage=incwage/0.804 if year==2007
	replace incwage=incwage/0.774 if year==2008
	replace incwage=incwage/0.777 if year==2009
	replace incwage=incwage/0.764 if year==2010
	replace incwage=incwage/0.741 if year==2011
	replace incwage=incwage/0.726 if year==2012
	replace incwage=incwage/0.715 if year==2013
	replace incwage=incwage/0.704 if year==2014

	
	save "analysis/processed/temp/tax_input.dta", replace

	// Collapse data to compute taxable income
	* NOTE: We moved computation of taxable income after 1910-1930 imputation
	
	use "analysis/processed/temp/tax_input.dta", clear 
	
	keep year incwage nchild
	gduplicates drop
	
	tab year 	
	
	// Merge on personal exemptions (1913-2015) by year and tax rates (1913-2013) by
	*	year and bracket to generate post-tax income variable
	merge m:1 year using "analysis/processed/intermediate/fed/personal_exemptions.dta", keep(1 3) nogen
	
	gen taxable_income = incwage - exemption_single - exemption_dependent*nchild/2
	replace taxable_income = 0 if taxable_income < 0
	
	gen long obs_id = _n
	save "analysis/processed/temp/temp_for_rangejoin.dta", replace

	use "analysis/processed/intermediate/fed/taxrates.dta", clear
	rangejoin taxable_income bracket_low bracket_high using "analysis/processed/temp/temp_for_rangejoin.dta", by(year)
	
	gen tax_amount = amtpaid_prev_brackets + rate*(taxable_income - bracket_low)/100
	replace tax_amount = 0 if tax_amount < 0

	gen incwage_posttax = incwage - tax_amount
	
	// Merge back on any observations which did not match to income tax data, and
	*	figure out why, since the income tax brackets should be comprehensive.
	
	preserve
		keep obs_id
		duplicates drop

		merge 1:1 obs_id using "analysis/processed/temp/temp_for_rangejoin.dta"
		keep if _merge != 3
		drop _merge

		count
		if r(N) > 0 {
			tempfile temp1
			save "`temp1'", replace
		}
	restore

	if r(N) > 0 {
		append using "`temp1'"
	}
	
	// Some people match to multiple brackets because they are on the border between
	*	two brackets. Make sure this is all of the duplicates and then drop the
	*	duplicates so that we are back to one observation per person.

	duplicates tag obs_id, gen(temp)
	tab temp, m

	gen border_check = taxable_income == bracket_low | taxable_income == bracket_high
	tab temp border_check, m

	drop rate bracket_low bracket_high border_check temp amtpaid_prev_brackets

	duplicates drop
	duplicates report obs_id
	unique year incwage nchild
	
	
	tab year if taxable_income == .
	drop if taxable_income == .
	
	save "analysis/processed/temp/tax_output.dta", replace
	
	use "analysis/processed/temp/tax_input.dta", clear
	merge m:1 year incwage nchild using "analysis/processed/temp/tax_output.dta", assert(3) nogen
	
	
	// Now inflate incwage to 2015 dollars. Inflation factors from here: https://usa.ipums.org/usa/cpi99.shtml
	foreach x of varlist incwage incwage_posttax { 

		// First inflate to 1999 dollars
		replace `x'=`x'*16.828 if year==1910 // 1913 is first year
		replace `x'=`x'*8.33 if year==1920
		replace `x'=`x'*9.976 if year==1930
		replace `x'=`x'*11.986 if year==1940
		replace `x'=`x'*7.000 if year==1950
		replace `x'=`x'*5.725 if year==1960
		replace `x'=`x'*4.540 if year==1970
		replace `x'=`x'*2.295 if year==1980
		replace `x'=`x'*1.344 if year==1990
		replace `x'=`x'*1.000 if year==2000
		replace `x'=`x'*0.941 if year==2001
		replace `x'=`x'*0.926 if year==2002
		replace `x'=`x'*0.905 if year==2003
		replace `x'=`x'*0.882 if year==2004
		replace `x'=`x'*0.853 if year==2005
		replace `x'=`x'*0.826 if year==2006
		replace `x'=`x'*0.804 if year==2007
		replace `x'=`x'*0.774 if year==2008
		replace `x'=`x'*0.777 if year==2009
		replace `x'=`x'*0.764 if year==2010
		replace `x'=`x'*0.741 if year==2011
		replace `x'=`x'*0.726 if year==2012
		replace `x'=`x'*0.715 if year==2013
		replace `x'=`x'*0.704 if year==2014

		// Now inflate to 2015 dollars
		replace `x'=`x'/0.703

	}
	
	
	// Analyze some raw descriptives in the data
	tab age, m
	sum incwage inctot incwage_posttax, d
	tab year incwage if missing(incwage), m
	bys year: sum incwage inctot incwage_posttax

	// Note that states entered the union at different times. That is okay,
	*	fixed effects can be based on 1940-present. http://www.u-s-history.com/pages/h928.html
	tab statefip year if inlist(year,1910,1930,1950,1970,1990,2010)

	// What industries were white men in, over time?
	tab ind1950 year if racesing == 1 & inrange(age,15,50) & inlist(year,1910,1930,1950,1970,1990,2010), m

	// What about black men?
	tab ind1950 year if racesing==2 & inrange(age,15,50) & inlist(year,1910,1930,1950,1970,1990,2010), m

	// What is the overall occupation and industry breakdown by year?
	tab ind1950 year if inlist(year,1910,1930,1950,1970,1990,2010), m
	tab occ1950 year if inlist(year,1910,1930,1950,1970,1990,2010), m

	// What was the age mass like over time?
	tab age year if inlist(year,1910,1930,1950,1970,1990,2010), m

	// Look at how imputed income evolved over time
	bys year: sum incwage inctot incwage_posttax
	

	gen slwt_round = slwt if year > 1940
	replace slwt_round = 1 if year <= 1940
	
	bys year: sum slwt_round slwt

	collapse (mean) incwage inctot incwage_posttax (rawsum) n = slwt_round [fw = slwt_round], by(year age racesing)

	replace incwage = 0 if incwage < 0
	replace inctot = 0 if inctot < 0
	replace incwage_posttax = 0 if incwage_posttax < 0

	// Create empty observations to fill in
	gen tempcount=1
	qui forval race=1/2 {
		qui forval year=1900/2014 {
			qui forval age=16/89 {
			
				sum tempcount if year==`year' & age==`age' & racesing==`race'
				
				if ( r(N) == 0 ) {
					set obs `=_N+1'
					replace racesing=`race' in `=_N'
					replace year=`year' in `=_N'
					replace age=`age' in `=_N'
				}
			}
		}
	}
	drop tempcount



	// Now interpolate the number of people at each age and the final income variables.
	gen i_n = .
	gen i_incwage = .
	gen i_inctot = .
	gen i_incwage_posttax = .

	qui forval race = 1/2 {
			qui forval age = 16/89 {			
			
			ipolate n year if racesing == `race' & age==`age', gen(temp1) epolate
			replace i_n=temp1 if racesing==`race' & age==`age'
			
			ipolate incwage year if racesing==`race' & age==`age', gen(temp2) epolate
			replace i_incwage=temp2 if racesing==`race' & age==`age'

			ipolate inctot year if racesing==`race' & age==`age', gen(temp3) epolate
			replace i_inctot=temp3 if racesing==`race' & age==`age'

			ipolate incwage_posttax year if racesing==`race' & age==`age', gen(temp4) epolate
			replace i_incwage_posttax=temp4 if racesing==`race' & age==`age'

			drop temp1 temp2 temp3 temp4
			
			}
	}

	gen birth_cohort=year-age


	// Now, for pre-1940 years of data, multiply all wages by the average wages in that
	*	year divided by the 1940 average wages per person.
	*Source: page 44 of https://www2.census.gov/library/publications/1975/compendia/hist_stats_colonial-1970/hist_stats_colonial-1970p1-chD.pdf
	*	Series D725, which describes the real earnings (1914 dollars) after deducting
	*	from the earnings for unemployment.


	foreach x of varlist incwage inctot incwage_posttax {

		// First divide by 1940 earnings
		replace `x'=`x'/754 if year<1940


		// Now multiply by that year's average earnings
		replace `x'=`x'*699 if year==1939
		replace `x'=`x'*641 if year==1938
		replace `x'=`x'*704 if year==1937
		replace `x'=`x'*633 if year==1936
		replace `x'=`x'*584 if year==1935
		replace `x'=`x'*569 if year==1934
		replace `x'=`x'*526 if year==1933
		replace `x'=`x'*554 if year==1932
		replace `x'=`x'*657 if year==1931
		replace `x'=`x'*725 if year==1930
		replace `x'=`x'*793 if year==1929
		replace `x'=`x'*759 if year==1928
		replace `x'=`x'*759 if year==1927
		replace `x'=`x'*743 if year==1926
		replace `x'=`x'*717 if year==1925
		replace `x'=`x'*702 if year==1924
		replace `x'=`x'*725 if year==1923
		replace `x'=`x'*639 if year==1922
		replace `x'=`x'*566 if year==1921
		replace `x'=`x'*619 if year==1920
		replace `x'=`x'*648 if year==1919
		replace `x'=`x'*648 if year==1918
		replace `x'=`x'*586 if year==1917
		replace `x'=`x'*595 if year==1916
		
	}


	// Construct forwarded imputation from all 2014 data, so that people born in later
	*	years have full earnings histories. This assumes that earnings will remain
	*	stable for each racesing*age in years 2017-2070.
	preserve
	keep if year == 2014
	drop birth_cohort

	expand 100

	bys year age racesing: gen temp_n = _n
	replace year = year + temp_n
	drop temp_n

	gen birth_cohort = year - age

	tempfile temp
	save "`temp'"  

	restore

	append using "`temp'"

	keep if inrange(birth_cohort,1900,2000)

	keep year birth_cohort age racesing i_*
	rename i_* *

	save "analysis/processed/data/earnings/census_earnings_by_race.dta", replace

	rm "analysis/processed/temp/temp_for_rangejoin.dta"
	rm "analysis/processed/temp/ipums_1900.dta"
	rm "analysis/processed/temp/ipums_1910_1930.dta"
	rm "analysis/processed/temp/ipums_1940.dta"
	rm "analysis/processed/temp/ipums_post_1950.dta"
	rm "analysis/processed/temp/tax_input.dta"
	rm "analysis/processed/temp/tax_output.dta"
	
}

* EOF
