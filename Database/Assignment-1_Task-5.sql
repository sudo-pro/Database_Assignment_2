\echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Task:5 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Create a stored procedure to update the stock quantity after an order is placed
-- Create a trigger function to update stock when a new order is placed
CREATE OR REPLACE FUNCTION update_stock_after_order()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the stock quantity of the product after the order is placed
    UPDATE Products
    SET Stock = Stock - NEW.Quantity
    WHERE ProductID = NEW.ProductID;

    RETURN NEW;
END;
$$;

-- Create the trigger on the OrderDetails table to update the stock after an order is placed
CREATE TRIGGER after_order_placed
AFTER INSERT ON OrderDetails
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_order();

-- When a new OrderDetail record is inserted the trigger activates automatically the insertion
INSERT INTO
    Orders (CustomerID, OrderDate, TotalAmount, ShippingAddress)
VALUES
    (4, '2025-02-15', 5000, '23, Juhu Beach, Mumbai, Maharashtra');

INSERT INTO
    OrderDetails (OrderID, ProductID, Quantity, Subtotal)
VALUES
    (11, 2, 1, 5000);

\echo Customers Table:
SELECT * FROM Customers;
\echo Products Table:
SELECT * FROM Products;
\echo Orders Table:
SELECT * FROM Orders;
\echo OrderDetails Table:
SELECT * FROM OrderDetails;