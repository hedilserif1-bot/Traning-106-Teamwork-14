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


--DATA PRODUCTS TABLE

INSERT INTO products
(seller_id, category_id, sku, product_name, description, price, cost_price, stock_quantity, minimum_stock, status)
VALUES
(1, 1, 'SKU-ELC-001', 'Samsung Galaxy A15', 'Akilli telefon', 8999.90, 7200.00, 35, 5, 'active'),
(2, 1, 'SKU-ELC-002', 'Apple iPhone 15', 'Apple akilli telefon', 42999.90, 36500.00, 20, 5, 'active'),
(3, 1, 'SKU-ELC-003', 'Xiaomi Redmi Note 13', 'Xiaomi akilli telefon', 10999.90, 8500.00, 42, 8, 'active'),
(4, 1, 'SKU-ELC-004', 'Huawei Nova 11', 'Huawei akilli telefon', 14999.90, 11800.00, 18, 4, 'active'),
(5, 1, 'SKU-ELC-005', 'Oppo Reno 11', 'Oppo akilli telefon', 16999.90, 13200.00, 25, 5, 'active'),
(6, 1, 'SKU-ELC-006', 'Samsung Galaxy S24', 'Samsung amiral gemisi telefon', 34999.90, 28500.00, 12, 3, 'active'),
(7, 1, 'SKU-ELC-007', 'Google Pixel 8', 'Google akilli telefon', 27999.90, 22500.00, 15, 3, 'active'),
(8, 1, 'SKU-ELC-008', 'OnePlus Nord 3', 'OnePlus akilli telefon', 18999.90, 14800.00, 22, 4, 'active'),

(9, 2, 'SKU-FSH-009', 'Erkek Basic Tisort', 'Pamuklu erkek tisortu', 499.90, 250.00, 80, 15, 'active'),
(10, 2, 'SKU-FSH-010', 'Kadin Basic Tisort', 'Pamuklu kadin tisortu', 499.90, 250.00, 75, 15, 'active'),
(11, 2, 'SKU-FSH-011', 'Erkek Kot Pantolon', 'Klasik kot pantolon', 1299.90, 700.00, 45, 8, 'active'),
(12, 2, 'SKU-FSH-012', 'Kadin Kot Pantolon', 'Modern kot pantolon', 1399.90, 760.00, 40, 8, 'active'),
(13, 2, 'SKU-FSH-013', 'Erkek Spor Mont', 'Su gecirmez spor mont', 2499.90, 1450.00, 30, 6, 'active'),
(14, 2, 'SKU-FSH-014', 'Kadin Kaban', 'Kislik kadin kaban', 2999.90, 1750.00, 25, 5, 'active'),
(15, 2, 'SKU-FSH-015', 'Erkek Sweatshirt', 'Kapusonlu sweatshirt', 999.90, 520.00, 60, 10, 'active'),
(16, 2, 'SKU-FSH-016', 'Kadin Sweatshirt', 'Gunluk sweatshirt', 999.90, 520.00, 55, 10, 'active'),

(17, 3, 'SKU-HOM-017', 'Modern Koltuk', 'Uc kisilik modern koltuk', 8999.90, 6100.00, 10, 2, 'active'),
(18, 3, 'SKU-HOM-018', 'Ahşap Yemek Masasi', 'Ahşap yemek masasi', 6499.90, 4300.00, 8, 2, 'active'),
(19, 3, 'SKU-HOM-019', 'Ofis Calisma Masasi', 'Modern calisma masasi', 3499.90, 2200.00, 15, 3, 'active'),
(20, 3, 'SKU-HOM-020', 'Kitaplik', 'Bes rafli kitaplik', 1999.90, 1150.00, 25, 5, 'active'),
(1, 3, 'SKU-HOM-021', 'TV Unitesi', 'Modern TV unitesi', 3999.90, 2500.00, 12, 3, 'active'),
(2, 3, 'SKU-HOM-022', 'Komodin', 'Ahşap komodin', 1499.90, 850.00, 20, 4, 'active'),
(3, 3, 'SKU-HOM-023', 'Gardrop', 'Uclu kapakli gardrop', 5999.90, 3800.00, 9, 2, 'active'),
(4, 3, 'SKU-HOM-024', 'Calisma Sandalyesi', 'Ergonomik ofis sandalyesi', 2799.90, 1700.00, 18, 4, 'active'),

