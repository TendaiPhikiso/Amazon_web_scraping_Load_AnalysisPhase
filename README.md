<div align="center">
	<h1>
		Amazon web scraping Load & Analysis Phase
	</h1>
</div>


### Loading Data to Microsoft SQL Server 
```python
# connection details
server = 'ServerName'
database = 'Amazon_DB'
driver = 'ODBC Driver 17 for SQL Server'

# Create a connection string
connection_string = f'mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes'

# Create an engine
engine = create_engine(connection_string)

# Save the DataFrame to the SQL Server table
table_name = 'Data_Books'
df.to_sql(table_name, engine, index=False)

```

### 1. What is the avg sellingPrice of all books that are in stock?

**SQL Query:**

```sql
SELECT
    Round(avg(SellingPrice), 2) AS Average_sellingPrice
FROM Data_Books
WHERE Availability LIKE '%In stock%'


```

#### Result Set


### 2. Number of books that are in stock & out of stock

**SQL Query:**

```sql

--- In stock 
SELECT Count(Availability) AS [In Stock]
FROM Data_Books
WHERE Availability = 'In stock'




--- Out of stock
SELECT Count(Availability) AS [Out Of Stock]
FROM Data_Books
WHERE Availability = 'Out of stock'

```

#### Result Set



### 3.

**SQL Query:**

```sql

--- Min price
WITH CTE_Min_SellingPrice AS (
SELECT BookTitle, SellingPrice AS min_sellingPrice,
ROW_NUMBER() OVER (ORDER BY SellingPrice) AS book_rank
FROM Data_Books
WHERE Availability LIKE '%In stock%'
)
SELECT BookTitle, min_sellingPrice
FROM CTE_Min_SellingPrice
WHERE book_rank = 1


--- Max Price
WITH CTE_Max_SellingPrice AS (
SELECT BookTitle, SellingPrice AS max_sellingPrice,
ROW_NUMBER() OVER (ORDER BY SellingPrice DESC) AS book_rank
FROM Data_Books
WHERE Availability LIKE '%In stock%'
)
SELECT BookTitle, max_sellingPrice
FROM CTE_Max_SellingPrice
WHERE book_rank = 1


```

#### Result Set



### 4. What are the most common types of books (e.g., Paperback, Hardcover, Kindle)?

**SQL Query:**

```sql
SELECT TypeofBook, COUNT(TypeofBook) AS BookCount
FROM Data_Books
GROUP BY TypeofBook
ORDER BY BookCount DESC;


```

#### Result Set



### 5. Which book formats are most in stock?

**SQL Query:**

```sql
SELECT
    TypeofBook,
    COUNT(Availability) AS [In Stock Level]
FROM Data_Books
WHERE Availability LIKE '%In stock%'
GROUP BY TypeofBook
ORDER BY  [In Stock Level] DESC;
```

#### Result Set



### 6. What books should people be expecting in the upcoming months of 2024?

**SQL Query:**

```sql
SELECT BookTitle,
AuthorName,
'£' + CAST(SellingPrice AS VARCHAR(15)) AS Price,
TypeofBook,
Availability
FROM Data_Books
WHERE Availability LIKE '%released%'


```

#### Result Set



### 7. Top 10 Authors by reviews count

**SQL Query:**

```sql
SELECT
    TOP 10 AuthorName,
    ReviewCount
FROM Data_Books
ORDER BY ReviewCount DESC;


```

#### Result Set



### 8. What is the average page length for books in different formats e.g paperback and hardcover?

**SQL Query:**

```sql
SELECT
    TypeofBook,
    AVG(PrintLength) AS [Average Print Length]
FROM Data_Books
WHERE NOT PrintLength =  0
GROUP BY TypeofBook;


```

#### Result Set


### 9. Is there a relationship between print length and price?

**SQL Query:**

```sql
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

-- Step 3: Calculating the product of deviations and summing it
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
    ROUND((CAST(SumProductDev AS FLOAT) / 
     (SQRT(SumSquaredDevPrint) * SQRT(SumSquaredDevPrice))), 3) AS CorrelationCoefficient
FROM CTE_Product, CTE_SquaredDevs;

```

#### Result Set


### 10.  Calculate the Avg Discount percentage

**SQL Query:**

```sql
WITH CTE_AvgDiscount AS (
SELECT
SellingPrice,
ListingPrice ,
((ListingPrice - SellingPrice) / NULLIF(ListingPrice, 0)) * 100  AS DiscountPercentage
FROM Data_Books
WHERE SellingPrice > 0 AND ListingPrice > 0

)

SELECT Round(Avg(DiscountPercentage), 3) AS [Average Discount]
FROM CTE_AvgDiscount


```

#### Result Set
