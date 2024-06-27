--creating database TopoDesigns
CREATE DATABASE TopoDesigns;
USE TopoDesigns;
--Loaded all 5 dataset
SELECT
*
FROM
Product_details_ics;
SELECT
*
FROM
Product_Hierarchy;
SELECT
*
FROM
Product_Price;
SELECT
TOP 10*
FROM
Product_Sales;
SELECT
TOP 10*
FROM
Users_ics;

--updating datatypes

ALTER TABLE product_details_ics
ALTER COLUMN product_id VARCHAR(10) NOT NULL;

ALTER TABLE product_details_ics
ALTER COLUMN product_name VARCHAR(255) NOT NULL;

ALTER TABLE product_details_ics
ALTER COLUMN Parent_id_category INT NOT NULL;

ALTER TABLE product_details_ics
ALTER COLUMN Parent_id_segment INT NOT NULL;

ALTER TABLE product_details_ics
ALTER COLUMN Parent_id_style INT NOT NULL;

-- Update the column data type
ALTER TABLE Product_Sales
ALTER COLUMN start_txn_time DATETIME NOT NULL;

-- Create new columns by deriving the  Year, Month, Weekend_flag values from start_txn_time 
ALTER TABLE Product_Sales
ADD Year INT,
    Month INT,
    Weekend_flag BIT;

--What is the count of records in each table? 
SELECT COUNT(*) AS TotalRecords1
FROM Product_Details_ics;
SELECT COUNT(*) AS TotalRecords2
FROM Product_Hierarchy;
SELECT COUNT(*) AS TotalRecords3
FROM Product_Price;
SELECT COUNT(*) AS TotalRecords4
FROM Product_Sales;
SELECT COUNT(*) AS TotalRecords5
FROM Users_ics;

--
-- Create the final table structure
CREATE TABLE Final_Raw_Data (
    prod_id VARCHAR(255),
    qty INT,
    discount FLOAT,
    user_id INT,
    member_flag CHAR(1),
    txn_id VARCHAR(255),
    start_txn_time DATETIME,
    product_name VARCHAR(255),
    Parent_id_category INT,
    Parent_id_segment INT,
    Parent_id_style INT,
    category_text VARCHAR(255),
    segment_text VARCHAR(255),
    style_text VARCHAR(255),
    price FLOAT,
    cookie_id VARCHAR(255),
    Gender CHAR(1),
    Location VARCHAR(255),
    amount FLOAT
);

-- Insert the data into the final table using appropriate joins
INSERT INTO Final_Raw_Data
SELECT 
    ps.prod_id,
    ps.qty,
    ps.discount,
    ps.user_id,
    ps.member_flag,
    ps.txn_id,
    ps.start_txn_time,
    pd.product_name,
    pd.Parent_id_category,
    pd.Parent_id_segment,
    pd.Parent_id_style,
    l1.level_text AS category_text,
    l2.level_text AS segment_text,
    l3.level_text AS style_text,
    pp.price,
    u.cookie_id,
    u.Gender,
    u.Location,
    (ps.qty * pp.price) AS amount
FROM Product_Sales ps
JOIN Product_Details_ics pd ON ps.prod_id = pd.product_id
JOIN Product_Price pp ON ps.prod_id = pp.product_id
JOIN Product_Hierarchy l1 ON pd.Parent_id_category = l1.Parent_id
JOIN Product_Hierarchy l2 ON pd.Parent_id_segment = l2.Parent_id
JOIN Product_Hierarchy l3 ON pd.Parent_id_style = l3.Parent_id
JOIN Users_ics u ON ps.user_id = u.User_id;


SELECT * FROM Final_Raw_Data;

-- Create the summary table structure
CREATE TABLE customer_360 (
    User_id INT,
    Gender CHAR(1),
    Location VARCHAR(255),
    Max_transaction_date DATETIME,
    No_of_transactions INT,
    No_of_transactions_weekends INT,
    No_of_transactions_weekdays INT,
    No_of_transactions_after_2PM INT,
    No_of_transactions_before_2PM INT,
    Total_spend FLOAT,
    Total_discount_amount FLOAT,
    Discount_percentage FLOAT,
    Total_quantity INT,
    No_of_transactions_with_discount_more_than_20pct INT,
    No_of_distinct_products_purchased INT,
    No_of_distinct_Categories_Purchased INT,
    No_of_distinct_segments_purchased INT,
    No_of_distinct_styles_purchased INT
);