(5, 4, 'SKU-SPT-025', 'Yoga Matisi', 'Kaymaz yoga matı', 699.90, 350.00, 70, 10, 'active'),
(6, 4, 'SKU-SPT-026', 'Dambıl Seti', '20 kg dambıl seti', 1599.90, 950.00, 35, 7, 'active'),
(7, 4, 'SKU-SPT-027', 'Koşu Ayakkabisi', 'Profesyonel kosu ayakkabisi', 2499.90, 1500.00, 28, 5, 'active'),
(8, 4, 'SKU-SPT-028', 'Futbol Topu', 'Profesyonel futbol topu', 899.90, 450.00, 50, 10, 'active'),
(9, 4, 'SKU-SPT-029', 'Basketbol Topu', 'Salon basketbol topu', 999.90, 500.00, 45, 8, 'active'),
(10, 4, 'SKU-SPT-030', 'Fitness Eldiveni', 'Spor salonu eldiveni', 399.90, 180.00, 90, 15, 'active'),
(11, 4, 'SKU-SPT-031', 'Spor Cantasi', 'Buyuk spor cantasi', 799.90, 400.00, 40, 8, 'active'),
(12, 4, 'SKU-SPT-032', 'Bisiklet Kaski', 'Guvenli bisiklet kaski', 1199.90, 650.00, 32, 6, 'active'),

(13, 5, 'SKU-BOK-033', 'SQL Ogreniyorum', 'SQL egitim kitabi', 349.90, 180.00, 60, 10, 'active'),
(14, 5, 'SKU-BOK-034', 'Python Programlama', 'Python baslangic kitabi', 449.90, 230.00, 55, 10, 'active'),
(15, 5, 'SKU-BOK-035', 'Web Gelistirme', 'Web programlama kitabi', 499.90, 260.00, 45, 8, 'active'),
(16, 5, 'SKU-BOK-036', 'Veri Yapilari', 'Veri yapilari ders kitabi', 399.90, 210.00, 35, 7, 'active'),
(17, 5, 'SKU-BOK-037', 'Algoritmalar', 'Algoritma ve programlama kitabi', 549.90, 290.00, 30, 6, 'active'),
(18, 5, 'SKU-BOK-038', 'Java Programlama', 'Java egitim kitabi', 599.90, 320.00, 25, 5, 'active'),
(19, 5, 'SKU-BOK-039', 'Veritabani Sistemleri', 'Veritabani yonetim kitabi', 479.90, 250.00, 40, 8, 'active'),
(20, 5, 'SKU-BOK-040', 'Yapay Zeka Temelleri', 'Yapay zeka baslangic kitabi', 649.90, 350.00, 22, 4, 'active'),

(1, 6, 'SKU-ACC-041', 'USB-C Sarj Kablosu', 'Hizli sarj destekli kablo', 249.90, 100.00, 120, 20, 'active'),
(2, 6, 'SKU-ACC-042', 'Bluetooth Kulaklik', 'Kablosuz bluetooth kulaklik', 1299.90, 700.00, 65, 12, 'active'),
(3, 6, 'SKU-ACC-043', 'Telefon Kilifi', 'Silikon telefon kilifi', 199.90, 70.00, 150, 25, 'active'),
(4, 6, 'SKU-ACC-044', 'Ekran Koruyucu', 'Temperli cam ekran koruyucu', 149.90, 50.00, 180, 30, 'active'),
(5, 6, 'SKU-ACC-045', 'Powerbank 20000mAh', 'Yuksek kapasiteli powerbank', 999.90, 550.00, 40, 8, 'active'),
(6, 6, 'SKU-ACC-046', 'Kablosuz Sarj Standi', 'Telefon sarj standi', 799.90, 420.00, 35, 7, 'active'),
(7, 6, 'SKU-ACC-047', 'USB Hub', 'Coklu USB hub', 599.90, 300.00, 50, 10, 'active'),
(8, 6, 'SKU-ACC-048', 'Laptop Cantasi', '15.6 inc laptop cantasi', 899.90, 480.00, 28, 5, 'active'),

