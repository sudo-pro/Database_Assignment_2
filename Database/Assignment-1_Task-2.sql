-- Insert data into Product table
INSERT INTO
    Products (ProductName, Category, Price, Stock)
VALUES
    ('Laptop', 'Electronics', 75000, 50), 
    ('Headphones', 'Electronics', 5000, 100),
    ('T-shirt', 'Clothing', 1500, 200),
    ('Coffee Maker', 'Home Appliances', 5000, 40),
    ('Gaming Chair', 'Furniture', 12000, 20);

-- Insert data into Customer table
INSERT INTO Customers (CustomerName, Phone, Email, CustomerAddress, EmailRegistrationDate)
VALUES
('Archie Bhatt', '9876543210', 'rajesh.kumar@email.com', '12, MG Road, Bangalore, Karnataka','2024-02-10'),
('Ishita Patel', '9988776655', 'priya.sharma@email.com', '45, Nehru Street, Chennai, Tamil Nadu', '2024-02-10'),
('Firoja Parveen', '9101122334', 'amit.verma@email.com', '78, Rajpath Avenue, Delhi', '2024-02-11'),
('Sanket Walunj', '9312345678', 'neha.gupta@email.com', '23, Juhu Beach, Mumbai, Maharashtra', '2024-02-15'),
('Jagadish Sau', '9494959595', 'suresh.reddy@email.com', '56, Banjara Hills, Hyderabad, Telangana', '2024-02-21');


-- Insert data into Order table
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, ShippingAddress)
VALUES
    (1, '2024-05-01', 100500, '12, MG Road, Bangalore, Karnataka'),  -- Archie Bhatt
    (2, '2024-05-05', 7500, '45, Nehru Street, Chennai, Tamil Nadu'),    -- Ishita Patel
    (3, '2024-07-10', 12000, '78, Rajpath Avenue, Delhi'),   -- Firoja Parveen
    (4, '2024-09-15', 3500, '23, Juhu Beach, Mumbai, Maharashtra'),    -- Sanket Walunj
    (5, '2024-10-20', 27000, '56, Banjara Hills, Hyderabad, Telangana'),   -- Jagadish Sau
    (1, '2024-11-01', 5000, '12, MG Road, Bangalore, Karnataka'),    -- Archie Bhatt
    (2, '2024-11-25', 10000, '45, Nehru Street, Chennai, Tamil Nadu'),   -- Ishita Patel
    (3, '2024-12-10', 15000, '78, Rajpath Avenue, Delhi'),   -- Firoja Parveen
    (4, '2025-01-05', 18000, '23, Juhu Beach, Mumbai, Maharashtra'),   -- Sanket Walunj
    (5, '2025-02-12', 40000, '56, Banjara Hills, Hyderabad, Telangana');   -- Jagadish Sau

-- Insert data into OrderDetails table (with corrected Subtotal values)
INSERT INTO
    OrderDetails (OrderID, ProductID, Quantity, Subtotal)
VALUES
    -- Archie Bhatt: Order 1 (Total = 100500 INR)
    (1, 1, 1, 75000),  -- 1 Laptop (1 * 75000)
    (1, 2, 1, 5000),   -- 1 Headphone (1 * 5000)
    (1, 3, 5, 7500),   -- 5 T-shirts (5 * 1500)
    (1, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)
    (1, 5, 1, 12000),  -- 1 Gaming Chair (1 * 12000)

    -- Ishita Patel: Order 2 (Total = 7500 INR)
    (2, 2, 1, 5000),   -- 1 Headphone (1 * 5000)
    (2, 3, 1, 1500),   -- 1 T-shirt (1 * 1500)
    (2, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)

    -- Firoja Parveen: Order 3 (Total = 12000 INR)
    (3, 1, 1, 75000),  -- 1 Laptop (1 * 75000)
    (3, 3, 1, 1500),   -- 1 T-shirt (1 * 1500)
    (3, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)
    (3, 5, 1, 12000),  -- 1 Gaming Chair (1 * 12000)

    -- Sanket Walunj: Order 4 (Total = 3500 INR)
    (4, 2, 1, 5000),   -- 1 Headphone (1 * 5000)
    (4, 3, 1, 1500),   -- 1 T-shirt (1 * 1500)

    -- Jagadish Sau: Order 5 (Total = 27000 INR)
    (5, 1, 2, 150000), -- 2 Laptops (2 * 75000)
    (5, 2, 1, 5000),   -- 1 Headphone (1 * 5000)
    (5, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)
    (5, 5, 1, 12000),  -- 1 Gaming Chair (1 * 12000)

    -- Archie Bhatt: Order 6 (Total = 5000 INR)
    (6, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)

    -- Ishita Patel: Order 7 (Total = 10000 INR)
    (7, 3, 3, 4500),   -- 3 T-shirts (3 * 1500)
    (7, 5, 1, 12000),  -- 1 Gaming Chair (1 * 12000)

    -- Firoja Parveen: Order 8 (Total = 15000 INR)
    (8, 2, 2, 10000),  -- 2 Headphones (2 * 5000)
    (8, 3, 1, 1500),   -- 1 T-shirt (1 * 1500)
    (8, 4, 1, 5000),   -- 1 Coffee Maker (1 * 5000)

    -- Sanket Walunj: Order 9 (Total = 18000 INR)
    (9, 1, 1, 75000),  -- 1 Laptop (1 * 75000)
    (9, 2, 1, 5000),   -- 1 Headphone (1 * 5000)
    (9, 5, 1, 12000),  -- 1 Gaming Chair (1 * 12000)

    -- Jagadish Sau: Order 10 (Total = 40000 INR)
    (10, 3, 5, 7500),  -- 5 T-shirts (5 * 1500)
    (10, 4, 2, 10000), -- 2 Coffee Makers (2 * 5000)
    (10, 5, 1, 12000); -- 1 Gaming Chair (1 * 12000)

\echo Customers Table:
SELECT * FROM Customers;
\echo Orders Table:
SELECT * FROM Orders;
\echo OrderDetails Table:
SELECT * FROM OrderDetails;
\echo Products Table:
SELECT * FROM Products;