-- Insert the data into the summary table using appropriate aggregations
INSERT INTO customer_360
SELECT 
    u.User_id,
    u.Gender,
    u.Location,
    MAX(ps.start_txn_time) AS Max_transaction_date,
    COUNT(ps.txn_id) AS No_of_transactions,
    SUM(CASE WHEN DATEPART(dw, ps.start_txn_time) IN (1, 7) THEN 1 ELSE 0 END) AS No_of_transactions_weekends,
    SUM(CASE WHEN DATEPART(dw, ps.start_txn_time) NOT IN (1, 7) THEN 1 ELSE 0 END) AS No_of_transactions_weekdays,
    SUM(CASE WHEN DATEPART(hour, ps.start_txn_time) >= 14 THEN 1 ELSE 0 END) AS No_of_transactions_after_2PM,
    SUM(CASE WHEN DATEPART(hour, ps.start_txn_time) < 14 THEN 1 ELSE 0 END) AS No_of_transactions_before_2PM,
    SUM(ps.qty * pp.price) AS Total_spend,
    SUM(ps.qty * (pp.price * (ps.discount / 100.0))) AS Total_discount_amount,
    CASE 
        WHEN SUM(ps.qty * pp.price) = 0 THEN 0 
        ELSE (SUM(ps.qty * (pp.price * (ps.discount / 100.0))) / SUM(ps.qty * pp.price)) * 100 
    END AS Discount_percentage,
    SUM(ps.qty) AS Total_quantity,
    SUM(CASE WHEN ps.discount > 20 THEN 1 ELSE 0 END) AS No_of_transactions_with_discount_more_than_20pct,
    COUNT(DISTINCT ps.prod_id) AS No_of_distinct_products_purchased,
    COUNT(DISTINCT pd.Parent_id_category) AS No_of_distinct_Categories_Purchased,
    COUNT(DISTINCT pd.Parent_id_segment) AS No_of_distinct_segments_purchased,
    COUNT(DISTINCT pd.Parent_id_style) AS No_of_distinct_styles_purchased
FROM Product_Sales ps
JOIN Product_Details_ics pd ON ps.prod_id = pd.product_id
JOIN Product_Price pp ON ps.prod_id = pp.product_id
JOIN Users_ics u ON ps.user_id = u.User_id
GROUP BY 
    u.User_id, 
    u.Gender, 
    u.Location;


SELECT * FROM customer_360;

--ADDING SEGMENT AND CHECKING CASES

ALTER TABLE customer_360
ADD segment VARCHAR(10);


UPDATE customer_360
SET segment = CASE
    WHEN Total_spend < 500 THEN 'Low'
    WHEN Total_spend BETWEEN 500 AND 1000 THEN 'Medium'
    WHEN Total_spend > 1000 THEN 'High'
END;


SELECT * FROM customer_360;
SELECT * FROM Product_Sales;
--TASK-2
--What was the total quantity sold for all products?
SELECT SUM(qty) AS TotalQuantitySold
FROM Final_Raw_Data;
-- What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS TotalRevenueBeforeDiscount
FROM Final_Raw_Data;
--What was the total discount amount for all products
SELECT SUM(qty * price * Discount) AS TotalDiscountAmount
FROM Final_Raw_Data;
-- How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS UniqueTransactions
FROM Final_Raw_Data;;
--What is the average unique products purchased in each transaction?
--  Count unique products per transaction
WITH UniqueProductsPerTransaction AS (
    SELECT txn_id,
           COUNT(DISTINCT prod_id) AS unique_product_count
    FROM Final_Raw_Data
    GROUP BY txn_id
)

-- Calculate the average number of unique products per transaction
SELECT AVG(unique_product_count) AS avg_unique_products_per_transaction
FROM UniqueProductsPerTransaction;
--What are the 25th, 50th and 75th percentile values for the revenue per transaction
WITH RevenuePerTransaction AS (
    SELECT 
        txn_id,
        SUM(qty * price) AS total_revenue
    FROM 
        Final_Raw_Data
    GROUP BY 
        txn_id
),
Percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) OVER () AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) OVER () AS p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) OVER () AS p75
    FROM 
        RevenuePerTransaction
)
SELECT 
    p25 AS "25th Percentile",
    p50 AS "50th Percentile",
    p75 AS "75th Percentile"
