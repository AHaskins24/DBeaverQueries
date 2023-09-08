--Practice: Employees - Employee Transfer

Kristopher Blumfield an employee of Carnival has asked to be transferred to a different dealership location. She is currently at dealership 9. She would like to work at dealership 20. Update her record to reflect her transfer.

UPDATE dealershipemployees
SET dealership_id = 20
WHERE employee_id = (SELECT employee_id FROM employees WHERE first_name = 'Kristopher' AND last_name = 'Blumfield');




--Practice: Sales
A Sales associate needs to update a sales record because her customer want to pay with a Mastercard instead of JCB. Update Customer, Ernestus Abeau Sales record which has an invoice number of 9086714242.

UPDATE sales
SET payment_method = 'Mastercard'
WHERE invoice_number = '9086714242';


--Practice - Employees
A sales employee at carnival creates a new sales record for a sale they are trying to close. The customer, last minute decided not to purchase the vehicle. Help delete the Sales record with an invoice number of '2436217483'.

DELETE FROM sales
WHERE invoice_number = '2436217483';


An employee was recently fired so we must delete them from our database. Delete the employee with employee_id of 35. What problems might you run into when deleting? How would you recommend fixing it?

UPDATE dealershipemployees
SET employee_id = NULL
WHERE employee_id = 35;

--After trying a few different paths to delete the employee, 'setting' the -id to 'NULL' was the simplest result that yielded the result.


-Creating STORED PROCEDURES FOR selling a vehicle, RETURNING a vehicle, AND logging oil changes ON BOTH.
-Selling a vehicle

CREATE OR REPLACE FUNCTION sp_SellVehicle(
    IN p_vehicle_id INT,
    IN p_sale_id INT
)
RETURNS VOID AS
$$
BEGIN
    -- Flag the vehicle as sold
    UPDATE vehicles
    SET is_sold = TRUE
    WHERE vehicle_id = p_vehicle_id;

    -- Update the associated sale record
    UPDATE sales
    SET sale_returned = FALSE
    WHERE sale_id = p_sale_id;

    -- Log the sale in the OilChangeLogs table
    INSERT INTO oilchangelogs (date_occurred, vehicle_id, description)
    VALUES (CURRENT_DATE, p_vehicle_id, 'Vehicle sold.');
END;
$$
LANGUAGE plpgsql;


-RETURNING a vehicle:
CREATE OR REPLACE FUNCTION sp_ReturnVehicle(
    IN p_vehicle_id INT,
    IN p_sale_id INT
)
RETURNS VOID AS
$$
BEGIN
    -- Flag the vehicle as available
    UPDATE vehicles
    SET is_sold = FALSE
    WHERE vehicle_id = p_vehicle_id;

    -- Update the associated sale record
    UPDATE sales
    SET sale_returned = TRUE
    WHERE sale_id = p_sale_id;

    -- Log the oil change for the returned vehicle
    INSERT INTO oilchangelogs (date_occurred, vehicle_id, description)
    VALUES (CURRENT_DATE, p_vehicle_id, 'Vehicle returned and oil change performed.');
END;
$$
LANGUAGE plpgsql;


-- Create a Trigger for New Sales Record (set_purchase_date):


CREATE OR REPLACE FUNCTION set_purchase_date()
RETURNS TRIGGER AS
$$
BEGIN
  NEW.purchase_date = CURRENT_DATE + INTERVAL '3 days';
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER new_sale_trigger
  BEFORE INSERT ON sales
  FOR EACH ROW
  EXECUTE FUNCTION set_purchase_date();
 
 
 
 --Create a Trigger for Updates to the Sales Table (update_pickup_date):

CREATE OR REPLACE FUNCTION update_pickup_date()
RETURNS TRIGGER AS
$$
BEGIN
  IF NEW.pickup_date <= NEW.purchase_date THEN
    NEW.pickup_date = NEW.purchase_date + INTERVAL '7 days';
  ELSIF NEW.pickup_date <= NEW.purchase_date + INTERVAL '7 days' THEN
    NEW.pickup_date = NEW.pickup_date + INTERVAL '4 days';
  END IF;
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER update_pickup_date_trigger
  BEFORE UPDATE ON sales
  FOR EACH ROW
  EXECUTE FUNCTION update_pickup_date();
 
 
 
 --Ensure the website URL format:
--Create a trigger function that modifies the website URL to the required format.
--Bind the trigger function to the Dealerships table to execute after INSERT and UPDATE operations.
 

CREATE OR REPLACE FUNCTION format_dealership_website()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.website_url = 'http://www.carnivalcars.com/' || REPLACE(LOWER(NEW.name), ' ', '_');
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_dealership_website
AFTER INSERT OR UPDATE
ON Dealerships
FOR EACH ROW
EXECUTE FUNCTION format_dealership_website();

 
--Set the default phone number:
--You can set the default phone number in the trigger function for new insertions if the phone number is not provided.


-- Create a trigger function to set the default phone number
CREATE OR REPLACE FUNCTION set_default_phone_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.phone IS NULL THEN
    NEW.phone = '777-111-0305';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_dealership_default_phone
BEFORE INSERT
ON Dealerships
FOR EACH ROW
EXECUTE FUNCTION set_default_phone_number();


--Include the state in the tax ID:
--Create a trigger function that appends the state name to the tax ID.
--Bind the trigger function to the Dealerships table to execute before INSERT operations.

-- Create a trigger function to include the state in the tax ID
CREATE OR REPLACE FUNCTION include_state_in_tax_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.tax_id = NEW.tax_id || '--' || NEW.state;
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_dealership_tax_id
BEFORE INSERT
ON Dealerships
FOR EACH ROW
EXECUTE FUNCTION include_state_in_tax_id();
