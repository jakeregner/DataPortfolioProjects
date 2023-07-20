-- Data Exploration of "Delivery truck trips" dataset from Kaggle
-- Link: https://www.kaggle.com/datasets/ramakrishnanthiyagu/delivery-truck-trips-data


--Overall view of master table...23,468 rows
SELECT *
FROM [Supply Chain Practice].[dbo].[trucking]


--NULL checker
SELECT *
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE BookingID IS NOT NULL
--16,588 NULL rows
--6,880 NOT NULL rows


--The Kaggle Data Card shows that there should be 6,880 rows for the dataset but there are 23,468 rows showing in SQL Server, 16,588 of which are NULL.
--There must have been error during the download, so the 16,588 NULL rows can be deleted.

--Delete 16,588 NULL rows
DELETE FROM [Supply Chain Practice].[dbo].[trucking]
WHERE BookingID IS NULL



--DISTINCT checker
SELECT
	DISTINCT(BookingID)
FROM [Supply Chain Practice].[dbo].[trucking]
	--LOCATION
		--Origin_location: 180
		--Destination_Location: 520 (Destination_Location and DestinationLocation columns both have 521 and appear to be the same)
	--VEHICLES
		--Vehicle_no: 2,321
		--vehicleType: 45
	--CUSTOMERS, SUPPLIERS, MATERIALS
		--customerID: 39
		--supplierID: 321
		--Material Shipped: 1,399
		--BookingID: 6,875


--There are 6,880 rows but 6,875 BookingIDs, so there might be a few duplicates


--Check BookingID duplicates
SELECT
	BookingID,
	COUNT(*)
FROM [Supply Chain Practice].[dbo].[trucking]
GROUP BY BookingID
HAVING COUNT(*) > 1;
--3 different BookingIDs occur 2x and 1 BookingID occurs 3x


--Analyzing the duplicate BookingIDs
SELECT *
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE BookingID = 'AEIBK1902026' OR BookingID = 'MVCV0000759/082021' OR BookingID = 'MVCV0000798/082021' OR BookingID = 'VCV00014072/082021'
--2 instances where BookingIDs had duplicates show that there was both a GpsProvider AND "Manual" entry
--In every case of BookingID duplicates, they show different values for "Material Shipped", which means there was only a failure to assign a new, unique BookingID


--This CTE converts BookingID_Date column to regular Date datatype in order to view the Max and Min dates in the dataset
WITH BookingDate_CTE AS (
	SELECT
		CAST(BookingID_Date as date) as NewBookingID_Date
	FROM [Supply Chain Practice].[dbo].[trucking]
)

SELECT
	MIN(NewBookingID_Date)
	,MAX(NewBookingID_Date)
FROM BookingDate_CTE
--This data spans from March 18, 2019 to December 3, 2020



--Rows with:
	--All deliveries on time, no delays
	--Only "TN" ID vehicles transporting deliveries 100 miles or more
SELECT *
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE delay <> 'R' AND ontime = 'G' AND vehicle_no LIKE 'TN%' AND TRANSPORTATION_DISTANCE_IN_KM >= 100


--Show list of customers who ordered specified materials and show each BookingID
SELECT
	customerID,
	[Material Shipped],
	BookingID
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE [Material Shipped] IN ('Mounting Bracket / Fuel Tank', 'Engine', 'Empty Bin', 'ZB', 'Valve Spring', 'A114 Alternator(New Versa)')
ORDER BY customerID


--Calculates the average distance of all, delayed, or on time deliveries
SELECT
	AVG(TRANSPORTATION_DISTANCE_IN_KM)
FROM [Supply Chain Practice].[dbo].[trucking]

SELECT
	AVG(TRANSPORTATION_DISTANCE_IN_KM)
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE delay = 'R'

SELECT
	AVG(TRANSPORTATION_DISTANCE_IN_KM)
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE ontime = 'G'

--Avg distance of all deliveries: ~554km
--Avg distance of delayed deliveries: ~612km
--Avg distance of on time deliveries: ~429km


--Shows # of orders that were delayed
SELECT
	vehicle_no,
	COUNT(BookingID) as Num_Orders
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE vehicle_no is not null and delay = 'R'
GROUP BY vehicle_no
ORDER BY Num_Orders desc


