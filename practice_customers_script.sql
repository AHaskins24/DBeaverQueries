SELECT c.first_name,
		c.last_name,
		c.email
FROM customers AS c



-- Find employees who haven't made any sales and the name of the dealership they work at.
SELECT
    e.first_name,
    e.last_name,
    d.business_name,
    s.price
FROM employees e
INNER JOIN dealershipemployees de ON e.employee_id = de.employee_id
INNER JOIN dealerships d ON d.dealership_id = de.dealership_id
LEFT JOIN sales s ON s.employee_id = e.employee_id
WHERE s.price IS NULL;

-- Get all the departments in the database,
-- all the employees in the database and the floor price of any vehicle they have sold.
SELECT
    d.business_name,
    e.first_name,
    e.last_name,
    v.floor_price
FROM dealerships d
LEFT JOIN dealershipemployees de ON d.dealership_id = de.dealership_id
INNER JOIN employees e ON e.employee_id = de.employee_id
INNER JOIN sales s ON s.employee_id = e.employee_id
INNER JOIN vehicles v ON s.vehicle_id = v.vehicle_id;

-- Use a self join to list all sales that will be picked up on the same day,
-- including the full name of customer picking up the vehicle. .
SELECT
    CONCAT  (c.first_name, ' ', c.last_name) AS last_name,
    s1.invoice_number,
    s1.pickup_date
FROM sales s1
INNER JOIN sales s2
    ON s1.sale_id <> s2.sale_id 
    AND s1.pickup_date = s2.pickup_date
INNER JOIN customers c
   ON c.customer_id = s1.customer_id;
  
  
-- Get employees and customers who have interacted through a sale.
-- Include employees who may not have made a sale yet.
-- Include customers who may not have completed a purchase.
SELECT
    e.first_name AS employee_first_name,
    e.last_name AS employee_last_name,
    c.first_name AS customer_first_name,
    c.last_name AS customer_last_name
FROM employees e
FULL OUTER JOIN sales s ON e.employee_id = s.employee_id
FULL OUTER JOIN customers c ON s.customer_id = c.customer_id;


-- Get a list of all dealerships and which roles each of the employees hold.
SELECT
    d.business_name,
    et.employee_type_name
FROM dealerships d
LEFT JOIN dealershipemployees de ON d.dealership_id = de.dealership_id
INNER JOIN employees e ON de.employee_id = e.employee_id
RIGHT JOIN employeetypes et ON e.employee_type_id = et.employee_type_id;


SELECT *
FROM salestypes s2 

--Produce a report that lists every dealership, the number of purchases done by each, and the number of leases done by each.
SELECT
    d.business_name AS dealership,
    COALESCE(purchase_count, 0) AS number_of_purchases,
    COALESCE(lease_count, 0) AS number_of_leases
FROM
    dealerships d
LEFT JOIN (
    SELECT
        s.dealership_id,
        COUNT(*) AS purchase_count
    FROM
        sales s
    INNER JOIN
        salestypes st ON s.sales_type_id = st.sales_type_id
    WHERE
        st.sales_type_name = 'Sale'
    GROUP BY
        s.dealership_id
) p ON d.dealership_id = p.dealership_id
LEFT JOIN (
    SELECT
        s.dealership_id,
        COUNT(*) AS lease_count
    FROM
        sales s
    INNER JOIN
        salestypes st ON s.sales_type_id = st.sales_type_id
    WHERE
        st.sales_type_name = 'Lease'
    GROUP BY
        s.dealership_id
) l ON d.dealership_id = l.dealership_id
ORDER BY
    d.business_name;


 		

--who sold what
--What is the most popular vehicle make in terms of number of sales?
SELECT *
FROM vehicles v 


--For the top 5 dealerships, which employees made the most sales?
WITH TopDealerships AS (
    SELECT
        d.dealership_id,
        d.business_name
    FROM
        dealerships d
    ORDER BY
        (SELECT COUNT(*) FROM sales s WHERE s.dealership_id = d.dealership_id) DESC
    LIMIT 5
)
SELECT
    td.business_name AS dealership,
    e.first_name || ' ' || e.last_name AS employee,
    COUNT(*) AS total_sales
