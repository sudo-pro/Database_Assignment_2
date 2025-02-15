\echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Task:1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\echo ~~~~~~~~~~~~~~~~~~ Query:1 ~~~~~~~~~~~~~~~~~~~~~
-- Retrieve the top 3 customers with the highest total purchase amount
SELECT
    c.CustomerID,
    c.CustomerName,
    SUM(o.TotalAmount) AS TotalSpent
FROM
    Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY
    c.CustomerID
ORDER BY
    TotalSpent DESC
LIMIT
    3;

\echo ~~~~~~~~~~~~~~~~~~ Query:2 ~~~~~~~~~~~~~~~~~~~~~
-- Show monthly sales revenue for the last 6 months using PIVOT
SELECT
    p.ProductName,
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '5 months', 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "5_Months_Ago",
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '4 months', 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "4_Months_Ago",
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '3 months', 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "3_Months_Ago",
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '2 months', 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "2_Months_Ago",
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "1_Month_Ago",
    SUM(CASE WHEN TO_CHAR(o.OrderDate, 'YYYY-MM') = TO_CHAR(CURRENT_DATE, 'YYYY-MM') THEN o.TotalAmount ELSE 0 END) AS "Current_Month"
FROM
    Orders o
JOIN 
    OrderDetails od ON o.OrderID = od.OrderID
JOIN
    Products p ON p.ProductID = od.ProductID
GROUP BY
    p.ProductID;

\echo ~~~~~~~~~~~~~~~~~~ Query:3 ~~~~~~~~~~~~~~~~~~~~~
-- Find the second most expensive product in each category using window functions
WITH RankedProducts AS (
    SELECT 
        p.Category,
        p.ProductID,
        p.ProductName,
        p.Price,
        RANK() OVER (
            PARTITION BY p.Category
            ORDER BY p.Price DESC
        ) AS PriceRank
    FROM Products p
)
SELECT 
    Category,
    ProductID,
    ProductName,
    Price
FROM RankedProducts
WHERE PriceRank = 2;
