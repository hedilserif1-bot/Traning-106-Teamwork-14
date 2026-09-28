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









--DATA CUSTOMERS TABLE


INSERT INTO customers
(full_name, email, phone, status)
VALUES
('Ahmed Taha', 'ahmed.taha01@gmail.com', '+902840571001', 'active'),
('Sara Ali', 'sara.ali02@gmail.com', '+902840571002', 'active'),
('Omar Hassan', 'omar.hassan03@gmail.com', '+902840571003', 'inactive'),
('Lina Khaled', 'lina.khaled04@gmail.com', '+902840571004', 'active'),
('Youssef Mahmoud', 'youssef.mahmoud05@gmail.com', '+902840571005', 'blocked'),
('Mariam Saleh', 'mariam.saleh06@gmail.com', '+902840571006', 'active'),
('Adam Ibrahim', 'adam.ibrahim07@gmail.com', '+902840571007', 'active'),
('Nour Ahmed', 'nour.ahmed08@gmail.com', '+902840571008', 'inactive'),
('Karim Adel', 'karim.adel09@gmail.com', '+902840571009', 'active'),
('Hana Mostafa', 'hana.mostafa10@gmail.com', '+902840571010', 'active'),

('Ali Nasser', 'ali.nasser11@gmail.com', '+902840571011', 'active'),
('Layla Sami', 'layla.sami12@gmail.com', '+902840571012', 'blocked'),
('Khaled Amin', 'khaled.amin13@gmail.com', '+902840571013', 'active'),
('Rana Fadi', 'rana.fadi14@gmail.com', '+902840571014', 'inactive'),
('Tarek Samir', 'tarek.samir15@gmail.com', '+902840571015', 'active'),
('Dina Hossam', 'dina.hossam16@gmail.com', '+902840571016', 'active'),
('Mahmoud Yasin', 'mahmoud.yasin17@gmail.com', '+902840571017', 'active'),
('Reem Adel', 'reem.adel18@gmail.com', '+902840571018', 'inactive'),
('Ziad Karim', 'ziad.karim19@gmail.com', '+902840571019', 'active'),
('Salma Nabil', 'salma.nabil20@gmail.com', '+902840571020', 'blocked'),

('Hasan Omar', 'hasan.omar21@gmail.com', '+902840571021', 'active'),
('Maya Khalil', 'maya.khalil22@gmail.com', '+902840571022', 'active'),
('Faris Ahmed', 'faris.ahmed23@gmail.com', '+902840571023', 'inactive'),
('Jana Ali', 'jana.ali24@gmail.com', '+902840571024', 'active'),
('Sami Hassan', 'sami.hassan25@gmail.com', '+902840571025', 'active'),
('Nada Mahmoud', 'nada.mahmoud26@gmail.com', '+902840571026', 'active'),
('Bilal Saleh', 'bilal.saleh27@gmail.com', '+902840571027', 'blocked'),
('Huda Ibrahim', 'huda.ibrahim28@gmail.com', '+902840571028', 'active'),
('Rami Nasser', 'rami.nasser29@gmail.com', '+902840571029', 'inactive'),
('Amira Khaled', 'amira.khaled30@gmail.com', '+902840571030', 'active'),

('Ibrahim Sami', 'ibrahim.sami31@gmail.com', '+902840571031', 'active'),
('Dalia Omar', 'dalia.omar32@gmail.com', '+902840571032', 'active'),
('Mustafa Adel', 'mustafa.adel33@gmail.com', '+902840571033', 'inactive'),
('Rita Nabil', 'rita.nabil34@gmail.com', '+902840571034', 'active'),
('Walid Fadi', 'walid.fadi35@gmail.com', '+902840571035', 'blocked'),
('Aya Samir', 'aya.samir36@gmail.com', '+902840571036', 'active'),
('Saeed Yasin', 'saeed.yasin37@gmail.com', '+902840571037', 'active'),
('Lama Karim', 'lama.karim38@gmail.com', '+902840571038', 'inactive'),
('Fadi Hossam', 'fadi.hossam39@gmail.com', '+902840571039', 'active'),
('Rania Amin', 'rania.amin40@gmail.com', '+902840571040', 'active'),

('Nader Hassan', 'nader.hassan41@gmail.com', '+902840571041', 'active'),
('Mona Saleh', 'mona.saleh42@gmail.com', '+902840571042', 'inactive'),
('Yara Ahmed', 'yara.ahmed43@gmail.com', '+902840571043', 'active'),
('Sultan Ali', 'sultan.ali44@gmail.com', '+902840571044', 'blocked'),
('Farah Mahmoud', 'farah.mahmoud45@gmail.com', '+902840571045', 'active'),
('Ayman Khaled', 'ayman.khaled46@gmail.com', '+902840571046', 'active'),
('Layan Sami', 'layan.sami47@gmail.com', '+902840571047', 'inactive'),
('Hani Ibrahim', 'hani.ibrahim48@gmail.com', '+902840571048', 'active'),
('Sahar Nasser', 'sahar.nasser49@gmail.com', '+902840571049', 'active'),
('Majed Adel', 'majed.adel50@gmail.com', '+902840571050', 'blocked'),

