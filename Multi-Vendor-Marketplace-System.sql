--Multi-Vendor-Marketplace-System.sql

--CREATE DATABASE

CREATE DATABASE IF NOT EXISTS marketplace_system
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE marketplace_system;


--- TABLES


--CUSTOMERS TABLE

CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status ENUM('active', 'inactive', 'blocked')
        NOT NULL DEFAULT 'active'
);



--CUSTOMER ADDRESSES--

CREATE TABLE customer_addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    street VARCHAR(255) NOT NULL,
    postal_code VARCHAR(20),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    UNIQUE KEY uq_customer_address (customer_id, id)
);


--SELLERS TABLE--

CREATE TABLE sellers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    owner_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    commission_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status ENUM('pending', 'active', 'suspended', 'closed')
        NOT NULL DEFAULT 'pending',
        CHECK (commission_rate >= 0 AND commission_rate <= 100)
);





-- CATEGORIES TABLE

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NULL,
    category_name VARCHAR(150) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'active',

        FOREIGN KEY (parent_id)
        REFERENCES categories(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    UNIQUE KEY uq_category_name_parent (parent_id, category_name)
);

--PRODUCTS TABLE--

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    category_id INT NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    minimum_stock INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status ENUM(
        'active',
        'inactive',
        'out_of_stock',
        'discontinued'
    ) NOT NULL DEFAULT 'active',


        FOREIGN KEY (seller_id)
        REFERENCES sellers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        CHECK (price >= 0),
        CHECK (cost_price >= 0)
);



--PRODUCT_PRICE_HISTORY TABLE


CREATE TABLE product_price_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    old_price DECIMAL(12,2) NOT NULL,
    new_price DECIMAL(12,2) NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        CHECK (old_price >= 0),
        CHECK (new_price >= 0)
);



--CARTS TABLE--

CREATE TABLE carts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active', 'converted', 'abandoned')
        NOT NULL DEFAULT 'active',
        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


--CART_ITEMS TABLE--

CREATE TABLE cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

        FOREIGN KEY (cart_id)
        REFERENCES carts(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
        CHECK (quantity > 0),
    UNIQUE KEY uq_cart_product (cart_id, product_id)
);


--COUPONS TABLE--



CREATE TABLE coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    discount_type ENUM('percentage', 'fixed') NOT NULL,
    discount_value DECIMAL(12,2) NOT NULL,
    minimum_order DECIMAL(12,2) NOT NULL DEFAULT 0,
    maximum_discount DECIMAL(12,2) NULL,
    usage_limit INT NOT NULL,
    used_count INT NOT NULL DEFAULT 0,
    starts_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'active',
    
        CHECK (discount_value >= 0),
        CHECK (minimum_order >= 0),
        CHECK (used_count <= usage_limit),
        CHECK (expires_at > starts_at)
);


--ORDERS TABLE--

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(100) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    address_id INT NOT NULL,
    coupon_id INT,

    subtotal DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,

    ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status ENUM(
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        'partially_returned',
        'returned'
    ) NOT NULL DEFAULT 'pending',

        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        FOREIGN KEY (customer_id, address_id)
        REFERENCES customer_addresses(customer_id, id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
        FOREIGN KEY (coupon_id)
        REFERENCES coupons(id)
    
);



-- ORDER ITEMS TABLE--

CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,

    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    platform_commission DECIMAL(12,2) NOT NULL DEFAULT 0,
    seller_amount DECIMAL(12,2) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'active',

   
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

   
        FOREIGN KEY (seller_id)
        REFERENCES sellers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    
        CHECK (quantity > 0),
        CHECK (unit_price >= 0),
        CHECK (discount_amount >= 0),
        CHECK (platform_commission >= 0),
        CHECK (seller_amount >= 0)
);


--PAYMENTS TABLE


CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_reference VARCHAR(150) NOT NULL UNIQUE,
    amount DECIMAL(12,2) NOT NULL,

    payment_method ENUM(
        'pix',
        'card',
        'bank_transfer',
        'wallet'
    ) NOT NULL,

    paid_at DATETIME,

    status ENUM(
        'pending',
        'paid',
        'failed',
        'refunded',
        'partially_refunded'
    ) NOT NULL DEFAULT 'pending',

        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
  
        CHECK (amount >= 0)
);


-- SHIPMENTS TABLE --



CREATE TABLE shipments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    tracking_number VARCHAR(150) NOT NULL UNIQUE,
    shipping_company VARCHAR(150) NOT NULL,
    shipped_at DATETIME NULL,
    expected_delivery DATETIME NULL,
    delivered_at DATETIME NULL,
    status ENUM( 
     'pending',
    'shipped',
    'in_transit',
    'delivered',
    'cancelled') NOT NULL,

        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);




-- RETURNS TABLE --




CREATE TABLE returns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_item_id INT NOT NULL,
    quantity INT NOT NULL,
    reason VARCHAR(500) NOT NULL,

    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME NULL,
    completed_at DATETIME NULL,

    status ENUM(
        'requested',
        'approved',
        'rejected',
        'completed'
    ) NOT NULL DEFAULT 'requested',


        FOREIGN KEY (order_item_id)
        REFERENCES order_items(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        CHECK (quantity > 0)
);



-- REVIEWS TABLE 


CREATE TABLE reviews (
    id INT
    AUTO_INCREMENT PRIMARY KEY,   
    customer_id INT NOT NULL,
   
    product_id INT NOT NULL,

    order_item_id INT NOT NULL,
    rating INT NOT NULL,
    comment TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
  
        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        FOREIGN KEY (order_item_id)
        REFERENCES order_items(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
   
        CHECK (rating BETWEEN 1 AND 5),
    UNIQUE KEY uq_customer_order_item_review
        (customer_id, order_item_id)
);



-- SELLER SETTLEMENTS TABLE




CREATE TABLE seller_settlements (
    id INT
    AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    gross_sales DECIMAL(12,2) NOT NULL DEFAULT 0,
    commission_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    refund_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    net_amount DECIMAL(12,2) NOT NULL DEFAULT 0,

    paid_at DATETIME,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',

        FOREIGN KEY (seller_id)
        REFERENCES sellers(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        CHECK (gross_sales >= 0),

        CHECK (commission_amount >= 0),
 
        CHECK (refund_amount >= 0),

        CHECK (net_amount >= 0),

        CHECK (period_end >= period_start),
    UNIQUE KEY uq_seller_settlement_period
        (seller_id, period_start, period_end)
);

