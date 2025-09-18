CREATE TABLE Locations (
    LocationID INT PRIMARY KEY IDENTITY(1,1),
    City NVARCHAR(50) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    Coordinates NVARCHAR(50) NULL
);

CREATE TABLE AirQuality (
    AirQualityID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT NOT NULL,
    DateTime DATETIME NOT NULL,
    AQI INT NOT NULL,
    PM25 FLOAT NULL,
    PM10 FLOAT NULL,
    Ozone FLOAT NULL,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE TABLE Precipitation (
    PrecipitationID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT NOT NULL,
    DateTime DATETIME NOT NULL,
    Rainfall FLOAT NULL,
    Snowfall FLOAT NULL,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE TABLE Temperature (
    TemperatureID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT NOT NULL,
    DateTime DATETIME NOT NULL,
    MinTemperature FLOAT NULL,
    MaxTemperature FLOAT NULL,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE TABLE Humidity (
    HumidityID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT NOT NULL,
    DateTime DATETIME NOT NULL,
    HumidityLevel FLOAT NOT NULL,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE TABLE Wind (
    WindID INT PRIMARY KEY IDENTITY(1,1),
    LocationID INT NOT NULL,
    DateTime DATETIME NOT NULL,
    WindSpeed FLOAT NOT NULL,
    WindDirection NVARCHAR(20) NOT NULL,
    FOREIGN KEY (LocationID) REFERENCES Locations(LocationID)
);

CREATE VIEW AverageAQIByCity AS
SELECT 
    L.City, 
    AVG(AQ.AQI) AS AverageAQI
FROM 
    AirQuality AQ
INNER JOIN 
    Locations L ON AQ.LocationID = L.LocationID
GROUP BY 
    L.City;

CREATE VIEW PrecipitationTrends AS
SELECT 
    L.City, 
    SUM(P.Rainfall) AS TotalRainfall, 
    SUM(P.Snowfall) AS TotalSnowfall
FROM 
    Precipitation P
INNER JOIN 
    Locations L ON P.LocationID = L.LocationID
GROUP BY 
    L.City;

CREATE PROCEDURE InsertLocation
    @City NVARCHAR(50),
    @Country NVARCHAR(50),
    @Coordinates NVARCHAR(50) = NULL
AS
BEGIN
    INSERT INTO Locations (City, Country, Coordinates)
    VALUES (@City, @Country, @Coordinates);
END;

CREATE PROCEDURE GetAirQualityByLocation
    @City NVARCHAR(50)
AS
BEGIN
    SELECT 
        AQ.DateTime, AQ.AQI, AQ.PM25, AQ.PM10, AQ.Ozone
    FROM 
        AirQuality AQ
    INNER JOIN 
        Locations L ON AQ.LocationID = L.LocationID
    WHERE 
        L.City = @City;
END;

CREATE TRIGGER CheckPrecipitationValues
ON Precipitation
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE Rainfall < 0 OR Snowfall < 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Rainfall and Snowfall values must be non-negative.', 1;
    END;
END;

CREATE TRIGGER LogAirQualityUpdates
ON AirQuality
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditLog (TableName, Operation, ChangeTime)
    VALUES ('AirQuality', 'UPDATE', GETDATE());
END;

CREATE TABLE AuditLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(50),
    Operation NVARCHAR(20),
    ChangeTime DATETIME
);
