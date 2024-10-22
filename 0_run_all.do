*****************************************************
* OVERVIEW
*	FILE: 0_run_all.do
*   This script generates tables and figures for the paper:
*		"The Black-White Lifetime Earnings Gap" 
*	AUTHORS: Ezra Karger and Anthony Wray
* 	VERSION: October 2024
*
* DESCRIPTION
* 	This script replicates the analysis in our paper and online appendix
*   All raw data are stored in /raw/
*   All code is stored in /scripts/
*   All tables and figures are outputted to /output/
* 
* SOFTWARE REQUIREMENTS
*   Analyses run on Windows using Stata version 18 and R-4.4.1
*
* TO PERFORM A CLEAN RUN, 
*	1. Be sure to have downloaded the publicly available IPUMS data that we are not allowed to redistribute
* 	2. Delete the following two directories:
*   	/processed
*   	/output
*	3. Open the stata project `bw-lifetime-earnings-replication.stpr` or 
*		make the working directory of Stata is the same directory `bw-lifetime-earnings.stpr`
*		 is located in
* 	4. Run this file, `0_run_all.do`

*****************************************************
// Local switches

* Install packages
local install_packages 	1

* Force removal of the gtools package that was installed
local remove_existing_gtools 0

* Install gtools, The stata package gtools installs differently depending on your machine.
* The version in our libraries may not work for your machine. 
local install_gtools 0

* Switch log on/off
local log 1

* Switches for running individual do files
local unzip_files		1 // Note this will not include some IPUMS data
local run_build			1 // You will need to download IPUMS data before this will run. Please see README.
local run_paper 		1
local run_robust_build	1
local run_robust		1

*****************************************************

// Set root directory
	local root_directory `c(pwd)'
	di "`root_directory'"
	global PROJ_PATH 	"`root_directory'"										// Project folder
	
// Set shell command paths
	global RSCRIPT_PATH "C:/Program Files/R/R-4.4.1/bin/x64/Rscript.exe"		// Location of the program R
	global ZIP_PATH 	"C:/Program Files/7-Zip/7zG.exe"						// Location of 7-Zip (used to unzip files)

*****************************************************

* Confirm that the globals for the project root directory and the R executable have been defined
assert !missing("$PROJ_PATH")

* Set project directory 
cd "$PROJ_PATH"

* Initialize log and record system parameters
cap mkdir "analysis/scripts/logs"
cap log close
set linesize 255 // Specify screen width for log files
local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "analysis/scripts/logs/log_`datetime'.txt"
if `log' {
	log using "`logfile'", text
}

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"

*****************************************************
* Make sure libraries are set up correctly
*****************************************************

local t0 = clock(c(current_time), "hms")
di "Starting extraction of libraries: `t0'"

// Takes ~14 seconds to run
if `unzip_files' {
	
	// Unzip Stata libraries
	shell "$ZIP_PATH" x "analysis/scripts/libraries.zip" -o"analysis/scripts" -aoa

	// Only Stata packages included in libraries.zip so R packages need to be installed via renv
	local install_packages 		1
			
}
else {
	
	// Initial set up for Stata libraries
	cap mkdir "analysis/scripts/libraries"
	cap mkdir "analysis/scripts/libraries/stata"
	
}

* Disable locally installed Stata programs
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE
cap adopath - "analysis/scripts/libraries/stata"

* Create and define a local installation directory for the packages
net set ado "analysis/scripts/libraries/stata"

adopath ++ "analysis/scripts/libraries/stata"
adopath ++ "analysis/scripts/programs" // Stata programs and R scripts are stored in /scripts/programs

if `install_gtools' {
	if `remove_existing_gtools' {
		shell rm -r "analysis/scripts/libraries/stata/g"
	}
	ssc install gtools
	gtools, upgrade
}

// Stata version control
version 18

// Build new list of libraries to be searched
mata: mata mlib index

// Set up R packages from renv
if `install_packages' {
	
	* Activate renv manually
	rscript using "renv/activate.R", rpath($RSCRIPT_PATH)
	
	* Install R packages by restoring renv
	rscript using "analysis/scripts/programs/_restore_renv.R", rpath($RSCRIPT_PATH)	
}

* R version control
rscript, rversion(4.4.1) 

*****************************************************
// Create project directories 

cap mkdir "analysis/output"
cap mkdir "analysis/output/figures"
cap mkdir "analysis/output/tables"
cap mkdir "analysis/processed"
cap mkdir "analysis/processed/data"
cap mkdir "analysis/processed/data/cdc"
cap mkdir "analysis/processed/data/earnings"
cap mkdir "analysis/processed/intermediate"
cap mkdir "analysis/processed/intermediate/cdc"
cap mkdir "analysis/processed/intermediate/fed"
cap mkdir "analysis/processed/temp"

**********************************************************************************************************
* Run project analysis ***********************************************************************************
**********************************************************************************************************

local t1 = clock(c(current_time), "hms")
di "Starting build: `t1'"

////////////////////////////////////////////////////////////////////////////
// Build main analysis data (~ 62 minutes to run)
////////////////////////////////////////////////////////////////////////////

if `run_build' {
	
	rscript using "analysis/scripts/code/0.1_construct_tax_rates.R", rpath($RSCRIPT_PATH)

	do "analysis/scripts/code/1.1_build_data.do"


}

local t2 = clock(c(current_time), "hms")
di "Ending build and starting analysis: `t2'"

////////////////////////////////////////////////////////////////////////////
// Main tables and figures (~ 21 seconds to run)
////////////////////////////////////////////////////////////////////////////

if `run_paper' {

	// Run main analysis for paper
	do "analysis/scripts/code/2.1_run_analysis.do"
	
}

local t3 = clock(c(current_time), "hms")
di "Ending main analysis and starting robustness build: `t3'"

////////////////////////////////////////////////////////////////////////////
// Build robustness data (~ 4 hours and 5 minutes to run)
////////////////////////////////////////////////////////////////////////////

if `run_robust_build' {

	// Build robustness data for Figure 9
	do "analysis/scripts/code/3.1_build_data_1960.do"
	do "analysis/scripts/code/3.2_build_data_by_race.do"
	do "analysis/scripts/code/3.3_build_data_with_kids.do"
	do "analysis/scripts/code/3.4_build_data_cwscore_with_kids.do"
	
}

local t4 = clock(c(current_time), "hms")
di "Ending robustness build: `t4'"

////////////////////////////////////////////////////////////////////////////
// Robustness Figure 9 (~4 seconds to run)
////////////////////////////////////////////////////////////////////////////

if `run_robust' {
	
	// Run robustness analysis for Figure 9
	do "analysis/scripts/code/4.1_run_analysis_robustness.do"

}

local t5 = clock(c(current_time), "hms")
di "Ending robustness analysis: `t5'"


*****************************************************
// Log of times per section

// Extract Stata libraries and install R packages
local time = clockdiff_frac(`t0', `t1', "minute")
di "Time to extract libraries: `time' minutes"

// Build
local time = clockdiff_frac(`t1', `t2', "minute")
di "Time to build raw data: `time' minutes"

// Main analysis
local time = clockdiff_frac(`t2', `t3', "minute")
di "Time to do main analysis: `time' minutes"

// Robustness build
local time = clockdiff_frac(`t3', `t4', "minute")
di "Total time to run robustness build: `time' minutes"

// Robustness analysis
local time = clockdiff_frac(`t4', `t5', "minute")
di "Total time to run robustness analysis: `time' minutes"

*****************************************************
// End log
di "End date and time: $S_DATE $S_TIME"

if `log' {
	log close
}

*****************************************************

** EOF