FROM 
    Percentiles;
--What is the average discount value per transaction?
WITH TotalDiscountPerTransaction AS (
    SELECT 
        txn_id,
        SUM(qty * price * discount / 100.0) AS total_discount
    FROM 
        Final_Raw_Data
    GROUP BY 
        txn_id
)
SELECT 
    AVG(total_discount) AS avg_discount_per_transaction
FROM 
    TotalDiscountPerTransaction;


--What is the percentage split of all transactions for members vs non-members?
-- first Count transactions for each category
WITH TransactionCounts AS (
    SELECT 
        member_flag,
        COUNT(DISTINCT txn_id) AS transaction_count
    FROM 
        Final_Raw_Data
    GROUP BY 
        member_flag
),
-- then Calculate total transactions
TotalTransactions AS (
    SELECT 
        SUM(transaction_count) AS total_transactions
    FROM 
        TransactionCounts
)
-- finally Calculate percentage split
SELECT 
    tc.member_flag,
    tc.transaction_count,
    (tc.transaction_count * 100.0 / tt.total_transactions) AS percentage
FROM 
    TransactionCounts tc,
    TotalTransactions tt;
--What is the average revenue for member transactions and non-member transactions
-- first Calculate total revenue per transaction
WITH RevenuePerTransaction AS (
    SELECT 
        txn_id,
        member_flag,
        SUM(qty * price) AS total_revenue
    FROM 
        Final_Raw_Data
    GROUP BY 
        txn_id, member_flag
)
-- then Calculate average revenue per member flag
SELECT 
    member_flag,
    AVG(total_revenue) AS avg_revenue
FROM 
    RevenuePerTransaction
GROUP BY 
    member_flag;

