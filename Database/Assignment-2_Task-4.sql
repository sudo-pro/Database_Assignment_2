\echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Task:4 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\echo ~~~~~~~~~~~~~~~~~~ Query:1 ~~~~~~~~~~~~~~~~~~~~~
/*
Generate a customer purchase report using ROLLUP that includes:
Total purchases by customer
Total of all purchases
*/
SELECT
    c.CustomerName AS CustomerName,
    p.ProductName,
    SUM(od.Quantity) AS Quantity,
    SUM(od.Subtotal) AS Subtotal,
    SUM(o.totalamount) AS GrandTotal 
FROM
    Orders o
JOIN
    Customers c
    ON o.CustomerId = c.CustomerId
JOIN
    OrderDetails od
    ON od.OrderId = o.OrderId
JOIN
    Products P
    ON od.ProductId = p.ProductId
GROUP BY 
    ROLLUP (c.CustomerName, p.ProductName)
    HAVING (c.CustomerName IS NOT NULL
    AND p.ProductName IS NOT NULL) 
ORDER BY
    (c.CustomerName, p.ProductName);
-- The ROLLUP operator adds subtotals for each customer and a grand total at the end of the report.

\echo ~~~~~~~~~~~~~~~~~~ Query:2 ~~~~~~~~~~~~~~~~~~~~~
/*
Using Window Functions (LEAD, LAG) for Order Comparison
*/
SELECT
    o.OrderID,
    o.CustomerID,
    o.TotalAmount,
    LAG(o.TotalAmount) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS PreviousOrderAmount,
    LEAD(o.TotalAmount) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS NextOrderAmount
FROM Orders o;
-- The LAG() function retrieves the previous order amount for a customer, and LEAD() retrieves the next order amount, allowing for order comparisons.
