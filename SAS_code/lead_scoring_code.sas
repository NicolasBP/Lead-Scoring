/* Generated Code (IMPORT) */
/* Source File: all_transactions.csv */
/* Source Path: /sscc/home/n/nba455/sasuser.v94/PREDICT490 */
/* Code generated on: Saturday, March 12, 2016 8:48:59 PM */

%web_drop_table(WORK.IMPORT);


FILENAME REFFILE "/sscc/home/n/nba455/sasuser.v94/PREDICT490/all_transactions.csv" TERMSTR=CR;

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT;
	GETNAMES=YES;
	DATAROW=2;
	GUESSINGROWS=700;
RUN;

PROC CONTENTS DATA=WORK.IMPORT; RUN;


%web_open_table(WORK.IMPORT);

data TEMPFILE;
set WORK.IMPORT;
run;


proc means data = TEMPFILE n nmiss min mean median max;
run;


data PREQUAL;
   set TEMPFILE;
   if INDEX = '.' then delete;
   /*Correct some recording errors*/
   if(TransactionID = '0770L') then SqFt = 1499;
   if(TransactionID = '4209C') then PurchasePrice = 221000;
   if(TransactionID = '0605R') then PurchasePrice = 120095;
   if(TransactionID = '0835P') then PurchasePrice = 50000;
   
   LEAD_SCORE = LoanAmount * Closed;
   LEAD_SCORE = LEAD_SCORE/(540000.00-15960.00)*100;
   if(LoanAmount > 540000.00 or LoanAmount < 15960.00) then LEAD_SCORE = -1;
   
run;


data RCL;
set PREQUAL;
if(RepairCreditLine > 0);
LOG_RepairCreditLine = LOG10(RepairCreditLine);
run;

proc corr data = RCL best=20;
	with LOG_RepairCreditLine;
run;


proc univariate data=RCL plots;
var LOG_RepairCreditLine;
histogram LOG_RepairCreditLine;
run;


proc reg data = RCL;
model LOG_RepairCreditLine = ClosingDate
							SqFt
							CashReserves
							MedianSalesPrice
							PurchasePrice
							MedianSalesPriceSqFt
							Bath
							MarketHealthIndex
							Closed
							Beds
							Quarter
							RegionName
							DaysOnMarket
							RepeatBorrower
							CompletedProperties / selection = stepwise vif;
run;




data PREQUAL;
set PREQUAL;
	
	/*Create variable transformation to impute with linear regression*/
   if(RepairCreditLine > 0) then LOG_RepairCreditLine = LOG10(RepairCreditLine);
   if(RepairCreditLine = 0) then LOG_RepairCreditLine = 1;
   M_EstimatedRepairs = 0;
   IMP_LOG_EstimatedRepairs = LOG_RepairCreditLine;
   /*Impute RepairCreditLine where RepairCreditLine is missing or RepairCreditLine is 0 (cases were the Borrower chose to pay for repairs out of pocket)*/
	if(missing(IMP_LOG_EstimatedRepairs) or IMP_LOG_EstimatedRepairs = 1) then do;
       /*Based on the fact that Loan Amounts are usually 90% of the PurchasePrice + EstimatedRepairs*/
       /*IMP_EstimatedRepairs = (LoanAmount - PurchasePrice * 0.90)/0.90;
       if(IMP_EstimatedRepairs < 0) then IMP_EstimatedRepairs = 0;*/
       
       IMP_LOG_EstimatedRepairs = -1.736 +
								0.00000000337 * ClosingDate +
								0.00009521 * SqFt +
								0.000000405 * CashReserves +
								0.000000763 * MedianSalesPrice +
								-0.03903 * Beds;
       if(IMP_LOG_EstimatedRepairs < 1) then IMP_LOG_EstimatedRepairs = 1;
       
       
		M_EstimatedRepairs = 1;

	end;
	
	
	M_PurchasePrice = 0;
	IMP_PurchasePrice = PurchasePrice;
	/*if(missing(IMP_PurchasePrice) and not missing(LoanAmount)) then do;*/
       /*Based on the fact that Loan Amounts are usually 90% of the PurchasePrice + EstimatedRepairs*/
       /*IMP_PurchasePrice = (LoanAmount - 0.90 * IMP_EstimatedRepairs)/0.90;
       if(IMP_PurchasePrice < 0) then IMP_PurchasePrice = 0;
       M_PurchasePrice = 1;
	end;*/
	if(missing(IMP_PurchasePrice)) then do;
		/*Impute with median of observations*/
		IMP_PurchasePrice = 76000;
		M_PurchasePrice = 1;
	end;
   
   /*Rule out leads out of the scope of the model*/
   /*P_LEAD_SCORE = 1;*/ /*Create score prediction variable. Scores range from -1 to 100*/
	/*Conditions for leads that are not necessarily disqualified, but are outside of the scope of this model*/
   /*if(LoanAmount > 540000.00 or LoanAmount < 15960.00) then P_LEAD_SCORE = -1;
   if(IMP_PurchasePrice > 1000000) then P_LEAD_SCORE = -1;*/
	