(9, 7, 'SKU-LAP-049', 'Lenovo IdeaPad 3', 'Gundelik kullanim laptopu', 22999.90, 18500.00, 14, 3, 'active'),
(10, 7, 'SKU-LAP-050', 'HP Pavilion 15', 'Performans laptopu', 24999.90, 20000.00, 12, 3, 'active'),
(11, 7, 'SKU-LAP-051', 'Asus VivoBook', 'Ince ve hafif laptop', 21999.90, 17500.00, 18, 3, 'active'),
(12, 7, 'SKU-LAP-052', 'Acer Aspire 5', 'Gundelik laptop', 19999.90, 16000.00, 20, 4, 'active'),
(13, 7, 'SKU-LAP-053', 'Dell Inspiron 15', 'Ofis laptopu', 25999.90, 21000.00, 10, 2, 'active'),
(14, 7, 'SKU-LAP-054', 'MacBook Air M2', 'Apple dizustu bilgisayar', 37999.90, 31000.00, 8, 2, 'active'),
(15, 7, 'SKU-LAP-055', 'MSI Gaming Laptop', 'Oyuncu laptopu', 49999.90, 41000.00, 6, 2, 'active'),
(16, 7, 'SKU-LAP-056', 'Huawei MateBook', 'Huawei dizustu bilgisayar', 27999.90, 22500.00, 9, 2, 'active'),

(17, 8, 'SKU-WOM-057', 'Kadin Spor Ayakkabi', 'Gunluk spor ayakkabi', 1799.90, 950.00, 35, 7, 'active'),
(18, 8, 'SKU-WOM-058', 'Kadin Elbise', 'Gunluk yazlik elbise', 1499.90, 750.00, 40, 8, 'active'),
(19, 8, 'SKU-WOM-059', 'Kadin Canta', 'Omuz cantasi', 1299.90, 650.00, 30, 6, 'active'),
(20, 8, 'SKU-WOM-060', 'Kadin Cuzdan', 'Deri cuzdan', 699.90, 320.00, 45, 8, 'active'),
(1, 8, 'SKU-WOM-061', 'Kadin Gunes Gozlugu', 'UV korumali gunes gozlugu', 899.90, 420.00, 55, 10, 'active'),
(2, 8, 'SKU-WOM-062', 'Kadin Saat', 'Klasik kol saati', 1999.90, 1050.00, 20, 4, 'active'),
(3, 8, 'SKU-WOM-063', 'Kadin Hirka', 'Yumusak triko hirka', 999.90, 500.00, 50, 10, 'active'),
(4, 8, 'SKU-WOM-064', 'Kadin Esarp', 'Desenli esarp', 399.90, 170.00, 75, 15, 'active'),

(5, 9, 'SKU-MEN-065', 'Erkek Spor Ayakkabi', 'Erkek kosu ayakkabisi', 1899.90, 1000.00, 40, 8, 'active'),
(6, 9, 'SKU-MEN-066', 'Erkek Gömlek', 'Klasik erkek gomlegi', 899.90, 450.00, 50, 10, 'active'),
(7, 9, 'SKU-MEN-067', 'Erkek Ceket', 'Klasik erkek ceketi', 2499.90, 1300.00, 25, 5, 'active'),
(8, 9, 'SKU-MEN-068', 'Erkek Cuzdan', 'Deri erkek cuzdan', 699.90, 320.00, 60, 12, 'active'),
(9, 9, 'SKU-MEN-069', 'Erkek Kemer', 'Deri kemer', 499.90, 220.00, 70, 12, 'active'),
(10, 9, 'SKU-MEN-070', 'Erkek Saat', 'Klasik erkek saati', 2199.90, 1200.00, 18, 4, 'active'),
(11, 9, 'SKU-MEN-071', 'Erkek Kazak', 'Kislik erkek kazagi', 1199.90, 600.00, 35, 7, 'active'),
(12, 9, 'SKU-MEN-072', 'Erkek Polo Tisort', 'Polo yaka tisort', 799.90, 390.00, 65, 12, 'active'),

(13, 10, 'SKU-FUR-073', 'Tek Kisilik Yatak', 'Konforlu tek kisilik yatak', 3999.90, 2500.00, 12, 3, 'active'),
(14, 10, 'SKU-FUR-074', 'Cift Kisilik Yatak', 'Konforlu cift kisilik yatak', 6499.90, 4200.00, 8, 2, 'active'),
(15, 10, 'SKU-FUR-075', 'Ofis Sehpası', 'Modern ofis sehpası', 1299.90, 650.00, 25, 5, 'active'),
(16, 10, 'SKU-FUR-076', 'TV Sehpası', 'Minimal TV sehpası', 1799.90, 900.00, 18, 4, 'active'),
(17, 10, 'SKU-FUR-077', 'Ayakkabilik', 'Bes rafli ayakkabilik', 1599.90, 800.00, 20, 4, 'active'),
(18, 10, 'SKU-FUR-078', 'Mutfak Masasi', 'Dort kisilik mutfak masasi', 2999.90, 1750.00, 15, 3, 'active'),
(19, 10, 'SKU-FUR-079', 'Bar Taburesi', 'Metal bar taburesi', 899.90, 450.00, 30, 6, 'active'),
(20, 10, 'SKU-FUR-080', 'Konsol', 'Modern salon konsolu', 3499.90, 2200.00, 7, 2, 'active'),

