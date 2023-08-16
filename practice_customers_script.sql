SELECT d.business_name,
		d.city,
		d.state,
		d.website
FROM dealerships AS d


--Get a list of sales records where the sale was a lease.
SELECT *
FROM sales AS s
WHERE s.sales_type_id = '2'


--Get a list of sales where the purchase date is within the last five years.
SELECT *
FROM sales s 
WHERE s.purchase_date >= NOW() - INTERVAL '5 years';


--Get a list of sales where the deposit was above 5000 or the customer payed with American Express.
SELECT *
FROM sales AS s
WHERE s.deposit > 5000 OR s.payment_method = 'americanexpress';

--Get a list of employees whose first names start with "M" or ends with "d".
SELECT e.first_name
FROM employees e 
WHERE e.first_name LIKE 'M%' OR e.first_name LIKE '%d'

--Get a list of employees whose phone numbers have the 604 area code
SELECT e.first_name,
		e.last_name,
		e.phone
FROM employees AS e
WHERE e.phone LIKE '604%'

--chapter 3 practice JOINS


--Get a list of the sales that were made for each sales type
SELECT *
FROM sales AS s 
LEFT JOIN salestypes AS st 
ON s.sales_type_id = st.sales_type_id 

--Get a list of sales with the VIN of the vehicle, the first name and last name of the customer, first name and last name of the employee who made the sale and the name, city and state of the dealership.