run;

data PREQUAL;
set PREQUAL;
	if(missing(IMP_LOG_EstimatedRepairs)) then do;
		/*Impute with median of observations where RepairCreditLine > 0*/
		IMP_LOG_EstimatedRepairs = 4.342422680822207;
		M_EstimatedRepairs = 1;
	end;
run;

proc univariate data =PREQUAL plots;
	var IMP_LOG_EstimatedRepairs RepairCreditLine;
	histogram IMP_LOG_EstimatedRepairs RepairCreditLine;
run;

data PREQUAL;
set PREQUAL;
if LEAD_SCORE > 0;
drop RepairCreditLine;
drop PurchasePrice;
drop LoanAmount_N;
drop LOG_RepairCreditLine;
run;


proc means data = PREQUAL nmiss min median mean max;
run;




data PREQUAL;
set PREQUAL;
IMP_CashReserves = CashReserves;
M_CashReserves = 0;
if(missing(CashReserves)) then do;
       IMP_CashReserves = 50000; 
       M_CashReserves = 1;
end;
drop CashReserves;

IMP_Beds = Beds;
M_Beds = 0;
if(missing(Beds))then do;
	IMP_Beds = 3;
	M_Beds = 1;
end;
drop Beds;

IMP_Bath = Bath;
M_Bath = 0;
if(missing(Bath)) then do;
	IMP_Bath = 2;
	M_Bath = 1;
end;
drop Bath;

IMP_SqFt = SqFt;
M_SqFt = 0;
if(missing(SqFt)) then do;
	IMP_SqFt = 1648;
	M_SqFt = 1;
end;
drop SqFt;
run;



