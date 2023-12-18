CREATE TRIGGER after_user_insert 
	AFTER INSERT ON All_User_Roles_Info 
	FOR EACH ROW 
	EXECUTE FUNCTION distribute_user_info();

CREATE TRIGGER hash_password_trigger
	BEFORE INSERT ON All_User_Roles_Info
	FOR EACH ROW
	EXECUTE FUNCTION hash_password();
	
CREATE TRIGGER before_department_insert
	BEFORE INSERT ON Departments
	FOR EACH ROW
	EXECUTE PROCEDURE generate_department_name();

CREATE TRIGGER support_status_update_online
	BEFORE UPDATE ON Technical_Supports
	FOR EACH ROW
	EXECUTE FUNCTION update_last_online();
	
CREATE TRIGGER support_request_insert
	BEFORE INSERT ON Support_Requests
	FOR EACH ROW
	EXECUTE FUNCTION assign_support_and_status();

CREATE TRIGGER insert_response
	AFTER INSERT ON Support_Requests
	FOR EACH ROW
	EXECUTE FUNCTION insert_request_response();
	
CREATE TRIGGER support_status_update
	AFTER UPDATE ON Technical_Supports
	FOR EACH ROW
	EXECUTE FUNCTION update_request_status();

CREATE TRIGGER support_response_insert
	AFTER UPDATE ON Support_Responses
	FOR EACH ROW
	EXECUTE FUNCTION close_request_on_response();
	
CREATE TRIGGER set_open_status_on_insert
	BEFORE INSERT ON Bank_Accounts
	FOR EACH ROW
	EXECUTE FUNCTION set_open_status_on_insert();
	
CREATE TRIGGER create_new_transaction
	BEFORE INSERT ON Transactions
	FOR EACH ROW
	EXECUTE FUNCTION execute_transaction();
	
CREATE TRIGGER update_balances
	AFTER INSERT ON Transactions
	FOR EACH ROW
	EXECUTE FUNCTION update_accounts_balances();

CREATE TRIGGER credit_request
	BEFORE INSERT ON Credit_Requests
	FOR EACH ROW
	EXECUTE FUNCTION add_credit_request();
	

CREATE TRIGGER update_credit_request_status
	BEFORE INSERT OR UPDATE ON Credit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE update_credit_request_status();


CREATE TRIGGER create_credit_account
	AFTER INSERT OR UPDATE ON Credit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE create_credit_account();
	

CREATE TRIGGER create_credit_transaction
	AFTER INSERT ON Credit_Accounts
	FOR EACH ROW 
	EXECUTE PROCEDURE create_credit_transaction();


CREATE TRIGGER delete_credit_account
	AFTER DELETE ON Credit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_credit_account();
	

CREATE TRIGGER new_credit_transaction
	AFTER INSERT ON Credit_Transactions
	FOR EACH ROW
	EXECUTE PROCEDURE new_credit_transaction();
	
	

CREATE TRIGGER delete_deposit_account
	AFTER DELETE ON Deposit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_deposit_account();
	

CREATE TRIGGER deposit_request
	BEFORE INSERT ON Deposit_Requests
	FOR EACH ROW
	EXECUTE FUNCTION add_deposit_request();
	

CREATE TRIGGER update_deposit_request_status
	BEFORE INSERT OR UPDATE ON Deposit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE update_deposit_request_status();


CREATE TRIGGER create_deposit_account
	AFTER INSERT OR UPDATE ON Deposit_Requests
	FOR EACH ROW 
	EXECUTE PROCEDURE create_deposit_account();
	

CREATE TRIGGER create_deposit_transaction
	AFTER INSERT ON Deposit_Accounts
	FOR EACH ROW 
	EXECUTE PROCEDURE create_deposit_transaction();


CREATE TRIGGER new_deposit_transaction
	AFTER INSERT ON Deposit_Transactions
	FOR EACH ROW
	EXECUTE PROCEDURE new_deposit_transaction();
	
	
	
	