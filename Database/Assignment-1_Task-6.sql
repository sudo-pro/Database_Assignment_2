-- Delete a Customer’s Record (Ensure referential integrity is maintained e.g., customer_id = 1)
DELETE
    FROM Customers
WHERE
    CustomerID = 1;


\echo Customers Table:
SELECT * FROM Customers;
\echo Orders Table:
SELECT * FROM Orders;
\echo OrderDetails Table:
SELECT * FROM OrderDetails;
\echo Products Table:
SELECT * FROM Products;
