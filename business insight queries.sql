/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
SELECT  market FROM  dim_customer WHERE  customer = 'Atliq Exclusive' AND region = 'APAC'

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/
WITH  cte as (SELECT  count(DISTINCT  CASE  when fiscal_year = 2020 then product_code end ) as unique_products_2020,
count(DISTINCT  CASE  when fiscal_year = 2021 then product_code end ) as unique_products_2021 FROM  fact_gross_price)
SELECT  *, (((unique_products_2021 - unique_products_2020)*100)/ unique_products_2020) as percent_change FROM  cte

/*3. Provide a report with  all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */
SELECT  segment, count(DISTINCT  product_code)as product_count FROM  dim_product
GROUP BY segment
ORDER BY 2 desc

/*4. Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/
WITH  cte as (SELECT  d.segment, count(DISTINCT  CASE  when fiscal_year = 2020 then f.product_code end ) as unique_products_2020,
count(DISTINCT  CASE  when fiscal_year = 2021 then f.product_code end ) as unique_products_2021 FROM  fact_gross_price as f
JOIN  dim_product as d
on f.product_code= d.product_code
GROUP BY d.segment)
SELECT  *, unique_products_2021- unique_products_2020 as difference FROM  cte
ORDER BY difference DESC


/* 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/
WITH cte_max AS (SELECT fmc.product_code, dp.product, manufacturing_cost
FROM fact_manufacturing_cost AS fmc
JOIN dim_product AS dp ON fmc.product_code = dp.product_code
ORDER BY manufacturing_cost DESC LIMIT 1 ),
cte_min AS (SELECT fmc.product_code, dp.product, manufacturing_cost
FROM fact_manufacturing_cost AS fmc 
JOIN dim_product AS dp ON fmc.product_code = dp.product_code
ORDER BY manufacturing_cost
LIMIT 1 )
SELECT * FROM cte_max UNION ALL SELECT * FROM cte_min

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/
SELECT  d.customer_code, customer, round(avg(pre_invoice_discount_pct),2) as average_discount_percentage 
FROM  dim_customer as d
JOIN  fact_pre_invoice_deductions as f
on d.customer_code= f.customer_code
WHERE  fiscal_year= 2021 and market= 'India'
GROUP BY 1,2
ORDER BY 3 desc
LIMIT 5

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/
WITH  cte as(SELECT  to_char(date, 'Mon') AS month, to_char(date, 'mm') AS monthno, extract (year FROM  date)as year,round((gross_price * sold_quantity),0) as gross_sales
FROM  fact_gross_price as fg                        
JOIN  fact_sales_monthly as f
on f.product_code= fg.product_code
JOIN  dim_customer as d on f.customer_code= d.customer_code 
WHERE  customer = 'Atliq Exclusive')
SELECT  month,year, concat(round(SUM (gross_sales)/1000000,2),'M') AS gross_sales FROM  cte
GROUP BY year,month,monthno
ORDER BY year, monthno;

/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/
WITH  cte AS (SELECT  EXTRACT(quarter FROM  date) AS quarter, SUM (sold_quantity) AS total_sold_quantity
FROM  fact_sales_monthly
WHERE  EXTRACT(year FROM  date) = 2020
GROUP BY quarter
)
SELECT  quarter,total_sold_quantity FROM  cte
ORDER BY total_sold_quantity DESC


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */
WITH  cte AS (
      SELECT  c.channel,SUM (s.sold_quantity * g.gross_price) AS total_sales
  FROM 
  fact_sales_monthly s 
  JOIN  fact_gross_price g ON s.product_code = g.product_code
  JOIN  dim_customer c ON s.customer_code = c.customer_code
  WHERE  s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT  
  channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(SUM (total_sales) OVER())*100,2) AS percentage 
FROM  cte ;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code.*/
WITH  ranked_products AS (SELECT  dp.division, fsm.product_code, SUM (sold_quantity) as total_sold_quantity,
						 rank() OVER (PARTITION BY division ORDER BY SUM (sold_quantity) DESC) AS rn
FROM  fact_sales_monthly as fsm 
JOIN  dim_product dp
ON fsm.product_code = dp.product_code						 
WHERE  fiscal_year = 2021
GROUP BY dp.division, fsm.product_code)
SELECT  * FROM  ranked_products
WHERE  division= 'N & S' and rn <= 3

WITH  ranked_products AS (SELECT  dp.division, fsm.product_code, SUM (sold_quantity) as total_sold_quantity,
						 rank() OVER (PARTITION BY division ORDER BY SUM (sold_quantity) DESC) AS rn
FROM  fact_sales_monthly as fsm 
JOIN  dim_product dp
ON fsm.product_code = dp.product_code						 
WHERE  fiscal_year = 2021
GROUP BY dp.division, fsm.product_code)
SELECT  * FROM  ranked_products
WHERE  division= 'P & A' and rn <= 3

WITH  ranked_products AS (SELECT  dp.division, fsm.product_code, SUM (sold_quantity) as total_sold_quantity,
						 rank() OVER (PARTITION BY division ORDER BY SUM (sold_quantity) DESC) AS rn
FROM  fact_sales_monthly as fsm 
JOIN  dim_product dp
ON fsm.product_code = dp.product_code						 
WHERE  fiscal_year = 2021
GROUP BY dp.division, fsm.product_code)
SELECT  * FROM  ranked_products
WHERE  division= 'PC' and rn <= 3

