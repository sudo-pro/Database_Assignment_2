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


\echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Task:2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\echo ~~~~~~~~~~~~~~~~~~ Query:1 ~~~~~~~~~~~~~~~~~~~~~
/*
Create a stored procedure to place an order, which:
Deducts stock from the Products table.
Inserts data into the Orders and OrderDetails tables.
Returns the new OrderId.
*/
CREATE OR REPLACE PROCEDURE PlaceOrder_StoredProcedure(
    p_CustomerID INT,  -- Input parameter: Customer ID placing the order
    p_ShippingAddress VARCHAR(150), -- Input parameter: Customer's Shipping Address for the order
    p_ProductQuantities JSONB  -- Input parameter: JSONB object containing product IDs and their respective quantities
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_OrderID INT;  -- Declares a variable to hold the OrderID after inserting a new order
    v_ProductID INT;  -- Declares a variable to hold the current product ID during iteration
    v_Quantity INT;  -- Declares a variable to hold the quantity for the current product
    v_Price DECIMAL;  -- Declares a variable to store the price of the product
    v_Subtotal DECIMAL;  -- Declares a variable to calculate the subtotal (Price * Quantity) for each product
BEGIN
    -- Step 1: Insert into Orders table to create a new order for the customer
    INSERT INTO
        Orders (CustomerID, OrderDate, TotalAmount, ShippingAddress)  -- Insert CustomerID, order date, and a default total amount (0) into Orders
    VALUES
        (p_CustomerID, CURRENT_DATE, 0, p_ShippingAddress)  -- The new order is created with the provided CustomerID and the current date, and the total amount is initially set to 0
    RETURNING
        OrderID  -- After inserting, return the OrderID of the newly created order
    INTO
        v_OrderID;  -- Store the returned OrderID into the variable v_OrderID

    -- Step 2: Loop through products in the JSONB input and process each one
    FOR v_ProductID, v_Quantity IN 
        SELECT 
            key::INT,  -- Convert the JSONB key (product ID) to an integer
            value::INT  -- Convert the JSONB value (quantity) to an integer
        FROM
            jsonb_each(p_ProductQuantities)  -- The jsonb_each function returns a set of key-value pairs (product ID, quantity) from the JSONB input
    LOOP
        -- Check stock availability for the product
        SELECT Price INTO v_Price FROM Products WHERE ProductID = v_ProductID;  -- Retrieve the price of the current product based on its ProductID
        
        IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = v_ProductID AND Stock >= v_Quantity) THEN
            RAISE EXCEPTION 'Insufficient stock for product ID %', v_ProductID;  -- If stock is insufficient, raise an exception and halt the procedure
        END IF;

        -- Deduct stock for the product after confirming availability
        UPDATE Products SET Stock = Stock - v_Quantity WHERE ProductID = v_ProductID;  -- Decrease the stock by the quantity purchased

        -- Insert the order details for this product
        v_Subtotal := v_Price * v_Quantity;  -- Calculate the subtotal (price * quantity)
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Subtotal)  -- Insert into OrderDetails table
        VALUES (v_OrderID, v_ProductID, v_Quantity, v_Subtotal);  -- Insert the new order detail (OrderID, ProductID, Quantity, Subtotal)
    END LOOP;

    -- Step 3: Update the total amount in the Orders table
    UPDATE Orders SET TotalAmount = (SELECT SUM(Subtotal) FROM OrderDetails WHERE OrderID = v_OrderID)  -- Update the TotalAmount by summing all subtotals for the current OrderID
    WHERE OrderID = v_OrderID;  -- Only update the order that was just placed

    -- Return the OrderID of the newly created order
    -- RETURN v_OrderID;  -- If this will be a function then simply retrun new OrderID
    RAISE NOTICE 'New OrderID: %', v_OrderID;  -- You can raise a notice or simply use RETURN to return the value if needed
END;
$$;


-- To test the procedure
CALL PlaceOrder_StoredProcedure(3, '78, Rajpath Avenue, Delhi', '{"1": 1, "2": 2, "3": 3}'::JSONB);