data PREQUAL;
set PREQUAL;
IMP_YearsOfExperience = YearsOfExperience;
M_YearsOfExperience = 0;
/***************Decision Tree for Years of Experience***************/
if(missing(IMP_YearsOfExperience) and not missing(IMP_CashReserves) and not missing(Closed)) then do;
M_YearsOfExperience = 1;
if(IMP_CashReserves <= 95000) then do;
    if(IMP_CashReserves <= 12000) then do;
        if(IMP_CashReserves <= 9000) then do;
            if(IMP_CashReserves <= 5000) then do;
                if(IMP_CashReserves <= 3800) then IMP_YearsOfExperience = 0;
                if(IMP_CashReserves > 3800) then IMP_YearsOfExperience = 1;
			end;
            if(IMP_CashReserves > 5000) then do;
                if(IMP_CashReserves <= 7000) then IMP_YearsOfExperience = 4;
                if(IMP_CashReserves > 7000) then IMP_YearsOfExperience = 7;
			end;
		end;
        if(IMP_CashReserves > 9000) then IMP_YearsOfExperience = 0;
	end;
    if(IMP_CashReserves > 12000) then do;
        if(Closed <= 0) then do;
            if(IMP_CashReserves <= 44000) then do;
                if(IMP_CashReserves <= 28500) then do;
                    if(IMP_CashReserves <= 20000) then do;
                        if(IMP_CashReserves <= 18000) then IMP_YearsOfExperience = 4;
                        if(IMP_CashReserves > 18000) then IMP_YearsOfExperience = 3;
					end;
                    if(IMP_CashReserves > 20000) then IMP_YearsOfExperience = 0;
				end;
                if(IMP_CashReserves > 28500) then do;
                    if(IMP_CashReserves <= 39000) then do;
                        if(IMP_CashReserves <= 30000) then do;
                            if(IMP_CashReserves <= 29000) then IMP_YearsOfExperience = 1;
                            if(IMP_CashReserves > 29000) then IMP_YearsOfExperience = 0;
						end;
                        if(IMP_CashReserves > 30000) then do;
                            if(IMP_CashReserves <= 33000) then IMP_YearsOfExperience = 20;
                            if(IMP_CashReserves > 33000) then IMP_YearsOfExperience = 2;
						end;
					end;
                    if(IMP_CashReserves > 39000) then IMP_YearsOfExperience = 0;
				end;
			end;
            if(IMP_CashReserves > 44000) then do;
                if(IMP_CashReserves <= 57000) then do;
                    if(IMP_CashReserves <= 47000) then IMP_YearsOfExperience = 12;
                    if(IMP_CashReserves > 47000) then IMP_YearsOfExperience = 20;
				end;
                if(IMP_CashReserves > 57000) then do;
                    if(IMP_CashReserves <= 70000) then do;
                        if(IMP_CashReserves <= 65443) then do;
                            if(IMP_CashReserves <= 60000) then IMP_YearsOfExperience = 5;
                            if(IMP_CashReserves > 60000) then IMP_YearsOfExperience = 4;
						end;
                        if(IMP_CashReserves > 65443) then IMP_YearsOfExperience = 1;
					end;
                    if(IMP_CashReserves > 70000) then do;
                        if(IMP_CashReserves <= 80000) then IMP_YearsOfExperience = 0;
                        if(IMP_CashReserves > 80000) then IMP_YearsOfExperience = 5;
					end;
				end;
			end;
		end;
        if(Closed > 0) then do;
            if(IMP_CashReserves <= 60000) then do;
                if(IMP_CashReserves <= 31000) then do;
                    if(IMP_CashReserves <= 26000) then do;
                        if(IMP_CashReserves <= 23000) then IMP_YearsOfExperience = 0;
                        if(IMP_CashReserves > 23000) then IMP_YearsOfExperience = 2;
					end;
                    if(IMP_CashReserves > 26000) then do;
                        if(IMP_CashReserves <= 29000) then do;
                            if(IMP_CashReserves <= 27500) then IMP_YearsOfExperience = 6;
                            if(IMP_CashReserves > 27500) then IMP_YearsOfExperience = 1;
						end;
                        if(IMP_CashReserves > 29000) then IMP_YearsOfExperience = 0;
					end;
				end;
                if(IMP_CashReserves > 31000) then IMP_YearsOfExperience = 0;
			end;
            if(IMP_CashReserves > 60000) then do;
                if(IMP_CashReserves <= 83988) then do;
                    if(IMP_CashReserves <= 75400) then do;
                        if(IMP_CashReserves <= 66787.32) then do;
                            if(IMP_CashReserves <= 63700) then do;
                                if(IMP_CashReserves <= 62000) then IMP_YearsOfExperience = 4;
                                if(IMP_CashReserves > 62000) then IMP_YearsOfExperience = 7;
							end;
                            if(IMP_CashReserves > 63700) then IMP_YearsOfExperience = 1;
						end;
                        if(IMP_CashReserves > 66787.32) then IMP_YearsOfExperience = 0;
					end;
                    if(IMP_CashReserves > 75400) then do;
                        if(IMP_CashReserves <= 78000) then IMP_YearsOfExperience = 4;
                        if(IMP_CashReserves > 78000) then IMP_YearsOfExperience = 1;
					end;
				end;
                if(IMP_CashReserves > 83988) then do;
                    if(IMP_CashReserves <= 90000) then IMP_YearsOfExperience = 0;
                    if(IMP_CashReserves > 90000) then IMP_YearsOfExperience = 6;
				end;
			end;
		end;
	end;
