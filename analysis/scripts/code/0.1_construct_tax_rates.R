###################################################################################

# Tax rate data downloaded from this PDF: https://files.taxfoundation.org/legacy/docs/fed_individual_rate_history_nominal.pdf
# then exported to an XLSX file using Adobe Acrobat and saved as a CSV.

#Personal exemptions are downloaded from this PDF: http://www.taxpolicycenter.org/sites/default/files/legacy/taxfacts/content/PDF/historical_parameters.pdf
# and I used the same conversion process to turn this PDF into a CSV.

###################################################################################
# Clear working directory/RAM
rm(list=ls())
###################################################################################
# Load packages
library(data.table)
library(dplyr)
library(haven)
library(plyr)
library(readr)
library(stringr)
library(tidyr)
###################################################################################

options(stringsAsFactors=FALSE)

taxrates = data.table(read.csv("analysis/raw/fed/fed_individual_rate_history_nominal.csv"))
personal_exemptions = read_csv("analysis/raw/fed/fed_personal_exemptions.csv",skip=7, locale = locale(encoding = "windows-1252"))

# Clean person exemption dataset:
personal_exemptions=personal_exemptions[,c(1,3,5,7)]
names(personal_exemptions)=c("year","exemption_single","exemption_married","exemption_dependent")
personal_exemptions=personal_exemptions[which(personal_exemptions$exemption_single!=""),]

personal_exemptions$exemption_dependent <- as.numeric(gsub(",","",personal_exemptions$exemption_dependent))
personal_exemptions$year <- as.numeric(personal_exemptions$year)

personal_exemptions$exemption_dependent[which(is.na(personal_exemptions$exemption_dependent))]=0


#Clean tax rate dataset

#First, some tax bracket data is offset to column X (eg. 1940), move those values to X.1.
#Similar offsets occur in a few other places
taxrates=taxrates[X.1=="",X.1:=X]
taxrates=taxrates[X.3=="",X.3:=X.4]
taxrates=taxrates[X.7=="",X.7:=X.5]
taxrates=taxrates[X.26=="",X.26:=X.27]


taxrates=taxrates[,c(1,3,5,9,11,13,14,17,18,21,24,25,28)]

taxrates[as.numeric(substr(Federal.Individual.Income.Tax.Rates.History,1,4))>1900,
         year:=as.numeric(substr(Federal.Individual.Income.Tax.Rates.History,1,4))]

taxrates[as.numeric(substr(X.12,1,4))>1500,year:=as.numeric(substr(X.12,1,4))]
taxrates[as.numeric(substr(X.11,1,4))>1500,year:=as.numeric(substr(X.11,1,4))]


#Fill year variable down and subset to 1913-2013
taxrates = taxrates %>% fill(year)
taxrates = taxrates[year>=1913,]


#Check that we have all years between 1913 and 2013
length(unique(taxrates$year[which(!is.na(taxrates$year))]))
length(1913:2013)


#Delete last filler variable, divide dataset into three pieces, label, and append.
taxrates$X.11=NULL

married_joint   =cbind(taxrates[,c(1,2,3,13)],"married_joint")
married_separate=cbind(taxrates[,c(4,5,6,13)],"married_separate")
single          =cbind(taxrates[,c(7,8,9,13)],"single")
household_head  =cbind(taxrates[,c(10,11,12,13)],"household_head")

taxrates=rbind(married_joint,married_separate,single,household_head,use.names=FALSE)
names(taxrates)=c("rate","bracket_low","bracket_high","year","type")

rm(list=setdiff(ls(),c("taxrates","personal_exemptions","basepath")))


#Now clean tax rate dataset, extracting rate and bracket amounts
taxrates=taxrates[grepl("%",rate)==TRUE,]

#Remove extra whitespace
taxrates$rate = gsub("\\s+", " ", str_trim(taxrates$rate))

#For some years, tax bracket information is all in the rate column. When that
# happens, extract these new values
extracted_strings=rbind.fill(lapply(strsplit(taxrates$rate," ",fixed=TRUE), function(X) data.frame(t(X))))

missingrows=which(taxrates$bracket_low=="")

taxrates$rate[missingrows]        =extracted_strings[missingrows,2]
taxrates$bracket_low[missingrows] =extracted_strings[missingrows,3]
taxrates$bracket_high[missingrows]=extracted_strings[missingrows,4]


#Remove punctuation from numeric variables
taxrates$rate = as.numeric(gsub('[^0-9\\.]', '', taxrates$rate))
taxrates$bracket_low = as.numeric(gsub('[^0-9\\.]', '', taxrates$bracket_low))
taxrates$bracket_high = as.numeric(gsub('[^0-9\\.]', '', taxrates$bracket_high))

taxrates[is.na(bracket_high),bracket_high:=100000000]


#Construct amount paid variable if someone is in the given bracket
taxrates=taxrates[order(year,type,bracket_low)] 
taxrates$amtpaid_prev_brackets=0

for (row in 2:nrow(taxrates)){
  if (taxrates$year[row]==taxrates$year[row-1] & taxrates$type[row]==taxrates$type[row-1]){
    
    taxrates$amtpaid_prev_brackets[row]=taxrates$amtpaid_prev_brackets[row-1]+
      (taxrates$bracket_high[row-1]-taxrates$bracket_low[row-1])*taxrates$rate[row-1]/100
    }
}


#If single tax brackets exist, use them. If not, use married filed separately.
# if that doesn't exist, use married filed jointly.
finaldataset=taxrates[year==1913,]

for (yearval in 1914:2013){
  
  annualdata=taxrates[year==yearval,]
  if ("single" %in% unique(annualdata$type)){
    finaldataset=rbind(finaldataset,annualdata[type=="single",])
  }

  else if ("married_separate" %in% unique(annualdata$type)){
    finaldataset=rbind(finaldataset,annualdata[type=="married_separate",])
  }
  
  else if ("married_joint" %in% unique(annualdata$type)){
    finaldataset=rbind(finaldataset,annualdata[type=="married_joint",])
  }
  
  else if ("household_head" %in% unique(annualdata$type)){
    finaldataset=rbind(finaldataset,annualdata[type=="household_head",])
  }
  
}

#Check which types we are using in all years.
tempcheck=unique(finaldataset[,c("year","type")])


#Extrapolate personal exemptions backward from 1913 to 1910 and forward from 2015 to 2016
temprow=personal_exemptions[which(personal_exemptions$year==1913),]
temprow$year=1910
personal_exemptions=rbind(personal_exemptions,temprow)

temprow=personal_exemptions[which(personal_exemptions$year==2015),]
temprow$year=2016
personal_exemptions=rbind(personal_exemptions,temprow)

temprow=finaldataset[year==1913,]
temprow$year=1910
finaldataset=rbind(finaldataset,temprow)

for (yearval in 2014:2016){
  temprow=finaldataset[year==2013,]
  temprow$year=yearval
  finaldataset=rbind(finaldataset,temprow)
}


#Output as Stata dataset
write_dta(finaldataset,"analysis/processed/intermediate/fed/taxrates.dta",version = 14)
write_dta(personal_exemptions,"analysis/processed/intermediate/fed/personal_exemptions.dta",version=14)