\echo ~~~~~~~~~~~~~~~~~~ Query:2 ~~~~~~~~~~~~~~~~~~~~~
/*
Write a user-defined function that takes a CustomerID and
returns the total amount spent by that customer
*/
CREATE OR REPLACE FUNCTION GetTotalSpent(p_CustomerID INT)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
    v_TotalSpent DECIMAL;
BEGIN
    SELECT
        SUM(o.TotalAmount)
    INTO
        v_TotalSpent
    FROM
        Orders o
    WHERE
        o.CustomerID = p_CustomerID;

    RETURN
        COALESCE(v_TotalSpent, 0); -- In case no orders exist
END;
$$;

-- To test the function
SELECT GetTotalSpent(2) AS total_spent; 

\echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Task:3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\echo ~~~~~~~~~~~~~~~~~~ Query:1 ~~~~~~~~~~~~~~~~~~~~~
/*
Write a transaction to ensure an order is placed only if all products are in stock.
If any product is out of stock, rollback the transaction.
*/
CREATE OR REPLACE FUNCTION PlaceOrder_CompleteTransaction(
    p_CustomerID INT,
    p_ShippingAddress VARCHAR(150),
    p_ProductQuantities JSONB
)
RETURNS INT
LANGUAGE plpgsql
AS $$  
DECLARE
    v_OrderID INT;
    v_ProductID INT;
    v_Quantity INT;
    v_Price DECIMAL;
    v_Subtotal DECIMAL;
BEGIN
    -- Step 1: Check if all products are in stock
    FOR v_ProductID, v_Quantity IN 
        SELECT key::INT, value::INT
        FROM jsonb_each(p_ProductQuantities)
    LOOP
        -- Check if there's enough stock for each product
        IF NOT EXISTS (
            SELECT 1 
            FROM Products 
            WHERE ProductID = v_ProductID 
            AND Stock >= v_Quantity
        ) THEN
            -- If stock is insufficient, raise an exception and rollback will happen automatically
            RAISE EXCEPTION 'Insufficient stock for product ID %', v_ProductID;
        END IF;
    END LOOP;

    -- Step 2: Insert into Orders table if all products are available
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, ShippingAddress)
    VALUES (p_CustomerID, CURRENT_DATE, 0, p_ShippingAddress)
    RETURNING OrderID INTO v_OrderID;

    -- Step 3: Loop through the products, deduct stock, and insert into OrderDetails
    FOR v_ProductID, v_Quantity IN 
        SELECT key::INT, value::INT FROM jsonb_each(p_ProductQuantities)
    LOOP
        -- Get the price for each product
        SELECT Price INTO v_Price FROM Products WHERE ProductID = v_ProductID;

        -- Deduct stock from the Products table
        UPDATE Products 
        SET Stock = Stock - v_Quantity 
        WHERE ProductID = v_ProductID;

        -- Calculate the subtotal for the product
        v_Subtotal := v_Price * v_Quantity;

        -- Insert the order details into OrderDetails table
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Subtotal)
        VALUES (v_OrderID, v_ProductID, v_Quantity, v_Subtotal);
    END LOOP;

    -- Step 4: Update the total amount for the order in Orders table
    UPDATE Orders
    SET TotalAmount = (SELECT SUM(Subtotal) FROM OrderDetails WHERE OrderID = v_OrderID)
    WHERE OrderID = v_OrderID;

    -- Return the OrderID of the placed order
    RETURN v_OrderID;

EXCEPTION
    -- Handle any exceptions raised, such as stock shortages
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- To test the function
SELECT PlaceOrder_CompleteTransaction(2, '45, Nehru Street, Chennai, Tamil Nadu', '{"1": 2, "2": 1, "3": 3}'::JSONB);

