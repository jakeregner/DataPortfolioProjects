/* VAERS Data Exploration with SQL Server

Purpose
	-VAERS is a database where anyone who experiences adverse symptoms from a vaccine can submit a report online. It is useful for the CDC and FDA to assess whether or not they should further investigate any concerns associated with a particular vaccine.
		-Link: https://vaers.hhs.gov/about.html
	-VAERS isn't designed to determine if a vaccine caused a health problem, but as we've seen, many people jump to conclusions based on VAERS data.
	-VAERS is often cited by vaccine skeptics, which led to my interest in exploring VAERS data for myself.

Data Files
	-3 Files downloaded from VAERS website on August 26th 2021: "VAERSDATA, VAERSSYMPTOMS, & VAERSVAX"
	-Contains anonymous data from people who received a vaccine between January 1st and August 13th of 2021.
	-Initially, I was unable to get the VAERSDATA file to transfer from Excel into SQLServer, so I removed the "Symptoms" column in the Excel file and then it worked. I'm guessing it couldn't handle all the text data from that column!
	-Explanation of data columns from all 3 files can be found in the VAERS Data guide: https://vaers.hhs.gov/docs/VAERSDataUseGuide_November2020.pdf

Skills Used
	-Creating Views, Aggregate Functions, Joins

*/


-- Select starting columns of interest from VAERSDATA

SELECT [VAERS_ID], [RECVDATE], [STATE], [AGE_YRS], [SEX], [DIED], [DATEDIED], [L_THREAT], [ER_VISIT], [HOSPITAL], [HOSPDAYS], [DISABLE], [RECOVD], [VAX_DATE], [ONSET_DATE]
, [NUMDAYS], [LAB_DATA], [OTHER_MEDS], [CUR_ILL], [HISTORY], [PRIOR_VAX], [TODAYS_DATE], [BIRTH_DEFECT], [OFC_VISIT], [ER_ED_VISIT], [ALLERGIES]
FROM [VAERS].[dbo].['2021VAERSData$']
ORDER BY [RECVDATE] DESC

-- Select VAERS_ID rows that involved Death

SELECT [VAERS_ID], [DIED]
FROM [VAERS].[dbo].['2021VAERSData$']
WHERE [DIED] = 'Y'
ORDER BY [VAERS_ID]

-- 6,194 of the 460,864 VAERS_ID rows (1.34%) involved Death

/* Show table of VAERS_ID's involving Death and display columns that show:

	-Number of days between vaccination date and onset of symptoms (NUMDAYS).
	-AGE of VAERS_ID (AGE_YRS).
	-Current illnesses at the time of vaccination (CUR_IL).
	-Pre-existing conditions (HISTORY).
	-Prescription or non-perscription drugs already being taken at time of vaccination (OTHER_MEDS).
	-Pre-existing physician-diagnosed allergies that existed prior to vaccination (ALLERGIES).

*/

SELECT [VAERS_ID], [DIED], [NUMDAYS], [AGE_YRS], [CUR_ILL], [HISTORY], [OTHER_MEDS], [ALLERGIES]
FROM [VAERS].[dbo].['2021VAERSData$']
WHERE [DIED] = 'Y'
ORDER BY [VAERS_ID]

/* 
	-I tried creating a View of the above table at first using code from this query file but it saved to the master database.
	-Instead I went to "Views" in this database and created one from there.
*/

-- Show ages of all VAERS_ID's that involved death.

SELECT [VAERS_ID], [AGE_YRS]
FROM [VAERS].[dbo].[Dead_VAERSID]
WHERE [AGE_YRS] is not null
ORDER BY [AGE_YRS]

-- Show average age of VAERS_ID's that involved Death (72.7).

SELECT AVG(AGE_YRS) AS 'Avg_Age'
FROM [VAERS].[dbo].[Dead_VAERSID]

-- Show value count of ages.

SELECT [AGE_YRS], COUNT(AGE_YRS) AS Frequency
FROM [VAERS].[dbo].[Dead_VAERSID]
GROUP BY [AGE_YRS]
ORDER BY COUNT(AGE_YRS) DESC

-- Show Age & current illnesses of VAERS_ID leading up to vaccination.

SELECT [VAERS_ID], [AGE_YRS], [CUR_ILL]
FROM [VAERS].[dbo].[Dead_VAERSID]
WHERE [CUR_ILL] is not null

-- Show Age & pre-existing physician-diagnosed birth defects or medical conditions of VAERS_ID that existed at the time of vaccination.

SELECT [VAERS_ID], [AGE_YRS], [HISTORY]
FROM [VAERS].[dbo].[Dead_VAERSID]
WHERE [HISTORY] is not null

-- Show Age & any pre-existing physician-diagnosed allergies that existed at time of vaccination.

SELECT [VAERS_ID], [AGE_YRS], [ALLERGIES]
FROM [VAERS].[dbo].[Dead_VAERSID]
WHERE [ALLERGIES] is not null

-- Show frequency table for number of days it took for onset of symptoms from day of vaccination.

