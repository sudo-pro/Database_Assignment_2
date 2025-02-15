-- Retrieve Orders for a Specific Customer (Use JOIN to display the customer’s name, product name, order date, and quantity).
SELECT c.CustomerName, p.ProductName, o.OrderDate, od.Quantity
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 1;
