--Banking-and-financial-transactions-system.sql
/*banking system DB */

CREATE DATABASE banking_system;

USE banking_system;


/* table branches */

CREATE TABLE branches(
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_code VARCHAR(20) NOT NULL UNIQUE,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    opened_at DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    
    CHECK (status IN ('active', 'inactive'))
);


/* table customers */

CREATE TABLE customers(
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_number VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    national_id VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100),
    phone VARCHAR(20),
    birthday DATE,
    city VARCHAR(100),
    address VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    
    CHECK(status IN ('active', 'inactive', 'blocked'))
);


/* table accounts */

CREATE TABLE accounts(
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_type VARCHAR(25),
    currency VARCHAR(3) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0,
    opened_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    
    CHECK (account_type IN ('checking', 'saving', 'business')),
    CHECK (currency IN ('SAR', 'USD', 'EUR', 'BRL')),
    CHECK (balance >= 0),
    CHECK (status IN ('active', 'frozen', 'closed'))
);


/* table beneficiaries */

CREATE TABLE beneficiaries (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    beneficiary_account_id INT NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (beneficiary_account_id) REFERENCES accounts(id),

    CHECK (status IN ('active', 'inactive'))
);


/* table transfers */

CREATE TABLE transfers(
    id INT PRIMARY KEY AUTO_INCREMENT,
    reference_number VARCHAR(50) NOT NULL UNIQUE,
    from_account_id INT NOT NULL,
    to_account_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transfer_fee DECIMAL(15,2) DEFAULT 0,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    status VARCHAR(20) DEFAULT 'pending',
    
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id),
    
    CHECK (amount > 0),
    CHECK (transfer_fee >= 0),
    CHECK (from_account_id <> to_account_id),
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled'))
    
);


/* table transactions */