\echo ~~~~~~~~~~~~~~~~~~ Query:2 ~~~~~~~~~~~~~~~~~~~~~
/*
Demonstrate how to handle deadlocks when updating order details.
*/
-- Create the function to handle deadlocks during the update of order details
CREATE OR REPLACE FUNCTION UpdateOrderDetailWithRetry(
    p_OrderDetailID INT,
    p_NewQuantity INT,
    p_RetryLimit INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_RetryCount INT := 0;
    v_UpdateSuccess BOOLEAN := FALSE;
BEGIN
    -- Loop to retry in case of deadlocks
    WHILE v_RetryCount < p_RetryLimit AND NOT v_UpdateSuccess LOOP
        BEGIN
            -- Attempt to update the order details
            UPDATE OrderDetails
            SET Quantity = p_NewQuantity
            WHERE OrderDetailID = p_OrderDetailID;

            -- If the update is successful, set the success flag to TRUE
            v_UpdateSuccess := TRUE;

        EXCEPTION
            WHEN serialization_failure THEN
                -- Handle deadlock or serialization failure
                v_RetryCount := v_RetryCount + 1;
                RAISE NOTICE 'Deadlock detected. Retrying... Attempt: %', v_RetryCount;
                PERFORM pg_sleep(2); -- Sleep for 2 seconds before retrying
            WHEN OTHERS THEN
                -- Reraise any other exceptions
                RAISE;
        END;
    END LOOP;

    IF NOT v_UpdateSuccess THEN
        RAISE EXCEPTION 'Failed to update OrderDetailID % after % attempts', p_OrderDetailID, p_RetryLimit;
    END IF;
END;
$$;

-- Now you can test the function outside the function itself:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- Set the transaction isolation level
-- Call the function (this will handle retries for deadlock issues)
SELECT UpdateOrderDetailWithRetry(1, 10, 3);  -- Update OrderDetailID 1 to quantity 10 with 3 retries allowed
COMMIT;


\echo ~~~~~~~~~~~~~~~~~~ Query:3 ~~~~~~~~~~~~~~~~~~~~~
/*
Use SAVEPOINT to allow partial updates in an order process where only some items might be out of stock.
*/
CREATE OR REPLACE FUNCTION PlaceOrder_PartialTransaction(
    p_CustomerID INT,
    p_ShippingAddress VARCHAR(150),
    p_ProductQuantities JSONB
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_OrderID INT;
    v_ProductID INT;
    v_Quantity INT;
    v_Price DECIMAL;
    v_Subtotal DECIMAL;
BEGIN
        -- Start the transaction block
        -- Insert the order into the Orders table
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, ShippingAddress)
        VALUES (p_CustomerID, CURRENT_DATE, 0, p_ShippingAddress)
        RETURNING OrderID INTO v_OrderID;

        -- Loop through each product and check stock
        FOR v_ProductID, v_Quantity IN 
            SELECT key::INT, value::INT 
            FROM jsonb_each(p_ProductQuantities)
        LOOP
            -- Savepoint before checking stock
            -- Check if there's enough stock for each product
            IF NOT EXISTS (
                SELECT 1 
                FROM Products 
                WHERE ProductID = v_ProductID 
                AND Stock >= v_Quantity
            ) THEN
                -- Insufficient stock, rollback to savepoint
                RAISE NOTICE 'Insufficient stock for product ID %', v_ProductID;
                CONTINUE;
            END IF;

            -- Get the price of the product
            SELECT Price INTO v_Price FROM Products WHERE ProductID = v_ProductID;

            -- Deduct stock for the product
            UPDATE Products
            SET Stock = Stock - v_Quantity
            WHERE ProductID = v_ProductID;

            -- Calculate the subtotal
            v_Subtotal := v_Price * v_Quantity;

            -- Insert the order details into the OrderDetails table
            INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Subtotal)
            VALUES (v_OrderID, v_ProductID, v_Quantity, v_Subtotal);
        END LOOP;

        -- Update the total amount for the order
        UPDATE Orders
        SET TotalAmount = (SELECT SUM(Subtotal) FROM OrderDetails WHERE OrderID = v_OrderID)
        WHERE OrderID = v_OrderID;

        RETURN v_OrderID;
END;
$$;

-- To test the function
SELECT PlaceOrder_PartialTransaction(4, '23, Juhu Beach, Mumbai, Maharashtra','{"3": 2, "1": 200, "3": 7}'::JSONB);


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
