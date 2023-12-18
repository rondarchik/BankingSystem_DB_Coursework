-- drop all
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;


-- create tables
CREATE TABLE IF NOT EXISTS Roles (
	id UUID PRIMARY KEY,
	role_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Users (
	id UUID PRIMARY KEY,
	username VARCHAR(50) NOT NULL UNIQUE,
	email VARCHAR(50) NOT NULL UNIQUE,
	first_name VARCHAR(50),
	surname VARCHAR(50), 
	password VARCHAR(200) NOT NULL,
	role_id UUID NOT NULL,
	CONSTRAINT FK_on_Role FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Clients (
	id UUID NOT NULL PRIMARY KEY REFERENCES Users(id),
	phone_number VARCHAR(17) NOT NULL UNIQUE,
	date_of_birth TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Support_Schedules (
	id UUID PRIMARY KEY,
	schedule_type_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Technical_Supports (
	id UUID NOT NULL PRIMARY KEY REFERENCES Users(id),
	support_status BOOLEAN DEFAULT FALSE,
	last_online TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
	schedule_type_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Schedules FOREIGN KEY (schedule_type_id) REFERENCES Support_Schedules(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Cities (
	id UUID PRIMARY KEY,
	city_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Departments (
	id UUID PRIMARY KEY,
	department_name VARCHAR(50) NOT NULL UNIQUE,
	city_id UUID NOT NULL,
	department_address VARCHAR(200) NOT NULL UNIQUE,
	
	CONSTRAINT FK_on_Cities FOREIGN KEY (city_id) REFERENCES Cities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Managers (
	id UUID NOT NULL PRIMARY KEY REFERENCES Users(id),
	department_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Departments FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE
);
	
CREATE TABLE IF NOT EXISTS Support_Request_Statuses (
	id UUID PRIMARY KEY,
	request_status_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Support_Requests (
	id UUID PRIMARY KEY,
	client_id UUID NOT NULL,
	technical_support_id UUID NOT NULL,
	request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	request_message VARCHAR(500) NOT NULL,
	request_status_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Technical_Supports FOREIGN KEY (technical_support_id) REFERENCES Technical_Supports(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Request_Status FOREIGN KEY (request_status_id) REFERENCES Support_Request_Statuses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Support_Responses (
	id UUID PRIMARY KEY,
	technical_support_id UUID NOT NULL,
	request_id UUID NOT NULL,
	response_date TIMESTAMP,
	response_message VARCHAR(500),
	
	CONSTRAINT FK_on_Technical_Supports FOREIGN KEY (technical_support_id) REFERENCES Technical_Supports(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Support_Requests FOREIGN KEY (request_id) REFERENCES Support_Requests(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Credit_Types (
	id UUID PRIMARY KEY,
	credit_name VARCHAR(50) NOT NULL,
	min_amount NUMERIC(10, 2) NOT NULL,
	max_amount NUMERIC(10, 2) NOT NULL,
	interest_rate NUMERIC(10, 2) NOT NULL,
	term_months INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Credit_Requests (
	id UUID PRIMARY KEY,
	credit_type_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	client_id UUID NOT NULL,
	manager_id UUID NOT NULL,
	request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	status BOOLEAN DEFAULT FALSE,
	city_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Credit_Types FOREIGN KEY (credit_type_id) REFERENCES Credit_Types(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Managers FOREIGN KEY (manager_id) REFERENCES Managers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Credit_Accounts (
	id UUID PRIMARY KEY,
	client_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	repaid_amount NUMERIC(10, 2) NOT NULL,
	interest_rate NUMERIC(10, 2) NOT NULL,
	start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	end_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS Credit_Transaction_Types (
	id UUID PRIMARY KEY,
	credit_trans_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Credit_Transactions (
	id UUID PRIMARY KEY,
	credit_account_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	transaction_type_id UUID NOT NULL,
	transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Credit_Accounts FOREIGN KEY (credit_account_id) REFERENCES Credit_Accounts(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Credit_Transaction_Types FOREIGN KEY (transaction_type_id) REFERENCES Credit_Transaction_Types(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Deposit_Types (
	id UUID PRIMARY KEY,
	deposit_name VARCHAR(50) NOT NULL,
	min_amount NUMERIC(10, 2) NOT NULL,
	max_amount NUMERIC(10, 2) NOT NULL,
	interest_rate NUMERIC(10, 2) NOT NULL,
	term_months INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Deposit_Requests (
	id UUID PRIMARY KEY,
	deposit_type_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	client_id UUID NOT NULL,
	manager_id UUID NOT NULL,
	request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	status BOOLEAN DEFAULT FALSE,
	city_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Deposit_Types FOREIGN KEY (deposit_type_id) REFERENCES Deposit_Types(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Managers FOREIGN KEY (manager_id) REFERENCES Managers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Deposit_Accounts (
	id UUID PRIMARY KEY,
	client_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	repaid_amount NUMERIC(10, 2) NOT NULL,
	interest_rate NUMERIC(10, 2) NOT NULL,
	start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	end_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Deposit_Transaction_Types (
	id UUID PRIMARY KEY,
	deposit_trans_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Deposit_Transactions (
	id UUID PRIMARY KEY,
	deposit_account_id UUID NOT NULL,
	amount NUMERIC(10, 2) NOT NULL,
	transaction_type_id UUID NOT NULL,
	transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Deposit_Accounts FOREIGN KEY (deposit_account_id) REFERENCES Deposit_Accounts(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Deposit_Transaction_Types FOREIGN KEY (transaction_type_id) REFERENCES Deposit_Transaction_Types(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Currencies (
	id UUID PRIMARY KEY,
	currency_code VARCHAR(3) NOT NULL,
	currency_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Currency_Rates (
	id UUID PRIMARY KEY,
	base_currency_id UUID NOT NULL,
	target_currency_id UUID NOT NULL,
	exchange_rate NUMERIC(10, 2) NOT NULL,
	last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Currency1 FOREIGN KEY (base_currency_id) REFERENCES Currencies(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Currency2 FOREIGN KEY (target_currency_id) REFERENCES Currencies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Account_Statuses (
	id UUID PRIMARY KEY,
	status_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Bank_Accounts (
	id UUID PRIMARY KEY,
	account_name VARCHAR(50) NOT NULL,
	client_id UUID NOT NULL,
	balance NUMERIC(10, 2) NOT NULL,
	currency_id UUID NOT NULL,
	creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	account_status_id UUID NOT NULL,
	
	CONSTRAINT FK_on_Clients FOREIGN KEY (client_id) REFERENCES Clients(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Currencies FOREIGN KEY (currency_id) REFERENCES Currencies(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Account_Statuses FOREIGN KEY (account_status_id) REFERENCES Account_Statuses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Transaction_Types (
	id UUID PRIMARY KEY,
	type_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Transaction_Categories (
	id UUID PRIMARY KEY,
	category_type_id UUID NOT NULL,
	category_name VARCHAR(50) NOT NULL,
	
	CONSTRAINT FK_on_Trans_types FOREIGN KEY (category_type_id) REFERENCES Transaction_Types(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Transactions (
	id UUID PRIMARY KEY,
	from_account_id UUID NOT NULL,
	to_account_id UUID,
	amount NUMERIC(10, 2) NOT NULL,
	category_id UUID NOT NULL,
	type_id UUID NOT NULL,
	transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CONSTRAINT FK_on_Account1 FOREIGN KEY (from_account_id) REFERENCES Bank_Accounts(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Account2 FOREIGN KEY (to_account_id) REFERENCES Bank_Accounts(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Categories FOREIGN KEY (category_id) REFERENCES Transaction_Categories(id) ON DELETE CASCADE,
	CONSTRAINT FK_on_Trans_types FOREIGN KEY (type_id) REFERENCES Transaction_Types(id) ON DELETE CASCADE
);

-- Вспомогательные таблицы для функций/триггеров
CREATE TABLE IF NOT EXISTS All_User_Roles_Info (
	id UUID PRIMARY KEY,
	username VARCHAR(50) NOT NULL,
	email VARCHAR(50) NOT NULL UNIQUE,
	first_name VARCHAR(50),
	surname VARCHAR(50), 
	password VARCHAR(200) NOT NULL,
	role_id UUID NOT NULL,
	phone_number VARCHAR(17) UNIQUE,
	date_of_birth TIMESTAMP,
	support_status BOOLEAN,
	department_id UUID,
	last_online TIMESTAMP,
	schedule_type_id UUID
);


CREATE TABLE IF NOT EXISTS City_Department_Number (
    city_id UUID PRIMARY KEY,
    dept_number INT DEFAULT 0,
	
    CONSTRAINT FK_on_Cities FOREIGN KEY (city_id) REFERENCES Cities(id) ON DELETE CASCADE
);

INSERT INTO City_Department_Number(city_id, dept_number)
	SELECT id, ROW_NUMBER() OVER (ORDER BY city_name) FROM Cities;
	
CREATE TABLE IF NOT EXISTS City_Department_Counters (
    city_id UUID PRIMARY KEY,
    last_department_number INT DEFAULT 0,
	
    CONSTRAINT FK_on_Cities FOREIGN KEY (city_id) REFERENCES Cities(id) ON DELETE CASCADE
);