FROM
    TopDealerships td
INNER JOIN
    sales s ON td.dealership_id = s.dealership_id
INNER JOIN
    employees e ON s.employee_id = e.employee_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Purchase'
GROUP BY
    td.business_name, e.first_name, e.last_name
ORDER BY
    td.business_name, total_sales DESC;



--For the top 5 dealerships, which vehicle models were the most popular in sales?
  WITH TopDealerships AS (
    SELECT
        d.dealership_id,
        d.business_name
    FROM
        dealerships d
    ORDER BY
        (SELECT COUNT(*) FROM sales s WHERE s.dealership_id = d.dealership_id) DESC
    LIMIT 5
)
SELECT
    td.business_name AS dealership,
    vt.model AS vehicle_model,
    COUNT(*) AS total_sales
FROM
    TopDealerships td
INNER JOIN
    sales s ON td.dealership_id = s.dealership_id
INNER JOIN
    vehicles v ON s.vehicle_id = v.vehicle_id
INNER JOIN
    vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Purchase'
GROUP BY
    td.business_name, vt.model
ORDER BY
    td.business_name, total_sales DESC;


   
--For the top 5 dealerships, were there more sales or leases?
  WITH TopDealerships AS (
    SELECT
        d.dealership_id,
        d.business_name
    FROM
        dealerships d
    ORDER BY
        (SELECT COUNT(*) FROM sales s WHERE s.dealership_id = d.dealership_id) DESC
    LIMIT 5
)
SELECT
    td.business_name AS dealership,
    SUM(CASE WHEN s.sales_type_id = 1 THEN 1 ELSE 0 END) AS total_sales,
    SUM(CASE WHEN s.sales_type_id = 2 THEN 1 ELSE 0 END) AS total_leases
FROM
    TopDealerships td
INNER JOIN
    sales s ON td.dealership_id = s.dealership_id
GROUP BY
    td.business_name
ORDER BY
    td.business_name;


   
--For all used cars, which states sold the most? The least?
   WITH UsedCarSalesByState AS (
    SELECT
        d.state,
        COUNT(*) AS used_car_count
    FROM
        sales s
    INNER JOIN
        vehicles v ON s.vehicle_id = v.vehicle_id
    INNER JOIN
        dealerships d ON s.dealership_id = d.dealership_id
    INNER JOIN
        vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
    WHERE
        vt.vehicle_type_id = 2 
    GROUP BY
        d.state
)
SELECT
    state,
    used_car_count,
    RANK() OVER (ORDER BY used_car_count DESC) AS rank_highest,
    RANK() OVER (ORDER BY used_car_count ASC) AS rank_lowest
FROM
    UsedCarSalesByState;

--For all used cars, which model is greatest in the inventory? Which make is greatest inventory?
   WITH UsedCarInventory AS (
    SELECT
        vt.make,
        vt.model,
        COUNT(*) AS inventory_count
    FROM
        vehicles v
    INNER JOIN
        vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
    WHERE
        vt.vehicle_type_id = 2 
    GROUP BY
        vt.make, vt.model
)
SELECT
    make,
    model,
    inventory_count,
    RANK() OVER (ORDER BY inventory_count DESC) AS rank_highest
FROM
    UsedCarInventory
ORDER BY
    inventory_count DESC
LIMIT 1;

--Practicing Window Functions

--Write a query that shows the total purchase sales income per dealership.
SELECT
    d.business_name AS dealership,
    SUM(s.price) AS total_purchase_income
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Purchase'
GROUP BY
    d.business_name
ORDER BY
    total_purchase_income DESC;


   --Write a query that shows the purchase sales income per dealership for July of 2020..
 SELECT
    d.business_name AS dealership,
    SUM(s.price) AS total_purchase_income
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Purchase'
    AND s.purchase_date >= '2020-07-01' AND s.purchase_date < '2020-08-01'
GROUP BY
    d.business_name
