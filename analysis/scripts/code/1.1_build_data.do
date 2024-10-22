************
* SCRIPT: 1.1_build_data.do
* PURPOSE: Process the data in preparation for analysis
************

* User switches for each section of code

local ipums 		1  	// DEPENDENCIES: none
local birthcounts	1	// DEPENDENCIES: ipums
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
// Construct birth counts *****
*******************************

if `birthcounts' {

	* Read in CDC mortality table, standardize, and interpolate it to project
	* 	survivorship rates (out of 100k births) for each race x birth
	*	cohort cell from 1900 to the present
	* Source: Table 20: https://www.cdc.gov/nchs/data/nvsr/nvsr64/nvsr64_11.pdf
	
	// Table 20 
		* Reports the number of survivors out of 100,000 for a hypothetical 
			* "period life table cohort"
		* i.e. how many survivors from this hypothetical cohort would there be if it 
			* experienced the age-specific death rates of the actual population in 
			* the given year 

	* Life table calculations from National Vital Statistics
	import delim using "analysis/raw/cdc/cdc_data.csv", varn(1) clear
	
	desc, f
	destring y*, ignore(",") replace

	reshape long y, i(age sex race) j(year)
	rename y survivors

	keep if sex == 1
	drop sex
	
	gisid race year age
	gsort race year age
	order race year age
	
	tempfile cdc
	save `cdc', replace
	
	* Now interpolate counts by age*race*birth cohort. First interpolate by age
	*	so that we have complete survivorship data by age, then interpolate by
	*	year so that we have all cells
	
	clear
	set obs 2
	gen race = _n
	tempfile race_values
	save `race_values', replace
	
	clear
	local year_start	1900
	local year_end		2011
	local year_range = `year_end' - `year_start' + 1
	set obs `year_range'
	
	gen year = _n + `year_start' - 1
	tempfile year_values
	save `year_values', replace
	
	clear
	set obs 101
	gen age = _n - 1
	tempfile age_values
	save `age_values', replace
	
	use `race_values', clear
	cross using `year_values'
	cross using `age_values'
	
	merge 1:1 race year age using `cdc', assert(1 3) nogen
	
	// Since Table 20 is an abridged life table, it only reports the number of survivors for
		* every 5 years of age 
	
	// For each year, fill in the number of survivors at each year of age 
	gsort race year age 
	qui forval race = 1/2 {
	
		qui forval year = 1900/2011 {	
		
			ipolate survivors age if race==`race' & year==`year', gen(temp) epolate
			replace survivors = temp if race==`race' & year==`year' & missing(survivors)
			drop temp
		}
			
	}
	
	// Table 20 only reports life tables for census years 
	// Fill in number of age-specific survivors in between census years 
	gsort race age year 
	qui forval race = 1/2 {
		
		qui forval age = 0/100 {	

			ipolate survivors year if race==`race' & age==`age', gen(temp2) epolate
			replace survivors = temp2 if race==`race' & age==`age' & missing(survivors)

			drop temp2
				
		}
	}
	
	
	* Now for birth cohorts and ages in the future with no available data, set survivors equal to
	*	2011 data, which assumes that mortality will be the same post-2011 as in 2011.
	gisid race year age
	gsort race year age

	expand 100 if year == 2011, gen(dup_id) 
	
	gen temp_year = year 
	egen counter = seq(), by(race year age)
	assert counter == 1 if year < 2011
	
	gisid race year age counter
	gsort race year age counter
	
	by race year age: replace temp_year = temp_year[_n-1] + 1 if temp_year == 2011 & counter > 1 
	replace year = temp_year if year == 2011 & temp_year > 2011 
	drop counter temp_year 
	
	// Calculate age-specific survival rates of actual population in a year 
	gisid race year age
	gsort race year age
	
	bys race year (age): gen prob_live = survivors/survivors[_n-1] 
	replace prob_live = 1 if age == 0 													

	// Define birth cohort variable 
	gen birth_cohort = year - age

	// Drop the number of survivors variable from the raw CDC table 
	// We don't care about this variable because it represents the number of 
		// survivors from a hypothetical "period life table cohort"
	drop survivors 	
	
	// Now we will reconstruct the number of survivors by age for each birth cohort 
	// Based on the age-specific survival rates we just computed 
	gisid race birth_cohort age 
	gsort race birth_cohort age 
	
	bys race birth_cohort (age): gen sumprod = exp(sum(ln(prob_live)))				

	// Restrict to sample we care about 
	keep if birth_cohort >= 1900 & birth_cohort <= 2000
	
	// Generate number of survivors variable
	gen survivors = sumprod*100000
	drop sumprod

	keep birth_cohort age race survivors
	
	save "analysis/processed/intermediate/cdc/survivorship_rates.dta", replace



	// Now read in census data and create population counts by birth cohort, age, and
	*	race. Link to mortality data to estimate birth counts for each birth cohort
	*	and race at multiple ages. Examine how consistent these estimates are.

	use "analysis/raw/ipums/usa_00041.dta" if (inrange(year,1950,2000) | inrange(year,2006,2014)), clear

	// Now using complete count data for 1900 to 1940 
	append using "analysis/processed/temp/ipums_1900.dta"
	append using "analysis/processed/temp/ipums_1910_1930.dta"
	append using "analysis/processed/temp/ipums_1940.dta"
	
	// Ages we care about
	keep if inrange(age,0,89)
	
	// In 1970, IPUMS bundles together two representative samples from the census,
	*	so the weights are twice as large as they should be.
	replace perwt = perwt/2 if year == 1970

	// Construct population counts by birth cohort, age, and race (black/white)
	gen birth_cohort = year - age
	keep if inrange(birth_cohort,1900,1970) & inlist(racesing,1,2) & inrange(bpl,1,56)
	replace race=racesing if !missing(racesing)

	assert !missing(perwt)
	collapse (sum) perwt, by(birth_cohort age race)


	// Link population counts to interpolated CDC mortality data
	merge 1:1 birth_cohort age race using "analysis/processed/intermediate/cdc/survivorship_rates.dta"

	keep if _merge == 3

	gen n_births=perwt*100000/survivors
	sort race birth_cohort age

	gen year=birth_cohort+age
	reg n_births i.year i.age if race == 1
	reg n_births i.year i.age if race == 2 

	reg n_births i.birth_cohort i.age if race == 1
	reg n_births i.birth_cohort i.age if race == 2


	// Early and late ages seem noisier, so for now focus on ages 5-60
	keep if inrange(age,5,60)
	bys birth_cohort race: egen n_births_med=median(n_births)
	by birth_cohort race: egen n_births_max=max(n_births)

	keep birth_cohort race n_births_med n_births_max

	duplicates drop


	// Collect birth counts by rates directly from the CDC as a comparison:
	*Source: https://www.cdc.gov/nchs/data/statab/t001x01.pdf

	preserve

		insheet using "analysis/raw/cdc/cdc_data_birthcounts.csv", names clear
		destring n*, ignore(",") replace


		// For missing black birth counts (pre-1959), estimate using all-white-55k to
		*	account for native americans, asian and pacific islanders, and other small
		*	groups. 0 is all, 1 is white, and 2 is black. The 55k number is from this
		*	1959 data (see source above): "4,257,850-3,600,744-602,264"

		replace n_births_2=n_births_0-n_births_1-55000 if missing(n_births_2)
		keep year n_births_1 n_births_2

		reshape long n_births_, i(year) j(race)
		rename n_births_ n_births_cdc
		rename year birth_cohort

		*The sex ratio at birth is 105 males per 100 females, which means that at birth,
		*	105/(105+100)=51.22% of these births are male
		*Source: https://www.cdc.gov/nchs/data/nvsr/nvsr53/nvsr53_20.pdf
		replace n_births_cdc=n_births_cdc*.5122
		keep if inrange(birth_cohort,1900,1970)

		tempfile temp1
		save "`temp1'"

	restore

	merge 1:1 birth_cohort race using "`temp1'"
	drop _merge

	gen pct_dif=(n_births_cdc-n_births_med)/n_births_med
	gen pct_dif2=(n_births_cdc-n_births_max)/n_births_max

	// What is the average percent difference between the CDC and the max/med birth count
	*	numbers?
	*For 1900-1908, replace the missing CDC birthcounts with the 1909 imputed birth counts

	sum pct_dif pct_dif2, d
	sum pct_dif pct_dif2 if birth_cohort<=1920 & race==1
	list race n_births_cdc if birth_cohort==1909

	replace n_births_cdc=n_births_med if missing(n_births_cdc)

	keep birth_cohort race n_births_med n_births_cdc


	save "analysis/processed/data/cdc/birth_counts.dta", replace

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

	// Construct a predictor for whether there was non-negligible non-wage income and
	*	include this predictor in the regressions. Also use the wage income as a
	*	predictor.

	gen nowages = inrange(inc_nonwg,-5,5)
	tab age nowages if year == 1950, m
	
	reg nowages i.racesing i.age i.occ1950 i.ind1950 i.bpl i.statefip if year == 1950
	predict nowages_predicted if inlist(year,1940,1950)
	xtile nowages_predicted_bins = nowages_predicted if inlist(year,1940,1950), n(20)

	xtile incwage_bins = incwage if inlist(year,1940,1950), n(20)

	// Now predict non-wage income for 1940
	reg inc_nonwg i.nowages_predicted_bins i.incwage_bins i.racesing i.age ///
		i.occ1950 i.ind1950 i.bpl i.statefip if year == 1950
	predict inc_nonwg_predicted if inlist(year,1940,1950)

	// And construct new inctot values for 1940 using this imputed wage information
	replace inctot = incwage + inc_nonwg_predicted if year == 1940

	drop nowages* inc_nonwg_predicted
	
	// Now impute wage income and total income for pre-1930 based on 1940 wage and total income.
	append using "analysis/processed/temp/ipums_1910_1930.dta" // Adding this data year since we don't need it earlier
	
	gen unemployed = inrange(incwage,-5,5)
	tab age unemployed if year == 1940

	reg unemployed i.racesing i.age i.occ1950 i.ind1950 i.bpl i.statefip if year == 1940
	predict unemployed_predicted if inrange(year,1910,1940)
	xtile unemployed_predicted_bins = unemployed_predicted, n(20)

	reg incwage i.unemployed_predicted_bins i.racesing i.age i.occ1950 i.ind1950 i.bpl i.statefip if year == 1940
	predict incwage_predicted if inrange(year,1910,1930)

	reg inctot i.unemployed_predicted_bins i.racesing i.age i.occ1950 i.ind1950 i.bpl i.statefip if year == 1940
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
	// Source: page 44 of https://www2.census.gov/library/publications/1975/compendia/hist_stats_colonial-1970/hist_stats_colonial-1970p1-chD.pdf
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

	save "analysis/processed/data/earnings/census_earnings.dta", replace

	rm "analysis/processed/temp/temp_for_rangejoin.dta"
	rm "analysis/processed/temp/ipums_1900.dta"
	rm "analysis/processed/temp/ipums_1910_1930.dta"
	rm "analysis/processed/temp/ipums_1940.dta"
	rm "analysis/processed/temp/ipums_post_1950.dta"
	rm "analysis/processed/temp/tax_input.dta"
	rm "analysis/processed/temp/tax_output.dta"
	
}

* EOF