--Change BookingID_Date column datatype from "Timestamp" to "Date"
SELECT
	CAST(BookingID_Date as date) as NewBookingID_Date
FROM [Supply Chain Practice].[dbo].[trucking]


--View of Booking, Data Ping, Planned ETA, Actual Eta, Ontime or Delay
SELECT 
	BookingID_Date,
	Data_Ping_Time,
	Planned_ETA,
	actual_eta,
	ontime,
	delay
FROM [Supply Chain Practice].[dbo].[trucking]


--Shows the difference (in days) between Actual ETA vs Planned ETA. Positive number is days early, negative number is days late.
SELECT
	CAST(Planned_ETA as DATE) as Planned_ETA,
	CAST(actual_ETA as DATE) as Actual_ETA
FROM [Supply Chain Practice].[dbo].[trucking]

WITH DeliveryDate_CTE AS (
	SELECT
		CAST(Planned_ETA as DATE) as Planned_ETA,
		CAST(actual_ETA as DATE) as Actual_ETA
	FROM [Supply Chain Practice].[dbo].[trucking]

)

SELECT
	DATEDIFF(day, Actual_ETA, Planned_ETA) as DateDiff
FROM DeliveryDate_CTE


--View of Materials shipped, ordered by the Suppliers that ship them
SELECT
	supplierID,
	[Material Shipped]
FROM [Supply Chain Practice].[dbo].[trucking]
ORDER BY supplierID desc


SELECT
	DISTINCT(supplierID),
	supplierNameCode
FROM [Supply Chain Practice].[dbo].[trucking]
ORDER BY supplierNameCode
--There are suppliers that have multiple supplierID's, either from the same supplier being spelled differently or by having a duplicate supplierID

SELECT
	DISTINCT(customerID),
	customerNameCode
FROM [Supply Chain Practice].[dbo].[trucking]
ORDER BY customerNameCode
--"Tvs srichakra limited" is a duplicate and has 2 different customerID's
--38 different customers


--Show supplier and customer locations, ordered by highest distance between them (in KM)
SELECT
	supplierNameCode,
	Origin_Location,
	customerNameCode,
	DestinationLocation,
	Transportation_Distance_IN_KM
FROM [Supply Chain Practice].[dbo].[trucking]
ORDER BY Transportation_Distance_IN_KM desc


SELECT
	vehicle_no
	,supplierNameCode
	,Origin_Location
	,customerNameCode
	,DestinationLocation
FROM [Supply Chain Practice].[dbo].[trucking]
WHERE ontime = 'G'
ORDER BY vehicle_no



--CTE showing the number of orders assigned to each vehicle
WITH orders_CTE as (
	SELECT
		vehicle_no
		, COUNT(BookingID) as Orders
	FROM [Supply Chain Practice].[dbo].[trucking]
	GROUP BY vehicle_no
)
SELECT
	vehicle_no
	, Orders
FROM orders_CTE
ORDER BY Orders DESC


--CTE showing the number of times each Vehicle was "On time"
WITH OnTime_CTE as (
	SELECT
		vehicle_no
		, COUNT(ontime) as NumOnTime
	FROM [Supply Chain Practice].[dbo].[trucking]
	WHERE ontime = 'G'
	GROUP BY vehicle_no
)
SELECT
	vehicle_no
	, NumOnTime
FROM OnTime_CTE
ORDER BY NumOnTime DESC


--CTE showing the number of times each Vehicle was "Delayed"
WITH Delay_CTE as (
	SELECT
		vehicle_no
		, COUNT(delay) as NumDelayed
	FROM [Supply Chain Practice].[dbo].[trucking]
	WHERE delay = 'R'
	GROUP BY vehicle_no
)
SELECT
	vehicle_no
	, NumDelayed
FROM Delay_CTE
ORDER BY NumDelayed DESC



--CTE showing the number of times each Customer has experienced a Delay
WITH CustDelay_CTE as (
	SELECT
		customerID
		, COUNT(delay) as NumDelayed
	FROM [Supply Chain Practice].[dbo].[trucking]
	WHERE delay = 'R'
	GROUP BY customerID
)
SELECT
	customerID
	, NumDelayed
FROM CustDelay_CTE
ORDER BY NumDelayed DESC