ORDER BY
    total_purchase_income DESC;
  

   
   --Write a query that shows the purchase sales income per dealership for all of 2020.
 SELECT
    d.business_name AS dealership,
    SUM(s.price) AS total_purchase_income
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Purchase'
    AND EXTRACT(YEAR FROM s.purchase_date) = 2020
GROUP BY
    d.business_name
ORDER BY
    total_purchase_income DESC;
  

--Write a query that shows the total lease income per dealership.
   SELECT
    d.business_name AS dealership,
    SUM(s.price) AS total_lease_income
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Lease'
GROUP BY
    d.business_name
ORDER BY
    total_lease_income DESC;


--Write a query that shows the lease income per dealership for Jan of 2020.
 SELECT
    d.business_name AS dealership,
    SUM(s.price) AS lease_income_jan_2020
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Lease'
    AND s.purchase_date >= '2020-01-01' AND s.purchase_date < '2020-02-01'
GROUP BY
    d.business_name
ORDER BY
    lease_income_jan_2020 DESC;
  

   
--Write a query that shows the lease income per dealership for all of 2019.
SELECT
    d.business_name AS dealership,
    SUM(s.price) AS total_lease_income_2019
FROM
    sales s
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Lease'
    AND EXTRACT(YEAR FROM s.purchase_date) = 2019
GROUP BY
    d.business_name
ORDER BY
    total_lease_income_2019 DESC;
  
   
   --Write a query that shows the total income (purchase and lease) per employee.
SELECT
    e.first_name || ' ' || e.last_name AS employee,
    SUM(CASE WHEN st.sales_type_name = 'Purchase' THEN s.price ELSE 0 END) AS total_purchase_income,
    SUM(CASE WHEN st.sales_type_name = 'Lease' THEN s.price ELSE 0 END) AS total_lease_income,
    SUM(s.price) AS total_income
FROM
    sales s
INNER JOIN
    employees e ON s.employee_id = e.employee_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
GROUP BY
    e.first_name, e.last_name
ORDER BY
    total_income DESC;
   
   
--Which model of vehicle has the lowest current inventory? This will help dealerships know which models the purchase from manufacturers.
SELECT
    vt.model,
    COUNT(*) AS current_inventory
FROM
    vehicles v
INNER JOIN
    vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
WHERE
    v.is_sold = true
GROUP BY
    vt.model
ORDER BY
    current_inventory ASC
LIMIT 10;



--Which model of vehicle has the highest current inventory? This will help dealerships know which models are, perhaps, not selling. 
SELECT
    vt.model,
    COUNT(*) AS current_inventory
FROM
    vehicles v
INNER JOIN
    vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
WHERE
    v.is_sold = false
GROUP BY
    vt.model
ORDER BY
    current_inventory DESC
LIMIT 10;



--Which dealerships are currently selling the least number of vehicle models? This will let dealerships market vehicle models more effectively per region.
SELECT
    d.business_name AS dealership,
    COUNT(DISTINCT v.vehicle_type_id) AS num_vehicle_models
FROM
    dealerships d
LEFT JOIN
    sales s ON d.dealership_id = s.dealership_id
LEFT JOIN
    vehicles v ON s.vehicle_id = v.vehicle_id
GROUP BY
    d.business_name
ORDER BY
    num_vehicle_models ASC
LIMIT 10;


--Which dealerships are currently selling the highest number of vehicle models? This will let dealerships know which regions have either a high population, or less brand loyalty.
SELECT
    d.business_name AS dealership,
    COUNT(DISTINCT v.vehicle_type_id) AS num_vehicle_models
FROM
    dealerships d
LEFT JOIN
    sales s ON d.dealership_id = s.dealership_id
LEFT JOIN
    vehicles v ON s.vehicle_id = v.vehicle_id
GROUP BY
    d.business_name
ORDER BY
    num_vehicle_models DESC
LIMIT 10;


--How many emloyees are there for each role?
SELECT
    et.employee_type_name AS role,
    COUNT(*) AS employee_count
FROM
    employees e
INNER JOIN
    employeetypes et ON e.employee_type_id = et.employee_type_id
