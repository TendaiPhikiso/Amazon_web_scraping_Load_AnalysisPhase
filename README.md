<div align="center">
	<h1>
		Amazon web scraping Load & Analysis Phase
	</h1>
</div>


### Loading Data to Microsoft SQL Server 

The Load phase of the ETL process involves transferring the processed and transformed data into a target storage system, such as a database or data warehouse. This phase ensures that the data is saved in a structured format where it can be easily accessed, managed, and analysed.

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

#### Load Phase Implementation
In the Load phase of this project, I focused on transferring the cleaned and transformed dataset of Amazon book information into Microsoft SQL Server. I began by establishing a connection to the SQL Server using a specified connection string and ODBC driver. Once connected, I used the pandas library’s to_sql method to load the DataFrame into the database. The data was stored in a table named Data_Books within the Amazon_DB database. This process ensured that the dataset was securely stored in a structured format, ready for any further analysis 

---
## Data Analysis 

### 1. What is the avg sellingPrice of all books that are in stock?

**SQL Query:**

```sql
SELECT
    Round(avg(SellingPrice), 2) AS Average_sellingPrice
FROM Data_Books
WHERE Availability LIKE '%In stock%'


```

#### Result Set

| Metric               | Value  |
|----------------------|--------|
| Average_sellingPrice | 27.12  |


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

| In Stock | Out Of Stock |
|----------|--------------|
| 172      | 59           |


### 3. What is the min & max Sellingprice of all books in stock

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

| BookTitle                                                                    | min_sellingPrice |
|------------------------------------------------------------------------------|------------------|
| Covid By Numbers: Making Sense of the Pandemic with Data (Pelican Books)     | 4                |


| BookTitle                                                                               | max_sellingPrice |
|-----------------------------------------------------------------------------------------|------------------|
| CRC Handbook of Chemistry and Physics: A Ready-reference Book of Chemical and Physical Data | 185              |


### 4. What are the most common types of books (e.g., Paperback, Hardcover, Kindle)?

**SQL Query:**

```sql
SELECT TypeofBook, COUNT(TypeofBook) AS BookCount
FROM Data_Books
GROUP BY TypeofBook
ORDER BY BookCount DESC;


```

#### Result Set

| TypeofBook       | BookCount |
|------------------|-----------|
| Paperback        | 158       |
| Kindle Edition   | 53        |
| Hardcover        | 18        |
| Unknown          | 5         |
| Unknown Binding  | 1         |


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

| TypeofBook       | In Stock Level |
|------------------|----------------|
| Paperback        | 152            |
| Hardcover        | 14             |
| Unknown          | 5              |
| Unknown Binding  | 1              |


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

| BookTitle                                                                                                           | AuthorName                 | Price  | TypeofBook | Availability                                      |
|---------------------------------------------------------------------------------------------------------------------|----------------------------|--------|------------|---------------------------------------------------|
| How to Win the Premier League: The Inside Story of Football’s Data Revolution                                       | Ian Graham                 | £16.99 | Hardcover   | This title will be released on August 15, 2024. Pre-order now. |
| Daphne Draws Data: A Storytelling with Data Adventure                                                               | Cole Nussbaumer Knaflic    | £15.63 | Hardcover   | This title will be released on October 29, 2024. Pre-order now. |
| Tinpot: Football's Forgotten Tournaments… from the Anglo Italian to Zenith Data Systems Cup                         | Simon Turne                | £11.99 | Paperback   | This title will be released on August 5, 2024. Pre-order now.   |


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

| AuthorName                 | ReviewCount |
|----------------------------|-------------|
| Emily Oste                 | 5828        |
| Martin Kleppmann           | 4660        |
| Cathy O'Neil               | 4652        |
| Cole Nussbaumer Knaflic    | 4651        |
| David Spiegelhalte         | 3615        |
| Foster Provos              | 1234        |
| Nick Sing                  | 986         |
| Jan Wengrow                | 733         |
| Malcolm Kendrick           | 696         |
| Ken Puls                   | 687         |


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

| TypeofBook | Average Print Length |
|------------|----------------------|
| Hardcover  | 392                  |
| Paperback  | 299                  |


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

 /* 
 - As PrintLength increases, SellingPrice tends to increase as well.
 A coefficient of 0.724 suggests a moderate to strong correlation. 
 The closer the value is to 1, the stronger the positive relationship between the two variables.
 */
```

#### Result Set

| CorrelationCoefficient |
|------------------------|
| 0.724                  |


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
| Average Discount |
|------------------|
| 21.8%            |