(1, 11, 'SKU-KIT-081', 'Tencere Seti', 'Paslanmaz celik tencere seti', 2999.90, 1650.00, 20, 4, 'active'),
(2, 11, 'SKU-KIT-082', 'Tava Seti', 'Yapismayan tava seti', 1899.90, 950.00, 30, 6, 'active'),
(3, 11, 'SKU-KIT-083', 'Blender', 'Guclu mutfak blenderi', 1499.90, 750.00, 35, 7, 'active'),
(4, 11, 'SKU-KIT-084', 'Kahve Makinesi', 'Filtre kahve makinesi', 2499.90, 1350.00, 22, 4, 'active'),
(5, 11, 'SKU-KIT-085', 'Elektrikli Su Isitici', 'Cam kettle', 899.90, 420.00, 45, 8, 'active'),
(6, 11, 'SKU-KIT-086', 'Mikser', 'Mutfak mikseri', 1199.90, 600.00, 25, 5, 'active'),
(7, 11, 'SKU-KIT-087', 'Ekmek Kizartma Makinesi', 'Iki dilimli tost makinesi', 999.90, 500.00, 28, 5, 'active'),
(8, 11, 'SKU-KIT-088', 'Mutfak Robotu', 'Cok fonksiyonlu mutfak robotu', 2999.90, 1600.00, 15, 3, 'active'),

(9, 12, 'SKU-FIT-089', 'Koşu Bandi', 'Ev tipi kosu bandi', 15999.90, 10500.00, 7, 2, 'active'),
(10, 12, 'SKU-FIT-090', 'Egzersiz Bisikleti', 'Ev tipi kondisyon bisikleti', 8999.90, 5600.00, 10, 2, 'active'),
(11, 12, 'SKU-FIT-091', 'Pilates Topu', 'Pilates egzersiz topu', 499.90, 220.00, 70, 12, 'active'),
(12, 12, 'SKU-FIT-092', 'Direnc Bandi Seti', 'Besli direnç bandi seti', 599.90, 280.00, 65, 12, 'active'),
(13, 12, 'SKU-FIT-093', 'Fitness Matı', 'Kalın fitness matı', 799.90, 380.00, 50, 10, 'active'),
(14, 12, 'SKU-FIT-094', 'Kettlebell 12kg', 'Döküm kettlebell', 999.90, 520.00, 30, 6, 'active'),
(15, 12, 'SKU-FIT-095', 'Kettlebell 16kg', 'Agirlik kettlebell', 1299.90, 680.00, 24, 5, 'active'),
(16, 12, 'SKU-FIT-096', 'Barfiks Demiri', 'Kapi tipi barfiks demiri', 699.90, 350.00, 40, 8, 'active'),

(17, 13, 'SKU-OUT-097', 'Kamp Cadiri', 'Dort kisilik kamp cadiri', 3499.90, 2000.00, 15, 3, 'active'),
(18, 13, 'SKU-OUT-098', 'Uyku Tulumu', 'Dort mevsim uyku tulumu', 1999.90, 1050.00, 25, 5, 'active'),
(19, 13, 'SKU-OUT-099', 'Kamp Sandalyesi', 'Katlanabilir kamp sandalyesi', 799.90, 380.00, 45, 8, 'active'),
(20, 13, 'SKU-OUT-100', 'Kamp Masasi', 'Katlanabilir kamp masasi', 999.90, 500.00, 30, 6, 'active'),
(1, 13, 'SKU-OUT-101', 'Trekking Cantasi', '50 litre trekking cantasi', 2499.90, 1350.00, 18, 4, 'active'),
(2, 13, 'SKU-OUT-102', 'El Feneri', 'LED kamp feneri', 499.90, 220.00, 80, 15, 'active'),
(3, 13, 'SKU-OUT-103', 'Termos', '1 litre celik termos', 699.90, 320.00, 60, 12, 'active'),
(4, 13, 'SKU-OUT-104', 'Pusula', 'Profesyonel kamp pusulasi', 399.90, 160.00, 35, 7, 'active'),

