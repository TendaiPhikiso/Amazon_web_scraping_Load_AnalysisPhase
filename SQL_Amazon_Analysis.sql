SELECT  [BookTitle]
      ,[AuthorName]
      ,[SellingPrice]
      ,[ListingPrice]
      ,[TypeofBook]
      ,[PrintLength]
      ,[PublicationDate]
      ,[Rating]
      ,[ReviewCount]
      ,[Availability]
  FROM [Amazon_DB].[dbo].[Data_Books]
---

 -- 1. What is the avg sellingPrice of all books that are in stock?
SELECT Round(avg(SellingPrice), 2) AS Average_sellingPrice
FROM Data_Books
WHERE Availability LIKE '%In stock%'

-- 2. What is the Avg listingPrice for books in stock?
SELECT Round(avg(ListingPrice), 2) AS [Avg ListingPrice]
FROM Data_Books
WHERE Availability LIKE '%In stock%'

-- 3. Num of books that are in stock 
SELECT Count(Availability) AS [In Stock]
FROM Data_Books
WHERE Availability = 'In stock'

-- 4. Num of books that are out of stock
SELECT Count(Availability) AS [Out Of Stock]
FROM Data_Books
WHERE Availability = 'Out of stock'

-- .5 What is the min price of all books in stock
SELECT  min(SellingPrice) AS min_sellingPrice
FROM Data_Books
WHERE Availability LIKE '%In stock%'
--
WITH CTE_Min_SellingPrice AS (
	SELECT BookTitle, SellingPrice AS min_sellingPrice,
		ROW_NUMBER() OVER (ORDER BY SellingPrice) AS book_rank
	FROM Data_Books
	WHERE Availability LIKE '%In stock%'
)
SELECT BookTitle, min_sellingPrice
FROM CTE_Min_SellingPrice
WHERE book_rank = 1

-- .6 What is the max Sellingprice of all books in stock

WITH CTE_Max_SellingPrice AS (
	SELECT BookTitle, SellingPrice AS max_sellingPrice,
		ROW_NUMBER() OVER (ORDER BY SellingPrice DESC) AS book_rank
	FROM Data_Books
	WHERE Availability LIKE '%In stock%'
)
SELECT BookTitle, max_sellingPrice
FROM CTE_Max_SellingPrice
WHERE book_rank = 1

-- 7. What are the most common types of books (e.g., Paperback, Hardcover, Kindle)?

SELECT TypeofBook, COUNT(TypeofBook) AS BookCount
FROM Data_Books 
GROUP BY TypeofBook
ORDER BY BookCount DESC;

-- 8. Which type of book (Paperback, Hardcover,  Kindle) has the highest review count?

SELECT TypeofBook, SUM(ReviewCount) AS [Review Count]
FROM Data_Books
GROUP BY TypeofBook
ORDER BY [Review Count] DESC;


-- 9. Which book formats are most in stock?
SELECT TypeofBook, COUNT(Availability) AS [In Stock Level]
FROM Data_Books
WHERE Availability LIKE '%In stock%'
GROUP BY TypeofBook
ORDER BY  [In Stock Level] DESC;

-- 10. Which book formats have the highest out-of-stock levels?
SELECT TypeofBook, COUNT(Availability) AS [Out of Stock Level]
FROM Data_Books
WHERE Availability LIKE '%out of stock%'
GROUP BY TypeofBook
ORDER BY  [Out of Stock Level] DESC;

-- 11. What books should people be expecting in the upcoming months of 2024? 
SELECT BookTitle,
		AuthorName, 
		'£' + CAST(SellingPrice AS VARCHAR(15)) AS Price,
		TypeofBook, 
		Availability
FROM Data_Books
WHERE Availability LIKE '%released%'

-- 12. What top 5 books have the most reviews 
SELECT TOP 5 BookTitle, ReviewCount 
FROM Data_Books
ORDER BY ReviewCount DESC;

