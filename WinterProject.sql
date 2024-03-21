--Creating Database

CREATE DATABASE WinterProject
GO

USE WinterProject
GO

--Creating Tables

CREATE TABLE dbo.SeniorityLevel(
		[Id] INT IDENTITY (1,1) NOT NULL,
		[Name] NVARCHAR (100) NOT NULL,
	CONSTRAINT PK_SeniorityLevel PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

CREATE TABLE dbo.[Location](
		[Id] INT IDENTITY(1,1) NOT NULL,
		[CountryName] NVARCHAR (100) NULL,
		[Continent] NVARCHAR (100) NULL,
		[Region] NVARCHAR (100) NULL,
	CONSTRAINT PK_Location PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

CREATE TABLE dbo.Department(
		[Id] INT IDENTITY (1,1) NOT NULL,
		[Name] NVARCHAR (100) NOT NULL,
	CONSTRAINT PK_Department PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

CREATE TABLE dbo.Employee(
		[Id] INT IDENTITY (1,1) NOT NULL,
		[FirstName] NVARCHAR (100) NOT NULL,
		[LastName] NVARCHAR(100) NOT NULL,
		[LocationId] INT NOT NULL, 
		[SeniorityLevelId] INT NOT NULL,
		[DepartmentId] INT NOT NULL,
	CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO

CREATE TABLE dbo.Salary(
		[Id] BIGINT IDENTITY (1,1) NOT NULL,
		[EmployeeId] INT NOT NULL,
		[Month] SMALLINT NOT NULL,
		[Year] SMALLINT  NOT NULL,
		[GrossAmount] DECIMAL (18,2) NOT NULL,
		[NetAmount] DECIMAL(18,2) NOT NULL,
		[RegularWorkAmount] DECIMAL (18,2) NOT NULL,
		[BonusAmount] DECIMAL (18,2) NOT NULL,
		[OvertimeAmount] DECIMAL (18,2) NOT NULL,
		[VacationDays] SMALLINT NOT NULL,
		[SickLeaveDays] SMALLINT NOT NULL,
	CONSTRAINT PK_Salary PRIMARY KEY CLUSTERED ([Id] ASC)
)
GO


--Adding foregin keys

ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Employee_SeniorityLevel FOREIGN KEY (SeniorityLevelId)
REFERENCES dbo.SeniorityLevel (Id)


ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Employee_Location FOREIGN KEY (LocationId)
REFERENCES dbo.Location (Id)


ALTER TABLE dbo.Employee WITH CHECK
ADD CONSTRAINT FK_Employee_Department FOREIGN KEY (DepartmentId)
REFERENCES dbo.Department (Id)


ALTER TABLE dbo.Salary WITH CHECK
ADD CONSTRAINT FK_Salary_Employee FOREIGN KEY (EmployeeId)
REFERENCES dbo.Employee (Id)


--Populating tables

--SeniorityLevel

INSERT INTO dbo.SeniorityLevel ([Name])
VALUES ('Junior'),('Intermediate'),('Senor'),('Lead'),('Project Manager'),
		('Division Manager'),('Office Manager'),('CEO'),('CTO'),('CIO')
GO

SELECT * FROM dbo.SeniorityLevel

--Location
GO
CREATE OR ALTER PROCEDURE dbo.InsertLocation
AS
BEGIN
		INSERT INTO dbo.Location (CountryName,Continent,Region)
		SELECT AC.CountryName,AC.Continent,AC.Region
		FROM WideWorldImporters.Application.Countries AS AC
END
GO

EXEC dbo.InsertLocation

SELECT * FROM dbo.Location

--Department
INSERT INTO dbo.Department ([Name])
VALUES ('Personal Banking & Operations'),('Digital Banking Department'),('Retail Banking & Marketing Department'),
		('Wealth Managment & Third Party Products'),('International Banking Division & DFB'),('Treasury'),
		('Information Technology'),('Corporate Communications'),('Support Services & Branch Expansion'),
		('Human Resources')
GO

SELECT * FROM dbo.Department

--Employee
GO 
CREATE OR ALTER PROCEDURE dbo.InsertEmployee
AS
BEGIN 
	;WITH CTE AS(
	SELECT	P.PersonID AS ID,
			LEFT(P.FullName, CHARINDEX(' ',P.FullName) - 1) AS FName,
			SUBSTRING(P.FullName, CHARINDEX(' ', P.FullName) + 1, LEN(P.FullName)) AS LName
	FROM WideWorldImporters.Application.People AS P)

	INSERT INTO dbo.Employee ( FirstName, LastName, LocationId, SeniorityLevelId, DepartmentId)
	SELECT CTE.FName AS FirstName, CTE.LName AS LastName,
	NTILE (190) OVER (ORDER BY L.ID) AS LocationID,
	NTILE (10) OVER (ORDER BY S.ID) AS SeniorityLevelId,
	NTILE (10) OVER (ORDER BY D.ID) AS DepartmentId
	FROM CTE
	LEFT OUTER JOIN dbo.Employee AS E ON E.Id = CTE.ID
	LEFT OUTER  JOIN dbo.Location AS L ON L.Id = E.LocationId
	LEFT OUTER JOIN dbo.SeniorityLevel AS S ON E.SeniorityLevelId = S.Id	
	LEFT OUTER  JOIN dbo.Department AS D ON E.DepartmentId = D.Id
END
GO

EXEC dbo.InsertEmployee

SELECT * FROM dbo.Employee


--Salary

GO 
CREATE OR ALTER PROCEDURE dbo.InsertSalary 
AS
BEGIN

					CREATE  TABLE #Dates([Year] SMALLINT, [Month] SMALLINT)

					DECLARE @StartYear SMALLINT = 2001; DECLARE @EndYear SMALLINT = 2020;
					WHILE @StartYear <= @EndYear
					BEGIN

					DECLARE @StartMonth SMALLINT = 1; DECLARE @EndMonth SMALLINT = 12;
					WHILE @StartMonth <= @EndMonth
					BEGIN
					INSERT INTO #Dates([Year],[Month])
					SELECT @StartYear, @StartMonth
					SET @StartMonth += 1
					END 

					SET @StartYear += 1
					END
				
					;WITH CTEA AS(
					SELECT E.Id,D.[Month] AS [Month],D.[Year] AS [Year], (ABS(CHECKSUM(NEWID()))%30000+ 30000 + 1) AS GrossAmount
					FROM #Dates AS D
					CROSS JOIN Employee AS E),
					
					CTEB AS(
					SELECT*, C.GrossAmount * 0.9 AS NetAmount, (c.GrossAmount*0.9)*0.8 AS RegularWorkAmount
					FROM CTEA AS C)
									
					INSERT INTO dbo.Salary([EmployeeId], [Month], [Year], [GrossAmount], [NetAmount], [RegularWorkAmount], 
					[BonusAmount], [OvertimeAmount], [VacationDays], [SickLeaveDays])
					SELECT B.Id AS EmpolyeeId, B.Month, B.Year, B.GrossAmount,B.NetAmount,B.RegularWorkAmount,
							CASE 
							WHEN (B.Month%2)=1 THEN B.NetAmount - B.RegularWorkAmount 
							ELSE 0 END AS BonusAmount,
							CASE 
							WHEN (B.Month%2)=0 THEN B.NetAmount - B.RegularWorkAmount 
							ELSE 0 END AS OvertimeAmount,
							CASE
							WHEN (B.Month in (7,12)) THEN 10 
							ELSE 0 END AS VacationDays,
							0 AS SickLeaveDays
					FROM CTEB AS B
						
END
GO 

EXEC dbo.InsertSalary


UPDATE dbo.Salary 
SET VacationDays = VacationDays + (EmployeeId % 2) 
WHERE  (EmployeeId + [Month] + [Year])%5 = 1
GO					
					
UPDATE dbo.Salary 
SET SickLeaveDays = EmployeeId%8, VacationDays = VacationDays + (EmployeeId % 3)
WHERE (EmployeeId + [Month] + [Year] )%5 = 2
GO

SELECT * FROM Salary

--Checking if the query returns 0 rows
SELECT * FROM Salary
WHERE NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount)

--Checking if the sum of VacationDays is between 20 and 30 days
SELECT Employeeid, [Year], SUM(VacationDays) FROM dbo.SalaryGROUP BY EmployeeId,[Year]HAVING SUM(VacationDays) BETWEEN 20 AND 30ORDER BY EmployeeId,[Year]





