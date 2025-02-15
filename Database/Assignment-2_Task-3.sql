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