end;
if(IMP_CashReserves > 95000) then do;
    if(IMP_CashReserves <= 361000) then do;
        if(IMP_CashReserves <= 230000) then do;
            if(IMP_CashReserves <= 130000) then do;
                if(Closed <= 0) then do;
                    if(IMP_CashReserves <= 100200) then IMP_YearsOfExperience = 2;
                    if(IMP_CashReserves > 100200) then IMP_YearsOfExperience = 0;
				end;
                if(Closed > 0) then do;
                    if(IMP_CashReserves <= 115000) then IMP_YearsOfExperience = 0;
                    if(IMP_CashReserves > 115000) then do;
                        if(IMP_CashReserves <= 120000) then IMP_YearsOfExperience = 1;
                        if(IMP_CashReserves > 120000) then IMP_YearsOfExperience = 8;
					end;
				end;
			end;
            if(IMP_CashReserves > 130000) then do;
                if(IMP_CashReserves <= 165000) then do;
                    if(IMP_CashReserves <= 150000) then do;
                        if(IMP_CashReserves <= 149000) then do;
                            if(IMP_CashReserves <= 140000) then IMP_YearsOfExperience = 2;
                            if(IMP_CashReserves > 140000) then IMP_YearsOfExperience = 0;
						end;
                        if(IMP_CashReserves > 149000) then IMP_YearsOfExperience = 5;
					end;
                    if(IMP_CashReserves > 150000) then do;
                        if(IMP_CashReserves <= 160000) then IMP_YearsOfExperience = 3;
                        if(IMP_CashReserves > 160000) then IMP_YearsOfExperience = 10;
					end;
				end;
                if(IMP_CashReserves > 165000) then do;
                    if(IMP_CashReserves <= 190000) then do;
                        if(IMP_CashReserves <= 170000) then IMP_YearsOfExperience = 2;
                        if(IMP_CashReserves > 170000) then IMP_YearsOfExperience = 10;
					end;
                    if(IMP_CashReserves > 190000) then do;
                        if(IMP_CashReserves <= 200000) then IMP_YearsOfExperience = 5;
                        if(IMP_CashReserves > 200000) then IMP_YearsOfExperience = 2;
					end;
				end;
			end;
		end;
        if(IMP_CashReserves > 230000) then do;
            if(IMP_CashReserves <= 285000) then do;
                if(IMP_CashReserves <= 272760) then IMP_YearsOfExperience = 20;
                if(IMP_CashReserves > 272760) then IMP_YearsOfExperience = 8;
			end;
            if(IMP_CashReserves > 285000) then do;
                if(Closed <= 0) then do;
                    if(IMP_CashReserves <= 300000) then IMP_YearsOfExperience = 0;
                    if(IMP_CashReserves > 300000) then IMP_YearsOfExperience = 5;
				end;
                if(Closed > 0) then IMP_YearsOfExperience = 10;
			end;
		end;
	end;
    if(IMP_CashReserves > 361000) then do;
        if(IMP_CashReserves <= 633317.79) then do;
            if(IMP_CashReserves <= 500000) then do;
                if(IMP_CashReserves <= 442670) then IMP_YearsOfExperience = 2;
                if(IMP_CashReserves > 442670) then IMP_YearsOfExperience = 0;
			end;
            if(IMP_CashReserves > 500000) then IMP_YearsOfExperience = 3;
		end;
        if(IMP_CashReserves > 633317.79) then do;
            if(IMP_CashReserves <= 800000) then IMP_YearsOfExperience = 10;
            if(IMP_CashReserves > 800000) then IMP_YearsOfExperience = 1;
		end;
	end;
end;
end;
drop YearsOfExperience;
run;

data PREQUAL;
set PREQUAL;

/**************Decision Tree to impute CompletedProperties**************/
M_CompletedProperties = 0;
IMP_CompletedProperties = CompletedProperties;
if(missing(IMP_CompletedProperties) and not missing(IMP_CashReserves) and not missing(IMP_YearsOfExperience) and not missing(RepeatBorrower)) then do;
M_CompletedProperties = 1;
if(IMP_YearsOfExperience <= 1) then do;
    if(RepeatBorrower <= 0) then do;
        if(IMP_CashReserves <= 250000) then IMP_CompletedProperties = 0;
        if(IMP_CashReserves > 250000)then do;
            if(IMP_CashReserves <= 500000) then IMP_CompletedProperties = 50;
            if(IMP_CashReserves > 500000) then IMP_CompletedProperties = 0;
		end;
	end;
    if(RepeatBorrower > 0)then do;
        if(IMP_YearsOfExperience <= 0) then IMP_CompletedProperties = 0;
        if(IMP_YearsOfExperience > 0) then IMP_CompletedProperties = 7;
	end;
