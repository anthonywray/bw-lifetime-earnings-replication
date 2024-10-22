************
* SCRIPT: 3.4_build_data_cwscore_with_kids.do
* PURPOSE: Process the data in preparation for robustness analysis using occupational income score from Collins and Wanamaker (2022)
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

	local main_sample_restrictions "inrange(age,14,89) & inrange(bpl,1,56)"
	
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
	
	// Use aggregate regions 
	rename region regiond
	gen region = floor(regiond/10)
		
	// Create group variable based on race 
	gen group = race 
	
	// Merge in occupational income data from Ward (2023) based on Collins and Wanamaker (2022) 
	merge m:1 region occ1950 group using "analysis/raw/ward_2023/cwscore_native_multgen.dta", keep(1 3) nogen keepusing(cwscore_group)
	
	// Use higher-order occupational groups if missing 
	gen occ1950_1 = floor(occ1950/100)
	merge m:1 region occ1950_1 group using "analysis/raw/ward_2023/cwscore_native_multgen_1.dta", keep(1 3) nogen keepusing(incwagemean_1)
	replace cwscore_group = incwagemean_1 if missing(cwscore_group)
	
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
		
		tab race racesing, m
		keep if inrange(racesing,1,2)
			
		tempfile ipums_`y'
		save `ipums_`y'', replace
	}
	
	clear
	forval y = 1910(10)1930 {
		append using `ipums_`y''
	}
	
	// Add region 
	cap drop region
	merge m:1 statefip using "analysis/raw/ward_2023/region.dta", keep(1 3) nogen 
	
	// Use aggregate regions 
	rename region regiond
	gen region = floor(regiond/10)
		
	// Create group variable based on race 
	gen group = race 
	
	// Merge in occupational income data from Ward (2023) based on Collins and Wanamaker (2022) 
	merge m:1 region occ1950 group using "analysis/raw/ward_2023/cwscore_native_multgen.dta", keep(1 3) nogen keepusing(cwscore_group)
	
	// Use higher-order occupational groups if missing 
	gen occ1950_1 = floor(occ1950/100)
	merge m:1 region occ1950_1 group using "analysis/raw/ward_2023/cwscore_native_multgen_1.dta", keep(1 3) nogen keepusing(incwagemean_1)
	replace cwscore_group = incwagemean_1 if missing(cwscore_group)	
	
	// Now inflate cwscore_group to 2015 dollars. Inflation factors from here: https://usa.ipums.org/usa/cpi99.shtml
	
	foreach x of varlist cwscore_group { 

		// First inflate 1940 occupational wages to 1999 dollars	
		replace `x' = `x'*11.986

		// Now inflate to 2015 dollars
		replace `x'=`x'/0.703		
	}
	
	
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
	
	gen racesing = race
	keep if inrange(racesing,1,2)
	
	// Add region 
	cap drop region
	merge m:1 statefip using "analysis/raw/ward_2023/region.dta", keep(1 3) nogen 
	
	// Use aggregate regions 
	rename region regiond
	gen region = floor(regiond/10)
		
	// Create group variable based on race 
	gen group = race 
	
	// Merge in occupational income data from Ward (2023) based on Collins and Wanamaker (2022) 
	merge m:1 region occ1950 group using "analysis/raw/ward_2023/cwscore_native_multgen.dta", keep(1 3) nogen keepusing(cwscore_group)
	
	// Use higher-order occupational groups if missing 
	gen occ1950_1 = floor(occ1950/100)
	merge m:1 region occ1950_1 group using "analysis/raw/ward_2023/cwscore_native_multgen_1.dta", keep(1 3) nogen keepusing(incwagemean_1)
	replace cwscore_group = incwagemean_1 if missing(cwscore_group)	
	
	save "analysis/processed/temp/ipums_1940.dta", replace
	
}


*******************************
// Construct earnings data ****
*******************************

if `earnings' {

	local main_sample_restrictions "inrange(age,14,89) & inrange(bpl,1,56)"

	**************************************
	***** Pre-process post-1940 data *****
	**************************************
	
	use "analysis/raw/ipums/usa_00064.dta" if `main_sample_restrictions', clear
	
	keep if inrange(racesing,1,2)
	
	// Restrict to post-1940 data
	keep if year > 1940
	
	// Drop 2001-2005 ACS since those years do not contain institutionalized respondents
	drop if inrange(year,2001,2005)

	// In 1970, weights are twice as large as they should be because IPUMS aggregates
	//	two representative samples.
	replace slwt = slwt/2 if year == 1970
	
	// For 1950 and beyond, we only need sample-line respondents with non-missing wage income
	drop if slwt == 0
	drop if incwage == 999999

	// Use reported income for post-1950 period 
	gen cwscore_group = inctot
	
	// Add 1940 data
	append using "analysis/processed/temp/ipums_1940.dta"
	
	// Drop variables we will not use
	drop perwt sex hhwt serial race raced bpld racesingd ///
		empstat empstatd labforce occscore sei erscor50 incbusfm incbus incbus00 ///
		incfarm incnonwg incother incearn occ
	
	// Now inflate cwscore_group from 1940 to 2015 dollars. Inflation factors from here: https://usa.ipums.org/usa/cpi99.shtml
	foreach x of varlist cwscore_group { 

		// First inflate to 1999 dollars
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
		
	// Adding this data year since we don't need it earlier
	append using "analysis/processed/temp/ipums_1910_1930.dta" 
		

	gen slwt_round = slwt if year > 1940
	replace slwt_round = 1 if year <= 1940
	
	bys year: sum slwt_round slwt

	collapse (mean) cwscore_group (rawsum) n = slwt_round [fw = slwt_round], by(year age racesing)

	// Create empty observations to fill in
	gen tempcount=1
	qui forval race=1/2 {
		qui forval year=1900/2014 {
			qui forval age=14/89 {
			
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
	gen i_cwscore_group = .

	qui forval race = 1/2 {
			qui forval age = 14/89 {			
			
			ipolate n year if racesing == `race' & age==`age', gen(temp1) epolate
			replace i_n=temp1 if racesing==`race' & age==`age'
			
			ipolate cwscore_group year if racesing==`race' & age==`age', gen(temp2) epolate
			replace i_cwscore_group = temp2 if racesing==`race' & age==`age'

			drop temp1 temp2
			
			}
	}

	gen birth_cohort = year - age


	// Now, for pre-1940 years of data, multiply all wages by the average wages in that
	*	year divided by the 1940 average wages per person.
	// Source: page 44 of https://www2.census.gov/library/publications/1975/compendia/hist_stats_colonial-1970/hist_stats_colonial-1970p1-chD.pdf
	*	Series D725, which describes the real earnings (1914 dollars) after deducting
	*	from the earnings for unemployment.


	foreach x of varlist cwscore_group {

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
		replace `x'=`x'*541 if year==1915
		replace `x'=`x'*555 if year==1914
		replace `x'=`x'*594 if year==1913
		replace `x'=`x'*570 if year==1912
		replace `x'=`x'*546 if year==1911
		replace `x'=`x'*546 if year==1910
		
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

	save "analysis/processed/data/earnings/census_earnings_cwscore_group_with_kids.dta", replace

	rm "analysis/processed/temp/ipums_1900.dta"
	rm "analysis/processed/temp/ipums_1910_1930.dta"
	rm "analysis/processed/temp/ipums_1940.dta"
	
}

* EOF