GROUP BY
    et.employee_type_name;

   
--How many finance managers work at each dealership?
  SELECT
    d.business_name AS dealership,
    COUNT(*) AS finance_manager_count
FROM
    dealerships d
INNER JOIN
    dealershipemployees de ON d.dealership_id = de.dealership_id
INNER JOIN
    employees e ON de.employee_id = e.employee_id
WHERE
    e.employee_type_id = (SELECT employee_type_id FROM employeetypes WHERE employee_type_name = 'Finance Manager')
GROUP BY
    d.business_name;

   
--Get the names of the top 3 employees who work shifts at the most dealerships?
 SELECT
    e.first_name || ' ' || e.last_name AS employee,
    COUNT(DISTINCT de.dealership_id) AS dealership_count
FROM
    employees e
INNER JOIN
    dealershipemployees de ON e.employee_id = de.employee_id
GROUP BY
    e.first_name, e.last_name
ORDER BY
    dealership_count DESC
LIMIT 3;

  
--Get a report on the top two employees who has made the most sales through leasing vehicles.
SELECT
    e.first_name || ' ' || e.last_name AS employee,
    COUNT(*) AS lease_sales_count
FROM
    employees e
INNER JOIN
    sales s ON e.employee_id = s.employee_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Lease'
GROUP BY
    e.first_name, e.last_name
ORDER BY
    lease_sales_count DESC
LIMIT 2;

--Available Models

--Which model of vehicle has the lowest current inventory? This will help dealerships know which models the purchase from manufacturers.
SELECT
    vt.model,
    COUNT(*) AS current_inventory
FROM
    vehicles v
INNER JOIN
    vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
WHERE
    v.is_sold = false
GROUP BY
    vt.model
ORDER BY
    current_inventory ASC
LIMIT 1;


--Which model of vehicle has the highest current inventory? This will help dealerships know which models are, perhaps, not selling.
SELECT
    vt.model,
    COUNT(*) AS current_inventory
FROM
    vehicles v
INNER JOIN
    vehicletypes vt ON v.vehicle_type_id = vt.vehicle_type_id
WHERE
    v.is_sold = false
GROUP BY
    vt.model
ORDER BY
    current_inventory DESC
LIMIT 1;



--Diverse Dealerships

--Which dealerships are currently selling the least number of vehicle models? This will let dealerships market vehicle models more effectively per region.
SELECT
    d.business_name AS dealership,
    COUNT(DISTINCT v.vehicle_type_id) AS num_vehicle_models
FROM
    dealerships d
LEFT JOIN
    sales s ON d.dealership_id = s.dealership_id
LEFT JOIN
    vehicles v ON s.vehicle_id = v.vehicle_id
GROUP BY
    d.business_name
ORDER BY
    num_vehicle_models ASC
LIMIT 1;


--Which dealerships are currently selling the highest number of vehicle models? This will let dealerships know which regions have either a high population, or less brand loyalty.
SELECT
    d.business_name AS dealership,
    COUNT(DISTINCT v.vehicle_type_id) AS num_vehicle_models
FROM
    dealerships d
LEFT JOIN
    sales s ON d.dealership_id = s.dealership_id
LEFT JOIN
    vehicles v ON s.vehicle_id = v.vehicle_id
GROUP BY
    d.business_name
ORDER BY
    num_vehicle_models DESC
LIMIT 1;

--Employee Reports
--How many emloyees are there for each role?
SELECT
    et.employee_type_name AS role,
    COUNT(*) AS employee_count
FROM
    employees e
INNER JOIN
    employeetypes et ON e.employee_type_id = et.employee_type_id
GROUP BY
    et.employee_type_name;

   
--How many finance managers work at each dealership?
 SELECT
    d.business_name AS dealership,
    COUNT(*) AS finance_manager_count
FROM
    dealerships d
INNER JOIN
    dealershipemployees de ON d.dealership_id = de.dealership_id
INNER JOIN
    employees e ON de.employee_id = e.employee_id