end;
if(IMP_YearsOfExperience > 1) then do;
    if(RepeatBorrower <= 0) then do;
        if(IMP_YearsOfExperience <= 7) then do;
            if(IMP_YearsOfExperience <= 5) then do;
                if(IMP_YearsOfExperience <= 2) then do;
                    if(IMP_CashReserves <= 32000) then do;
                        if(IMP_CashReserves <= 28000) then do;
                            if(IMP_CashReserves <= 22000) then IMP_CompletedProperties = 0;
                            if(IMP_CashReserves > 22000) then IMP_CompletedProperties = 1;
						end;
                        if(IMP_CashReserves > 28000) then IMP_CompletedProperties = 4;
					end;
                    if(IMP_CashReserves > 32000) then do;
                        if(IMP_CashReserves <= 205000) then do;
                            if(IMP_CashReserves <= 42000) then do;
                                if(IMP_CashReserves <= 36000) then IMP_CompletedProperties = 2;
                                if(IMP_CashReserves > 36000) then IMP_CompletedProperties = 7;
							end;
                            if(IMP_CashReserves > 42000) then do;
                                if(IMP_CashReserves <= 120000) then do;
                                    if(IMP_CashReserves <= 50167) then IMP_CompletedProperties = 3;
                                    if(IMP_CashReserves > 50167) then do;
                                        if(IMP_CashReserves <= 85000) then IMP_CompletedProperties = 0;
                                        if(IMP_CashReserves > 85000) then IMP_CompletedProperties = 3;
									end;
								end;
                                if(IMP_CashReserves > 120000) then IMP_CompletedProperties = 6;
							end;
						end;
                        if(IMP_CashReserves > 205000) then do;
                            if(IMP_CashReserves <= 409000) then IMP_CompletedProperties = 2;
                            if(IMP_CashReserves > 409000) then IMP_CompletedProperties = 1;
						end;
					end;
				end;
                if(IMP_YearsOfExperience > 2) then do;
                    if(IMP_CashReserves <= 60000) then do;
                        if(IMP_CashReserves <= 42000) then do;
                            if(IMP_CashReserves <= 16000) then do;
                                if(IMP_YearsOfExperience <= 3) then IMP_CompletedProperties = 0;
                                if(IMP_YearsOfExperience > 3) then IMP_CompletedProperties = 2;
							end;
                            if(IMP_CashReserves > 16000) then IMP_CompletedProperties = 0;
						end;
                        if(IMP_CashReserves > 42000) then do;
                            if(IMP_YearsOfExperience <= 4) then IMP_CompletedProperties = 1;
                            if(IMP_YearsOfExperience > 4) then do;
                                if(IMP_CashReserves <= 51000) then IMP_CompletedProperties = 2;
                                if(IMP_CashReserves > 51000) then IMP_CompletedProperties = 4;
							end;
						end;
					end;
                    if(IMP_CashReserves > 60000) then do;
                        if(IMP_YearsOfExperience <= 3) then do;
                            if(IMP_CashReserves <= 272760) then do;
                                if(IMP_CashReserves <= 100200) then IMP_CompletedProperties = 0;
                                if(IMP_CashReserves > 100200) then IMP_CompletedProperties = 25;
							end;
                            if(IMP_CashReserves > 272760) then do;
                                if(IMP_CashReserves <= 500000) then IMP_CompletedProperties = 0;
                                if(IMP_CashReserves > 500000) then IMP_CompletedProperties = 2;
							end;
						end;
                        if(IMP_YearsOfExperience > 3) then IMP_CompletedProperties = 0;
					end;
				end;
			end;
            if(IMP_YearsOfExperience > 5) then do;
                if(IMP_YearsOfExperience <= 6) then do;
                    if(IMP_CashReserves <= 44000) then do;
                        if(Closed <= 0) then IMP_CompletedProperties = 1;
                        if(Closed > 0) then do;
                            if(IMP_CashReserves <= 22000) then IMP_CompletedProperties = 31;
                            if(IMP_CashReserves > 22000) then IMP_CompletedProperties = 4;
						end;
					end;
                    if(IMP_CashReserves > 44000) then do;
                        if(IMP_CashReserves <= 55000) then IMP_CompletedProperties = 3;
                        if(IMP_CashReserves > 55000) then IMP_CompletedProperties = 0;
					end;
				end;
                if(IMP_YearsOfExperience > 6) then do;
                    if(IMP_CashReserves <= 47000) then do;
                        if(IMP_CashReserves <= 38000) then IMP_CompletedProperties = 6;
                        if(IMP_CashReserves > 38000) then IMP_CompletedProperties = 5;
					end;
                    if(IMP_CashReserves > 47000) then do;
                        if(IMP_CashReserves <= 60000) then IMP_CompletedProperties = 7;
                        if(IMP_CashReserves > 60000) then IMP_CompletedProperties = 1;
					end;
				end;
			end;
		end;
        if(IMP_YearsOfExperience > 7) then do;
            if(IMP_YearsOfExperience <= 9) then do;
                if(Closed <= 0) then do;
                    if(IMP_CashReserves <= 33000) then IMP_CompletedProperties = 1;
                    if(IMP_CashReserves > 33000) then IMP_CompletedProperties = 7;
				end;
                if(Closed > 0) then do;
                    if(IMP_YearsOfExperience <= 8) then do;
                        if(IMP_CashReserves <= 75000) then do;
                            if(IMP_CashReserves <= 45000) then IMP_CompletedProperties = 8;
                            if(IMP_CashReserves > 45000) then IMP_CompletedProperties = 5;
						end;
                        if(IMP_CashReserves > 75000) then IMP_CompletedProperties = 0;
					end;
                    if(IMP_YearsOfExperience > 8) then do;
                        if(IMP_CashReserves <= 82000) then IMP_CompletedProperties = 12;
                        if(IMP_CashReserves > 82000) then IMP_CompletedProperties = 3;
					end;
				end;
			end;
            if(IMP_YearsOfExperience > 9) then do;
                if(IMP_CashReserves <= 170000) then IMP_CompletedProperties = 0;
                if(IMP_CashReserves > 170000) then do;
                    if(IMP_CashReserves <= 318000) then IMP_CompletedProperties = 0;
                    if(IMP_CashReserves > 318000) then IMP_CompletedProperties = 3;
				end;
			end;
		end;
	end;
    if(RepeatBorrower > 0) then do;
        if(IMP_YearsOfExperience <= 8) then do;
            if(IMP_CashReserves <= 85000) then do;
                if(IMP_CashReserves <= 40000) then do;
                    if(IMP_CashReserves <= 34000) then IMP_CompletedProperties = 1;
                    if(IMP_CashReserves > 34000) then IMP_CompletedProperties = 2;
				end;
                if(IMP_CashReserves > 40000) then do;
                    if(IMP_CashReserves <= 50000) then IMP_CompletedProperties = 15;
                    if(IMP_CashReserves > 50000) then IMP_CompletedProperties = 5;
				end;
			end;
            if(IMP_CashReserves > 85000) then do;
                if(IMP_CashReserves <= 120000) then do;
                    if(IMP_YearsOfExperience <= 4) then IMP_CompletedProperties = 7;
                    if(IMP_YearsOfExperience > 4) then IMP_CompletedProperties = 18;
				end;
                if(IMP_CashReserves > 120000) then do;
                    if(IMP_CashReserves <= 140000) then IMP_CompletedProperties = 4;
                    if(IMP_CashReserves > 140000) then IMP_CompletedProperties = 2;
				end;
			end;
		end;
        if(IMP_YearsOfExperience > 8) then do;
            if(IMP_YearsOfExperience <= 13) then IMP_CompletedProperties = 15;
            if(IMP_YearsOfExperience > 13) then do;
                if(IMP_YearsOfExperience <= 20) then IMP_CompletedProperties = 0;
                if(IMP_YearsOfExperience > 20) then IMP_CompletedProperties = 50;
			end;
		end;
	end;
