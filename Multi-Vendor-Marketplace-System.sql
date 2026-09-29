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



--REFUNDS TABLE


CREATE TABLE refunds (
    id INT AUTO_INCREMENT PRIMARY KEY,
    return_id INT NOT NULL,
    payment_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    refunded_at DATETIME NULL,
    status VARCHAR(50) NOT NULL,


        FOREIGN KEY (return_id)
        REFERENCES returns(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

        FOREIGN KEY (payment_id)
        REFERENCES payments(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
 
        CHECK (amount >= 0)
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






--DATA CUSTOMER_ADDRESSES TABLE


INSERT INTO customer_addresses
(customer_id, title, city, district, street, postal_code, is_default)
VALUES
(1, 'Home', 'Istanbul', 'Kadikoy', 'Bagdat Caddesi No:15', '34710', TRUE),
(2, 'Apartment', 'Istanbul', 'Besiktas', 'Ihlamurdere Caddesi No:28', '34349', TRUE),
(3, 'Residence', 'Istanbul', 'Sisli', 'Halaskargazi Caddesi No:42', '34371', TRUE),
(4, 'Home', 'Ankara', 'Cankaya', 'Tunali Hilmi Caddesi No:18', '06680', TRUE),
(5, 'Family House', 'Izmir', 'Konak', 'Mithatpasa Caddesi No:55', '35260', TRUE),
(6, 'Apartment', 'Istanbul', 'Uskudar', 'Selmanipak Caddesi No:12', '34668', TRUE),
(7, 'Home', 'Bursa', 'Nilufer', 'Gorukle Caddesi No:31', '16285', TRUE),
(8, 'Residence', 'Antalya', 'Muratpasa', 'Lara Caddesi No:24', '07100', TRUE),
(9, 'Family House', 'Adana', 'Seyhan', 'Ziyapasa Bulvari No:17', '01140', TRUE),
(10, 'Apartment', 'Istanbul', 'Maltepe', 'Baglarbasi Caddesi No:9', '34844', TRUE),

(11, 'Home', 'Ankara', 'Kecioren', 'Etlik Caddesi No:36', '06290', TRUE),
(12, 'Residence', 'Izmir', 'Bornova', 'Kazim Dirik Caddesi No:44', '35100', TRUE),
(13, 'Apartment', 'Istanbul', 'Bakirkoy', 'Istasyon Caddesi No:21', '34142', TRUE),
(14, 'Family House', 'Bursa', 'Osmangazi', 'Cekirge Caddesi No:13', '16100', TRUE),
(15, 'Home', 'Antalya', 'Konyaalti', 'Arapsuyu Caddesi No:48', '07070', TRUE),
(16, 'Residence', 'Istanbul', 'Fatih', 'Fevzi Pasa Caddesi No:27', '34083', TRUE),
(17, 'Apartment', 'Ankara', 'Etimesgut', 'Baglica Bulvari No:19', '06790', TRUE),
(18, 'Home', 'Istanbul', 'Kartal', 'Kordonboyu Caddesi No:33', '34860', TRUE),
(19, 'Family House', 'Izmir', 'Karsiyaka', 'Cemal Gurbuz Caddesi No:11', '35540', TRUE),
(20, 'Residence', 'Adana', 'Cukurova', 'Turgut Ozal Bulvari No:29', '01170', TRUE),

(21, 'Apartment', 'Istanbul', 'Atasehir', 'Kayisdagi Caddesi No:16', '34750', TRUE),
(22, 'Home', 'Istanbul', 'Umraniye', 'Alemdag Caddesi No:51', '34768', TRUE),
(23, 'Family House', 'Ankara', 'Mamak', 'Dikimevi Caddesi No:25', '06620', TRUE),
(24, 'Residence', 'Izmir', 'Buca', 'Menderes Caddesi No:37', '35370', TRUE),
(25, 'Apartment', 'Bursa', 'Yildirim', 'Davutdede Caddesi No:62', '16350', TRUE),
(26, 'Home', 'Istanbul', 'Pendik', 'Gazi Pasa Caddesi No:14', '34890', TRUE),
(27, 'Residence', 'Antalya', 'Kepez', 'Sakarya Bulvari No:23', '07060', TRUE),
(28, 'Family House', 'Istanbul', 'Bakirkoy', 'Yesilkoy Caddesi No:39', '34149', TRUE),
(29, 'Apartment', 'Ankara', 'Cankaya', 'Mesrutiyet Caddesi No:8', '06420', TRUE),
(30, 'Home', 'Izmir', 'Konak', 'Kibris Sehitleri Caddesi No:46', '35220', TRUE),

(31, 'Residence', 'Istanbul', 'Kadikoy', 'Moda Caddesi No:32', '34710', TRUE),
(32, 'Apartment', 'Istanbul', 'Beyoglu', 'Siraselviler Caddesi No:74', '34433', TRUE),
(33, 'Family House', 'Bursa', 'Nilufer', 'Odunluk Caddesi No:18', '16110', TRUE),
(34, 'Home', 'Antalya', 'Muratpasa', 'Guzeloba Caddesi No:27', '07230', TRUE),
(35, 'Residence', 'Adana', 'Seyhan', 'Cemalpasa Caddesi No:41', '01120', TRUE),
(36, 'Apartment', 'Istanbul', 'Sariyer', 'Buyukdere Caddesi No:63', '34453', TRUE),
(37, 'Home', 'Ankara', 'Yenimahalle', 'Ivedik Caddesi No:22', '06378', TRUE),
(38, 'Family House', 'Izmir', 'Bayrakli', 'Mansuroglu Caddesi No:35', '35535', TRUE),
(39, 'Residence', 'Istanbul', 'Esenyurt', 'Dogan Arasli Bulvari No:17', '34510', TRUE),
(40, 'Apartment', 'Bursa', 'Osmangazi', 'Altinova Caddesi No:45', '16250', TRUE),

(41, 'Home', 'Istanbul', 'Uskudar', 'Kisikli Caddesi No:29', '34676', TRUE),
(42, 'Residence', 'Ankara', 'Cankaya', 'Esat Caddesi No:52', '06660', TRUE),
(43, 'Apartment', 'Izmir', 'Bornova', 'Ergene Caddesi No:16', '35040', TRUE),
(44, 'Family House', 'Antalya', 'Konyaalti', 'Liman Caddesi No:38', '07130', TRUE),
(45, 'Home', 'Istanbul', 'Sisli', 'Valikonagi Caddesi No:21', '34365', TRUE),
(46, 'Residence', 'Adana', 'Seyhan', 'Kurtulus Caddesi No:34', '01130', TRUE),
(47, 'Apartment', 'Istanbul', 'Avcilar', 'Marmara Caddesi No:12', '34320', TRUE),
(48, 'Home', 'Bursa', 'Nilufer', 'Fethiye Caddesi No:47', '16140', TRUE),
(49, 'Family House', 'Ankara', 'Altindag', 'Talatpasa Bulvari No:26', '06140', TRUE),
(50, 'Residence', 'Izmir', 'Gaziemir', 'Akcay Caddesi No:53', '35410', TRUE),

(51, 'Apartment', 'Istanbul', 'Bakirkoy', 'Atakoy Caddesi No:18', '34158', TRUE),
(52, 'Home', 'Istanbul', 'Besiktas', 'Nispetiye Caddesi No:105', '34340', TRUE),
(53, 'Residence', 'Ankara', 'Kecioren', 'Sanatoryum Caddesi No:33', '06280', TRUE),
(54, 'Family House', 'Izmir', 'Karsiyaka', 'Girne Bulvari No:24', '35560', TRUE),
(55, 'Apartment', 'Antalya', 'Muratpasa', 'Fener Caddesi No:61', '07160', TRUE),
(56, 'Home', 'Istanbul', 'Kartal', 'Soganlik Caddesi No:14', '34880', TRUE),
(57, 'Residence', 'Bursa', 'Yildirim', 'Setbasi Caddesi No:28', '16360', TRUE),
(58, 'Apartment', 'Adana', 'Cukurova', 'Toros Caddesi No:39', '01170', TRUE),
(59, 'Family House', 'Istanbul', 'Pendik', 'Kaynarca Caddesi No:25', '34890', TRUE),
(60, 'Home', 'Ankara', 'Etimesgut', 'Eryaman Caddesi No:44', '06820', TRUE),

(61, 'Residence', 'Istanbul', 'Kadikoy', 'Fenerbahce Caddesi No:17', '34726', TRUE),
(62, 'Apartment', 'Izmir', 'Konak', 'Cumhuriyet Bulvari No:36', '35220', TRUE),
(63, 'Home', 'Antalya', 'Kepez', 'Dumlupinar Bulvari No:49', '07090', TRUE),
(64, 'Family House', 'Istanbul', 'Umraniye', 'Ihlamurkuyu Caddesi No:22', '34771', TRUE),
(65, 'Residence', 'Bursa', 'Osmangazi', 'Kukurtlu Caddesi No:31', '16080', TRUE),
(66, 'Apartment', 'Ankara', 'Cankaya', 'Oran Caddesi No:15', '06450', TRUE),
(67, 'Home', 'Istanbul', 'Beylikduzu', 'Adnan Kahveci Bulvari No:27', '34528', TRUE),
(68, 'Residence', 'Adana', 'Seyhan', 'Resatbey Caddesi No:42', '01120', TRUE),
(69, 'Family House', 'Izmir', 'Bornova', 'Evka Caddesi No:19', '35050', TRUE),
(70, 'Apartment', 'Istanbul', 'Sancaktepe', 'Sarikazi Caddesi No:34', '34885', TRUE);





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








--DATA CARTS TABLE

INSERT INTO carts
(customer_id, status)
VALUES
(1, 'active'),
(2, 'active'),
(3, 'converted'),
(4, 'abandoned'),
(5, 'active'),
(6, 'converted'),
(7, 'active'),
(8, 'active'),
(9, 'abandoned'),
(10, 'converted'),
(11, 'active'),
(12, 'active'),
(13, 'converted'),
(14, 'abandoned'),
(15, 'active'),
(16, 'active'),
(17, 'converted'),
(18, 'active'),
(19, 'abandoned'),
(20, 'active'),
(21, 'converted'),
(22, 'active'),
(23, 'active'),
(24, 'abandoned'),
(25, 'converted'),
(26, 'active'),
(27, 'active'),
(28, 'converted'),
(29, 'abandoned'),
(30, 'active'),
(31, 'active'),
(32, 'converted'),
(33, 'active'),
(34, 'abandoned'),
(35, 'active'),
(36, 'converted'),
(37, 'active'),
(38, 'active'),
(39, 'abandoned'),
(40, 'converted'),
(41, 'active'),
(42, 'active'),
(43, 'converted'),
(44, 'abandoned'),
(45, 'active'),
(46, 'converted'),
(47, 'active'),
(48, 'active'),
(49, 'abandoned'),
(50, 'converted');



--DATA CART ITEM TABLE


INSERT INTO cart_items (cart_id, product_id, quantity) VALUES
(1, 1, 5),
(1, 12, 3),
(1, 25, 7),
(1, 44, 4),
(2, 2, 6),
(2, 18, 4),
(2, 31, 8),
(2, 55, 5),
(3, 3, 9),
(3, 20, 4),
(3, 42, 6),
(3, 67, 3),
(4, 4, 5),
(4, 15, 7),
(4, 38, 4),
(4, 72, 9),
(5, 5, 3),
(5, 29, 8),
(5, 48, 6),
(5, 91, 4),
(6, 6, 7),
(6, 24, 5),
(6, 51, 3),
(6, 80, 6),
(7, 7, 4),
(7, 16, 9),
(7, 35, 5),
(7, 63, 7),
(8, 8, 6),
(8, 27, 3),
(8, 46, 8),
(8, 74, 5),
(9, 9, 4),
(9, 21, 7),
(9, 58, 5),
(9, 86, 9),
(10, 10, 8),
(10, 33, 4),
(10, 61, 6),
(10, 95, 3),
(11, 11, 5),
(11, 19, 7),
(11, 43, 4),
(11, 69, 8),
(12, 13, 6),
(12, 28, 5),
(12, 54, 9),
(12, 82, 4),
(13, 14, 3),
(13, 37, 6),
(13, 52, 7),
(13, 77, 5),
(14, 15, 8),
(14, 32, 4),
(14, 66, 5),
(14, 104, 7),
(15, 16, 5),
(15, 41, 9),
(15, 59, 4),
(15, 88, 6),
(16, 17, 7),
(16, 30, 3),
(16, 56, 8),
(16, 101, 5),
(17, 19, 4),
(17, 26, 6),
(17, 73, 5),
(17, 109, 8),
(18, 21, 9),
(18, 45, 4),
(18, 70, 6),
(18, 93, 5),
(19, 22, 5),
(19, 39, 7),
(19, 64, 3),
(19, 98, 6),
(20, 23, 8),
(20, 34, 5),
(20, 57, 4),
(20, 84, 7),
(21, 24, 6),
(21, 49, 3),
(21, 76, 8),
(21, 107, 5),
(22, 26, 4),
(22, 40, 7),
(22, 68, 6),
(22, 96, 9),
(23, 28, 5),
(23, 53, 8),
(23, 71, 4),
(23, 113, 6),
(24, 30, 7),
(24, 47, 5),
(24, 79, 3),
(24, 115, 8),
(25, 32, 6),
(25, 44, 4),
(25, 81, 7),
(25, 102, 5),
(26, 33, 8),
(26, 50, 3),
(26, 65, 6),
(26, 118, 4),
(27, 34, 5),
(27, 62, 9),
(27, 83, 4),
(27, 111, 7),
(28, 36, 6),
(28, 55, 5),
(28, 78, 8),
(28, 105, 3),
(29, 38, 4),
(29, 46, 7),
(29, 85, 5),
(29, 120, 6),
(30, 40, 9),
(30, 59, 3),
(30, 90, 7),
(30, 114, 5),
(31, 41, 6),
(31, 52, 4),
(31, 87, 8),
(31, 108, 5),
(32, 43, 7),
(32, 63, 3),
(32, 94, 6),
(32, 116, 4),
(33, 45, 5),
(33, 58, 8),
(33, 75, 4),
(33, 100, 7),
(34, 47, 6),
(34, 69, 5),
(34, 92, 3),
(34, 119, 8),
(35, 50, 4),
(35, 60, 7),
(35, 89, 5),
(35, 103, 6),
(36, 52, 8),
(36, 73, 4),
(36, 99, 7),
(36, 112, 5),
(37, 54, 6),
(37, 68, 3),
(37, 86, 8),
(37, 117, 4),
(38, 56, 5),
(38, 77, 7),
(38, 91, 4),
(38, 110, 6),
(39, 59, 9),
(39, 74, 5),
(39, 97, 3),
(39, 106, 7),
(40, 62, 4),
(40, 80, 6),
(40, 104, 5),
(40, 118, 8),
(41, 64, 7),
(41, 71, 4),
(41, 93, 6),
(41, 109, 5),
(42, 65, 5),
(42, 83, 8),
(42, 95, 3),
(42, 115, 7),
(43, 67, 6),
(43, 76, 4),
(43, 88, 9),
(43, 113, 5),
(44, 71, 8),
(44, 82, 3),
(44, 101, 6),
(44, 116, 4),
(45, 74, 5),
(45, 85, 7),
(45, 99, 4),
(45, 120, 8),
(46, 78, 6),
(46, 89, 3),
(46, 105, 5),
(46, 114, 7),
(47, 79, 4),
(47, 92, 8),
(47, 103, 6),
(47, 118, 5),
(48, 81, 7),
(48, 96, 4),
(48, 107, 6),
(48, 119, 3),
(49, 85, 5),
(49, 98, 7),
(49, 110, 4),
(49, 117, 8),
(50, 87, 6),
(50, 100, 3),
(50, 108, 7),
(50, 120, 5);

--DATA COUPON TABLE

INSERT INTO coupons
(
    code,
    discount_type,
    discount_value,
    minimum_order,
    maximum_discount,
    usage_limit,
    used_count,
    starts_at,
    expires_at,
    status
)
VALUES

('WELCOME10', 'percentage', 10.00, 50.00, 30.00, 100, 15,
 '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'active'),

('SAVE20', 'percentage', 20.00, 100.00, 50.00, 80, 20,
 '2026-02-01 00:00:00', '2026-12-31 23:59:59', 'active'),

('FIXED15', 'fixed', 15.00, 60.00, NULL, 50, 10,
 '2026-03-01 00:00:00', '2026-11-30 23:59:59', 'active'),

('SHOP25', 'percentage', 25.00, 150.00, 70.00, 60, 25,
 '2026-01-15 00:00:00', '2026-10-31 23:59:59', 'active'),

('NEWUSER', 'fixed', 20.00, 80.00, NULL, 150, 45,
 '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'active'),

('SUMMER15', 'percentage', 15.00, 70.00, 40.00, 120, 50,
 '2026-06-01 00:00:00', '2026-09-30 23:59:59', 'active'),

('VIP30', 'percentage', 30.00, 300.00, 100.00, 30, 12,
 '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'active'),

('DEAL10', 'fixed', 10.00, 40.00, NULL, 200, 90,
 '2026-04-01 00:00:00', '2026-12-01 23:59:59', 'active'),

('FLASH20', 'percentage', 20.00, 120.00, 45.00, 40, 18,
 '2026-09-01 00:00:00', '2026-10-15 23:59:59', 'active'),

('BIGSAVE', 'fixed', 50.00, 250.00, NULL, 35, 14,
 '2026-05-01 00:00:00', '2026-12-31 23:59:59', 'active'),

('FASHION12', 'percentage', 12.00, 90.00, 35.00, 75, 30,
 '2026-03-01 00:00:00', '2026-11-30 23:59:59', 'active'),

('TECH40', 'fixed', 40.00, 200.00, NULL, 45, 22,
 '2026-02-15 00:00:00', '2026-12-15 23:59:59', 'active'),

('SPECIAL18', 'percentage', 18.00, 110.00, 55.00, 90, 35,
 '2026-01-20 00:00:00', '2026-12-20 23:59:59', 'active'),

('WEEKEND25', 'fixed', 25.00, 100.00, NULL, 70, 28,
 '2026-07-01 00:00:00', '2026-10-31 23:59:59', 'active'),

('MEGA35', 'percentage', 35.00, 400.00, 120.00, 25, 8,
 '2026-08-01 00:00:00', '2026-12-31 23:59:59', 'active');






--DATA ORDERS TABLE

INSERT INTO orders
(order_number, customer_id, address_id, coupon_id, subtotal, discount_amount, shipping_cost, total_amount, status)
VALUES
('ORD-2026-0001', 1, 1, 1, 1250.00, 125.00, 49.90, 1174.90, 'delivered'),
('ORD-2026-0002', 2, 2, NULL, 2450.00, 0.00, 59.90, 2509.90, 'shipped'),
('ORD-2026-0003', 3, 3, 2, 3200.00, 480.00, 0.00, 2720.00, 'delivered'),
('ORD-2026-0004', 4, 4, NULL, 890.00, 0.00, 39.90, 929.90, 'confirmed'),
('ORD-2026-0005', 5, 5, 6, 1750.00, 100.00, 49.90, 1699.90, 'processing'),
('ORD-2026-0006', 6, 6, 3, 4200.00, 400.00, 0.00, 3800.00, 'delivered'),
('ORD-2026-0007', 7, 7, NULL, 675.00, 0.00, 34.90, 709.90, 'pending'),
('ORD-2026-0008', 8, 8, 4, 1850.00, 185.00, 49.90, 1714.90, 'shipped'),
('ORD-2026-0009', 9, 9, NULL, 2990.00, 0.00, 59.90, 3049.90, 'cancelled'),
('ORD-2026-0010', 10, 10, 7, 5100.00, 250.00, 0.00, 4850.00, 'delivered'),
('ORD-2026-0011', 11, 11, NULL, 760.00, 0.00, 39.90, 799.90, 'processing'),
('ORD-2026-0012', 12, 12, 1, 1450.00, 145.00, 49.90, 1354.90, 'delivered'),
('ORD-2026-0013', 13, 13, 5, 3800.00, 500.00, 0.00, 3300.00, 'shipped'),
('ORD-2026-0014', 14, 14, NULL, 920.00, 0.00, 39.90, 959.90, 'confirmed'),
('ORD-2026-0015', 15, 15, 8, 2750.00, 250.00, 49.90, 2549.90, 'delivered'),
('ORD-2026-0016', 16, 16, NULL, 1100.00, 0.00, 44.90, 1144.90, 'pending'),
('ORD-2026-0017', 17, 17, 9, 4500.00, 600.00, 0.00, 3900.00, 'delivered'),
('ORD-2026-0018', 18, 18, NULL, 680.00, 0.00, 34.90, 714.90, 'processing'),
('ORD-2026-0019', 19, 19, 10, 2100.00, 350.00, 49.90, 1799.90, 'shipped'),
('ORD-2026-0020', 20, 20, NULL, 3350.00, 0.00, 0.00, 3350.00, 'delivered'),
('ORD-2026-0021', 21, 21, 11, 1600.00, 160.00, 39.90, 1479.90, 'confirmed'),
('ORD-2026-0022', 22, 22, NULL, 2480.00, 0.00, 59.90, 2539.90, 'delivered'),
('ORD-2026-0023', 23, 23, 12, 3650.00, 450.00, 0.00, 3200.00, 'processing'),
('ORD-2026-0024', 24, 24, NULL, 570.00, 0.00, 34.90, 604.90, 'cancelled'),
('ORD-2026-0025', 25, 25, 13, 940.00, 50.00, 39.90, 929.90, 'delivered'),
('ORD-2026-0026', 26, 26, NULL, 1850.00, 0.00, 49.90, 1899.90, 'shipped'),
('ORD-2026-0027', 27, 27, 14, 5200.00, 750.00, 0.00, 4450.00, 'delivered'),
('ORD-2026-0028', 28, 28, NULL, 1320.00, 0.00, 44.90, 1364.90, 'pending'),
('ORD-2026-0029', 29, 29, 15, 2980.00, 596.00, 49.90, 2433.90, 'processing'),
('ORD-2026-0030', 30, 30, NULL, 720.00, 0.00, 39.90, 759.90, 'delivered'),
('ORD-2026-0031', 31, 31, 1, 1950.00, 195.00, 49.90, 1804.90, 'shipped'),
('ORD-2026-0032', 32, 32, NULL, 4100.00, 0.00, 0.00, 4100.00, 'delivered'),
('ORD-2026-0033', 33, 33, 2, 2350.00, 352.50, 59.90, 2057.40, 'confirmed'),
('ORD-2026-0034', 34, 34, NULL, 880.00, 0.00, 34.90, 914.90, 'processing'),
('ORD-2026-0035', 35, 35, 6, 3100.00, 100.00, 49.90, 3049.90, 'delivered'),
('ORD-2026-0036', 36, 36, NULL, 1270.00, 0.00, 44.90, 1314.90, 'pending'),
('ORD-2026-0037', 37, 37, 3, 4600.00, 460.00, 0.00, 4140.00, 'shipped'),
('ORD-2026-0038', 38, 38, NULL, 990.00, 0.00, 39.90, 1029.90, 'delivered'),
('ORD-2026-0039', 39, 39, 4, 2700.00, 270.00, 49.90, 2479.90, 'cancelled'),
('ORD-2026-0040', 40, 40, NULL, 3500.00, 0.00, 0.00, 3500.00, 'delivered'),
('ORD-2026-0041', 41, 41, 7, 1450.00, 250.00, 39.90, 1239.90, 'processing'),
('ORD-2026-0042', 42, 42, NULL, 2250.00, 0.00, 49.90, 2299.90, 'shipped'),
('ORD-2026-0043', 43, 43, 8, 3950.00, 250.00, 0.00, 3700.00, 'delivered'),
('ORD-2026-0044', 44, 44, NULL, 630.00, 0.00, 34.90, 664.90, 'confirmed'),
('ORD-2026-0045', 45, 45, 9, 2850.00, 427.50, 49.90, 2472.40, 'delivered'),
('ORD-2026-0046', 46, 46, NULL, 1180.00, 0.00, 44.90, 1224.90, 'pending'),
('ORD-2026-0047', 47, 47, 10, 5200.00, 1040.00, 0.00, 4160.00, 'shipped'),
('ORD-2026-0048', 48, 48, NULL, 890.00, 0.00, 39.90, 929.90, 'delivered'),
('ORD-2026-0049', 49, 49, 11, 1780.00, 178.00, 49.90, 1651.90, 'processing'),
('ORD-2026-0050', 50, 50, NULL, 2650.00, 0.00, 59.90, 2709.90, 'delivered'),

('ORD-2026-0051', 1, 1, NULL, 950.00, 0.00, 39.90, 989.90, 'delivered'),
('ORD-2026-0052', 2, 2, 12, 3150.00, 450.00, 0.00, 2700.00, 'shipped'),
('ORD-2026-0053', 3, 3, NULL, 1280.00, 0.00, 44.90, 1324.90, 'processing'),
('ORD-2026-0054', 4, 4, 13, 760.00, 50.00, 39.90, 749.90, 'delivered'),
('ORD-2026-0055', 5, 5, NULL, 4400.00, 0.00, 0.00, 4400.00, 'confirmed'),
('ORD-2026-0056', 6, 6, 14, 2250.00, 675.00, 49.90, 1624.90, 'delivered'),
('ORD-2026-0057', 7, 7, NULL, 590.00, 0.00, 34.90, 624.90, 'pending'),
('ORD-2026-0058', 8, 8, 15, 2800.00, 560.00, 0.00, 2240.00, 'shipped'),
('ORD-2026-0059', 9, 9, NULL, 1750.00, 0.00, 49.90, 1799.90, 'delivered'),
('ORD-2026-0060', 10, 10, 1, 3600.00, 360.00, 0.00, 3240.00, 'processing'),
('ORD-2026-0061', 11, 11, NULL, 820.00, 0.00, 39.90, 859.90, 'delivered'),
('ORD-2026-0062', 12, 12, 2, 2400.00, 360.00, 49.90, 2089.90, 'shipped'),
('ORD-2026-0063', 13, 13, NULL, 1450.00, 0.00, 44.90, 1494.90, 'confirmed'),
('ORD-2026-0064', 14, 14, 6, 5100.00, 100.00, 0.00, 5000.00, 'delivered'),
('ORD-2026-0065', 15, 15, NULL, 980.00, 0.00, 39.90, 1019.90, 'cancelled'),
('ORD-2026-0066', 16, 16, 7, 1850.00, 250.00, 49.90, 1649.90, 'processing'),
('ORD-2026-0067', 17, 17, NULL, 3250.00, 0.00, 0.00, 3250.00, 'delivered'),
('ORD-2026-0068', 18, 18, 8, 2750.00, 250.00, 59.90, 2559.90, 'shipped'),
('ORD-2026-0069', 19, 19, NULL, 690.00, 0.00, 34.90, 724.90, 'pending'),
('ORD-2026-0070', 20, 20, 9, 4200.00, 600.00, 0.00, 3600.00, 'delivered'),
('ORD-2026-0071', 21, 21, NULL, 1120.00, 0.00, 44.90, 1164.90, 'processing'),
('ORD-2026-0072', 22, 22, 10, 2950.00, 350.00, 49.90, 2649.90, 'delivered'),
('ORD-2026-0073', 23, 23, NULL, 1680.00, 0.00, 39.90, 1719.90, 'shipped'),
('ORD-2026-0074', 24, 24, 11, 3850.00, 385.00, 0.00, 3465.00, 'confirmed'),
('ORD-2026-0075', 25, 25, NULL, 740.00, 0.00, 34.90, 774.90, 'delivered'),
('ORD-2026-0076', 26, 26, 12, 2180.00, 450.00, 49.90, 1779.90, 'processing'),
('ORD-2026-0077', 27, 27, NULL, 3350.00, 0.00, 0.00, 3350.00, 'shipped'),
('ORD-2026-0078', 28, 28, 13, 950.00, 50.00, 39.90, 939.90, 'delivered'),
('ORD-2026-0079', 29, 29, NULL, 1420.00, 0.00, 49.90, 1469.90, 'pending'),
('ORD-2026-0080', 30, 30, 14, 4750.00, 750.00, 0.00, 4000.00, 'delivered'),
('ORD-2026-0081', 31, 31, NULL, 870.00, 0.00, 39.90, 909.90, 'processing'),
('ORD-2026-0082', 32, 32, 15, 2650.00, 530.00, 49.90, 2169.90, 'shipped'),
('ORD-2026-0083', 33, 33, NULL, 1950.00, 0.00, 44.90, 1994.90, 'delivered'),
('ORD-2026-0084', 34, 34, 1, 3300.00, 330.00, 0.00, 2970.00, 'confirmed'),
('ORD-2026-0085', 35, 35, NULL, 560.00, 0.00, 34.90, 594.90, 'cancelled'),
('ORD-2026-0086', 36, 36, 2, 1850.00, 277.50, 49.90, 1622.40, 'delivered'),
('ORD-2026-0087', 37, 37, NULL, 4100.00, 0.00, 0.00, 4100.00, 'processing'),
('ORD-2026-0088', 38, 38, 6, 1250.00, 100.00, 39.90, 1189.90, 'shipped'),
('ORD-2026-0089', 39, 39, NULL, 2950.00, 0.00, 59.90, 3009.90, 'delivered'),
('ORD-2026-0090', 40, 40, 7, 2150.00, 250.00, 0.00, 1900.00, 'pending'),
('ORD-2026-0091', 41, 41, NULL, 790.00, 0.00, 39.90, 829.90, 'delivered'),
('ORD-2026-0092', 42, 42, 8, 3420.00, 250.00, 49.90, 3219.90, 'processing'),
('ORD-2026-0093', 43, 43, NULL, 1570.00, 0.00, 44.90, 1614.90, 'shipped'),
('ORD-2026-0094', 44, 44, 9, 2800.00, 420.00, 0.00, 2380.00, 'delivered'),
('ORD-2026-0095', 45, 45, NULL, 940.00, 0.00, 39.90, 979.90, 'confirmed'),
('ORD-2026-0096', 46, 46, 10, 3900.00, 780.00, 49.90, 3169.90, 'delivered'),
('ORD-2026-0097', 47, 47, NULL, 1280.00, 0.00, 34.90, 1314.90, 'processing'),
('ORD-2026-0098', 48, 48, 11, 2350.00, 235.00, 49.90, 2164.90, 'shipped'),
('ORD-2026-0099', 49, 49, NULL, 1780.00, 0.00, 39.90, 1819.90, 'delivered'),
('ORD-2026-0100', 50, 50, 12, 4500.00, 450.00, 0.00, 4050.00, 'delivered'),

('ORD-2026-0101', 1, 1, NULL, 1850.00, 0.00, 49.90, 1899.90, 'delivered'),
('ORD-2026-0102', 2, 2, 4, 3200.00, 320.00, 0.00, 2880.00, 'delivered'),
('ORD-2026-0103', 3, 3, NULL, 975.00, 0.00, 39.90, 1014.90, 'shipped'),
('ORD-2026-0104', 4, 4, 7, 2450.00, 245.00, 49.90, 2254.90, 'processing'),
('ORD-2026-0105', 5, 5, NULL, 4100.00, 0.00, 0.00, 4100.00, 'delivered'),
('ORD-2026-0106', 6, 6, 2, 1350.00, 135.00, 39.90, 1254.90, 'confirmed'),
('ORD-2026-0107', 7, 7, NULL, 2875.00, 0.00, 59.90, 2934.90, 'shipped'),
('ORD-2026-0108', 8, 8, 9, 5200.00, 520.00, 0.00, 4680.00, 'delivered'),
('ORD-2026-0109', 9, 9, NULL, 760.00, 0.00, 39.90, 799.90, 'cancelled'),
('ORD-2026-0110', 10, 10, 5, 1980.00, 198.00, 49.90, 1831.90, 'delivered'),
('ORD-2026-0111', 11, 11, NULL, 3420.00, 0.00, 59.90, 3479.90, 'shipped'),
('ORD-2026-0112', 12, 12, 3, 1575.00, 157.50, 39.90, 1457.40, 'delivered'),
('ORD-2026-0113', 13, 13, NULL, 2280.00, 0.00, 0.00, 2280.00, 'processing'),
('ORD-2026-0114', 14, 14, 8, 3650.00, 365.00, 49.90, 3334.90, 'delivered'),
('ORD-2026-0115', 15, 15, NULL, 1190.00, 0.00, 39.90, 1229.90, 'confirmed'),
('ORD-2026-0116', 16, 16, 1, 2750.00, 275.00, 0.00, 2475.00, 'delivered'),
('ORD-2026-0117', 17, 17, NULL, 4325.00, 0.00, 59.90, 4384.90, 'shipped'),
('ORD-2026-0118', 18, 18, 6, 1840.00, 184.00, 39.90, 1695.90, 'delivered'),
('ORD-2026-0119', 19, 19, NULL, 980.00, 0.00, 49.90, 1029.90, 'processing'),
('ORD-2026-0120', 20, 20, 10, 3150.00, 315.00, 0.00, 2835.00, 'delivered'),
('ORD-2026-0121', 21, 21, NULL, 2250.00, 0.00, 39.90, 2289.90, 'shipped'),
('ORD-2026-0122', 22, 22, 12, 4750.00, 475.00, 49.90, 4324.90, 'delivered'),
('ORD-2026-0123', 23, 23, NULL, 1320.00, 0.00, 39.90, 1359.90, 'confirmed'),
('ORD-2026-0124', 24, 24, 4, 2890.00, 289.00, 0.00, 2601.00, 'delivered'),
('ORD-2026-0125', 25, 25, NULL, 3650.00, 0.00, 59.90, 3709.90, 'shipped'),
('ORD-2026-0126', 26, 26, 7, 1725.00, 172.50, 39.90, 1592.40, 'processing'),
('ORD-2026-0127', 27, 27, NULL, 890.00, 0.00, 49.90, 939.90, 'delivered'),
('ORD-2026-0128', 28, 28, 2, 5400.00, 540.00, 0.00, 4860.00, 'delivered'),
('ORD-2026-0129', 29, 29, NULL, 2140.00, 0.00, 39.90, 2179.90, 'cancelled'),
('ORD-2026-0130', 30, 30, 11, 3275.00, 327.50, 49.90, 2997.40, 'delivered'),
('ORD-2026-0131', 31, 31, NULL, 1450.00, 0.00, 39.90, 1489.90, 'shipped'),
('ORD-2026-0132', 32, 32, 5, 3820.00, 382.00, 0.00, 3438.00, 'delivered'),
('ORD-2026-0133', 33, 33, NULL, 990.00, 0.00, 49.90, 1039.90, 'processing'),
('ORD-2026-0134', 34, 34, 9, 2600.00, 260.00, 39.90, 2379.90, 'delivered'),
('ORD-2026-0135', 35, 35, NULL, 4150.00, 0.00, 59.90, 4209.90, 'shipped'),
('ORD-2026-0136', 36, 36, 3, 1680.00, 168.00, 0.00, 1512.00, 'confirmed'),
('ORD-2026-0137', 37, 37, NULL, 2375.00, 0.00, 39.90, 2414.90, 'delivered'),
('ORD-2026-0138', 38, 38, 8, 3500.00, 350.00, 49.90, 3199.90, 'delivered'),
('ORD-2026-0139', 39, 39, NULL, 1275.00, 0.00, 39.90, 1314.90, 'cancelled'),
('ORD-2026-0140', 40, 40, 6, 2980.00, 298.00, 0.00, 2682.00, 'shipped'),
('ORD-2026-0141', 41, 41, NULL, 4560.00, 0.00, 59.90, 4619.90, 'delivered'),
('ORD-2026-0142', 42, 42, 1, 1890.00, 189.00, 39.90, 1740.90, 'processing'),
('ORD-2026-0143', 43, 43, NULL, 2750.00, 0.00, 49.90, 2799.90, 'delivered'),
('ORD-2026-0144', 44, 44, 10, 5100.00, 510.00, 0.00, 4590.00, 'shipped'),
('ORD-2026-0145', 45, 45, NULL, 1125.00, 0.00, 39.90, 1164.90, 'confirmed'),
('ORD-2026-0146', 46, 46, 12, 3350.00, 335.00, 49.90, 3064.90, 'delivered'),
('ORD-2026-0147', 47, 47, NULL, 2480.00, 0.00, 59.90, 2539.90, 'processing'),
('ORD-2026-0148', 48, 48, 4, 3975.00, 397.50, 0.00, 3577.50, 'delivered'),
('ORD-2026-0149', 49, 49, NULL, 1540.00, 0.00, 39.90, 1579.90, 'shipped'),
('ORD-2026-0150', 50, 50, 7, 4625.00, 462.50, 49.90, 4212.40, 'delivered');








--DATA ORDER ITEM TABLE

INSERT INTO order_items
(order_id, product_id, seller_id, quantity, unit_price, discount_amount, platform_commission, seller_amount, status)
VALUES
(1, 1, 1, 2, 100.00, 10.00, 10.00, 180.00, 'active'),
(1, 12, 4, 1, 250.00, 20.00, 15.00, 215.00, 'active'),
(2, 5, 2, 3, 80.00, 10.00, 12.00, 218.00, 'active'),
(3, 18, 6, 1, 450.00, 30.00, 20.00, 400.00, 'active'),
(4, 22, 8, 2, 120.00, 15.00, 10.00, 215.00, 'active'),
(5, 30, 10, 1, 300.00, 25.00, 15.00, 260.00, 'active'),
(6, 9, 3, 4, 50.00, 10.00, 10.00, 180.00, 'active'),
(7, 15, 5, 2, 175.00, 20.00, 15.00, 315.00, 'active'),
(8, 27, 9, 1, 500.00, 40.00, 25.00, 435.00, 'active'),
(9, 35, 12, 3, 90.00, 15.00, 12.00, 243.00, 'active'),

(10, 40, 14, 2, 200.00, 20.00, 20.00, 360.00, 'active'),
(11, 48, 16, 1, 650.00, 50.00, 30.00, 570.00, 'active'),
(12, 55, 18, 2, 140.00, 10.00, 15.00, 255.00, 'active'),
(13, 60, 20, 1, 320.00, 20.00, 15.00, 285.00, 'active'),
(14, 7, 2, 3, 75.00, 10.00, 10.00, 205.00, 'active'),
(15, 14, 4, 2, 160.00, 20.00, 15.00, 285.00, 'active'),
(16, 21, 7, 1, 275.00, 15.00, 10.00, 250.00, 'active'),
(17, 28, 9, 4, 60.00, 10.00, 12.00, 218.00, 'active'),
(18, 36, 12, 2, 225.00, 25.00, 20.00, 405.00, 'active'),
(19, 44, 15, 1, 480.00, 30.00, 25.00, 425.00, 'active'),

(20, 52, 17, 3, 110.00, 15.00, 15.00, 300.00, 'active'),
(21, 61, 1, 2, 190.00, 20.00, 18.00, 342.00, 'active'),
(22, 68, 3, 1, 350.00, 25.00, 15.00, 310.00, 'active'),
(23, 73, 5, 2, 130.00, 10.00, 12.00, 238.00, 'active'),
(24, 80, 8, 1, 700.00, 50.00, 35.00, 615.00, 'active'),
(25, 86, 10, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(26, 92, 13, 2, 210.00, 20.00, 20.00, 380.00, 'active'),
(27, 98, 15, 1, 550.00, 40.00, 25.00, 485.00, 'active'),
(28, 104, 17, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(29, 110, 19, 2, 165.00, 15.00, 15.00, 300.00, 'active'),

(30, 116, 20, 1, 420.00, 30.00, 20.00, 370.00, 'active'),
(31, 3, 1, 2, 115.00, 10.00, 10.00, 210.00, 'active'),
(32, 11, 3, 1, 260.00, 15.00, 12.00, 233.00, 'active'),
(33, 19, 6, 3, 85.00, 10.00, 10.00, 235.00, 'active'),
(34, 25, 8, 2, 145.00, 15.00, 12.00, 263.00, 'active'),
(35, 33, 11, 1, 390.00, 25.00, 20.00, 345.00, 'active'),
(36, 41, 14, 4, 55.00, 10.00, 10.00, 200.00, 'active'),
(37, 49, 16, 2, 180.00, 20.00, 15.00, 325.00, 'active'),
(38, 57, 19, 1, 525.00, 35.00, 25.00, 465.00, 'active'),
(39, 64, 2, 3, 105.00, 15.00, 15.00, 285.00, 'active'),

(40, 72, 4, 2, 230.00, 20.00, 20.00, 420.00, 'active'),
(41, 79, 7, 1, 310.00, 20.00, 15.00, 275.00, 'active'),
(42, 87, 10, 2, 155.00, 15.00, 15.00, 280.00, 'active'),
(43, 95, 13, 4, 65.00, 10.00, 10.00, 240.00, 'active'),
(44, 102, 16, 1, 600.00, 45.00, 30.00, 525.00, 'active'),
(45, 109, 18, 3, 125.00, 20.00, 15.00, 340.00, 'active'),
(46, 117, 20, 2, 195.00, 20.00, 18.00, 352.00, 'active'),
(47, 6, 2, 1, 280.00, 15.00, 15.00, 250.00, 'active'),
(48, 13, 5, 3, 90.00, 10.00, 12.00, 248.00, 'active'),
(49, 20, 7, 2, 170.00, 20.00, 15.00, 305.00, 'active'),

(50, 29, 10, 1, 460.00, 30.00, 20.00, 410.00, 'active'),
(51, 37, 12, 4, 75.00, 15.00, 15.00, 270.00, 'active'),
(52, 45, 15, 2, 205.00, 20.00, 20.00, 370.00, 'active'),
(53, 53, 18, 1, 375.00, 25.00, 15.00, 335.00, 'active'),
(54, 62, 1, 3, 100.00, 10.00, 15.00, 275.00, 'active'),
(55, 70, 4, 2, 185.00, 20.00, 15.00, 335.00, 'active'),
(56, 78, 7, 1, 490.00, 35.00, 25.00, 430.00, 'active'),
(57, 85, 9, 3, 115.00, 15.00, 15.00, 315.00, 'active'),
(58, 93, 12, 2, 240.00, 25.00, 20.00, 435.00, 'active'),
(59, 101, 15, 1, 330.00, 20.00, 15.00, 295.00, 'active'),

(60, 108, 18, 4, 80.00, 10.00, 15.00, 295.00, 'active'),
(61, 115, 20, 2, 215.00, 20.00, 20.00, 390.00, 'active'),
(62, 4, 1, 1, 580.00, 40.00, 30.00, 510.00, 'active'),
(63, 10, 3, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(64, 17, 6, 2, 150.00, 10.00, 15.00, 275.00, 'active'),
(65, 24, 8, 1, 410.00, 30.00, 20.00, 360.00, 'active'),
(66, 32, 11, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(67, 39, 13, 2, 175.00, 15.00, 15.00, 320.00, 'active'),
(68, 47, 16, 1, 540.00, 40.00, 25.00, 475.00, 'active'),
(69, 54, 18, 3, 120.00, 20.00, 15.00, 325.00, 'active'),

(70, 63, 1, 2, 225.00, 25.00, 20.00, 405.00, 'active'),
(71, 71, 4, 1, 295.00, 15.00, 15.00, 265.00, 'active'),
(72, 77, 6, 3, 85.00, 10.00, 10.00, 235.00, 'active'),
(73, 84, 9, 2, 165.00, 15.00, 15.00, 300.00, 'active'),
(74, 91, 12, 1, 470.00, 30.00, 25.00, 415.00, 'active'),
(75, 99, 15, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(76, 106, 17, 2, 200.00, 20.00, 20.00, 360.00, 'active'),
(77, 114, 20, 1, 625.00, 45.00, 30.00, 550.00, 'active'),
(78, 2, 1, 3, 110.00, 15.00, 15.00, 300.00, 'active'),
(79, 8, 3, 2, 140.00, 10.00, 15.00, 255.00, 'active'),

(80, 16, 5, 1, 360.00, 25.00, 15.00, 320.00, 'active'),
(81, 23, 8, 4, 65.00, 10.00, 10.00, 240.00, 'active'),
(82, 31, 10, 2, 190.00, 20.00, 18.00, 342.00, 'active'),
(83, 38, 13, 1, 515.00, 35.00, 25.00, 455.00, 'active'),
(84, 46, 16, 3, 100.00, 10.00, 15.00, 275.00, 'active'),
(85, 51, 17, 2, 235.00, 25.00, 20.00, 425.00, 'active'),
(86, 59, 20, 1, 345.00, 20.00, 15.00, 310.00, 'active'),
(87, 67, 3, 3, 125.00, 20.00, 15.00, 340.00, 'active'),
(88, 75, 5, 2, 155.00, 15.00, 15.00, 280.00, 'active'),
(89, 82, 8, 1, 440.00, 30.00, 20.00, 390.00, 'active'),

(90, 90, 11, 4, 75.00, 15.00, 15.00, 270.00, 'active'),
(91, 97, 14, 2, 210.00, 20.00, 20.00, 380.00, 'active'),
(92, 105, 17, 1, 570.00, 40.00, 30.00, 500.00, 'active'),
(93, 113, 19, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(94, 120, 20, 2, 180.00, 20.00, 15.00, 325.00, 'active'),
(95, 5, 2, 1, 390.00, 25.00, 20.00, 345.00, 'active'),
(96, 14, 4, 4, 55.00, 10.00, 10.00, 200.00, 'active'),
(97, 26, 9, 2, 220.00, 20.00, 20.00, 400.00, 'active'),
(98, 34, 11, 1, 475.00, 30.00, 25.00, 420.00, 'active'),
(99, 43, 14, 3, 115.00, 15.00, 15.00, 315.00, 'active'),

(100, 50, 17, 2, 195.00, 20.00, 18.00, 352.00, 'active'),
(101, 58, 19, 1, 610.00, 45.00, 30.00, 535.00, 'active'),
(102, 66, 2, 3, 90.00, 10.00, 12.00, 248.00, 'active'),
(103, 74, 5, 2, 160.00, 15.00, 15.00, 290.00, 'active'),
(104, 81, 8, 1, 430.00, 30.00, 20.00, 380.00, 'active'),
(105, 89, 11, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(106, 96, 14, 2, 205.00, 20.00, 20.00, 370.00, 'active'),
(107, 103, 16, 1, 525.00, 35.00, 25.00, 465.00, 'active'),
(108, 111, 19, 3, 105.00, 15.00, 15.00, 285.00, 'active'),
(109, 119, 20, 2, 170.00, 20.00, 15.00, 305.00, 'active'),

(110, 6, 2, 1, 350.00, 25.00, 15.00, 310.00, 'active'),
(111, 13, 4, 3, 80.00, 10.00, 10.00, 220.00, 'active'),
(112, 21, 7, 2, 185.00, 20.00, 15.00, 335.00, 'active'),
(113, 29, 10, 1, 495.00, 35.00, 25.00, 435.00, 'active'),
(114, 37, 12, 4, 65.00, 10.00, 10.00, 240.00, 'active'),
(115, 45, 15, 2, 215.00, 20.00, 20.00, 390.00, 'active'),
(116, 53, 18, 1, 385.00, 25.00, 20.00, 340.00, 'active'),
(117, 61, 1, 3, 110.00, 15.00, 15.00, 300.00, 'active'),
(118, 69, 4, 2, 150.00, 10.00, 15.00, 275.00, 'active'),
(119, 76, 6, 1, 560.00, 40.00, 30.00, 490.00, 'active'),

(120, 83, 9, 3, 100.00, 10.00, 15.00, 275.00, 'active'),
(121, 91, 12, 2, 225.00, 25.00, 20.00, 405.00, 'active'),
(122, 99, 15, 1, 320.00, 20.00, 15.00, 285.00, 'active'),
(123, 107, 18, 4, 75.00, 15.00, 15.00, 270.00, 'active'),
(124, 115, 20, 2, 190.00, 20.00, 18.00, 342.00, 'active'),
(125, 3, 1, 1, 450.00, 30.00, 20.00, 400.00, 'active'),
(126, 12, 4, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(127, 20, 7, 2, 175.00, 20.00, 15.00, 315.00, 'active'),
(128, 28, 9, 1, 500.00, 40.00, 25.00, 435.00, 'active'),
(129, 36, 12, 4, 60.00, 10.00, 12.00, 218.00, 'active'),

(130, 44, 15, 2, 230.00, 20.00, 20.00, 420.00, 'active'),
(131, 52, 17, 1, 375.00, 25.00, 15.00, 335.00, 'active'),
(132, 60, 20, 3, 85.00, 10.00, 10.00, 235.00, 'active'),
(133, 68, 3, 2, 165.00, 15.00, 15.00, 300.00, 'active'),
(134, 76, 6, 1, 470.00, 30.00, 25.00, 415.00, 'active'),
(135, 84, 9, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(136, 92, 13, 2, 200.00, 20.00, 20.00, 360.00, 'active'),
(137, 100, 16, 1, 625.00, 45.00, 30.00, 550.00, 'active'),
(138, 108, 18, 3, 110.00, 15.00, 15.00, 300.00, 'active'),
(139, 116, 20, 2, 140.00, 10.00, 15.00, 255.00, 'active'),

(140, 4, 1, 1, 360.00, 25.00, 15.00, 320.00, 'active'),
(141, 11, 3, 4, 65.00, 10.00, 10.00, 240.00, 'active'),
(142, 19, 6, 2, 190.00, 20.00, 18.00, 342.00, 'active'),
(143, 27, 9, 1, 515.00, 35.00, 25.00, 455.00, 'active'),
(144, 35, 12, 3, 100.00, 10.00, 15.00, 275.00, 'active'),
(145, 43, 14, 2, 235.00, 25.00, 20.00, 425.00, 'active'),
(146, 51, 17, 1, 345.00, 20.00, 15.00, 310.00, 'active'),
(147, 59, 20, 3, 125.00, 20.00, 15.00, 340.00, 'active'),
(148, 67, 3, 2, 155.00, 15.00, 15.00, 280.00, 'active'),
(149, 75, 5, 1, 440.00, 30.00, 20.00, 390.00, 'active'),

(150, 83, 8, 4, 75.00, 15.00, 15.00, 270.00, 'active'),

(1, 91, 12, 1, 210.00, 10.00, 10.00, 190.00, 'active'),
(2, 98, 15, 2, 180.00, 20.00, 15.00, 325.00, 'active'),
(3, 105, 17, 3, 90.00, 10.00, 12.00, 248.00, 'active'),
(4, 112, 19, 1, 550.00, 40.00, 25.00, 485.00, 'active'),
(5, 120, 20, 2, 165.00, 15.00, 15.00, 300.00, 'active'),
(6, 2, 1, 4, 50.00, 10.00, 10.00, 180.00, 'active'),
(7, 10, 3, 1, 300.00, 20.00, 15.00, 265.00, 'active'),
(8, 18, 6, 2, 125.00, 10.00, 12.00, 228.00, 'active'),
(9, 26, 9, 3, 80.00, 10.00, 10.00, 220.00, 'active'),

(10, 34, 11, 1, 420.00, 30.00, 20.00, 370.00, 'active'),
(11, 42, 14, 2, 175.00, 20.00, 15.00, 315.00, 'active'),
(12, 50, 17, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(13, 58, 19, 1, 480.00, 30.00, 25.00, 425.00, 'active'),
(14, 66, 2, 3, 105.00, 15.00, 15.00, 285.00, 'active'),
(15, 74, 5, 2, 200.00, 20.00, 20.00, 360.00, 'active'),
(16, 82, 8, 1, 350.00, 25.00, 15.00, 310.00, 'active'),
(17, 90, 11, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(18, 97, 14, 2, 160.00, 15.00, 15.00, 290.00, 'active'),
(19, 104, 17, 1, 600.00, 45.00, 30.00, 525.00, 'active'),

(20, 111, 19, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(21, 118, 20, 2, 205.00, 20.00, 20.00, 370.00, 'active'),
(22, 7, 2, 1, 390.00, 25.00, 20.00, 345.00, 'active'),
(23, 15, 5, 3, 115.00, 15.00, 15.00, 315.00, 'active'),
(24, 23, 8, 2, 195.00, 20.00, 18.00, 352.00, 'active'),
(25, 31, 10, 1, 525.00, 35.00, 25.00, 465.00, 'active'),
(26, 39, 13, 4, 55.00, 10.00, 10.00, 200.00, 'active'),
(27, 47, 16, 2, 225.00, 25.00, 20.00, 405.00, 'active'),
(28, 55, 18, 1, 320.00, 20.00, 15.00, 285.00, 'active'),
(29, 63, 1, 3, 100.00, 10.00, 15.00, 275.00, 'active'),

(30, 71, 4, 2, 185.00, 20.00, 15.00, 335.00, 'active'),
(31, 79, 7, 1, 490.00, 35.00, 25.00, 430.00, 'active'),
(32, 87, 10, 3, 115.00, 15.00, 15.00, 315.00, 'active'),
(33, 95, 13, 2, 240.00, 25.00, 20.00, 435.00, 'active'),
(34, 103, 16, 1, 330.00, 20.00, 15.00, 295.00, 'active'),
(35, 110, 19, 4, 80.00, 10.00, 15.00, 295.00, 'active'),
(36, 117, 20, 2, 215.00, 20.00, 20.00, 390.00, 'active'),
(37, 5, 2, 1, 580.00, 40.00, 30.00, 510.00, 'active'),
(38, 13, 5, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(39, 21, 7, 2, 150.00, 10.00, 15.00, 275.00, 'active'),

(40, 29, 10, 1, 410.00, 30.00, 20.00, 360.00, 'active'),
(41, 37, 12, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(42, 45, 15, 2, 175.00, 15.00, 15.00, 320.00, 'active'),
(43, 53, 18, 1, 540.00, 40.00, 25.00, 475.00, 'active'),
(44, 61, 1, 3, 120.00, 20.00, 15.00, 325.00, 'active'),
(45, 69, 4, 2, 225.00, 25.00, 20.00, 405.00, 'active'),
(46, 77, 6, 1, 295.00, 15.00, 15.00, 265.00, 'active'),
(47, 85, 9, 3, 85.00, 10.00, 10.00, 235.00, 'active'),
(48, 93, 12, 2, 165.00, 15.00, 15.00, 300.00, 'active'),
(49, 101, 15, 1, 470.00, 30.00, 25.00, 415.00, 'active'),

(50, 109, 18, 4, 70.00, 10.00, 15.00, 255.00, 'active')
(51, 8, 3, 2, 120.00, 10.00, 12.00, 218.00, 'delivered'),
(52, 16, 5, 1, 350.00, 20.00, 18.00, 312.00, 'shipped'),
(53, 24, 8, 3, 90.00, 15.00, 12.00, 243.00, 'active'),
(54, 32, 11, 2, 175.00, 20.00, 15.00, 315.00, 'pending'),
(55, 40, 14, 1, 480.00, 30.00, 25.00, 425.00, 'delivered'),
(56, 48, 16, 4, 65.00, 10.00, 10.00, 240.00, 'cancelled'),
(57, 56, 19, 2, 210.00, 20.00, 20.00, 380.00, 'shipped'),
(58, 64, 2, 1, 325.00, 20.00, 15.00, 290.00, 'returned'),
(59, 72, 4, 3, 105.00, 15.00, 15.00, 285.00, 'active'),
(60, 80, 8, 2, 195.00, 20.00, 18.00, 352.00, 'delivered'),

(61, 88, 11, 1, 550.00, 40.00, 25.00, 485.00, 'shipped'),
(62, 96, 14, 4, 70.00, 10.00, 15.00, 255.00, 'pending'),
(63, 104, 17, 2, 230.00, 25.00, 20.00, 415.00, 'delivered'),
(64, 112, 19, 1, 390.00, 25.00, 20.00, 345.00, 'cancelled'),
(65, 120, 20, 3, 95.00, 15.00, 10.00, 260.00, 'active'),
(66, 7, 2, 2, 160.00, 15.00, 15.00, 290.00, 'returned'),
(67, 15, 5, 1, 425.00, 30.00, 20.00, 375.00, 'delivered'),
(68, 23, 8, 4, 55.00, 10.00, 10.00, 200.00, 'shipped'),
(69, 31, 10, 2, 185.00, 20.00, 15.00, 335.00, 'pending'),
(70, 39, 13, 1, 510.00, 35.00, 25.00, 450.00, 'active'),

(71, 47, 16, 3, 110.00, 15.00, 15.00, 300.00, 'delivered'),
(72, 55, 18, 2, 225.00, 25.00, 20.00, 405.00, 'cancelled'),
(73, 63, 1, 1, 360.00, 25.00, 15.00, 320.00, 'shipped'),
(74, 71, 4, 4, 75.00, 15.00, 15.00, 270.00, 'returned'),
(75, 79, 7, 2, 200.00, 20.00, 20.00, 360.00, 'active'),
(76, 87, 10, 1, 590.00, 40.00, 30.00, 520.00, 'delivered'),
(77, 95, 13, 3, 85.00, 10.00, 10.00, 235.00, 'pending'),
(78, 103, 16, 2, 170.00, 15.00, 15.00, 310.00, 'shipped'),
(79, 111, 19, 1, 450.00, 30.00, 20.00, 400.00, 'delivered'),
(80, 119, 20, 3, 125.00, 20.00, 15.00, 340.00, 'cancelled'),

(81, 6, 2, 2, 145.00, 15.00, 12.00, 263.00, 'active'),
(82, 14, 4, 1, 375.00, 25.00, 15.00, 335.00, 'returned'),
(83, 22, 7, 4, 60.00, 10.00, 10.00, 220.00, 'delivered'),
(84, 30, 10, 2, 215.00, 20.00, 20.00, 390.00, 'shipped'),
(85, 38, 13, 1, 525.00, 35.00, 25.00, 465.00, 'pending'),
(86, 46, 16, 3, 100.00, 10.00, 15.00, 275.00, 'active'),
(87, 54, 18, 2, 180.00, 20.00, 15.00, 325.00, 'delivered'),
(88, 62, 1, 1, 410.00, 30.00, 20.00, 360.00, 'cancelled'),
(89, 70, 4, 4, 80.00, 10.00, 15.00, 295.00, 'shipped'),
(90, 78, 7, 2, 195.00, 20.00, 18.00, 352.00, 'returned'),

(91, 86, 10, 1, 470.00, 30.00, 25.00, 415.00, 'active'),
(92, 94, 13, 3, 115.00, 15.00, 15.00, 315.00, 'delivered'),
(93, 102, 16, 2, 235.00, 25.00, 20.00, 425.00, 'pending'),
(94, 110, 19, 1, 340.00, 20.00, 15.00, 305.00, 'shipped'),
(95, 118, 20, 3, 90.00, 10.00, 12.00, 248.00, 'delivered'),
(96, 5, 2, 2, 155.00, 15.00, 15.00, 280.00, 'cancelled'),
(97, 13, 4, 1, 440.00, 30.00, 20.00, 390.00, 'active'),
(98, 21, 7, 4, 70.00, 10.00, 15.00, 255.00, 'returned'),
(99, 29, 10, 2, 205.00, 20.00, 20.00, 370.00, 'delivered'),
(100, 37, 12, 1, 570.00, 40.00, 30.00, 500.00, 'shipped'),

(101, 45, 15, 3, 95.00, 15.00, 10.00, 260.00, 'pending'),
(102, 53, 18, 2, 175.00, 20.00, 15.00, 315.00, 'active'),
(103, 61, 1, 1, 495.00, 35.00, 25.00, 435.00, 'delivered'),
(104, 69, 4, 4, 65.00, 10.00, 10.00, 240.00, 'cancelled'),
(105, 77, 6, 2, 220.00, 20.00, 20.00, 400.00, 'shipped'),
(106, 85, 9, 1, 385.00, 25.00, 20.00, 340.00, 'returned'),
(107, 93, 12, 3, 110.00, 15.00, 15.00, 300.00, 'active'),
(108, 101, 15, 2, 190.00, 20.00, 18.00, 342.00, 'delivered'),
(109, 109, 18, 1, 610.00, 45.00, 30.00, 535.00, 'pending'),
(110, 117, 20, 3, 80.00, 10.00, 10.00, 220.00, 'shipped'),

(111, 4, 1, 2, 165.00, 15.00, 15.00, 300.00, 'delivered'),
(112, 12, 4, 1, 460.00, 30.00, 20.00, 410.00, 'cancelled'),
(113, 20, 7, 4, 75.00, 15.00, 15.00, 270.00, 'active'),
(114, 28, 9, 2, 210.00, 20.00, 20.00, 380.00, 'returned'),
(115, 36, 12, 1, 540.00, 40.00, 25.00, 475.00, 'delivered'),
(116, 44, 15, 3, 105.00, 15.00, 15.00, 285.00, 'shipped'),
(117, 52, 17, 2, 185.00, 20.00, 15.00, 335.00, 'pending'),
(118, 60, 20, 1, 420.00, 30.00, 20.00, 370.00, 'active'),
(119, 68, 3, 4, 55.00, 10.00, 10.00, 200.00, 'delivered'),
(120, 76, 6, 2, 225.00, 25.00, 20.00, 405.00, 'cancelled'),

(121, 84, 9, 1, 350.00, 25.00, 15.00, 310.00, 'shipped'),
(122, 92, 13, 3, 100.00, 10.00, 15.00, 275.00, 'returned'),
(123, 100, 16, 2, 195.00, 20.00, 18.00, 352.00, 'active'),
(124, 108, 18, 1, 580.00, 40.00, 30.00, 510.00, 'delivered'),
(125, 116, 20, 3, 85.00, 10.00, 10.00, 235.00, 'pending'),
(126, 3, 1, 2, 150.00, 10.00, 15.00, 275.00, 'shipped'),
(127, 11, 3, 1, 400.00, 30.00, 20.00, 350.00, 'cancelled'),
(128, 19, 6, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(129, 27, 9, 2, 230.00, 20.00, 20.00, 420.00, 'delivered'),
(130, 35, 12, 1, 515.00, 35.00, 25.00, 455.00, 'returned'),

(131, 43, 14, 3, 120.00, 20.00, 15.00, 325.00, 'shipped'),
(132, 51, 17, 2, 175.00, 15.00, 15.00, 320.00, 'pending'),
(133, 59, 20, 1, 490.00, 35.00, 25.00, 430.00, 'delivered'),
(134, 67, 3, 4, 70.00, 10.00, 15.00, 255.00, 'active'),
(135, 75, 5, 2, 200.00, 20.00, 20.00, 360.00, 'cancelled'),
(136, 83, 9, 1, 625.00, 45.00, 30.00, 550.00, 'shipped'),
(137, 91, 12, 3, 90.00, 10.00, 12.00, 248.00, 'returned'),
(138, 99, 15, 2, 160.00, 15.00, 15.00, 290.00, 'delivered'),
(139, 107, 18, 1, 450.00, 30.00, 20.00, 400.00, 'pending'),
(140, 115, 20, 3, 115.00, 15.00, 15.00, 315.00, 'active'),

(141, 2, 1, 2, 180.00, 20.00, 15.00, 325.00, 'delivered'),
(142, 10, 3, 1, 525.00, 35.00, 25.00, 465.00, 'cancelled'),
(143, 18, 6, 4, 65.00, 10.00, 10.00, 240.00, 'shipped'),
(144, 26, 9, 2, 215.00, 20.00, 20.00, 390.00, 'returned'),
(145, 34, 11, 1, 375.00, 25.00, 15.00, 335.00, 'active'),
(146, 42, 14, 3, 95.00, 15.00, 10.00, 260.00, 'delivered'),
(147, 50, 17, 2, 190.00, 20.00, 18.00, 342.00, 'pending'),
(148, 58, 19, 1, 560.00, 40.00, 30.00, 490.00, 'shipped'),
(149, 66, 2, 3, 125.00, 20.00, 15.00, 340.00, 'cancelled'),
(150, 74, 5, 2, 155.00, 15.00, 15.00, 280.00, 'delivered'),

(1, 82, 8, 1, 430.00, 30.00, 20.00, 380.00, 'returned'),
(2, 90, 11, 4, 75.00, 15.00, 15.00, 270.00, 'active'),
(3, 98, 15, 2, 205.00, 20.00, 20.00, 370.00, 'shipped'),
(4, 106, 17, 1, 570.00, 40.00, 30.00, 500.00, 'delivered'),
(5, 114, 20, 3, 95.00, 15.00, 10.00, 260.00, 'pending'),
(6, 1, 1, 2, 170.00, 15.00, 15.00, 310.00, 'cancelled'),
(7, 9, 3, 1, 480.00, 30.00, 25.00, 425.00, 'active'),
(8, 17, 6, 4, 70.00, 10.00, 15.00, 255.00, 'returned'),
(9, 25, 8, 2, 225.00, 25.00, 20.00, 405.00, 'delivered'),
(10, 33, 11, 1, 320.00, 20.00, 15.00, 285.00, 'shipped'),

(11, 41, 14, 3, 100.00, 10.00, 15.00, 275.00, 'pending'),
(12, 49, 16, 2, 185.00, 20.00, 15.00, 335.00, 'delivered'),
(13, 57, 19, 1, 495.00, 35.00, 25.00, 435.00, 'cancelled'),
(14, 65, 2, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(15, 73, 5, 2, 210.00, 20.00, 20.00, 380.00, 'shipped'),
(16, 81, 8, 1, 385.00, 25.00, 20.00, 340.00, 'returned'),
(17, 89, 11, 3, 110.00, 15.00, 15.00, 300.00, 'delivered'),
(18, 97, 14, 2, 195.00, 20.00, 18.00, 352.00, 'pending'),
(19, 105, 17, 1, 610.00, 45.00, 30.00, 535.00, 'active'),
(20, 113, 19, 3, 80.00, 10.00, 10.00, 220.00, 'cancelled'),

(21, 120, 20, 2, 165.00, 15.00, 15.00, 300.00, 'delivered'),
(22, 6, 2, 1, 460.00, 30.00, 20.00, 410.00, 'shipped'),
(23, 14, 4, 4, 75.00, 15.00, 15.00, 270.00, 'returned'),
(24, 22, 7, 2, 210.00, 20.00, 20.00, 380.00, 'active'),
(25, 30, 10, 1, 540.00, 40.00, 25.00, 475.00, 'delivered'),
(26, 38, 13, 3, 105.00, 15.00, 15.00, 285.00, 'pending'),
(27, 46, 16, 2, 185.00, 20.00, 15.00, 335.00, 'cancelled'),
(28, 54, 18, 1, 420.00, 30.00, 20.00, 370.00, 'shipped'),
(29, 62, 1, 4, 55.00, 10.00, 10.00, 200.00, 'delivered'),
(30, 70, 4, 2, 225.00, 25.00, 20.00, 405.00, 'returned'),

(31, 78, 7, 1, 350.00, 25.00, 15.00, 310.00, 'active'),
(32, 86, 10, 3, 100.00, 10.00, 15.00, 275.00, 'shipped'),
(33, 94, 13, 2, 195.00, 20.00, 18.00, 352.00, 'delivered'),
(34, 102, 16, 1, 580.00, 40.00, 30.00, 510.00, 'cancelled'),
(35, 110, 19, 3, 85.00, 10.00, 10.00, 235.00, 'pending'),
(36, 118, 20, 2, 150.00, 10.00, 15.00, 275.00, 'active'),
(37, 5, 2, 1, 400.00, 30.00, 20.00, 350.00, 'returned'),
(38, 13, 5, 4, 60.00, 10.00, 10.00, 220.00, 'delivered'),
(39, 21, 7, 2, 230.00, 20.00, 20.00, 420.00, 'shipped'),
(40, 29, 10, 1, 515.00, 35.00, 25.00, 455.00, 'cancelled'),

(41, 37, 12, 3, 120.00, 20.00, 15.00, 325.00, 'active'),
(42, 45, 15, 2, 175.00, 15.00, 15.00, 320.00, 'delivered'),
(43, 53, 18, 1, 490.00, 35.00, 25.00, 430.00, 'pending'),
(44, 61, 1, 4, 70.00, 10.00, 15.00, 255.00, 'shipped'),
(45, 69, 4, 2, 200.00, 20.00, 20.00, 360.00, 'returned'),
(46, 77, 6, 1, 625.00, 45.00, 30.00, 550.00, 'delivered'),
(47, 85, 9, 3, 90.00, 10.00, 12.00, 248.00, 'cancelled'),
(48, 93, 12, 2, 160.00, 15.00, 15.00, 290.00, 'active'),
(49, 101, 15, 1, 450.00, 30.00, 20.00, 400.00, 'shipped'),
(50, 109, 18, 3, 115.00, 15.00, 15.00, 315.00, 'delivered')
(51, 117, 20, 2, 240.00, 20.00, 20.00, 440.00, 'active'),
(52, 4, 1, 1, 385.00, 25.00, 20.00, 340.00, 'delivered'),
(53, 12, 4, 3, 105.00, 15.00, 15.00, 285.00, 'shipped'),
(54, 20, 7, 2, 175.00, 20.00, 15.00, 315.00, 'pending'),
(55, 28, 9, 1, 520.00, 35.00, 25.00, 460.00, 'returned'),

(56, 36, 12, 4, 65.00, 10.00, 10.00, 240.00, 'cancelled'),
(57, 44, 15, 2, 215.00, 20.00, 20.00, 390.00, 'delivered'),
(58, 52, 17, 1, 450.00, 30.00, 20.00, 400.00, 'active'),
(59, 60, 20, 3, 90.00, 10.00, 12.00, 248.00, 'shipped'),
(60, 68, 3, 2, 160.00, 15.00, 15.00, 290.00, 'pending'),

(61, 76, 6, 1, 575.00, 40.00, 30.00, 505.00, 'delivered'),
(62, 84, 9, 4, 70.00, 10.00, 15.00, 255.00, 'returned'),
(63, 92, 13, 2, 205.00, 20.00, 20.00, 370.00, 'active'),
(64, 100, 16, 1, 395.00, 25.00, 20.00, 350.00, 'cancelled'),
(65, 108, 18, 3, 115.00, 15.00, 15.00, 315.00, 'shipped'),

(66, 116, 20, 2, 185.00, 20.00, 15.00, 335.00, 'delivered'),
(67, 3, 1, 1, 475.00, 30.00, 25.00, 420.00, 'pending'),
(68, 11, 3, 4, 60.00, 10.00, 10.00, 220.00, 'active'),
(69, 19, 6, 2, 225.00, 25.00, 20.00, 405.00, 'returned'),
(70, 27, 9, 1, 340.00, 20.00, 15.00, 305.00, 'delivered'),

(71, 35, 12, 3, 100.00, 10.00, 15.00, 275.00, 'cancelled'),
(72, 43, 14, 2, 195.00, 20.00, 18.00, 352.00, 'shipped'),
(73, 51, 17, 1, 610.00, 45.00, 30.00, 535.00, 'active'),
(74, 59, 20, 3, 85.00, 10.00, 10.00, 235.00, 'pending'),
(75, 67, 3, 2, 150.00, 10.00, 15.00, 275.00, 'delivered'),

(76, 75, 5, 1, 430.00, 30.00, 20.00, 380.00, 'returned'),
(77, 83, 9, 4, 75.00, 15.00, 15.00, 270.00, 'shipped'),
(78, 91, 12, 2, 210.00, 20.00, 20.00, 380.00, 'cancelled'),
(79, 99, 15, 1, 540.00, 40.00, 25.00, 475.00, 'active'),
(80, 107, 18, 3, 105.00, 15.00, 15.00, 285.00, 'delivered'),

(81, 115, 20, 2, 180.00, 20.00, 15.00, 325.00, 'pending'),
(82, 2, 1, 1, 490.00, 35.00, 25.00, 430.00, 'shipped'),
(83, 10, 3, 4, 55.00, 10.00, 10.00, 200.00, 'returned'),
(84, 18, 6, 2, 230.00, 20.00, 20.00, 420.00, 'active'),
(85, 26, 9, 1, 365.00, 25.00, 15.00, 325.00, 'delivered'),

(86, 34, 11, 3, 95.00, 15.00, 10.00, 260.00, 'cancelled'),
(87, 42, 14, 2, 200.00, 20.00, 20.00, 360.00, 'shipped'),
(88, 50, 17, 1, 585.00, 40.00, 30.00, 515.00, 'pending'),
(89, 58, 19, 3, 125.00, 20.00, 15.00, 340.00, 'active'),
(90, 66, 2, 2, 155.00, 15.00, 15.00, 280.00, 'delivered'),

(91, 74, 5, 1, 445.00, 30.00, 20.00, 395.00, 'returned'),
(92, 82, 8, 4, 80.00, 10.00, 15.00, 295.00, 'shipped'),
(93, 90, 11, 2, 220.00, 20.00, 20.00, 400.00, 'active'),
(94, 98, 15, 1, 515.00, 35.00, 25.00, 455.00, 'cancelled'),
(95, 106, 17, 3, 110.00, 15.00, 15.00, 300.00, 'delivered'),

(96, 114, 20, 2, 190.00, 20.00, 18.00, 342.00, 'pending'),
(97, 1, 1, 1, 625.00, 45.00, 30.00, 550.00, 'shipped'),
(98, 9, 3, 4, 70.00, 10.00, 15.00, 255.00, 'returned'),
(99, 17, 6, 2, 165.00, 15.00, 15.00, 300.00, 'active'),
(100, 25, 8, 1, 470.00, 30.00, 25.00, 415.00, 'delivered');





-----------DATA PAYMENT--------


INSERT INTO payments
(order_id, payment_reference, amount, payment_method, paid_at, status)
VALUES

(1, 'PAY-0001', 849.90, 'card', '2026-08-12 10:24:00', 'paid'),
(2, 'PAY-0002', 1249.50, 'pix', '2026-08-12 11:05:00', 'paid'),
(3, 'PAY-0003', 459.99, 'wallet', '2026-08-12 12:18:00', 'paid'),
(4, 'PAY-0004', 2199.00, 'bank_transfer', '2026-08-12 13:42:00', 'paid'),
(5, 'PAY-0005', 679.90, 'card', '2026-08-13 09:16:00', 'paid'),
(6, 'PAY-0006', 1599.00, 'pix', '2026-08-13 10:37:00', 'paid'),
(7, 'PAY-0007', 329.90, 'wallet', '2026-08-13 11:49:00', 'paid'),
(8, 'PAY-0008', 2890.00, 'card', '2026-08-13 14:21:00', 'paid'),
(9, 'PAY-0009', 749.50, 'pix', '2026-08-14 09:32:00', 'paid'),
(10, 'PAY-0010', 1149.90, 'card', '2026-08-14 10:44:00', 'paid'),

(11, 'PAY-0011', 599.00, 'bank_transfer', '2026-08-14 12:15:00', 'paid'),
(12, 'PAY-0012', 1799.90, 'pix', '2026-08-14 15:06:00', 'paid'),
(13, 'PAY-0013', 389.90, 'card', '2026-08-15 09:27:00', 'paid'),
(14, 'PAY-0014', 2399.00, 'wallet', '2026-08-15 11:18:00', 'paid'),
(15, 'PAY-0015', 929.90, 'pix', '2026-08-15 13:35:00', 'paid'),
(16, 'PAY-0016', 1450.00, 'card', '2026-08-15 16:12:00', 'paid'),
(17, 'PAY-0017', 519.90, 'bank_transfer', '2026-08-16 10:08:00', 'paid'),
(18, 'PAY-0018', 3099.00, 'card', '2026-08-16 11:46:00', 'paid'),
(19, 'PAY-0019', 699.90, 'pix', '2026-08-16 14:29:00', 'paid'),
(20, 'PAY-0020', 999.00, 'wallet', '2026-08-16 17:03:00', 'paid'),

(21, 'PAY-0021', 1299.90, 'card', '2026-08-17 09:41:00', 'paid'),
(22, 'PAY-0022', 429.50, 'pix', '2026-08-17 10:22:00', 'paid'),
(23, 'PAY-0023', 1899.00, 'bank_transfer', '2026-08-17 12:54:00', 'paid'),
(24, 'PAY-0024', 759.90, 'card', '2026-08-17 15:18:00', 'paid'),
(25, 'PAY-0025', 2499.00, 'pix', '2026-08-18 09:13:00', 'paid'),
(26, 'PAY-0026', 349.90, 'wallet', '2026-08-18 11:27:00', 'paid'),
(27, 'PAY-0027', 899.90, 'card', '2026-08-18 13:44:00', 'paid'),
(28, 'PAY-0028', 1590.00, 'pix', '2026-08-18 16:31:00', 'paid'),
(29, 'PAY-0029', 549.90, 'bank_transfer', '2026-08-19 10:05:00', 'paid'),
(30, 'PAY-0030', 2799.00, 'card', '2026-08-19 12:48:00', 'paid'),

(31, 'PAY-0031', 679.50, 'pix', '2026-08-19 14:16:00', 'paid'),
(32, 'PAY-0032', 1199.90, 'wallet', '2026-08-19 17:25:00', 'paid'),
(33, 'PAY-0033', 449.00, 'card', '2026-08-20 09:52:00', 'paid'),
(34, 'PAY-0034', 2099.90, 'bank_transfer', '2026-08-20 11:36:00', 'paid'),
(35, 'PAY-0035', 799.90, 'pix', '2026-08-20 13:17:00', 'paid'),
(36, 'PAY-0036', 1399.00, 'card', '2026-08-20 15:42:00', 'paid'),
(37, 'PAY-0037', 299.90, 'wallet', '2026-08-21 10:14:00', 'paid'),
(38, 'PAY-0038', 3199.00, 'pix', '2026-08-21 12:08:00', 'paid'),
(39, 'PAY-0039', 649.90, 'card', '2026-08-21 14:37:00', 'paid'),
(40, 'PAY-0040', 1099.00, 'bank_transfer', '2026-08-21 16:54:00', 'paid'),

(41, 'PAY-0041', 879.90, 'pix', '2026-08-22 09:18:00', 'paid'),
(42, 'PAY-0042', 1549.00, 'card', '2026-08-22 11:43:00', 'paid'),
(43, 'PAY-0043', 499.90, 'wallet', '2026-08-22 13:26:00', 'paid'),
(44, 'PAY-0044', 2299.00, 'pix', '2026-08-22 15:11:00', 'paid'),
(45, 'PAY-0045', 729.90, 'card', '2026-08-23 10:03:00', 'paid'),
(46, 'PAY-0046', 1890.00, 'bank_transfer', '2026-08-23 12:34:00', 'paid'),
(47, 'PAY-0047', 359.90, 'pix', '2026-08-23 14:48:00', 'paid'),
(48, 'PAY-0048', 2699.00, 'card', '2026-08-23 16:22:00', 'paid'),
(49, 'PAY-0049', 919.90, 'wallet', '2026-08-24 09:45:00', 'paid'),
(50, 'PAY-0050', 1349.00, 'pix', '2026-08-24 11:29:00', 'paid'),

(51, 'PAY-0051', 589.90, 'card', '2026-08-24 13:12:00', 'paid'),
(52, 'PAY-0052', 1999.00, 'bank_transfer', '2026-08-24 15:47:00', 'paid'),
(53, 'PAY-0053', 769.90, 'pix', '2026-08-25 10:21:00', 'paid'),
(54, 'PAY-0054', 1149.00, 'wallet', '2026-08-25 12:06:00', 'paid'),
(55, 'PAY-0055', 429.90, 'card', '2026-08-25 14:39:00', 'paid'),
(56, 'PAY-0056', 2899.00, 'pix', '2026-08-25 16:18:00', 'paid'),
(57, 'PAY-0057', 839.90, 'bank_transfer', '2026-08-26 09:56:00', 'paid'),
(58, 'PAY-0058', 1649.00, 'card', '2026-08-26 11:24:00', 'paid'),
(59, 'PAY-0059', 379.90, 'wallet', '2026-08-26 13:51:00', 'paid'),
(60, 'PAY-0060', 2190.00, 'pix', '2026-08-26 15:33:00', 'paid'),

(61, 'PAY-0061', 699.00, 'card', '2026-08-27 10:11:00', 'paid'),
(62, 'PAY-0062', 1249.90, 'bank_transfer', '2026-08-27 12:45:00', 'paid'),
(63, 'PAY-0063', 549.00, 'pix', '2026-08-27 14:27:00', 'paid'),
(64, 'PAY-0064', 1799.00, 'card', '2026-08-27 16:05:00', 'paid'),
(65, 'PAY-0065', 949.90, 'wallet', '2026-08-28 09:37:00', 'paid'),
(66, 'PAY-0066', 2399.90, 'pix', '2026-08-28 11:18:00', 'paid'),
(67, 'PAY-0067', 319.90, 'card', '2026-08-28 13:49:00', 'paid'),
(68, 'PAY-0068', 1499.00, 'bank_transfer', '2026-08-28 15:26:00', 'paid'),
(69, 'PAY-0069', 629.90, 'pix', '2026-08-29 10:04:00', 'paid'),
(70, 'PAY-0070', 2599.00, 'card', '2026-08-29 12:41:00', 'paid'),

(71, 'PAY-0071', 779.90, 'wallet', '2026-08-29 14:18:00', 'paid'),
(72, 'PAY-0072', 1099.90, 'pix', '2026-08-29 16:52:00', 'paid'),
(73, 'PAY-0073', 459.00, 'card', '2026-08-30 09:26:00', 'paid'),
(74, 'PAY-0074', 1999.90, 'bank_transfer', '2026-08-30 11:57:00', 'paid'),
(75, 'PAY-0075', 869.90, 'pix', '2026-08-30 13:33:00', 'paid'),
(76, 'PAY-0076', 1299.00, 'card', '2026-08-30 15:09:00', 'paid'),
(77, 'PAY-0077', 599.90, 'wallet', '2026-08-31 10:15:00', 'paid'),
(78, 'PAY-0078', 2749.00, 'pix', '2026-08-31 12:36:00', 'paid'),
(79, 'PAY-0079', 739.90, 'card', '2026-08-31 14:22:00', 'paid'),
(80, 'PAY-0080', 1549.90, 'bank_transfer', '2026-08-31 16:47:00', 'paid'),

(81, 'PAY-0081', 489.90, 'pix', '2026-09-01 09:42:00', 'paid'),
(82, 'PAY-0082', 2199.90, 'card', '2026-09-01 11:14:00', 'paid'),
(83, 'PAY-0083', 679.00, 'wallet', '2026-09-01 13:58:00', 'paid'),
(84, 'PAY-0084', 1399.90, 'pix', '2026-09-01 15:35:00', 'paid'),
(85, 'PAY-0085', 929.00, 'card', '2026-09-02 10:08:00', 'paid'),
(86, 'PAY-0086', 1899.90, 'bank_transfer', '2026-09-02 12:29:00', 'paid'),
(87, 'PAY-0087', 399.90, 'pix', '2026-09-02 14:46:00', 'paid'),
(88, 'PAY-0088', 3099.90, 'card', '2026-09-02 16:17:00', 'paid'),
(89, 'PAY-0089', 849.00, 'wallet', '2026-09-03 09:51:00', 'paid'),
(90, 'PAY-0090', 1199.00, 'pix', '2026-09-03 11:38:00', 'paid'),

(91, 'PAY-0091', 569.90, 'card', NULL, 'pending'),
(92, 'PAY-0092', 1449.00, 'pix', NULL, 'pending'),
(93, 'PAY-0093', 799.90, 'bank_transfer', NULL, 'pending'),
(94, 'PAY-0094', 2299.90, 'card', NULL, 'pending'),
(95, 'PAY-0095', 649.00, 'wallet', NULL, 'pending'),

(96, 'PAY-0096', 1099.90, 'card', NULL, 'failed'),
(97, 'PAY-0097', 1899.00, 'pix', NULL, 'failed'),
(98, 'PAY-0098', 459.90, 'bank_transfer', NULL, 'failed'),
(99, 'PAY-0099', 1299.90, 'card', NULL, 'failed'),
(100, 'PAY-0100', 899.00, 'wallet', NULL, 'failed'),

(101, 'PAY-0101', 749.90, 'pix', '2026-09-04 10:17:00', 'paid'),
(102, 'PAY-0102', 1699.00, 'card', '2026-09-04 12:41:00', 'paid'),
(103, 'PAY-0103', 529.90, 'bank_transfer', '2026-09-04 14:08:00', 'paid'),
(104, 'PAY-0104', 2399.00, 'pix', '2026-09-04 16:29:00', 'paid'),
(105, 'PAY-0105', 919.90, 'card', '2026-09-05 09:34:00', 'paid'),
(106, 'PAY-0106', 1349.90, 'wallet', '2026-09-05 11:52:00', 'paid'),
(107, 'PAY-0107', 379.00, 'pix', '2026-09-05 13:16:00', 'paid'),
(108, 'PAY-0108', 2799.90, 'card', '2026-09-05 15:43:00', 'paid'),
(109, 'PAY-0109', 689.90, 'bank_transfer', '2026-09-06 10:06:00', 'paid'),
(110, 'PAY-0110', 1599.90, 'pix', '2026-09-06 12:35:00', 'paid'),

(111, 'PAY-0111', 469.90, 'card', '2026-09-06 14:19:00', 'paid'),
(112, 'PAY-0112', 2099.00, 'wallet', '2026-09-06 16:47:00', 'paid'),
(113, 'PAY-0113', 829.90, 'pix', '2026-09-07 09:28:00', 'paid'),
(114, 'PAY-0114', 1199.90, 'card', '2026-09-07 11:13:00', 'paid'),
(115, 'PAY-0115', 599.90, 'bank_transfer', '2026-09-07 13:56:00', 'paid'),
(116, 'PAY-0116', 2499.00, 'pix', '2026-09-07 15:21:00', 'paid'),
(117, 'PAY-0117', 729.00, 'wallet', '2026-09-08 10:04:00', 'paid'),
(118, 'PAY-0118', 1849.90, 'card', '2026-09-08 12:42:00', 'paid'),
(119, 'PAY-0119', 419.90, 'pix', '2026-09-08 14:27:00', 'paid'),
(120, 'PAY-0120', 2999.00, 'bank_transfer', '2026-09-08 16:08:00', 'paid'),

(121, 'PAY-0121', 879.90, 'card', '2026-09-09 09:47:00', 'paid'),
(122, 'PAY-0122', 1399.00, 'pix', '2026-09-09 11:25:00', 'paid'),
(123, 'PAY-0123', 549.90, 'wallet', '2026-09-09 13:18:00', 'paid'),
(124, 'PAY-0124', 2199.90, 'card', '2026-09-09 15:54:00', 'paid'),
(125, 'PAY-0125', 799.00, 'bank_transfer', '2026-09-10 10:13:00', 'paid'),
(126, 'PAY-0126', 1649.90, 'pix', '2026-09-10 12:36:00', 'paid'),
(127, 'PAY-0127', 349.90, 'card', '2026-09-10 14:42:00', 'paid'),
(128, 'PAY-0128', 2699.90, 'wallet', '2026-09-10 16:17:00', 'paid'),
(129, 'PAY-0129', 939.90, 'pix', '2026-09-11 09:31:00', 'paid'),
(130, 'PAY-0130', 1149.00, 'card', '2026-09-11 11:49:00', 'paid'),

(131, 'PAY-0131', 679.90, 'bank_transfer', '2026-09-11 13:27:00', 'paid'),
(132, 'PAY-0132', 1999.00, 'pix', '2026-09-11 15:38:00', 'paid'),
(133, 'PAY-0133', 489.90, 'wallet', '2026-09-12 10:05:00', 'paid'),
(134, 'PAY-0134', 2299.90, 'card', '2026-09-12 12:24:00', 'paid'),
(135, 'PAY-0135', 849.90, 'pix', '2026-09-12 14:51:00', 'paid'),
(136, 'PAY-0136', 1499.90, 'bank_transfer', '2026-09-12 16:33:00', 'paid'),
(137, 'PAY-0137', 399.90, 'card', '2026-09-13 09:18:00', 'paid'),
(138, 'PAY-0138', 2899.00, 'pix', '2026-09-13 11:46:00', 'paid'),
(139, 'PAY-0139', 759.90, 'wallet', '2026-09-13 13:39:00', 'paid'),
(140, 'PAY-0140', 1299.90, 'card', '2026-09-13 15:22:00', 'paid'),

(141, 'PAY-0141', 589.90, 'pix', '2026-09-14 10:11:00', 'paid'),
(142, 'PAY-0142', 1799.00, 'bank_transfer', '2026-09-14 12:34:00', 'paid'),
(143, 'PAY-0143', 929.90, 'card', '2026-09-14 14:16:00', 'paid'),
(144, 'PAY-0144', 2499.90, 'pix', '2026-09-14 16:48:00', 'paid'),
(145, 'PAY-0145', 699.90, 'wallet', '2026-09-15 09:27:00', 'paid'),
(146, 'PAY-0146', 1549.00, 'card', '2026-09-15 11:53:00', 'paid'),
(147, 'PAY-0147', 459.90, 'bank_transfer', '2026-09-15 13:42:00', 'paid'),
(148, 'PAY-0148', 2099.90, 'pix', '2026-09-15 15:19:00', 'paid'),
(149, 'PAY-0149', 819.90, 'card', '2026-09-16 10:08:00', 'paid'),
(150, 'PAY-0150', 1399.00, 'wallet', '2026-09-16 12:45:00', 'paid'),

(5, 'PAY-0151', 340.00, 'pix', '2026-09-16 14:12:00', 'partially_refunded'),
(18, 'PAY-0152', 520.00, 'card', '2026-09-16 15:37:00', 'refunded'),
(27, 'PAY-0153', 275.00, 'wallet', '2026-09-17 09:26:00', 'partially_refunded'),
(39, 'PAY-0154', 610.00, 'bank_transfer', '2026-09-17 11:48:00', 'refunded'),
(52, 'PAY-0155', 430.00, 'pix', '2026-09-17 13:19:00', 'partially_refunded'),
(64, 'PAY-0156', 780.00, 'card', '2026-09-17 15:44:00', 'refunded'),
(78, 'PAY-0157', 295.00, 'wallet', '2026-09-18 10:07:00', 'partially_refunded'),
(91, 'PAY-0158', 560.00, 'pix', NULL, 'pending'),
(112, 'PAY-0159', 715.00, 'card', NULL, 'pending'),
(135, 'PAY-0160', 480.00, 'bank_transfer', NULL, 'pending');



--DATA SHIPMENTS TABLE

INSERT INTO shipments
(order_id, tracking_number, shipping_company, shipped_at, expected_delivery, delivered_at, status)
VALUES

(12, 'TRK-584921', 'Yurtici Kargo', '2026-08-14 10:25:00', '2026-08-17 18:00:00', '2026-08-17 15:42:00', 'delivered'),
(47, 'TRK-731604', 'Aras Kargo', '2026-08-18 14:10:00', '2026-08-21 18:00:00', NULL, 'in_transit'),
(5, 'TRK-249815', 'MNG Kargo', '2026-08-13 09:40:00', '2026-08-16 18:00:00', '2026-08-16 13:18:00', 'delivered'),
(83, 'TRK-916273', 'PTT Kargo', NULL, '2026-09-03 18:00:00', NULL, 'pending'),
(31, 'TRK-408562', 'Surat Kargo', '2026-08-20 11:35:00', '2026-08-23 18:00:00', '2026-08-23 16:05:00', 'delivered'),

(106, 'TRK-672194', 'Hepsijet', '2026-09-07 10:15:00', '2026-09-09 18:00:00', NULL, 'in_transit'),
(19, 'TRK-315847', 'Yurtici Kargo', '2026-08-16 13:20:00', '2026-08-19 18:00:00', '2026-08-19 14:37:00', 'delivered'),
(72, 'TRK-853206', 'Aras Kargo', '2026-08-29 09:55:00', '2026-09-01 18:00:00', NULL, 'shipped'),
(3, 'TRK-194638', 'MNG Kargo', '2026-08-12 16:20:00', '2026-08-15 18:00:00', '2026-08-15 12:49:00', 'delivered'),
(94, 'TRK-527481', 'Surat Kargo', NULL, '2026-09-08 18:00:00', NULL, 'pending'),

(56, 'TRK-768315', 'Hepsijet', '2026-08-25 12:05:00', '2026-08-27 18:00:00', '2026-08-27 16:21:00', 'delivered'),
(28, 'TRK-341729', 'PTT Kargo', '2026-08-18 10:30:00', '2026-08-22 18:00:00', NULL, 'in_transit'),
(119, 'TRK-905416', 'Yurtici Kargo', '2026-09-08 15:45:00', '2026-09-11 18:00:00', NULL, 'shipped'),
(41, 'TRK-286593', 'Aras Kargo', '2026-08-22 09:15:00', '2026-08-25 18:00:00', '2026-08-25 13:07:00', 'delivered'),
(67, 'TRK-614827', 'MNG Kargo', '2026-08-28 14:40:00', '2026-08-31 18:00:00', '2026-08-31 17:12:00', 'delivered'),

(14, 'TRK-472951', 'Surat Kargo', '2026-08-15 11:20:00', '2026-08-18 18:00:00', '2026-08-18 16:34:00', 'delivered'),
(101, 'TRK-839264', 'Hepsijet', '2026-09-05 10:45:00', '2026-09-07 18:00:00', '2026-09-07 14:19:00', 'delivered'),
(36, 'TRK-157483', 'PTT Kargo', '2026-08-21 13:50:00', '2026-08-25 18:00:00', NULL, 'in_transit'),
(88, 'TRK-624915', 'Yurtici Kargo', NULL, '2026-09-05 18:00:00', NULL, 'pending'),
(52, 'TRK-391758', 'Aras Kargo', '2026-08-24 09:25:00', '2026-08-27 18:00:00', '2026-08-27 11:43:00', 'delivered'),

(7, 'TRK-845216', 'MNG Kargo', '2026-08-13 15:35:00', '2026-08-16 18:00:00', '2026-08-16 15:26:00', 'delivered'),
(124, 'TRK-263749', 'Hepsijet', '2026-09-10 11:15:00', '2026-09-12 18:00:00', NULL, 'in_transit'),
(63, 'TRK-918532', 'Surat Kargo', '2026-08-27 14:05:00', '2026-08-30 18:00:00', '2026-08-30 13:52:00', 'delivered'),
(25, 'TRK-506184', 'Yurtici Kargo', '2026-08-18 08:55:00', '2026-08-21 18:00:00', '2026-08-21 17:28:00', 'delivered'),
(97, 'TRK-734625', 'PTT Kargo', NULL, '2026-09-09 18:00:00', NULL, 'pending'),

(44, 'TRK-182946', 'Aras Kargo', '2026-08-23 10:10:00', '2026-08-26 18:00:00', NULL, 'in_transit'),
(115, 'TRK-659314', 'MNG Kargo', '2026-09-08 09:40:00', '2026-09-11 18:00:00', '2026-09-11 15:16:00', 'delivered'),
(9, 'TRK-327581', 'Hepsijet', '2026-08-14 13:15:00', '2026-08-16 18:00:00', '2026-08-16 12:02:00', 'delivered'),
(78, 'TRK-841963', 'Yurtici Kargo', '2026-08-31 16:25:00', '2026-09-03 18:00:00', NULL, 'shipped'),
(132, 'TRK-295714', 'Surat Kargo', '2026-09-13 11:50:00', '2026-09-16 18:00:00', NULL, 'in_transit'),

(58, 'TRK-613482', 'PTT Kargo', '2026-08-26 12:30:00', '2026-08-30 18:00:00', '2026-08-30 16:44:00', 'delivered'),
(21, 'TRK-957316', 'Aras Kargo', '2026-08-17 10:45:00', '2026-08-20 18:00:00', '2026-08-20 14:08:00', 'delivered'),
(109, 'TRK-426875', 'MNG Kargo', '2026-09-06 14:20:00', '2026-09-09 18:00:00', NULL, 'in_transit'),
(39, 'TRK-781524', 'Hepsijet', '2026-08-21 09:05:00', '2026-08-24 18:00:00', '2026-08-24 12:37:00', 'delivered'),
(146, 'TRK-358219', 'Yurtici Kargo', NULL, '2026-09-18 18:00:00', NULL, 'pending'),

(16, 'TRK-694731', 'Surat Kargo', '2026-08-15 14:25:00', '2026-08-18 18:00:00', '2026-08-18 11:54:00', 'delivered'),
(91, 'TRK-247863', 'PTT Kargo', '2026-09-02 10:35:00', '2026-09-05 18:00:00', NULL, 'shipped'),
(34, 'TRK-815492', 'Aras Kargo', '2026-08-20 15:10:00', '2026-08-23 18:00:00', '2026-08-23 13:25:00', 'delivered'),
(69, 'TRK-531786', 'MNG Kargo', '2026-08-29 12:45:00', '2026-09-01 18:00:00', '2026-09-01 16:18:00', 'delivered'),
(127, 'TRK-964215', 'Hepsijet', '2026-09-11 09:20:00', '2026-09-13 18:00:00', NULL, 'in_transit'),

(48, 'TRK-276594', 'Yurtici Kargo', '2026-08-23 13:40:00', '2026-08-26 18:00:00', '2026-08-26 15:09:00', 'delivered'),
(82, 'TRK-713958', 'Surat Kargo', '2026-09-01 11:05:00', '2026-09-04 18:00:00', NULL, 'shipped'),
(6, 'TRK-459821', 'PTT Kargo', '2026-08-13 12:20:00', '2026-08-17 18:00:00', '2026-08-17 14:42:00', 'delivered'),
(137, 'TRK-824367', 'Aras Kargo', '2026-09-14 14:30:00', '2026-09-17 18:00:00', NULL, 'in_transit'),
(53, 'TRK-196742', 'MNG Kargo', NULL, '2026-08-29 18:00:00', NULL, 'pending'),

(112, 'TRK-638451', 'Hepsijet', '2026-09-07 13:25:00', '2026-09-10 18:00:00', '2026-09-10 16:32:00', 'delivered'),
(73, 'TRK-925714', 'Yurtici Kargo', '2026-08-30 10:50:00', '2026-09-02 18:00:00', '2026-09-02 13:46:00', 'delivered'),
(29, 'TRK-347618', 'Aras Kargo', '2026-08-19 16:15:00', '2026-08-22 18:00:00', '2026-08-22 17:05:00', 'delivered'),
(98, 'TRK-581263', 'Surat Kargo', '2026-09-04 09:30:00', '2026-09-07 18:00:00', NULL, 'in_transit'),
(143, 'TRK-762495', 'PTT Kargo', NULL, '2026-09-18 18:00:00', NULL, 'pending'),

(61, 'TRK-214859', 'MNG Kargo', '2026-08-27 11:40:00', '2026-08-30 18:00:00', '2026-08-30 14:21:00', 'delivered'),
(11, 'TRK-873641', 'Hepsijet', '2026-08-14 09:15:00', '2026-08-16 18:00:00', '2026-08-16 10:37:00', 'delivered'),
(126, 'TRK-435927', 'Yurtici Kargo', '2026-09-10 15:05:00', '2026-09-13 18:00:00', NULL, 'in_transit'),
(42, 'TRK-698314', 'Aras Kargo', '2026-08-22 16:40:00', '2026-08-25 18:00:00', '2026-08-25 16:52:00', 'delivered'),
(85, 'TRK-352761', 'Surat Kargo', '2026-09-02 12:10:00', '2026-09-05 18:00:00', NULL, 'shipped'),

(18, 'TRK-947526', 'PTT Kargo', '2026-08-16 11:30:00', '2026-08-20 18:00:00', '2026-08-20 15:47:00', 'delivered'),
(104, 'TRK-528639', 'MNG Kargo', '2026-09-06 09:45:00', '2026-09-09 18:00:00', '2026-09-09 17:03:00', 'delivered'),
(57, 'TRK-163895', 'Hepsijet', '2026-08-25 14:55:00', '2026-08-28 18:00:00', NULL, 'in_transit'),
(134, 'TRK-719428', 'Yurtici Kargo', '2026-09-13 13:10:00', '2026-09-16 18:00:00', NULL, 'shipped'),
(76, 'TRK-286147', 'Aras Kargo', NULL, '2026-09-04 18:00:00', NULL, 'pending'),

(23, 'TRK-654982', 'Surat Kargo', '2026-08-17 15:20:00', '2026-08-20 18:00:00', '2026-08-20 12:15:00', 'delivered'),
(117, 'TRK-391624', 'PTT Kargo', '2026-09-08 12:40:00', '2026-09-11 18:00:00', NULL, 'in_transit'),
(65, 'TRK-825713', 'MNG Kargo', '2026-08-28 10:25:00', '2026-08-31 18:00:00', '2026-08-31 13:38:00', 'delivered'),
(8, 'TRK-479351', 'Yurtici Kargo', '2026-08-13 16:05:00', '2026-08-16 18:00:00', '2026-08-16 16:21:00', 'delivered'),
(145, 'TRK-936284', 'Hepsijet', NULL, '2026-09-19 18:00:00', NULL, 'pending'),

(35, 'TRK-572816', 'Aras Kargo', '2026-08-20 09:50:00', '2026-08-23 18:00:00', '2026-08-23 11:29:00', 'delivered'),
(93, 'TRK-318465', 'Surat Kargo', '2026-09-03 14:15:00', '2026-09-06 18:00:00', NULL, 'in_transit'),
(122, 'TRK-741953', 'MNG Kargo', '2026-09-09 10:30:00', '2026-09-12 18:00:00', NULL, 'shipped'),
(27, 'TRK-265817', 'PTT Kargo', '2026-08-18 13:35:00', '2026-08-21 18:00:00', '2026-08-21 15:12:00', 'delivered'),
(49, 'TRK-894632', 'Hepsijet', '2026-08-24 16:20:00', '2026-08-27 18:00:00', '2026-08-27 12:46:00', 'delivered'),

(108, 'TRK-427159', 'Yurtici Kargo', '2026-09-06 11:55:00', '2026-09-09 18:00:00', NULL, 'in_transit'),
(15, 'TRK-681534', 'Aras Kargo', '2026-08-15 09:35:00', '2026-08-18 18:00:00', '2026-08-18 14:27:00', 'delivered'),
(71, 'TRK-253978', 'MNG Kargo', NULL, '2026-09-02 18:00:00', NULL, 'pending'),
(139, 'TRK-516824', 'Surat Kargo', '2026-09-14 10:05:00', '2026-09-17 18:00:00', NULL, 'shipped'),
(32, 'TRK-749315', 'PTT Kargo', '2026-08-20 12:15:00', '2026-08-24 18:00:00', '2026-08-24 17:41:00', 'delivered'),

(87, 'TRK-365291', 'Hepsijet', '2026-09-02 15:30:00', '2026-09-05 18:00:00', '2026-09-05 14:18:00', 'delivered'),
(54, 'TRK-918463', 'Yurtici Kargo', '2026-08-25 10:40:00', '2026-08-28 18:00:00', NULL, 'in_transit'),
(120, 'TRK-274856', 'Aras Kargo', '2026-09-09 14:50:00', '2026-09-12 18:00:00', NULL, 'shipped'),
(46, 'TRK-631927', 'MNG Kargo', '2026-08-23 08:45:00', '2026-08-26 18:00:00', '2026-08-26 13:57:00', 'delivered'),
(100, 'TRK-485216', 'Surat Kargo', NULL, '2026-09-10 18:00:00', NULL, 'pending'),

(24, 'TRK-753849', 'PTT Kargo', '2026-08-18 11:10:00', '2026-08-21 18:00:00', '2026-08-21 12:33:00', 'delivered'),
(136, 'TRK-196528', 'Hepsijet', '2026-09-13 09:25:00', '2026-09-16 18:00:00', NULL, 'in_transit'),
(62, 'TRK-842617', 'Yurtici Kargo', '2026-08-27 15:15:00', '2026-08-30 18:00:00', '2026-08-30 15:49:00', 'delivered'),
(89, 'TRK-527936', 'Aras Kargo', '2026-09-03 10:20:00', '2026-09-06 18:00:00', NULL, 'shipped'),
(130, 'TRK-314785', 'MNG Kargo', NULL, '2026-09-15 18:00:00', NULL, 'pending'),

(38, 'TRK-679421', 'Surat Kargo', '2026-08-21 14:35:00', '2026-08-24 18:00:00', '2026-08-24 12:21:00', 'delivered'),
(114, 'TRK-925368', 'PTT Kargo', '2026-09-07 11:45:00', '2026-09-10 18:00:00', NULL, 'in_transit'),
(68, 'TRK-451792', 'Hepsijet', '2026-08-28 13:25:00', '2026-08-31 18:00:00', '2026-08-31 15:36:00', 'delivered'),
(102, 'TRK-738514', 'Yurtici Kargo', '2026-09-05 16:10:00', '2026-09-08 18:00:00', NULL, 'shipped'),
(59, 'TRK-286431', 'Aras Kargo', '2026-08-26 09:20:00', '2026-08-29 18:00:00', '2026-08-29 14:43:00', 'delivered'),

(90, 'TRK-614359', 'MNG Kargo', NULL, '2026-09-07 18:00:00', NULL, 'cancelled'),
(116, 'TRK-857214', 'Surat Kargo', '2026-09-08 16:25:00', '2026-09-11 18:00:00', NULL, 'in_transit'),
(4, 'TRK-329681', 'PTT Kargo', '2026-08-12 11:50:00', '2026-08-15 18:00:00', '2026-08-15 16:08:00', 'delivered'),
(79, 'TRK-742915', 'Hepsijet', '2026-09-01 13:35:00', '2026-09-04 18:00:00', '2026-09-04 15:27:00', 'delivered'),
(141, 'TRK-518763', 'Yurtici Kargo', NULL, '2026-09-18 18:00:00', NULL, 'cancelled'),

(55, 'TRK-963174', 'Aras Kargo', '2026-08-25 08:50:00', '2026-08-28 18:00:00', '2026-08-28 17:14:00', 'delivered'),
(128, 'TRK-275418', 'MNG Kargo', '2026-09-11 15:40:00', '2026-09-14 18:00:00', NULL, 'in_transit'),
(22, 'TRK-631485', 'Surat Kargo', '2026-08-17 12:55:00', '2026-08-20 18:00:00', '2026-08-20 16:41:00', 'delivered'),
(103, 'TRK-849276', 'PTT Kargo', '2026-09-05 09:10:00', '2026-09-08 18:00:00', NULL, 'shipped'),
(70, 'TRK-394618', 'Hepsijet', '2026-08-29 15:05:00', '2026-09-01 18:00:00', '2026-09-01 12:58:00', 'delivered'),

(45, 'TRK-716325', 'Yurtici Kargo', '2026-08-23 15:45:00', '2026-08-26 18:00:00', '2026-08-26 16:12:00', 'delivered'),
(131, 'TRK-582947', 'Aras Kargo', '2026-09-12 10:35:00', '2026-09-15 18:00:00', NULL, 'in_transit'),
(10, 'TRK-248531', 'MNG Kargo', '2026-08-14 08:40:00', '2026-08-17 18:00:00', '2026-08-17 13:11:00', 'delivered'),
(84, 'TRK-935714', 'PTT Kargo', NULL, '2026-09-06 18:00:00', NULL, 'pending'),
(118, 'TRK-461829', 'Surat Kargo', '2026-09-08 14:05:00', '2026-09-11 18:00:00', NULL, 'shipped'),

(33, 'TRK-792415', 'Hepsijet', '2026-08-20 14:50:00', '2026-08-23 18:00:00', '2026-08-23 14:32:00', 'delivered'),
(107, 'TRK-315968', 'Yurtici Kargo', '2026-09-06 12:35:00', '2026-09-09 18:00:00', NULL, 'in_transit'),
(74, 'TRK-648213', 'Aras Kargo', '2026-08-30 09:45:00', '2026-09-02 18:00:00', '2026-09-02 17:03:00', 'delivered'),
(96, 'TRK-527814', 'MNG Kargo', NULL, '2026-09-08 18:00:00', NULL, 'cancelled'),
(121, 'TRK-861495', 'PTT Kargo', '2026-09-09 13:20:00', '2026-09-12 18:00:00', NULL, 'in_transit'),

(30, 'TRK-439721', 'Surat Kargo', '2026-08-19 10:05:00', '2026-08-22 18:00:00', '2026-08-22 13:49:00', 'delivered'),
(138, 'TRK-715482', 'Hepsijet', '2026-09-14 12:15:00', '2026-09-17 18:00:00', NULL, 'shipped'),
(51, 'TRK-286739', 'Yurtici Kargo', '2026-08-24 11:35:00', '2026-08-27 18:00:00', '2026-08-27 15:22:00', 'delivered'),
(110, 'TRK-954126', 'Aras Kargo', '2026-09-06 16:45:00', '2026-09-09 18:00:00', NULL, 'in_transit'),
(75, 'TRK-618534', 'MNG Kargo', NULL, '2026-09-05 18:00:00', NULL, 'pending');




--DATA RETURNS TABLE


INSERT INTO returns
(order_item_id, quantity, reason, requested_at, approved_at, completed_at, status)
VALUES
(4, 1, 'Wrong size', '2026-08-10 13:20:00', '2026-08-11 09:15:00', '2026-08-15 16:40:00', 'completed'),
(9, 1, 'Product arrived damaged', '2026-08-12 15:45:00', '2026-08-13 10:30:00', NULL, 'approved'),
(17, 2, 'Item was different from the description', '2026-08-14 11:20:00', NULL, NULL, 'requested'),
(23, 1, 'Wrong product received', '2026-08-16 18:10:00', '2026-08-17 09:40:00', '2026-08-21 14:25:00', 'completed'),
(31, 1, 'Product stopped working', '2026-08-18 12:35:00', '2026-08-19 11:10:00', NULL, 'approved'),
(38, 1, 'Color was not as expected', '2026-08-20 16:50:00', NULL, NULL, 'requested'),
(45, 2, 'Damaged during delivery', '2026-08-22 10:15:00', '2026-08-23 09:25:00', '2026-08-27 17:30:00', 'completed'),
(52, 10, 'Missing parts', '2026-08-24 14:40:00', '2026-08-25 10:05:00', NULL, 'approved'),
(61, 1, 'Wrong size', '2026-08-26 17:25:00', NULL, NULL, 'requested'),
(68, 7, 'Product quality was poor', '2026-08-28 12:10:00', NULL, NULL, 'rejected'),

(74, 1, 'Item arrived damaged', '2026-08-30 15:35:00', '2026-08-31 09:50:00', '2026-09-04 13:20:00', 'completed'),
(82, 2, 'Wrong item received', '2026-09-01 11:45:00', '2026-09-02 14:15:00', NULL, 'approved'),
(89, 1, 'Product does not work', '2026-09-03 19:05:00', NULL, NULL, 'requested'),
(96, 1, 'Item was damaged', '2026-09-05 13:30:00', '2026-09-06 10:20:00', '2026-09-10 15:45:00', 'completed'),
(103, 1, 'Wrong color', '2026-09-07 16:15:00', '2026-09-08 11:35:00', NULL, 'approved'),
(111, 1, 'Size was too small', '2026-09-09 10:40:00', NULL, NULL, 'requested'),
(119, 2, 'Missing accessories', '2026-09-11 18:25:00', '2026-09-12 09:30:00', '2026-09-16 16:10:00', 'completed'),
(127, 1, 'Product did not match the listing', '2026-09-13 14:50:00', NULL, NULL, 'rejected'),
(135, 1, 'Damaged packaging and product', '2026-09-15 12:20:00', '2026-09-16 10:45:00', NULL, 'approved'),
(143, 1, 'Wrong model received', '2026-09-17 17:40:00', NULL, NULL, 'requested'),

(151, 1, 'Product stopped working', '2026-09-19 11:15:00', '2026-09-20 09:40:00', '2026-09-24 14:30:00', 'completed'),
(159, 1, 'Wrong size', '2026-09-20 15:25:00', '2026-09-21 10:10:00', NULL, 'approved'),
(167, 2, 'Product arrived scratched', '2026-09-21 18:05:00', NULL, NULL, 'requested'),
(175, 3, 'Different product received', '2026-09-22 13:45:00', '2026-09-23 11:25:00', '2026-09-27 15:50:00', 'completed'),
(183, 6, 'Item was not working properly', '2026-09-23 16:30:00', NULL, NULL, 'requested'),
(191, 3, 'Wrong color received', '2026-09-24 10:55:00', '2026-09-25 09:15:00', NULL, 'approved'),
(199, 4, 'Damaged on arrival', '2026-09-25 14:20:00', '2026-09-26 10:30:00', '2026-09-29 12:15:00', 'rejected'),
(207, 6, 'Missing component', '2026-09-26 17:10:00', NULL, NULL, 'requested'),
(215, 7, 'Wrong item received', '2026-09-27 11:35:00', '2026-09-28 09:50:00', NULL, 'approved'),
(223, 3, 'Product was not as described', '2026-09-28 16:45:00', NULL, NULL, 'requested')
(231, 2, 'Product arrived damaged', '2026-09-29 10:20:00', '2026-09-30 09:15:00', '2026-10-04 14:30:00', 'completed'),
(239, 1, 'Wrong size received', '2026-09-30 13:45:00', '2026-10-01 10:20:00', NULL, 'approved'),
(247, 3, 'Product quality was poor', '2026-10-01 16:30:00', NULL, NULL, 'requested'),
(255, 1, 'Wrong product received', '2026-10-02 11:15:00', NULL, NULL, 'rejected'),
(263, 4, 'Missing accessories', '2026-10-03 14:50:00', '2026-10-04 09:40:00', '2026-10-08 16:20:00', 'completed'),

(271, 2, 'Item was different from the description', '2026-10-04 17:25:00', NULL, NULL, 'requested'),
(279, 1, 'Product stopped working', '2026-10-05 12:10:00', '2026-10-06 10:30:00', NULL, 'approved'),
(287, 5, 'Damaged during delivery', '2026-10-06 15:40:00', '2026-10-07 09:25:00', '2026-10-11 13:50:00', 'completed'),
(295, 2, 'Wrong color received', '2026-10-07 18:15:00', NULL, NULL, 'rejected'),
(303, 3, 'Missing parts', '2026-10-08 10:35:00', '2026-10-09 11:20:00', NULL, 'approved'),

(311, 1, 'Product did not match the listing', '2026-10-09 14:25:00', NULL, NULL, 'requested'),
(319, 2, 'Item arrived scratched', '2026-10-10 16:50:00', '2026-10-11 09:45:00', '2026-10-15 15:30:00', 'completed'),
(327, 1, 'Wrong model received', '2026-10-11 11:40:00', '2026-10-12 10:15:00', NULL, 'approved'),
(335, 4, 'Product was not working properly', '2026-10-12 13:20:00', NULL, NULL, 'requested'),
(343, 2, 'Damaged packaging and product', '2026-10-13 17:10:00', NULL, NULL, 'rejected'),

(351, 3, 'Wrong item received', '2026-10-14 10:45:00', '2026-10-15 09:30:00', '2026-10-19 14:40:00', 'completed'),
(359, 1, 'Size was too small', '2026-10-15 15:25:00', NULL, NULL, 'requested'),
(367, 6, 'Missing component', '2026-10-16 12:55:00', '2026-10-17 10:05:00', NULL, 'approved'),
(375, 2, 'Product arrived broken', '2026-10-17 18:30:00', '2026-10-18 09:50:00', '2026-10-22 16:15:00', 'completed'),
(383, 3, 'Product was not as described', '2026-10-18 14:10:00', NULL, NULL, 'requested');



