CREATE TABLE raw.orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  status TEXT,
  total_amount DECIMAL
);

COPY raw.orders(
  order_id,
  customer_id,
  order_date,
  status,
  total_amount
) 
FROM 'C:\csv files\raw_orders.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE raw.customers (
  customer_id INT PRIMARY KEY,
  customer_name TEXT,
  email TEXT,
  registration_date DATE,
  city TEXT,
  country TEXT
);

COPY raw.customers(
  customer_id,
  customer_name,
  email,
  registration_date,
  city,
  country
) 
FROM 'C:\csv files\raw_customers.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM RAW.ORDERS;
SELECT * FROM RAW.CUSTOMERS;