end;
end;
drop CompletedProperties;
run;





proc means data = PREQUAL N nmiss min max;
run;

proc corr data = PREQUAL best=20;
 with MedianSalesPriceSqFt;
run;

data PREQUAL;
set PREQUAL;
CAP_MedianSalesPriceSqFt = MedianSalesPriceSqFt;
if(CAP_MedianSalesPriceSqFt > 215) then CAP_MedianSalesPriceSqFt = 215;
run;



proc univariate data=PREQUAL plots;
       var CAP_MedianSalesPriceSqFt;
       histogram CAP_MedianSalesPriceSqFt;
run;



proc reg data = PREQUAL;
model CAP_MedianSalesPriceSqFt = MedianSalesPrice MarketHealthIndex;
output cookd=cooksd_MSPSqFt;
run;

data PREQUAL;
set PREQUAL;
drop cooksd_MSPSqFt;
run;

data PREQUAL;
set PREQUAL;
IMP_MedianSalesPriceSqFt = CAP_MedianSalesPriceSqFt;
M_MedianSalesPriceSqFt = 0;
if(missing(CAP_MedianSalesPriceSqFt) and not missing(MedianSalesPrice) and not missing(MarketHealthIndex)) then do;
M_MedianSalesPriceSqFt = 1;
IMP_MedianSalesPriceSqFt = 31.39949 +
							0.00032010 * MedianSalesPrice +
							3.98392 * MarketHealthIndex;
end;
if(missing(CAP_MedianSalesPriceSqFt) and (missing(MedianSalesPrice) or missing(MarketHealthIndex))) then do;
/*Impute with median*/
M_MedianSalesPriceSqFt = 1;
IMP_MedianSalesPriceSqFt = 88.2242;
end;