SELECT [NUMDAYS], COUNT(NUMDAYS) AS Frequency
FROM [VAERS].[dbo].[Dead_VAERSID]
GROUP BY [NUMDAYS]
ORDER BY COUNT(NUMDAYS) DESC


-- The following 3 queries are Views that I created directly from the Views folder.

-- Create View of all columns of interest where VAERS_ID Death is involved with VAERS_ID

SELECT [VAERS_ID], [RECVDATE], [STATE], [AGE_YRS], [SEX], [DIED], [DATEDIED], [L_THREAT], [ER_VISIT], [HOSPITAL], [HOSPDAYS], [DISABLE], [RECOVD], [VAX_DATE], [ONSET_DATE]
, [NUMDAYS], [LAB_DATA], [OTHER_MEDS], [CUR_ILL], [HISTORY], [PRIOR_VAX], [TODAYS_DATE], [BIRTH_DEFECT], [OFC_VISIT], [ER_ED_VISIT], [ALLERGIES]
FROM [VAERS].[dbo].['2021VAERSData$']
WHERE [DIED] = 'Y'

-- Create View of VAERS_ID's involved with death with no null values in the VAX_DATE or DATEDIED columns.

SELECT VAERS_ID, VAX_DATE, DATEDIED
FROM [VAERS].[dbo].[Dead_AllCols]
WHERE [DATEDIED] is not null AND [VAX_DATE] is not null

-- Create View from VAX file that shows the type of vaccine (Covid-19) and its manufacturer associated with VAERS_ID

SELECT [VAERS_ID], [VAX_TYPE], [VAX_MANU]
FROM [VAERS].[dbo].['2021VAERSVAX$']
WHERE [VAX_TYPE] like 'Covid19'

-- Join "Only_VAERSID_DIED" view with "ID_Vax_Manu" view

SELECT Dead.[VAERS_ID], Dead.[DIED], Vax.[VAX_TYPE], Vax.[VAX_MANU]
 FROM [VAERS].[dbo].[Only_VAERSID_DIED] Dead

 JOIN [VAERS].[dbo].[ID_Vax_Manu] Vax
 ON Dead.VAERS_ID = Vax.VAERS_ID

 /*
	-For VAERS_ID's associated with Death, show columns that tell us:
		-Date VAERS report was received [RECVDATE]
		-Date VAERS_ID was vaccinated [VAX_DATE]
		-Date where adverse symptoms first appeared [ONSET_DATE]
		-Number of days between Onset of symptoms and Vaccination [NUMDAYS]
 */

SELECT [VAERS_ID], [RECVDATE], [VAX_DATE], [ONSET_DATE],[NUMDAYS]
FROM [VAERS].[dbo].['2021VAERSData$']
WHERE [DIED] = 'Y'

/*
	-Join all 3 datasets on VAERS_ID
*/

SELECT *
FROM [VAERS].[dbo].['2021VAERSData$'] A
Join [VAERS].[dbo].['2021VAERSVAX$'] B
ON A.[VAERS_ID] = B.[VAERS_ID]
Join [VAERS].[dbo].['2021VAERSSYMPTOMS$'] C
ON A.[VAERS_ID] = C.[VAERS_ID]

/*
	-Join all 3 datasets on columns of interest
*/

SELECT A.[VAERS_ID], A.[AGE_YRS], A.[DIED], A.[NUMDAYS], A.[CUR_ILL], A.[HISTORY], A.[ALLERGIES], B.[VAX_MANU],
C.[SYMPTOM1], C.[SYMPTOM2], C.[SYMPTOM3], C.[SYMPTOM4], C.[SYMPTOM5]	
FROM [VAERS].[dbo].['2021VAERSData$'] A
Join [VAERS].[dbo].['2021VAERSVAX$'] B
ON A.[VAERS_ID] = B.[VAERS_ID]
Join [VAERS].[dbo].['2021VAERSSYMPTOMS$'] C
ON A.[VAERS_ID] = C.[VAERS_ID]

/*
	-Join VAERSSYMPTOMS & VAERSVAX columns of interest with the table that shows VAERS_ID's that involved death
	-I did this by substituting an existing View I created into alias "A", but I could've just as easily done this by inserting "WHERE [DIED] = 'Y' " in the query above.
*/

SELECT A.[VAERS_ID], A.[AGE_YRS], A.[DIED], A.[NUMDAYS], A.[CUR_ILL], A.[HISTORY], A.[ALLERGIES], B.[VAX_MANU],
C.[SYMPTOM1], C.[SYMPTOM2], C.[SYMPTOM3], C.[SYMPTOM4], C.[SYMPTOM5]	
FROM [VAERS].[dbo].[Dead_AllCols] A
Join [VAERS].[dbo].['2021VAERSVAX$'] B
ON A.[VAERS_ID] = B.[VAERS_ID]
Join [VAERS].[dbo].['2021VAERSSYMPTOMS$'] C
ON A.[VAERS_ID] = C.[VAERS_ID]
ORDER BY A.[VAERS_ID]