-- What are the top 3 products by total revenue before discount?   (Excel - 5 Marks
WITH ProductRevenue AS (
    SELECT 
        prod_id,
        SUM(qty * price) AS total_revenue
    FROM 
        Final_Raw_Data
    GROUP BY 
        prod_id
)
SELECT 
    TOP 3
    prod_id,
    total_revenue
FROM 
    ProductRevenue
ORDER BY 
    total_revenue DESC;

--What is the total quantity, revenue and discount for each segment?
WITH SegmentAggregates AS (
    SELECT 
        segment_text,
        SUM(qty) AS total_quantity,
        SUM(qty * price) AS total_revenue,
        SUM(qty * price * discount / 100.0) AS total_discount
    FROM 
        Final_Raw_Data
    GROUP BY 
        segment_text
)
SELECT 
    segment_text,
    total_quantity,
    total_revenue,
    total_discount
FROM 
    SegmentAggregates
ORDER BY 
    segment_text;

-- What is the top selling product for each segment?
WITH RankedProducts AS (
    SELECT 
        segment_text,
        Product_Name,
        SUM(qty) AS TotalQuantitySold,
        ROW_NUMBER() OVER (PARTITION BY Segment_text ORDER BY SUM(qty) DESC) AS RowNum
    FROM Final_Raw_Data
    GROUP BY segment_text, Product_Name
)

SELECT segment_text, Product_Name AS TopSellingProduct, TotalQuantitySold
FROM RankedProducts
WHERE RowNum = 1;

--What is the total quantity, revenue and discount for each category?
SELECT 
    category_text AS Category,
    SUM(qty) AS TotalQuantity,
    SUM(amount) AS TotalRevenue,
    SUM(discount) AS TotalDiscount
FROM Final_Raw_Data
GROUP BY category_text;

--What is the top selling product for each category?  
WITH RankedProducts AS (
    SELECT 
        category_text AS Category,
        product_name AS ProductName,
        SUM(qty) AS TotalQuantitySold,
        ROW_NUMBER() OVER (PARTITION BY category_text ORDER BY SUM(qty) DESC) AS RowNum
    FROM Final_Raw_Data
    GROUP BY category_text, product_name
)

SELECT Category, ProductName AS TopSellingProduct, TotalQuantitySold
FROM RankedProducts
WHERE RowNum = 1;

--What is the percentage split of revenue by product for each segment? 
WITH SegmentRevenue AS (
    SELECT 
        segment_text AS Segment,
        product_name AS ProductName,
        SUM(amount) AS TotalRevenue
    FROM Final_Raw_Data
    GROUP BY segment_text, product_name
),
SegmentTotalRevenue AS (
    SELECT 
        Segment,
        SUM(TotalRevenue) AS TotalSegmentRevenue
    FROM SegmentRevenue
    GROUP BY Segment
)

SELECT 
    sr.Segment,
    sr.ProductName,
    sr.TotalRevenue,
    ROUND(sr.TotalRevenue / str.TotalSegmentRevenue * 100, 2) AS RevenuePercentage
FROM SegmentRevenue sr
JOIN SegmentTotalRevenue str ON sr.Segment = str.Segment
ORDER BY sr.Segment, sr.ProductName;

--What is the percentage split of revenue by segment for each category? 
WITH CategorySegmentRevenue AS (
    SELECT 
        category_text AS Category,
        segment_text AS Segment,
        SUM(amount) AS TotalRevenue
    FROM Final_Raw_Data
    GROUP BY category_text, segment_text
),
CategoryTotalRevenue AS (
    SELECT 
        Category,
        SUM(TotalRevenue) AS TotalCategoryRevenue
    FROM CategorySegmentRevenue
    GROUP BY Category
)

SELECT 
    csr.Category,
    csr.Segment,
    csr.TotalRevenue,
    ROUND(csr.TotalRevenue / ctr.TotalCategoryRevenue * 100, 2) AS RevenuePercentage
FROM CategorySegmentRevenue csr
JOIN CategoryTotalRevenue ctr ON csr.Category = ctr.Category
ORDER BY csr.Category, csr.Segment;

-- What is the percentage split of total revenue by category?  
SELECT 
    category_text AS Category,
    SUM(amount) AS TotalRevenue,
    ROUND(SUM(amount) / (SELECT SUM(amount) FROM Final_Raw_Data) * 100, 2) AS RevenuePercentage
FROM Final_Raw_Data
GROUP BY category_text;

--What is the total transaction “penetration” for each product? 
WITH ProductTransactions AS (
    SELECT 
        prod_id,
        COUNT(DISTINCT txn_id) AS TotalTransactions,
        COUNT(DISTINCT CASE WHEN qty > 0 THEN txn_id END) AS TransactionsWithProduct
    FROM Final_Raw_Data
    GROUP BY prod_id
)

SELECT 
    prod_id,
    TransactionsWithProduct,
    TotalTransactions,
    ROUND((TransactionsWithProduct / TotalTransactions) * 100, 2) AS PenetrationPercentage
FROM ProductTransactions;

--What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH TransactionProducts AS (
    SELECT 
        txn_id,
        STRING_AGG(prod_id, ',') WITHIN GROUP (ORDER BY prod_id) AS ProductCombination
    FROM (
        SELECT DISTINCT
            txn_id,
            prod_id
        FROM Final_Raw_Data
        WHERE qty > 0
    ) AS DistinctProducts
    GROUP BY txn_id
    HAVING COUNT(*) >= 3
)

SELECT TOP 1
    ProductCombination,
    COUNT(*) AS TransactionCount
FROM TransactionProducts
GROUP BY ProductCombination
ORDER BY TransactionCount DESC;

--Calculate the below metrics by each month. (Excel - 10 Marks, SQL-10 Marks)

/*Revenue
Qty
Average transaction value 
No_of_transactions
No_of_Customers
Discount amount
No_customers_who_are_members
No_of_distinct_products
Product_name_with_highest_sales*/

SELECT
    FORMAT(start_txn_time, 'yyyy-MM') AS Month,
    SUM(amount) AS Revenue,
    SUM(qty) AS Qty,
    AVG(amount) AS AvgTransactionValue,
    COUNT(DISTINCT txn_id) AS No_of_transactions,
    COUNT(DISTINCT user_id) AS No_of_Customers,
    SUM(discount) AS Discount_amount,
    SUM(CASE WHEN member_flag = 'Y' THEN 1 ELSE 0 END) AS No_customers_who_are_members,
    COUNT(DISTINCT prod_id) AS No_of_distinct_products,
    MAX(product_name) AS Product_name_with_highest_sales  -- Using MAX() to get product_name
FROM Final_Raw_Data
GROUP BY FORMAT(start_txn_time, 'yyyy-MM');

----------------------------------------------