('Rasha Karim', 'rasha.karim51@gmail.com', '+902840571051', 'active'),
('Fahad Omar', 'fahad.omar52@gmail.com', '+902840571052', 'active'),
('Dima Hassan', 'dima.hassan53@gmail.com', '+902840571053', 'inactive'),
('Bassem Saleh', 'bassem.saleh54@gmail.com', '+902840571054', 'active'),
('Laila Fadi', 'laila.fadi55@gmail.com', '+902840571055', 'active'),
('Anas Samir', 'anas.samir56@gmail.com', '+902840571056', 'active'),
('Hiba Yasin', 'hiba.yasin57@gmail.com', '+902840571057', 'blocked'),
('Tamer Nabil', 'tamer.nabil58@gmail.com', '+902840571058', 'inactive'),
('Samar Ahmed', 'samar.ahmed59@gmail.com', '+902840571059', 'active'),
('Bassam Ali', 'bassam.ali60@gmail.com', '+902840571060', 'active'),

('Rayan Khaled', 'rayan.khaled61@gmail.com', '+902840571061', 'active'),
('Mira Hassan', 'mira.hassan62@gmail.com', '+902840571062', 'inactive'),
('Wassim Mahmoud', 'wassim.mahmoud63@gmail.com', '+902840571063', 'active'),
('Sonia Saleh', 'sonia.saleh64@gmail.com', '+902840571064', 'active'),
('Nabil Ibrahim', 'nabil.ibrahim65@gmail.com', '+902840571065', 'blocked'),
('Joud Ali', 'joud.ali66@gmail.com', '+902840571066', 'active'),
('Hussein Sami', 'hussein.sami67@gmail.com', '+902840571067', 'active'),
('Mariam Nasser', 'mariam.nasser68@gmail.com', '+902840571068', 'inactive'),
('Kareem Fadi', 'kareem.fadi69@gmail.com', '+902840571069', 'active'),
('Salim Yasin', 'salim.yasin70@gmail.com', '+902840571070', 'active');


--DATA SELLERS TABLE


INSERT INTO sellers
(store_name, owner_name, email, phone, commission_rate, status)
VALUES
('Tech World', 'Ahmed Taha', 'techworld01@gmail.com', '+902840580001', 8.50, 'active'),
('Fashion House', 'Sara Ali', 'fashionhouse02@gmail.com', '+902840580002', 10.00, 'active'),
('Home Center', 'Omar Hassan', 'homecenter03@gmail.com', '+902840580003', 7.50, 'pending'),
('Smart Market', 'Lina Khaled', 'smartmarket04@gmail.com', '+902840580004', 12.00, 'active'),
('Book Planet', 'Youssef Mahmoud', 'bookplanet05@gmail.com', '+902840580005', 6.00, 'suspended'),

('Beauty Store', 'Mariam Saleh', 'beautystore06@gmail.com', '+902840580006', 9.50, 'active'),
('Sports Zone', 'Adam Ibrahim', 'sportszone07@gmail.com', '+902840580007', 11.00, 'active'),
('Kids World', 'Nour Ahmed', 'kidsworld08@gmail.com', '+902840580008', 8.00, 'pending'),
('Electro Shop', 'Karim Adel', 'electroshop09@gmail.com', '+902840580009', 13.50, 'active'),
('Garden Life', 'Hana Mostafa', 'gardenlife10@gmail.com', '+902840580010', 5.50, 'closed'),

('Mobile Center', 'Ali Nasser', 'mobilecenter11@gmail.com', '+902840580011', 14.00, 'active'),
('Luxury Store', 'Layla Sami', 'luxurystore12@gmail.com', '+902840580012', 15.00, 'suspended'),
('Daily Market', 'Khaled Amin', 'dailymarket13@gmail.com', '+902840580013', 7.00, 'active'),
('Office Plus', 'Rana Fadi', 'officeplus14@gmail.com', '+902840580014', 6.50, 'pending'),
('Auto Parts', 'Tarek Samir', 'autoparts15@gmail.com', '+902840580015', 9.00, 'active'),

('Pet World', 'Dina Hossam', 'petworld16@gmail.com', '+902840580016', 8.75, 'active'),
('Music Store', 'Mahmoud Yasin', 'musicstore17@gmail.com', '+902840580017', 10.50, 'suspended'),
('Coffee Market', 'Reem Adel', 'coffeemarket18@gmail.com', '+902840580018', 5.00, 'active'),
('Travel Shop', 'Ziad Karim', 'travelshop19@gmail.com', '+902840580019', 12.50, 'pending'),
('Gift Center', 'Salma Nabil', 'giftcenter20@gmail.com', '+902840580020', 7.25, 'active');


--DATA CATEGORIES TABLE


INSERT INTO categories (parent_id, category_name, status)
VALUES
(NULL, 'Electronics', 'active'),
(NULL, 'Clothing', 'active'),
(NULL, 'Home & Kitchen', 'active'),
(NULL, 'Beauty & Personal Care', 'active'),
(NULL, 'Sports', 'active'),
(1, 'Mobile Phones', 'active'),
(1, 'Laptops', 'active'),
(1, 'Headphones', 'active'),
(2, 'Men Clothing', 'active'),
(2, 'Women Clothing', 'active'),
(2, 'Shoes', 'active'),
(3, 'Kitchen Appliances', 'active'),
(3, 'Furniture', 'active'),
(4, 'Skin Care', 'active'),
(5, 'Fitness Equipment', 'active');
