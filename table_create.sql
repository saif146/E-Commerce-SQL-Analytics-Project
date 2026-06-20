-- Drop tables (child tables first)

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;

-- Customers Table

CREATE TABLE customers (
customer_id SERIAL PRIMARY KEY,
first_name VARCHAR(100) NOT NULL,
last_name VARCHAR(100),
email VARCHAR(255) UNIQUE NOT NULL,
country VARCHAR(100),
city VARCHAR(100),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table

CREATE TABLE orders (
order_id SERIAL PRIMARY KEY,
customer_id INT NOT NULL,
status VARCHAR(50) NOT NULL,
created_at TIMESTAMP DEFAULT NULL,
shiped_at TIMESTAMP DEFAULT NULL,
delivered_at TIMESTAMP DEFAULT NULL,

CONSTRAINT fk_order_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)

);

select * from orders;


-- Categories Table

CREATE TABLE categories (
category_id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
description varchar(500) not null
);

select * from categories;
___________________________________________________

-- products Table
CREATE TABLE products (
product_id SERIAL PRIMARY KEY,
name VARCHAR(255) NOT NULL,
category_id INT,
price NUMERIC(10,2) NOT NULL,
stock INT DEFAULT 0,
CONSTRAINT fk_product_category
    FOREIGN KEY (category_id)
    REFERENCES categories(category_id)

);


select * from products;

___________________________________________________

-- order-items Table

CREATE TABLE order_items (
order_item_id SERIAL PRIMARY KEY,
order_id INT NOT NULL,
product_id INT NOT NULL,
quantity INT NOT NULL CHECK (quantity > 0),
unit_price NUMERIC(10,2) NOT NULL,

CONSTRAINT fk_orderitem_order
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

CONSTRAINT fk_orderitem_product
    FOREIGN KEY (product_id)
    REFERENCES products(product_id)

);

select * from order_items;



-- Reviews Table

CREATE TABLE reviews (
review_id SERIAL PRIMARY KEY,
product_id INT NOT NULL,
customer_id INT NOT NULL,
rating INT CHECK (rating BETWEEN 1 AND 5),
created_at TIMESTAMP DEFAULT null,

CONSTRAINT fk_review_product
    FOREIGN KEY (product_id)
    REFERENCES products(product_id),

CONSTRAINT fk_review_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)

);

select * from reviews;