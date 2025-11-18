/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */

SELECT 

product_name || ', ' || ifnull(product_size, '')|| ' (' || coalesce (product_qty_type, 'unit') || ')' as listformanager

FROM product; 

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */


SELECT 

customer_id
,market_date
,row_number() OVER (PARTITION BY customer_id ORDER BY market_date ASC) as aggrageted_visit

FROM customer_purchases; 



/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT 

customer_id
,market_date
,row_number() OVER (PARTITION BY customer_id ORDER BY market_date DESC) as aggrageted_visit

FROM customer_purchases; 

SELECT*
FROM(
	SELECT
	customer_id
	,market_date
	,row_number() OVER (PARTITION BY customer_id ORDER BY market_date DESC) as aggrageted_visit
	

	FROM customer_purchases

)x
WHERE x.aggrageted_visit = 1; 


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT*
,COUNT(*) OVER (PARTITION BY customer_id, product_id ORDER BY market_date, transaction_time ASC) as agg_product_per_custumer
FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT* 

,CASE 
	WHEN product_name like '%-%' THEN SUBSTR(product_name, INSTR(product_name, '-') + 1)
	ELSE NULL
END as description

FROM product;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT* 

,CASE 
	WHEN product_name like '%-%' THEN SUBSTR(product_name, INSTR(product_name, '-') + 1)
	ELSE NULL
END as description

FROM product
WHERE product_size REGEXP '^(0|1|2|3|4|5|6|7|8|9)';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


----stage 1
DROP TABLE IF EXISTS temp.sales_per_day;

CREATE TEMP TABLE temp.sales_per_day as
SELECT 
    market_date,
    SUM(quantity * cost_to_customer_per_qty) as total_per_day
FROM customer_purchases
GROUP BY market_date;

SELECT*--chek
FROM temp.sales_per_day
ORDER BY total_per_day DESC;
--stage II 
DROP TABLE IF EXISTS temp.ranked_days;

CREATE TEMP TABLE temp.ranked_days AS
SELECT
    market_date,
    total_per_day,
    RANK() OVER (ORDER BY total_per_day DESC) AS best_rank,
    RANK() OVER (ORDER BY total_per_day ASC) AS worst_rank
FROM temp.sales_per_day;

SELECT* -- CHECK
FROM temp.ranked_days; 

--stage II
SELECT market_date, total_per_day, 'Best Day' AS day_type
FROM temp.ranked_days
WHERE best_rank = 1

UNION

SELECT market_date, total_per_day, 'Worst Day' AS day_type
FROM temp.ranked_days
WHERE worst_rank = 1


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- first we I will culculate the custumer mumber * 5 (number of units from each product)
 
 --number of customers 
 SELECT
 count (*) FROM customer; --26*5(TIMES SALES)--130 from each product for each vendor
 
 --there are three vendors in vendor_inventory
 --vendor 4 (product 16); vendor 7 (products 1-4); vendor 8 (product5,7,8)-- sum 8 rows for each 130 sales
 --by prices

SELECT DISTINCT product_id,vendor_id, original_price 
FROM vendor_inventory
ORDER BY vendor_id ASC,product_id ASC;


---without cross join
SELECT DISTINCT 
    v.vendor_name,
    p.product_name,
    vi.original_price * 5* 26 as total_income
FROM vendor_inventory vi
JOIN vendor v 
	ON vi.vendor_id = v.vendor_id
JOIN product p 
	ON vi.product_id = p.product_id
ORDER BY v.vendor_name, p.product_name


---with cross join
SELECT DISTINCT 
    v.vendor_name,
    p.product_name,
    vi.original_price * 5* c.customer_count as total_income
FROM vendor_inventory vi
JOIN vendor v 
	ON vi.vendor_id = v.vendor_id
JOIN product p 
	ON vi.product_id = p.product_id
CROSS JOIN (
    SELECT COUNT(*) AS customer_count
    FROM customer
) as c
ORDER BY v.vendor_name, p.product_name


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS temp.product_units;
CREATE TEMP TABLE product_units AS
SELECT * FROM product;

SELECT* --precheck
FROM product_units
WHERE product_qty_type != 'unit' OR product_qty_type IS NULL; 

DELETE FROM product_units
WHERE product_qty_type != 'unit' OR product_qty_type IS NULL; 

SELECT* ---post check 
FROM product_units;  

ALTER TABLE product_units ADD COLUMN snapshot_timestamp datetime;
UPDATE product_units SET snapshot_timestamp = CURRENT_TIMESTAMP;

SELECT* 
FROM product_units; 

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units 
VALUES(25,'Basbousa', '45"', 3, 'unit', CURRENT_TIMESTAMP); 
  
SELECT* 
FROM product_units; 
-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
SELECT* --pre-check
FROM product_units
WHERE product_id =25;

DELETE FROM product_units
WHERE product_id =25;

SELECT*-- post check
FROM product_units;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units ADD COLUMN current_quantity INT;

SELECT*--check
FROM product_units; 

SELECT* --review the table 
FROM vendor_inventory
ORDER BY market_date DESC, product_id DESC; 

-- get the "last" quantity per product: 


SELECT*
FROM(
	SELECT
	market_date
	,product_id
	,quantity
	,row_number() OVER (PARTITION BY product_id ORDER BY market_date DESC) as rn_last

	FROM vendor_inventory


)as x
WHERE x.rn_last = 1; 

--coalesce null values to 0 
UPDATE product_units
SET current_quantity = COALESCE(current_quantity, 0)
WHERE current_quantity IS NULL;

SELECT*--checking 
FROM product_units;

--SET current_quantity = (...your select statement...)

UPDATE product_units
SET current_quantity = x.quantity	
	FROM(
	SELECT
	market_date
	,product_id
	,quantity
	,row_number() OVER (PARTITION BY product_id ORDER BY market_date DESC) as rn_last
		FROM vendor_inventory 
	)as x
	WHERE x.rn_last = 1
	AND current_quantity = 0
	AND product_units.product_id = x.product_id;
		
SELECT*
FROM product_units