WHERE
    e.employee_type_id = (SELECT employee_type_id FROM employeetypes WHERE employee_type_name = 'Finance Manager')
GROUP BY
    d.business_name;
  
   

--Get the names of the top 3 employees who work shifts at the most dealerships?
SELECT
    e.first_name || ' ' || e.last_name AS employee,
    COUNT(DISTINCT de.dealership_id) AS dealership_count
FROM
    employees e
INNER JOIN
    dealershipemployees de ON e.employee_id = de.employee_id
GROUP BY
    e.first_name, e.last_name
ORDER BY
    dealership_count DESC
LIMIT 3;

   
--Get a report on the top two employees who has made the most sales through leasing vehicles.
SELECT
    e.first_name || ' ' || e.last_name AS employee,
    COUNT(*) AS lease_sales_count
FROM
    employees e
INNER JOIN
    sales s ON e.employee_id = s.employee_id
INNER JOIN
    salestypes st ON s.sales_type_id = st.sales_type_id
WHERE
    st.sales_type_name = 'Lease'
GROUP BY
    e.first_name, e.last_name
ORDER BY
    lease_sales_count DESC
LIMIT 2;


--States With Most Customers
--What are the top 5 US states with the most customers who have purchased a vehicle from a dealership participating in the Carnival platform?
SELECT
    c.state,
    COUNT(*) AS customer_count
FROM
    customers c
INNER JOIN
    sales s ON c.customer_id = s.customer_id
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
GROUP BY
    c.state
ORDER BY
    customer_count DESC
LIMIT 5;


--What are the top 5 US zipcodes with the most customers who have purchased a vehicle from a dealership participating in the Carnival platform?
SELECT
    c.zipcode,
    COUNT(*) AS customer_count
FROM
    customers c
INNER JOIN
    sales s ON c.customer_id = s.customer_id
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
GROUP BY
    c.zipcode
ORDER BY
    customer_count DESC
LIMIT 5;



--What are the top 5 dealerships with the most customers?
SELECT
    d.business_name AS dealership,
    COUNT(*) AS customer_count
FROM
    customers c
INNER JOIN
    sales s ON c.customer_id = s.customer_id
INNER JOIN
    dealerships d ON s.dealership_id = d.dealership_id
GROUP BY
    d.business_name
ORDER BY
    customer_count DESC
LIMIT 5;


--Advantages of Using Views
--Practice: Carnival
--Create a view that lists all vehicle body types, makes and models.
CREATE VIEW vehicle_info AS
  SELECT
    vt.body_type,
    vt.make,
    vt.model
  FROM vehicletypes vt;


--Create a view that shows the total number of employees for each employee type.
CREATE VIEW employee_type_counts AS
  SELECT
    et.employee_type_name,
    COUNT(*) AS employee_count
  FROM employeetypes et
  LEFT JOIN employees e ON et.employee_type_id = e.employee_type_id
  GROUP BY et.employee_type_name;


--Create a view that lists all customers without exposing their emails, phone numbers and street address.
CREATE VIEW customer_information AS
  SELECT
    c.customer_id,
    c.last_name,
    c.first_name,
    c.city,
    c.state,
    c.zipcode
  FROM customers c;


--Create a view named sales2018 that shows the total number of sales for each sales type for the year 2018.
CREATE VIEW sales2018 AS
  SELECT
    st.sales_type_name,
    COUNT(*) AS sales_count
  FROM sales s
  INNER JOIN salestypes st ON s.sales_type_id = st.sales_type_id
  WHERE EXTRACT(YEAR FROM s.purchase_date) = 2018
  GROUP BY st.sales_type_name;


--Create a view that shows the employee at each dealership with the most number of sales.
CREATE VIEW top_sales_employee_per_dealership AS
  SELECT
    d.business_name AS dealership,
    e.first_name,
    e.last_name,
    COUNT(*) AS total_sales
  FROM dealerships d
  INNER JOIN sales s ON d.dealership_id = s.dealership_id
  INNER JOIN employees e ON s.employee_id = e.employee_id
  GROUP BY d.business_name, e.first_name, e.last_name;