-- 13. Top 5 authors by number of books published
SELECT TOP 5 AuthorName, COUNT(AuthorName) AS [Number of books published]
FROM Data_Books
WHERE NOT AuthorName = 'Unknown'
GROUP BY AuthorName
ORDER BY [Number of books published] DESC;

-- 14.  Top 10 Auth by reviews count 
SELECT TOP 10 AuthorName, ReviewCount 
FROM Data_Books
ORDER BY ReviewCount DESC;

-- 15. Top 10 author with the highest-priced books?

SELECT TOP 10 AuthorName,'£' + CAST(MAX(SellingPrice) AS VARCHAR(15)) AS HighestPrice
FROM Data_Books
GROUP BY AuthorName
ORDER BY MAX(SellingPrice) DESC;

-- 16. What is the average page length for books in different formats e.g paperback and hardcover?

SELECT TypeofBook, AVG(PrintLength) AS [Average Print Length]
FROM Data_Books
WHERE NOT PrintLength =  0
GROUP BY TypeofBook;

-- 17.Is there a relationship between print length and price? 

-- Step 1: Calculating mean
WITH CTE_Averages AS (
    SELECT 
        AVG(PrintLength) AS MeanPrint,
        AVG(SellingPrice) AS MeanPrice
    FROM Data_Books
    WHERE PrintLength > 0 AND SellingPrice > 0
),

-- Step 2: Calculating deviations
CTE_Dev AS (
    SELECT 
        PrintLength,
        SellingPrice,
        PrintLength - MeanPrint AS DevPrint,
        SellingPrice - MeanPrice AS DevPrice
    FROM Data_Books
    CROSS JOIN CTE_Averages
    WHERE PrintLength > 0 AND SellingPrice > 0
),

-- Step 3: Calculating the product of deviations and suming it
CTE_Product AS (
    SELECT 
        SUM(DevPrint * DevPrice) AS SumProductDev
    FROM CTE_Dev
),

-- Step 4: Calculate the sum of squared deviations
CTE_SquaredDevs AS (
    SELECT 
        SUM(DevPrint * DevPrint) AS SumSquaredDevPrint,
        SUM(DevPrice * DevPrice) AS SumSquaredDevPrice
    FROM CTE_Dev
)

-- Step 5: Calculate the correlation coefficient
SELECT
    Round((CAST(SumProductDev AS FLOAT) / 
     (SQRT(SumSquaredDevPrint) * SQRT(SumSquaredDevPrice))), 3) AS CorrelationCoefficient
FROM CTE_Product, CTE_SquaredDevs;
 /* 
 - As PrintLength increases, SellingPrice tends to increase as well.
 A coefficient of 0.724 suggests a moderate to strong correlation. 
 The closer the value is to 1, the stronger the positive relationship between the two variables.
 */


 -- 18. Calculating the discount percentage and Discount amount for top 10 books
 /*
 NOTE:
 Discount Amount: The actual £ amount by which the price is reduced.
Discount Percentage: The percentage by which the price is reduced relative to the original price.
 */
SELECT TOP 10 BookTitle, 
	SellingPrice,
	ListingPrice ,
	CAST(Round(((ListingPrice - SellingPrice) / NULLIF(ListingPrice, 0)) * 100, 1) AS VARCHAR(10)) + '%' AS DiscountPercentage,
	Round((ListingPrice - SellingPrice), 2) AS DiscountAmount
FROM Data_Books
WHERE SellingPrice > 0 AND ListingPrice > 0 


-- 19. Calculate the Avg Discount percentage 
WITH CTE_AvgDiscount AS (
SELECT 
	SellingPrice,
	ListingPrice ,
	((ListingPrice - SellingPrice) / NULLIF(ListingPrice, 0)) * 100  AS DiscountPercentage
FROM Data_Books
WHERE SellingPrice > 0 AND ListingPrice > 0 

)

SELECT Round(Avg(DiscountPercentage), 3) AS [Average Discount]
FROM CTE_AvgDiscount
