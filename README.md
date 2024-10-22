---
contributors:
  - Ezra Karger
  - Anthony Wray
---

# README: Replication code and data for "The Black-White Lifetime Earnings Gap"

## Overview

The code in this replication package (Karger and Wray 2024b) constructs the analysis datasets used to reproduce the figures and tables in the following article (Karger and Wray 2024a):

Ezra Karger and Anthony Wray. "The Black-White Lifetime Earnings Gap." Forthcoming at _Explorations in Economic History_. 101629. [https://doi.org/10.1016/j.eeh.2024.101629](https://doi.org/10.1016/j.eeh.2024.101629).

Some public-use datasets from IPUMS USA cannot be included in the repository. These must first be downloaded using the IPUMS data extraction system before running our code. Instructions for accessing data from IPUMS USA are provided below.

The code is executed using Stata version 18 and R version 4.4.1. To recreate our paper, navigate to the home directory `bw-lifetime-earnings-replication` and open the Stata project `bw-lifetime-earnings-replication.stpr`, then run the do file `0_run_all.do`. This will run all of the code to create the figures and tables in the manuscript, including the online appendix. The replicator should expect the code to run for about 5 hours.

## Data Availability and Provenance Statements

### Statement about Rights

- I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permission are documented in the [LICENSE.txt](LICENSE.txt) file.

### License for Data

The data are licensed under a MIT License license. See LICENSE.txt for details.

### Summary of Availability

- All data **are** publicly available.

### Details on each Data Source

The data used to support the findings of this study have been deposited in a replication package hosted at OpenICPSR ([project openicpsr-209621](https://doi.org/10.3886/E209621V1)). Data are made available under a MIT license. Here we provide further details on the sources for all datasets used in the study:

The paper uses data on survivorship rates per 100,000 births by age, race, and sex. The data was retrieved from [Table 20](https://www.cdc.gov/nchs/data/nvsr/nvsr64/nvsr64_11.pdf) of "United States Life Tables, 2011" published in _National Vital Statistics Reports_ Vol. 64 No. 11 (Arias 2015).

Annual birth counts by race come from the [Center for Disease Control (CDC)] and were retrieved from [Table 1-1](https://www.cdc.gov/nchs/data/statab/t001x01.pdf) "Live Births, Birth Rates, and Fertility Rates, by Race: United States, 1909-2000" (Hamilton et al. 2003).

Data on average earnings by year prior to 1940 were obtained from [series D722-727 on page 44 of Chapter D (Labor)](https://www2.census.gov/library/publications/1975/compendia/hist_stats_colonial-1970/hist_stats_colonial-1970p1-chD.pdf) of the "Historical Statistics of the United States, Colonial Times to 1970" (United States. Bureau of the Census, 1975).

Federal individual income tax rate data were downloaded from a [Tax Foundation](https://files.taxfoundation.org/legacy/docs/fed_individual_rate_history_nominal.pdf) report (Tax Foundation 2013). Data were downloaded in PDF format and were exported to `xlsx` format using Adobe Acrobat and then saved as a `.csv`.

Data on federal individual income tax personal exemptions were downloaded from a [Tax Policy Center](https://taxpolicycenter.org/sites/default/files/legacy/taxfacts/content/PDF/historical_parameters.pdf) report (Tax Policy Center 2015). Data were downloaded in PDF format and were exported to `xlsx` format using Adobe Acrobat and then saved as a `.csv`.

The paper uses __IPUMS USA__ [full count U.S. Census microdata](https://usa.ipums.org/usa/full_count.shtml) constructed from source data provided by the United States Census Bureau (Ruggles et al. 2024a,b). IPUMS USA does not allow users to redistribute IPUMS-USA Full-Count data, but these data can be freely downloaded from the [IPUMS-USA extract system](https://usa.ipums.org/usa-action/variables/group). Users will first need to [register for an account](https://uma.pop.umn.edu/usa/user/new) with IPUMS USA by filling out the registration form, including a brief description of the project, and agreeing to the conditions of use. In lieu of providing a copy of the data files as part of this archive, we include codebook files for each of the five full count extracts used (1900-1940), which provide information on the variables and observations to be selected.

The paper also uses samples of the 1900-2000 US Censuses of Population and 2000-2014 American Community Survey (ACS) provided by __IPUMS USA__ (Ruggles et al. 2024a). The data can be downloaded from [IPUMS USA](https://usa.ipums.org/usa-action/samples). We include the codebook file (`usa_00064.cbk`) provided by IPUMS along with the data. The data was downloaded on 21 July 2021. Interested  replicators can use the list of variables in the codebook file to generate an identical extract from the IPUMS system. In such cases with non-full count data, IPUMS USA does not allow for redistribution without permission, but their [terms of use](https://usa.ipums.org/usa/terms.shtml) makes an exception for users to "publish a subset of the data to meet journal requirements for accessing data related to a particular publication."

Data on age-adjusted death rates (deaths per 100,000) and life expectancy at birth by race and sex come from the [Center for Disease Control](https://data.cdc.gov/NCHS/NCHS-Death-rates-and-life-expectancy-at-birth/w9j2-ggv5/about_data) and National Center for Health Statistics (2015).

The occupational income score data in Figure 9 are based on the implementation of Collins and Wanamker (2022) by Ward (2023). The data and code used to construct the measures come from the replication package of Ward (2023).

## Dataset list

The following table provides a list of all datasets included in this replication package (stored within the `analysis/raw` directory) and their provenance.

| Data file and subdirectory                | Source                       | Notes                                       |Provided |
|-------------------------------------------|------------------------------|---------------------------------------------|---------|
| `cdc/cdc_data.csv`                        | Arias (2015) | Survivorship rates per 100,000 births | Yes |
| `cdc/cdc_data_birthcounts.csv` | Hamilton et al. (2003) | CDC birth and fertility rates | Yes | 
| `earnings/earnings_table_from_historical_statistics_of_the_us.csv` | United States. Bureau of the Census. (1975) | Average earnings by year before 1940 | Yes |
| `fed/fed_individual_rate_history_nominal.csv` | Tax Foundation (2013) | Federal individual income tax rates, 1913-2013 | Yes|
| `fed/fed_personal_exemptions.csv` | Tax Policy Center (2015) | Federal individual income tax personal exemptions, 1913-2015 | Yes |
| `ipums/ipums_1900_100_pct/usa_00075.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1900 Census complete count | No |
| `ipums/ipums_1910_100_pct/usa_00062.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1910 Census complete count | No |
| `ipums/ipums_1920_100_pct/usa_00061.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1920 Census complete count | No |
| `ipums/ipums_1930_100_pct/usa_00060.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1930 Census complete count | No |
| `ipums/ipums_1940_100_pct/usa_00059.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1940 Census complete count | No |
| `ipums/ipums_1940_100_pct/usa_00059.dta` | Ruggles et al. (2024a) and Ruggles et al. (2024b) | US 1940 Census complete count | No |
| `ipums/usa_00041.dta` | Ruggles et al. (2024a) | US Census samples 1900-2000 and ACS 2000-2014 | Yes |
| `ipums/usa_00064.dta` | Ruggles et al. (2024a) | US Census samples 1900-2000 and ACS 2000-2014 | Yes |
| `nchs/nchs_death_rates_and_life_expectancy_at_birth.csv` | National Center for Health Statistics (2015) | Death rates and life expectancy at birth | Yes |
| `ward_2023/cwscore_native_multgen.dta` | Ward (2023) | Occupational income score based on Collins and Wanamaker (2022) | Yes |
| `ward_2023/cwscore_native_multgen_1.dta` | Ward (2023) | Occupational income score based on Collins and Wanamaker (2022) | Yes |
| `ward_2023/region.dta` | Ward (2023) | Census region crosswalk | Yes |

## Computational requirements

### Software Requirements

- The replication package contains all Stata programs used for computation in the `analysis/scripts/libraries/stata` directory.
- The download and installation of R packages used in the study is initiated from Stata by the `0_run_all.do` do file which calls the `renv/activate.R` and `analysis/programs/_restore_renv.R` scripts. R packages will be downloaded and installed in the `renv/libraries/` directory.

All software used for Stata is contained within the `analysis/scripts/libraries/stata` directory. If you would like to use updated versions of this code (which may be different than the versions we used) you may install stata packages using the `analysis/scripts/code/_install_stata_packages.do` file. Note that you may need to delete and then reinstall all the packages in `analysis/scripts/libraries/stata/g` related to gtools since gtools will install machine specific libraries.

Packages and version control related to R are controlled using `renv` package. You may need to install the `renv` package before proceeding (`install.packages("renv")`). Metadata on the package versions used in the study is contained in the `renv.lock` file. The exact versions of the R packages used in the study are downloaded and installed by the `0_run_all.do` do file. If you wish to run the analysis in R without using Stata, opening the `bw-lifetime-earnings-replication.Rproj` R project file in RStudio will automatically activate `renv`. Packages can be manually installed by running the `renv::restore()` command.

- Stata (Version 18)
- R 4.4.1

Portions of the code require data to be unzipped using a program such as 7-Zip.

### Controlled Randomness

The code does not include any instances of controlled randomness.

### Memory, Runtime, Storage Requirements

#### Summary

Approximate time needed to reproduce the analyses on a standard (2024) desktop machine:

- 5 hours

Approximate storage space needed:

- 45 GB - 50 GB

#### Details

The code was last run on a **HP EliteBook 840 G8 Notebook PC with a 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz, 2803 Mhz, 4 core processor, running Microsoft Windows 11 Enterprise with 64 GB of RAM and 400GB of free space**. Computation took **5 hours 7 minutes 49 seconds** to run.

Each section of the code took the following time to run

- Unzip packages: 14 seconds
- Build data for main analysis: 62 minutes
- Main figures and tables: 21 seconds
- Build robustness data for Figure 9: 4 hours and 5 minutes
- Figure 9: 14 seconds

## Description of programs/code

- The program `0_run_all.do` will run all programs in the sequence listed below. If running in any order other than the one outlined above, your results may differ.
  - Stata packages (`.ado` files) been included in the `analysis/scripts/libraries` directory. The `0_run_all.do` file unzips the libraries folder and sets the `.ado` directories appropriately.
  - Information on R package versions are recorded by the `renv` package. The `0_run_all.do` file uses the `rscript` Stata command to run `renv/activate.R` which activates `renv` and `analysis/scripts/programs/_restore_renv.R` which restores the R environment by installing the correct versions of the project libraries.
- The program `analysis/scripts/code/0.1_construct_tax_rates.R` computes income tax rates and personal exemption amounts for each year.
- The program `analysis/scripts/code/1.1_build_data.do`: extracts, cleans, and compiles datasets referenced above to generate the dataset used in the main analysis.
- The program `analysis/scripts/code/2.1_run_analysis.do`: generates all tables and figures based on the main analysis dataset produced in `1.1_build_data.do`.
- The program `analysis/scripts/code/3.1_build_data_1960.do`: modifies `1.1_build_data.do` to use non-wage income from 1960 rather than 1950 to predict non-wage income in 1940.
- The program `analysis/scripts/code/3.2_build_data_by_race.do`: modifies `1.1_build_data.do` to interact predictor variables with indicators for race when predicting pre-1940 income.
- The program `analysis/scripts/code/3.3_build_data_with_kids.do`: modifies `1.1_build_data.do` to include income earned at ages 14 and 15 in the computation of lifetime earnings.
- The program `analysis/scripts/code/3.4_build_data_cwscore_with_kids.do`: modifies `1.1_build_data.do` to use occupational income score rather than predicted individual income as the input to estimates of lifetime earnings.
- The program `analysis/scripts/code/4.1_run_analysis_robustness.do`: generates the data series plotted in Figure 9 based on the robustness analysis datasets produced in `3.1_build_data_1960.do` to `3.4_build_data_cwscore_with_kids.do`.

### License for Code

The code is licensed under a MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Instructions to Replicators

To perform a clean run:

1. Be sure to have downloaded the publicly available IPUMS data that we are not allowed to redistribute:
    - The extract from the 1900 full count census must be downloaded in `.dta` format to `analysis/raw/ipums/ipums_1900_100_pct/` 
    - The extract from the 1910 full count census must be downloaded in `.dta` format to `analysis/raw/ipums/ipums_1910_100_pct/`
    - The extract from the 1920 full count census must be downloaded in `.dta` format to `analysis/raw/ipums/ipums_1920_100_pct/`
    - The extract from the 1930 full count census must be downloaded in `.dta` format to `analysis/raw/ipums/ipums_1930_100_pct/`
    - The extract from the 1940 full count census must be downloaded in `.dta` format to `analysis/raw/ipums/ipums_1940_100_pct/`

2. Extract the IPUMS data that we are allowed to share:
    - `analysis/raw/ipums/usa_00041.dta.zip`
    - `analysis/raw/ipums/usa_00064.dta.gz`

3. Delete the following two directories:
    - `/processed`
    - `/output`

4. Open the Stata project `bw-lifetime-earnings-replication.stpr` or make sure the working directory of Stata is the same as the directory in which `bw-lifetime-earnings-replication.stpr` is located.

5. Modify the following lines of the file `0_run_all.do`:
    - Users must specify the path to the installation of R (`Rscript.exe`) on line 59
    - Users must specify the path to the relevant application for unzipping files on line 60

6. Run the file `0_run_all.do`

## List of tables and programs

The provided code reproduces:

- All tables and figures in the paper

| Figure/Table # | Program                                         | Line Numbers | Output File                                           |
|-----------|------------------------------------------------------|---------|------------------------------------------------------------|
| Table 1   | analysis/scripts/code/2.1_run_analysis.do            | 217-225 | table_1_wages_living.tex                                   |
| Table 2   | analysis/scripts/code/2.1_run_analysis.do            | 438-450 | table_2_wages_lifetime_discount_100.tex                    |
| Table 3   | analysis/scripts/code/2.1_run_analysis.do            | 438-450 | table_3_wages_lifetime_discount_096.tex                    |
| Table 4   | analysis/scripts/code/2.1_run_analysis.do            | 470-478 | table_4_wages_lifetime_gaps_discount_100.tex               |
| Table 5   | analysis/scripts/code/2.1_run_analysis.do            | 470-478 | table_5_wages_lifetime_gaps_discount_096.tex               |
| Figure 1  | analysis/scripts/code/2.1_run_analysis.do            | 024-035 | figure_1_survivorship_age30_by_race.png                    |
| Figure 2  | analysis/scripts/code/2.1_run_analysis.do            | 049-060 | figure_2_infant_mortality_by_race.png                      |
| Figure 3  | analysis/scripts/code/2.1_run_analysis.do            | 086-097 | figure_3_life_expectancy_by_race.png                       |
| Figure 4a | analysis/scripts/code/2.1_run_analysis.do            | 146-158 | figure_4a_bw_ratio_incwage_by_age.png                      |
| Figure 4b | analysis/scripts/code/2.1_run_analysis.do            | 117-129 | figure_4b_bw_ratio_incwage_by_cohort.png                   |
| Figure 5a | analysis/scripts/code/2.1_run_analysis.do            | 494-509 | figure_5a_wages_lifetime_gaps_discount_100.png             |
| Figure 5b | analysis/scripts/code/2.1_run_analysis.do            | 494-509 | figure_5b_wages_lifetime_gaps_discount_096.png             |
| Figure 6a | analysis/scripts/code/2.1_run_analysis.do            | 170-180 | figure_6a_birthcounts_blacks.png                           |
| Figure 6b | analysis/scripts/code/2.1_run_analysis.do            | 183-193 | figure_6b_birthcounts_whites.png                           |
| Figure 7a | analysis/scripts/code/2.1_run_analysis.do            | 523-537 | figure_7a_utility_by_race_discount_100.png                 |
| Figure 7b | analysis/scripts/code/2.1_run_analysis.do            | 555-566 | figure_7b_utility_gaps_discount_100.png                    |
| Figure 8a | analysis/scripts/code/2.1_run_analysis.do            | 523-537 | figure_8a_utility_by_race_discount_096.png                 |
| Figure 8b | analysis/scripts/code/2.1_run_analysis.do            | 555-566 | figure_8b_utility_gaps_discount_096.png                    |
| Figure 9a | analysis/scripts/code/4.1_run_analysis_robustness.do | 276-289 | figure_9a_wages_lifetime_gaps_robustness_discount_100.png  |
| Figure 9b | analysis/scripts/code/4.1_run_analysis_robustness.do | 313-326 | figure_9b_utility_gaps_robustness_discount_096.png         |

## Data citations

Arias, Elizabeth (2015) "United States Life Tables, 2011," National Vital Statistics Reports, Vol. 64, No. 11, pp. 1–63, Hyattsville, MD: National Center for Health Statistics.

Collins, William J. and Marianne H. Wanamaker (2022) "African American Intergenerational Economic Mobility since 1880," American Economic Journal: Applied Economics, Vol. 14, No. 3, pp. 84–117.

Hamilton, Brady E., Paul D. Sutton, and Stephanie J. Ventura (2003) “Revised birth and fertility rates for the 1990s and new rates for Hispanic populations, 2000 and 2001: United States,” National Vital Statistics Reports: From the Centers for Disease Control and Prevention, National Center for Health Statistics, National Vital Statistics System, Vol. 51, No. 12, pp. 1–94.

Karger, Ezra and Anthony Wray. (2024) "The Black-White Lifetime Earnings Gap." Forthcoming at _Explorations in Economic History_. 101629. [https://doi.org/10.1016/j.eeh.2024.101629](https://doi.org/10.1016/j.eeh.2024.101629).

Karger, Ezra and Anthony Wray. (2024) Data and Code for: The Black-White Lifetime Earnings Gap. Ann Arbor, MI: Inter-university Consortium for Political and Social Research [distributor], 2024-10-22. [https://doi.org/10.3886/E209621V1](https://doi.org/10.3886/E209621V1).

National Center for Health Statistics (2015) "NCHS - Death rates and life expectancy at birth."

Ruggles, Steven, Sarah Flood, Matthew Sobek, Daniel Backman, Annie Chen, Grace Cooper, Stephanie Richards, Renae Rodgers, and Megan Schouweiler. IPUMS USA: Version 15.0 [dataset]. Minneapolis, MN: IPUMS, 2024a. [https://doi.org/10.18128/D010.V15.0](https://doi.org/10.18128/D010.V15.0).

Ruggles, Steven, Matt A. Nelson, Matthew Sobek, Catherine A. Fitch, Ronald Goeken, J. David Hacker, Evan Roberts, and J. Robert Warren. IPUMS Ancestry Full Count Data: Version 4.0 [dataset]. Minneapolis, MN: IPUMS, 2024b. [https://doi.org/10.18128/D014.V4.0](https://doi.org/10.18128/D014.V4.0).

Tax Foundation (2013) "Federal Individual Income Tax Rates History, Nominal Dollars, Income Years 1913-2013."

Tax Policy Center (2015) "U.S. Individual Income Tax: Personal Exemptions and Lowest and Highest Tax Bracket, Tax Rates and Tax Base for Regular Tax, Tax Years 1913-2015."

United States. Bureau of the Census (1975) _Historical statistics of the United States, Colonial times to 1970_, No. 93: US Department of Commerce, Bureau of the Census.

Ward, Zachary (2023) "Intergenerational Mobility in American History: Accounting for Race and Measurement Error," American Economic Review, Vol. 113, No. 12, pp. 3213–3248.

## Package Citations

### Stata

Daniel Bischof, 2016. "BLINDSCHEMES: Stata module to provide graph schemes sensitive to color vision deficiency," Statistical Software Components S458251, Boston College Department of Economics, revised 07 Aug 2020.

Tony Brady, 1998. "UNIQUE: Stata module to report number of unique values in variable(s)," Statistical Software Components S354201, Boston College Department of Economics, revised 18 Jun 2020.

Mauricio Caceres Bravo, 2018. "GTOOLS: Stata module to provide a fast implementation of common group commands," Statistical Software Components S458514, Boston College Department of Economics, revised 05 Dec 2022.

Sergio Correia, 2016. "FTOOLS: Stata module to provide alternatives to common Stata commands optimized for large datasets," Statistical Software Components S458213, Boston College Department of Economics, revised 21 Aug 2023.

Ben Jann, 2004 "ESTOUT: Stata module to make regression tables," Statistical Software Components S439301, Boston College Department of Economics, revised 12 Feb 2023.

David Molitor & Julian Reif, 2019. "RSCRIPT: Stata module to call an R script from Stata," Statistical Software Components S458644, Boston College Department of Economics, revised 03 Jun 2023.

Robert Picard, 2016. "RANGEJOIN: Stata module to form pairwise combinations if a key variable is within range," Statistical Software Components S458162, Boston College Department of Economics, revised 15 Apr 2021.

Robert Picard & Nicholas J. Cox & Roberto Ferrer, 2016. "RANGESTAT: Stata module to generate statistics using observations within range," Statistical Software Components S458161, Boston College Department of Economics, revised 11 May 2017.

Ian Watson, 2004. "TABOUT: Stata module to export publication quality cross-tabulations," Statistical Software Components S447101, Boston College Department of Economics, revised 16 Mar 2019.

---

## Acknowledgements

Some content on this page was copied from [Hindawi](https://www.hindawi.com/research.data/#statement.templates). Other content was adapted  from [Fort (2016)](https://doi.org/10.1093/restud/rdw057), Supplementary data, with the author's permission.