drop MedianSalesPriceSqFt;
drop CAP_MedianSalesPriceSqFt;

run;

proc univariate data=PREQUAL plots;
       var IMP_MedianSalesPriceSqFt;
       histogram IMP_MedianSalesPriceSqFt;
run;


proc univariate data = PREQUAL plots;
	var DaysOnMarket;
	histogram DaysOnMarket;
run;

data PREQUAL;
set PREQUAL;
M_DaysOnMarket = 0;
IMP_DaysOnMarket = DaysOnMarket;
if(missing(DaysOnMarket)) then do;
	M_DaysOnMarket = 1;
	IMP_DaysOnMarket = 95.00000;
end;
drop DaysOnMarket;
run;



proc means data = PREQUAL N nmiss min max;
run;




proc corr data=PREQUAL best=20;
	with ARV;
run;



data PREQUAL;
set PREQUAL;
LOG_ARV = LOG10(ARV);
Quarter1 = 0;
Quarter2 = 0;
Quarter3 = 0;
if(Quarter = 1) then Quarter1 = 1;
if(Quarter = 2) then Quarter2 = 1;
if(Quarter = 3) then Quarter3 = 1;
drop ARV;
run;

proc univariate data = PREQUAL plots;
	var LOG_ARV;
	histogram LOG_ARV;
run;

proc reg data=PREQUAL;
model LOG_ARV = IMP_PurchasePrice M_PurchasePrice MedianSalesPrice IMP_SqFt IMP_LOG_EstimatedRepairs M_EstimatedRepairs IMP_CashReserves M_CashReserves /*IMP_Bath*/ IMP_Beds Quarter1 Quarter2 Quarter3 / selection = stepwise VIF;
run;

data PREQUAL;
set PREQUAL;
IMP_LOG_ARV = LOG_ARV;
M_LOG_ARV = 0;
if(missing(LOG_ARV))then do;
	M_LOG_ARV = 1;
	IMP_LOG_ARV = 4.58442 +
					0.00000152 * IMP_PurchasePrice +
					0.00000069 * MedianSalesPrice +
					0.00003325 * IMP_SqFt +
					0.07307 * IMP_LOG_EstimatedRepairs +
					-0.03491 * M_EstimatedRepairs +
					0.00000016 * IMP_CashReserves +
					0.09908 * M_CashReserves +
					-0.04585 * Quarter2;
end;
drop ARV;
drop LOG_ARV;
run;



/*Estimate Loan Amount*/

data PREQUAL;
set PREQUAL;
LOG_LoanAmount = LOG10(LoanAmount);
run;

proc univariate data = PREQUAL plots;
	var LoanAmount LOG_LoanAmount;
	histogram LoanAmount LOG_LoanAmount;
run;

proc corr data = PREQUAL best=20;
	with LOG_LoanAmount;
run;



proc reg data = PREQUAL;
model LOG_LoanAmount = IMP_LOG_ARV
						M_LOG_ARV
						IMP_PurchasePrice
						MedianSalesPrice
						IMP_SqFt
						IMP_MedianSalesPriceSqFt
						ClosingDate
						IMP_Bath
						IMP_Beds
						IMP_LOG_EstimatedRepairs
						MarketHealthIndex
						IMP_CashReserves
						M_YearsOfExperience
						M_CompletedProperties
						M_CashReserves
						M_EstimatedRepairs
						IMP_YearsOfExperience
						M_Bath
						Quarter1 
						Quarter2 
						Quarter3  / selection = stepwise vif;
run;


data LEAD_VALUE;
set PREQUAL;

P_LOG_LoanAmount = 1.42308 +
				0.33721 * IMP_LOG_ARV +
				0.00000055 * IMP_PurchasePrice +
				0.000000739 * MedianSalesPrice +
				0.00003807 * IMP_SqFt +
				0.00049456 * IMP_MedianSalesPriceSqFt +
				0.000000000867 * ClosingDate +
				0.02303 * IMP_Bath +
				0.01239 * IMP_Beds +
				-0.01675 * IMP_LOG_EstimatedRepairs +
				-0.02629 * M_CompletedProperties +
				0.1051 * M_Bath +
				-0.03015 * Quarter1;	
run;


/************************** Likelihood of Closing ***************************/

proc univariate data = LEAD_VALUE plots;
	var Closed;
	histogram Closed;
run;



proc logistic data = LEAD_VALUE;
class Quarter / param=ref;

