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


/* ================================================================================== */

/* table transactions */

CREATE TABLE transactions (
id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    transfer_id INT,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'completed',
    
    FOREIGN KEY account_id REFERENCES accounts(id),
    FOREIGN KEY transfer_id REFERENCES (id),
    
    CHECK (amount > 0),
    CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer_in', 'transfer_out', 'fee', 'refund', 'loan_payment'))
);


/* TABLE cards  */

CREATE TABLE cards (
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    card_number VARCHAR(30) NOT NULL UNIQUE,
    card_type VARCHAR(20) NOT NULL,
    issued_at DATE NOT NULL,
    expiry_date DATE NOT NULL,
    daily_limit DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (account_id) REFERENCES accounts(id),

    CHECK (card_type IN ('debit', 'credit')),
    CHECK (daily_limit >= 0),

    CHECK (status IN ('active', 'blocked', 'expired', 'cancelled'))
);


/* TABLE card_transactions  */

CREATE TABLE cards (
    id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    merchant_name VARCHAR(150) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    
    FOREIGN KEY (card_id) REFERENCES cards(id),
    
    CHECK (amount > 0),
    CHECK (status IN ('pending', 'approved', 'declined', 'refunded'))
    );



/* table loan */

CREATE TABLE loans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    loan_number VARCHAR(50) NOT NULL UNIQUE,
    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',

    FOREIGN KEY (customer_id) REFERENCES customers(id),

    CHECK (principal_amount >= 0),
    CHECK (interest_rate >= 0),
    CHECK (total_amount >= principal_amount),
    CHECK (
        status IN ('pending','active', 'paid', 'defaulted', 'cancelled'))
);



/* TABLE loan_installments */

CREATE TABLE loan_installments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    paid_at DATETIME,
    status VARCHAR(20) DEFAULT 'pending',

    FOREIGN KEY (loan_id) REFERENCES loans(id),

    CHECK (amount >= 0),
    CHECK (paid_amount >= 0),
    CHECK (paid_amount <= amount),
    CHECK (status IN ('pending','partially_paid','paid','overdue')),

    UNIQUE (loan_id, installment_number)
);



/* audit_logs */

CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT ,
    customer_id INT,
    account_id INT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (account_id) REFERENCES accounts(id)
);

