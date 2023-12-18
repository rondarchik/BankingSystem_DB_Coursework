SELECT * FROM Roles;

SELECT * FROM Users;

SELECT * FROM All_User_Roles_Info;

SELECT * FROM Clients;

SELECT * FROM Managers;

SELECT * FROM Technical_Supports;

SELECT * FROM Departments;

SELECT * FROM Cities;

SELECT * FROM City_Department_Counters;

SELECT * FROM Support_Request_Statuses;

SELECT * FROM Support_Requests;

SELECT * FROM Support_Responses;

SELECT * FROM Account_Statuses;

SELECT * FROM Bank_Accounts;

SELECT * FROM Currencies;

SELECT * FROM Currency_Rates;

SELECT * FROM Transaction_Types;

SELECT * FROM Transaction_Categories;

SELECT * FROM Transactions;

SELECT * FROM Credit_Accounts;

SELECT * FROM Credit_Requests;

SELECT * FROM Credit_Transaction_Types;

SELECT * FROM Credit_Transactions;

SELECT * FROM Credit_Types;

SELECT * FROM Deposit_Accounts;

SELECT * FROM Deposit_Requests;

SELECT * FROM Deposit_Transaction_Types;

SELECT * FROM Deposit_Transactions;

SELECT * FROM Deposit_Types;

SELECT tablename FROM pg_tables WHERE schemaname = 'public';

SELECT tgname AS trigger_name, 
       relname AS table_name, 
       nspname AS schema_name
		FROM pg_trigger 
		JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid 
		JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace 
		WHERE tgname = 'set_uuid';


SELECT 
    base.currency_name AS base_currency_name, 
    target.currency_name AS target_currency_name, 
    cr.exchange_rate, 
    cr.last_updated
FROM 
    Currency_Rates AS cr
JOIN 
    Currencies AS base ON cr.base_currency_id = base.id
JOIN 
    Currencies AS target ON cr.target_currency_id = target.id;



SELECT 
    from_acc.account_name AS from_account_name, 
    from_acc.balance AS old_from_account_balance,
    to_acc.account_name AS to_account_name, 
    to_acc.balance AS old_to_account_balance,
    t.amount, 
    from_acc.balance AS new_from_account_balance,
    to_acc.balance AS new_to_account_balance
FROM 
    Transactions AS t
JOIN 
    Bank_Accounts AS from_acc ON t.from_account_id = from_acc.id
JOIN 
    Bank_Accounts AS to_acc ON t.to_account_id = to_acc.id;


SELECT 
    from_acc.account_name AS from_account_name, 
    from_cur.currency_code AS from_account_currency,
    from_acc.balance AS old_from_account_balance,
    to_acc.account_name AS to_account_name, 
    to_cur.currency_code AS to_account_currency,
    to_acc.balance AS old_to_account_balance,
    t.amount, 
    (from_acc.balance - t.amount) AS new_from_account_balance,
    (to_acc.balance + t.amount) AS new_to_account_balance
FROM 
    Transactions AS t
JOIN 
    Bank_Accounts AS from_acc ON t.from_account_id = from_acc.id
JOIN 
    Currencies AS from_cur ON from_acc.currency_id = from_cur.id
JOIN 
    Bank_Accounts AS to_acc ON t.to_account_id = to_acc.id
JOIN 
    Currencies AS to_cur ON to_acc.currency_id = to_cur.id;


SELECT 
    c.city_name, 
    d.department_name, 
    m.id AS manager_id
FROM 
    Managers AS m
JOIN 
    Departments AS d ON m.department_id = d.id
JOIN 
    Cities AS c ON d.city_id = c.id;
	
	
SELECT 
    cr.status AS credit_request_status, 
    ca.start_date, 
    ctt.credit_trans_name, 
    ct.transaction_date
FROM 
    Credit_Requests AS cr
JOIN 
    Credit_Accounts AS ca ON cr.client_id = ca.client_id
JOIN 
    Credit_Transactions AS ct ON ca.id = ct.credit_account_id
JOIN 
    Credit_Transaction_Types AS ctt ON ct.transaction_type_id = ctt.id;


SELECT 
    ctt.credit_trans_name AS transaction_type_name, 
    ct.amount AS transaction_amount,
    ca.repaid_amount,
    ba.account_name AS from_account_name,
    (ba.balance + ct.amount) AS old_balance,
    ba.balance AS new_balance
FROM 
    Credit_Transactions AS ct
JOIN 
    Credit_Transaction_Types AS ctt ON ct.transaction_type_id = ctt.id
JOIN 
    Credit_Accounts AS ca ON ct.credit_account_id = ca.id
JOIN 
    Bank_Accounts AS ba ON ca.client_id = ba.client_id;

