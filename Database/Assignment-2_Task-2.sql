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


\echo Customers Table:
SELECT * FROM Customers;
\echo Orders Table:
SELECT * FROM Orders;
\echo OrderDetails Table:
SELECT * FROM OrderDetails;
\echo Products Table:
SELECT * FROM Products;

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