(5, 14, 'SKU-EDU-105', 'Matematik Soru Bankasi', 'Lise matematik soru bankasi', 299.90, 140.00, 90, 15, 'active'),
(6, 14, 'SKU-EDU-106', 'Fizik Soru Bankasi', 'Lise fizik soru bankasi', 299.90, 140.00, 80, 15, 'active'),
(7, 14, 'SKU-EDU-107', 'Kimya Soru Bankasi', 'Lise kimya soru bankasi', 299.90, 140.00, 75, 15, 'active'),
(8, 14, 'SKU-EDU-108', 'Biyoloji Soru Bankasi', 'Lise biyoloji soru bankasi', 299.90, 140.00, 70, 12, 'active'),
(9, 14, 'SKU-EDU-109', 'Ingilizce Gramer', 'Ingilizce gramer kitabi', 349.90, 170.00, 65, 12, 'active'),
(10, 14, 'SKU-EDU-110', 'YDS Hazirlik', 'YDS sinavi hazirlik kitabi', 449.90, 230.00, 50, 10, 'active'),
(11, 14, 'SKU-EDU-111', 'TYT Deneme', 'TYT deneme sinavi kitabi', 249.90, 120.00, 100, 20, 'active'),
(12, 14, 'SKU-EDU-112', 'AYT Deneme', 'AYT deneme sinavi kitabi', 249.90, 120.00, 95, 20, 'active'),

(13, 15, 'SKU-GEN-113', 'Akilli Saat', 'Bluetooth destekli akilli saat', 2499.90, 1350.00, 25, 5, 'active'),
(14, 15, 'SKU-GEN-114', 'Masa Lambasi', 'LED masa lambasi', 599.90, 280.00, 45, 8, 'active'),
(15, 15, 'SKU-GEN-115', 'Sirt Cantasi', 'Gunluk kullanim sirt cantasi', 899.90, 420.00, 50, 10, 'active'),
(16, 15, 'SKU-GEN-116', 'Cok Amacli Organizer', 'Ev ve ofis organizeri', 399.90, 180.00, 70, 12, 'active'),
(17, 15, 'SKU-GEN-117', 'Bluetooth Hoparlor', 'Tasınabilir bluetooth hoparlor', 1499.90, 750.00, 35, 7, 'active'),
(18, 15, 'SKU-GEN-118', 'Masaustu Saat', 'Dijital masaustu saat', 499.90, 230.00, 55, 10, 'active'),
(19, 15, 'SKU-GEN-119', 'Kablosuz Mouse', 'Ergonomik kablosuz mouse', 699.90, 350.00, 65, 12, 'active'),
(20, 15, 'SKU-GEN-120', 'Mekanik Klavye', 'RGB mekanik klavye', 1799.90, 950.00, 30, 6, 'active');


--DATA PRODUCT_PRICE_HISTORY


INSERT INTO product_price_history
(product_id, old_price, new_price)
VALUES
(1, 8499.90, 8999.90),
(2, 41999.90, 42999.90),
(3, 10499.90, 10999.90),
(4, 14499.90, 14999.90),
(5, 15999.90, 16999.90),
(6, 33999.90, 34999.90),
(7, 26999.90, 27999.90),
(8, 17999.90, 18999.90),

(9, 449.90, 499.90),
(10, 449.90, 499.90),
(11, 1199.90, 1299.90),
(12, 1299.90, 1399.90),
(13, 2299.90, 2499.90),
(14, 2799.90, 2999.90),
(15, 899.90, 999.90),
(16, 899.90, 999.90),

(17, 8499.90, 8999.90),
(18, 6199.90, 6499.90),
(19, 3299.90, 3499.90),
(20, 1799.90, 1999.90),
(21, 3799.90, 3999.90),
(22, 1399.90, 1499.90),
(23, 5699.90, 5999.90),
(24, 2599.90, 2799.90),

(25, 649.90, 699.90),
(26, 1499.90, 1599.90),
(27, 2299.90, 2499.90),
(28, 799.90, 899.90),
(29, 899.90, 999.90),
(30, 349.90, 399.90),
(31, 699.90, 799.90),
(32, 1099.90, 1199.90),

(33, 299.90, 349.90),
(34, 399.90, 449.90),
(35, 449.90, 499.90),
(36, 349.90, 399.90),
(37, 499.90, 549.90),
(38, 549.90, 599.90),
(39, 429.90, 479.90),
(40, 599.90, 649.90);
