-- UK Road Accident Database

SELECT * FROM AccidentPortfolio..accident_data;

-- Adding an ID to denote the separate incidents
USE AccidentPortfolio 
ALTER TABLE AccidentPortfolio..accident_data
ADD ID INT IDENTITY(1, 1) PRIMARY KEY;

-- Selecting any null values that may have appeared within the dataset

SELECT * FROM AccidentPortfolio..accident_data 
WHERE [Index] IS NULL OR
[Accident_Severity] IS NULL OR
[Accident_Date] IS NULL OR
[Latitude] IS NULL OR
[Light_Conditions] IS NULL OR
[District_Area] IS NULL OR
[Longitude] IS NULL OR
[Number_of_Casualties] IS NULL OR
[Number_of_Vehicles] IS NULL OR
[Road_Surface_Conditions] IS NULL OR
[Road_Type] IS NULL OR
[Urban_or_Rural_Area] IS NULL OR
[Weather_Conditions] IS NULL OR
[Vehicle_Type] IS NULL;

-- Deleting rows containing null values which may not be entirely helpful during visualisation of data

DELETE FROM AccidentPortfolio..accident_data
WHERE [Latitude] IS NULL OR
[Longitude] IS NULL;

-- What are the earliest and latest recorded road accidents?

SELECT MIN([Accident_Date]) AS Earliest_date, MAX([Accident_Date]) AS Latest_date
FROM AccidentPortfolio..accident_data;

-- Selecting distinct district areas
SELECT DISTINCT [District_Area] FROM AccidentPortfolio..accident_data;

-- Which Cities/Districts have the highest instances of road accidents?

SELECT [District_Area], COUNT(*) AS AccidentNumber
FROM AccidentPortfolio..accident_data
GROUP BY [District_Area]
ORDER BY AccidentNumber DESC;

-- Which weather conditions cause the most accidents?

SELECT [Weather_Conditions], COUNT(*) AS WeatherAccidents
FROM AccidentPortfolio..accident_data
WHERE [Weather_Conditions] IS NOT NULL
GROUP BY [Weather_Conditions]
ORDER BY WeatherAccidents DESC;

-- Which type of vehicles are most involved in road accidents?

SELECT [Vehicle_Type], COUNT(*) AS VehicleAccidents
FROM AccidentPortfolio..accident_data
GROUP BY [Vehicle_Type]
ORDER BY VehicleAccidents DESC;

-- Does the average number of casualties change depending on the mode of transport involed in the accident?

SELECT [Vehicle_Type], ROUND(AVG([Number_of_Casualties]), 0) AS Average_Vehicular_Casualties
FROM AccidentPortfolio..accident_data
GROUP BY [Vehicle_Type]
ORDER BY Average_Vehicular_Casualties DESC;

-- If not, do the number of vehicles impact the average number of casualties? 

SELECT [Number_of_Vehicles], ROUND(AVG([Number_of_Casualties]), 0) AS Average_Vehicular_Casualties
FROM AccidentPortfolio..accident_data
GROUP BY [Number_of_Vehicles]
ORDER BY Average_Vehicular_Casualties DESC;

-- Did we see significant changes in total accidents over the years of data collection?

SELECT YEAR([Accident_Date]) AS YEAR, COUNT(*) AS Total_Accidents
FROM AccidentPortfolio..accident_data
GROUP BY YEAR([Accident_Date])
ORDER BY YEAR;

-- Let's create a new table whereby specific vehicle types will be grouped and accident averages will be stored with the totals

USE AccidentPortfolio
CREATE TABLE Vehicle_Groups (
	Group_ID INT PRIMARY KEY IDENTITY(1,1),
	Group_Name VARCHAR(50),
	Group_Description VARCHAR(255),
	Total_Accidents INT,
	Total_Casualties INT,
	Percentage_of_Total DECIMAL (5,2)
);

SELECT * FROM AccidentPortfolio..Vehicle_Groups;

-- Inserting the vehicle group names and descriptions
INSERT INTO AccidentPortfolio..Vehicle_Groups (Group_Name, Group_Description)
VALUES
	('Car', 'Types of cars including private private vehicles and taxis'),
	('Motorcycle', 'Types of motorcycles including different engine capacities'),
	('Buses/Coaches', 'Buses or coaches with 17 or more passenger seats'),
	('Vans/Goods Vehicles', 'Vans and goods vehicels of various sizes and weights'),
	('Other', 'Various vehicle types not fitting specific descriptions including minibus and agricultural vehicles'),
	('Non-motorised', 'Non-motorised vehicles including pedal cycles and ridden horses'),
	('Unknown', 'Vehicle types with missing data')
;

-- Adding an ID column to accident_data table

ALTER TABLE AccidentPortfolio..accident_data
ADD VehicleGroup_ID INT;

--Defining a foreign key constraint
ALTER TABLE AccidentPortfolio..accident_data
ADD CONSTRAINT FK_VehicleGroup
FOREIGN KEY (VehicleGroup_ID)
REFERENCES AccidentPortfolio..Vehicle_Groups (Group_ID);

-- Assigning each vehicle type a group ID

UPDATE AccidentPortfolio..accident_data
SET VehicleGroup_ID = CASE 
WHEN Vehicle_Type IN ('CAR') OR Vehicle_Type LIKE 'TAXI%' THEN 1
WHEN Vehicle_Type LIKE 'Motorcycle%' THEN 2
WHEN Vehicle_Type LIKE 'BUS%' THEN 3
WHEN Vehicle_Type LIKE 'Van%' OR Vehicle_Type LIKE 'Goods%' THEN 4
WHEN Vehicle_Type LIKE 'Minibus%' OR Vehicle_Type LIKE 'Agricultural%' OR Vehicle_Type LIKE 'Other vehicle%' THEN 5
WHEN Vehicle_Type LIKE 'Pedal cycle%'OR Vehicle_Type LIKE 'Ridden horse%' THEN 6
ELSE 7
END;

-- Checking if the Vehicle_Type and VehicleGroup_ID were correctly assigned using joins.

SELECT DISTINCT ad.Vehicle_Type, ad.VehicleGroup_ID, vg.Group_Name
FROM AccidentPortfolio..accident_data ad
JOIN AccidentPortfolio..Vehicle_Groups vg 
ON ad.VehicleGroup_ID = vg.Group_ID
ORDER BY ad.VehicleGroup_ID ASC;

-- Calculating the average accidents per vehicle group
SELECT VehicleGroup_ID, COUNT(*) AS Number_of_Accidents, SUM(Number_of_Casualties) AS Total_Casualties
FROM AccidentPortfolio..accident_data
GROUP BY VehicleGroup_ID;

-- Calculate total accidents and casualties per vehicle group ID

WITH AggregatedData AS (
SELECT VehicleGroup_ID, COUNT(*) AS Total_Accidents, SUM(Number_of_Casualties) AS Total_Casualties
FROM AccidentPortfolio..accident_data
GROUP BY VehicleGroup_ID
)
SELECT * FROM AggregatedData

UPDATE Vehicle_Groups
SET Total_Accidents = Total_Accidents, Total_Casualties = Total_Casualties, Percentage_of_Total = 
CAST((Total_Accidents * 100.0 / Total_Accidents) AS DECIMAL (5,2))
FROM AccidentPortfolio..Vehicle_Groups
JOIN AggregatedData ad ON vg.Group_ID = ad.VehicleGroup_ID 
CROSS JOIN Total_Accidents 