model Closed (ref="0") = Quarter
				RepeatBorrower
				MarketHealthIndex
				YoY
				MedianSalesPrice
				M_EstimatedRepairs
				IMP_LOG_EstimatedRepairs
				M_PurchasePrice
				IMP_PurchasePrice
				IMP_CashReserves
				M_CashReserves
				IMP_Beds
				M_Beds
				IMP_Bath
				M_Bath
				IMP_SqFt
				M_SqFt
				IMP_YearsOfExperience
				M_YearsOfExperience
				M_CompletedProperties
				IMP_CompletedProperties
				IMP_MedianSalesPriceSqFt
				M_MedianSalesPriceSqFt
				M_DaysOnMarket
				IMP_DaysOnMarket / selection=stepwise outroc=LEAD_VALUE_TEMP;
				/*IMP_LOG_ARV
				M_LOG_ARV
				LOG_LoanAmount
				P_LOG_LoanAmount*/
				
run; 


data LEAD_VALUE;
set LEAD_VALUE;
LOGIT_TEMP = 1.8665 +
			0.9612 * RepeatBorrower +
			0.0838 * MarketHealthIndex +
			-0.1421 * IMP_YearsOfExperience +
			0.00896 * IMP_CompletedProperties;
		
ODDS_TEMP = exp(LOGIT_TEMP);
PROBABILITY_CLOSING = ODDS_TEMP/(1 + ODDS_TEMP);

P_LoanAmount = 10 ** (P_LOG_LoanAmount);

LEAD_VALUE = PROBABILITY_CLOSING * P_LoanAmount;
if(P_LoanAmount > 540000.00 or P_LoanAmount < 15960.00) then do;
	P_LEAD_SCORE = -1;
end;
else do;
	P_LEAD_SCORE = LEAD_VALUE/(540000.00-15960.00)*100;
end;

run;

/*Scoring Function (Assuming no data is missing)*/
/*data SCORE;
set TEMPFILE;
P_LOG_LoanAmount = 1.42308 +
				0.33721 * IMP_LOG_ARV +
				0.00000055 * IMP_PurchasePrice +
				0.000000739 * MedianSalesPrice +
				0.00003807 * IMP_SqFt +
				0.00049456 * IMP_MedianSalesPriceSqFt +
				0.000000000867 * ClosingDate +
				0.02303 * IMP_Bath +
				0.01239 * IMP_Beds +
				-0.01675 * IMP_LOG_EstimatedRepairs +
				-0.02629 * M_CompletedProperties +
				0.1051 * M_Bath +
				-0.03015 * Quarter1;

P_LoanAmount = 10 ** (P_LOG_LoanAmount);

if(P_LoanAmount > 540000.00 or P_LoanAmount < 15960.00) then do;
	P_LEAD_SCORE = -1;
end;
else do;
	LOGIT_TEMP = 1.8665 +
			0.9612 * RepeatBorrower +
			0.0838 * MarketHealthIndex +
			-0.1421 * IMP_YearsOfExperience +
			0.00896 * IMP_CompletedProperties;
			
	ODDS_TEMP = exp(LOGIT_TEMP);
	PROBABILITY_CLOSING = ODDS_TEMP/(1 + ODDS_TEMP);
	
	LEAD_VALUE = PROBABILITY_CLOSING * P_LoanAmount;
	P_LEAD_SCORE = LEAD_VALUE/(540000.00-15960.00)*100;
end;

run;
*/



proc print data=LEAD_VALUE (OBS=20);
	var LoanAmount P_LoanAmount;
run;


proc print data=LEAD_VALUE (OBS=20);
	var LEAD_SCORE P_LEAD_SCORE;
run;



proc sgscatter data=LEAD_VALUE;
  compare x=(LoanAmount)
          y=(P_LoanAmount);
run;


proc sgscatter data=LEAD_VALUE;
  compare x=(LEAD_SCORE)
          y=(P_LEAD_SCORE);
run;



data RESULTS;
set LEAD_VALUE;
RSRERR = SQRT((LEAD_SCORE - P_LEAD_SCORE)**2);
MAERR = ABS(LEAD_SCORE - P_LEAD_SCORE);
run;

proc means data=RESULTS min mean median max stddev n nmiss;
	var RSRERR MAERR;
run;

proc univariate data = RESULTS PLOTS;
	var P_LEAD_SCORE LEAD_SCORE;
	histogram P_LEAD_SCORE LEAD_SCORE;
run;










