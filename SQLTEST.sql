SELECT name, database_id, create_date  
FROM sys.databases;  

CREATE DATABASE kafka;

USE kafka;

CREATE TABLE kafka.PurchaseOrderDetail  
(  
    PurchaseOrderID int NOT NULL  
    ,LineNumber smallint NOT NULL  
    ,ProductID int NULL  
    ,UnitPrice money NULL  
    ,OrderQty smallint NULL  
    ,ReceivedQty float NULL  
    ,RejectedQty float NULL  
    ,DueDate datetime NULL  
);