CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Генерация уникальных id для всех таблиц (кроме определенных ролей)
CREATE OR REPLACE FUNCTION generate_uuid()
	RETURNS TRIGGER AS 
$$
BEGIN
  NEW.id = uuid_generate_v4();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION generate_id_for_tables() 
	RETURNS void AS 
$$
DECLARE
   table_name TEXT;
BEGIN
   FOR table_name IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
					  	AND tablename NOT IN ('users', 'clients', 'managers', 'technical_supports'))
   LOOP
      EXECUTE format('
         CREATE TRIGGER set_uuid
         	BEFORE INSERT ON %I
         	FOR EACH ROW
         		EXECUTE PROCEDURE generate_uuid();
      ', table_name);
   END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT generate_id_for_tables();


CREATE OR REPLACE FUNCTION generate_id_for_one_new_table(_table_name VARCHAR) 
	RETURNS void AS 
$$
DECLARE
BEGIN
	EXECUTE format('
    	CREATE TRIGGER set_uuid
        	BEFORE INSERT ON %I
         	FOR EACH ROW
         		EXECUTE PROCEDURE generate_uuid();
      	', _table_name);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION hash_password()
	RETURNS TRIGGER AS 
$$
BEGIN
   	NEW.password = crypt(NEW.password, gen_salt('bf'));
   	RETURN NEW;
END;
$$ LANGUAGE plpgsql;	

CREATE OR REPLACE PROCEDURE add_currency(_code VARCHAR, _name VARCHAR) AS 
$$
BEGIN
	INSERT INTO Currencies (currency_code, currency_name)
		VALUES (_code, _name);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_credit_type(
	_name VARCHAR, _min NUMERIC, _max NUMERIC, _rate NUMERIC, _term INT) AS
$$
BEGIN
	INSERT INTO Credit_types(
		credit_name, 
		min_amount, 
		max_amount, 
		interest_rate, 
		term_months) 
		VALUES (_name, _min, _max, _rate, _term);
END;
$$ LANGUAGE plpgsql;

-- При вставке в таблицу Users и "выбора" роли также производится вставка в таблицу соответствующей роли
CREATE OR REPLACE FUNCTION insert_new_user(
    _username VARCHAR, 
    _email VARCHAR, 
    _password VARCHAR, 
    _role_id UUID, 
    _first_name VARCHAR DEFAULT NULL, 
    _surname VARCHAR DEFAULT NULL, 
    _phone_number VARCHAR DEFAULT NULL, --client
    _date_of_birth TIMESTAMP DEFAULT NULL, -- client
    _support_status BOOLEAN DEFAULT FALSE, -- supp
    _department_id UUID DEFAULT NULL, -- manager
	_last_online TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- supp
	_schedule_type_id UUID DEFAULT NULL) -- supp
	RETURNS void AS 
$$
BEGIN
    INSERT INTO All_User_Roles_Info(username, email, first_name, surname, 
									password, role_id, phone_number, date_of_birth, 
									support_status, department_id, last_online, schedule_type_id) 
        VALUES (_username, _email, _first_name, _surname, 
				_password, _role_id, _phone_number, _date_of_birth, 
				_support_status, _department_id, _last_online, _schedule_type_id);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION distribute_user_info() 
	RETURNS TRIGGER AS 
$$
BEGIN
    INSERT INTO Users(id, username, email, first_name, surname, password, role_id) 
    	VALUES (NEW.id, NEW.username, NEW.email, NEW.first_name, NEW.surname, NEW.password, NEW.role_id);

    IF NEW.role_id = (SELECT id FROM Roles WHERE role_name = 'Клиент') THEN
        INSERT INTO Clients(id, phone_number, date_of_birth) 
            VALUES (NEW.id, NEW.phone_number, NEW.date_of_birth);
    ELSIF NEW.role_id = (SELECT id FROM Roles WHERE role_name = 'Менеджер') THEN
        INSERT INTO Managers(id, department_id) 
            VALUES (NEW.id, NEW.department_id);
	ELSIF NEW.role_id = (SELECT id FROM Roles WHERE role_name = 'Специалист технической поддержки') THEN
        INSERT INTO Technical_Supports(id, support_status, last_online, schedule_type_id) 
            VALUES (NEW.id, NEW.support_status, NEW.last_online, NEW.schedule_type_id);
    END IF;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Функция генерирующая название отдела
CREATE OR REPLACE FUNCTION generate_department_name()
	RETURNS TRIGGER AS 
$$
DECLARE
    city_rank INT;
    department_number INT;
    new_department_name VARCHAR;
BEGIN
    SELECT dept_number INTO city_rank
    	FROM City_Department_Number WHERE city_id = NEW.city_id;
			
    SELECT last_department_number + 1 INTO department_number
    	FROM City_Department_Counters WHERE city_id = NEW.city_id;

    IF department_number IS NULL THEN
        department_number := 1;
    END IF;
	
	INSERT INTO City_Department_Counters(city_id, last_department_number)
    	VALUES (NEW.city_id, department_number)
    		ON CONFLICT (city_id) DO UPDATE SET last_department_number = department_number;

    new_department_name := 'Отделение №' || city_rank || '00/' || city_rank || '00' || department_number;
	NEW.department_name := new_department_name;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- обновление времени последнего пребывания в сети
CREATE OR REPLACE FUNCTION update_last_online()
	RETURNS TRIGGER AS 
$$
BEGIN
   IF NEW.support_status = FALSE THEN
      NEW.last_online = CURRENT_TIMESTAMP;
   END IF;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- запросы и их статус
CREATE OR REPLACE FUNCTION assign_support_and_status()
	RETURNS TRIGGER AS 
$$
BEGIN
   	IF (SELECT support_status FROM Technical_Supports WHERE id = NEW.technical_support_id) THEN
      	NEW.request_status_id = (SELECT id FROM Support_Request_Statuses WHERE request_status_name = 'Принят');
   	ELSE
      	NEW.request_status_id = (SELECT id FROM Support_Request_Statuses WHERE request_status_name = 'Отправлен');
   	END IF;
   
   	NEW.technical_support_id = (
      	SELECT id FROM Technical_Supports 
      	WHERE support_status = TRUE OR last_online = (
         	SELECT MAX(last_online) FROM Technical_Supports
      	)
      	LIMIT 1
   	);
	
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_request_response()
	RETURNS TRIGGER AS 
$$
BEGIN
   	INSERT INTO Support_Responses (technical_support_id, request_id)
   		VALUES (NEW.technical_support_id, NEW.id);
   
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_request_status()
	RETURNS TRIGGER AS 
$$
BEGIN
   	IF NEW.support_status = TRUE THEN
      	UPDATE Support_Requests 
      		SET request_status_id = (SELECT id FROM Support_Request_Statuses WHERE request_status_name = 'Принят')
    		WHERE technical_support_id = NEW.id;
   	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION close_request_on_response()
	RETURNS TRIGGER AS 
$$
BEGIN
	NEW.response_date = CURRENT_TIMESTAMP;
		
	UPDATE Support_Requests 
   		SET request_status_id = (SELECT id FROM Support_Request_Statuses WHERE request_status_name = 'Закрыт')
   		WHERE id = NEW.request_id;
   
   	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_open_status_on_insert() 
	RETURNS TRIGGER AS 
$$
BEGIN
	NEW.account_status_id := (SELECT id FROM Account_Statuses WHERE status_name = 'Открыт');
	NEW.balance := 0;
	NEW.creation_date := CURRENT_TIMESTAMP;
   	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION execute_transaction()
	RETURNS TRIGGER AS
$$
DECLARE
    from_account_status UUID;
    to_account_status UUID;
    from_account_currency UUID;
    to_account_currency UUID;
    exch_rate NUMERIC;
BEGIN
	SELECT account_status_id INTO from_account_status FROM Bank_Accounts WHERE id = NEW.from_account_id;
    SELECT account_status_id INTO to_account_status FROM Bank_Accounts WHERE id = NEW.to_account_id;

	IF (SELECT status_name FROM Account_Statuses WHERE id = from_account_status) != 'Открыт'
		OR (SELECT status_name FROM Account_Statuses WHERE id = to_account_status) != 'Открыт' 
	THEN
        RAISE EXCEPTION 'Счет не открыт!';
    END IF;
	
	SELECT currency_id INTO from_account_currency FROM Bank_Accounts WHERE id = NEW.from_account_id;
    SELECT currency_id INTO to_account_currency FROM Bank_Accounts WHERE id = NEW.to_account_id;

	IF from_account_currency != to_account_currency THEN
        SELECT exchange_rate INTO exch_rate FROM Currency_Rates 
			WHERE base_currency_id = from_account_currency AND target_currency_id = to_account_currency;
        NEW.amount := NEW.amount / exch_rate;
    END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_accounts_balances()
	RETURNS TRIGGER AS
$$
BEGIN
	UPDATE Bank_Accounts SET balance = balance - NEW.amount WHERE id = NEW.from_account_id;
    UPDATE Bank_Accounts SET balance = balance + NEW.amount WHERE id = NEW.to_account_id;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_credit_request()
	RETURNS TRIGGER AS
$$
DECLARE
    v_min_amount NUMERIC;
    v_max_amount NUMERIC;
    v_manager_id UUID;
BEGIN
	SELECT min_amount, max_amount INTO v_min_amount, v_max_amount 
		FROM Credit_Types WHERE id = NEW.credit_type_id;
		
	IF NEW.amount < v_min_amount OR NEW.amount > v_max_amount THEN
        RAISE EXCEPTION 'Запрошенная сумма не соответствует допустимому диапазону для данного типа кредита';
    END IF;
	
	SELECT id INTO v_manager_id FROM Managers WHERE 
		department_id = (SELECT id FROM Departments WHERE city_id = NEW.city_id LIMIT 1);
	
	IF v_manager_id IS NULL THEN
        RAISE EXCEPTION 'Не найдено менеджеров в данном городе';
	ELSE
		NEW.manager_id := v_manager_id;
    END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_credit_request_status()
	RETURNS TRIGGER AS
$$
DECLARE
	user_record Users%ROWTYPE;
    client_record Clients%ROWTYPE;
    age INTERVAL;
BEGIN
    SELECT * INTO user_record FROM Users WHERE id = NEW.client_id;
    SELECT * INTO client_record FROM Clients WHERE id = NEW.client_id;

    IF user_record IS NULL OR client_record IS NULL THEN
        RAISE EXCEPTION 'Пользователь не найден';
    END IF;

    -- Проверка на NULL для first_name и surname в Users
    IF user_record.first_name IS NULL OR user_record.surname IS NULL THEN
        NEW.status := FALSE;
        RAISE NOTICE 'Кредит не одобрен, потому что недостаточно данных о клиенте';
        RETURN NEW;
    END IF;

    -- Проверка на NULL для date_of_birth в Clients
    IF client_record.date_of_birth IS NULL THEN
        NEW.status := FALSE;
		RAISE NOTICE 'Кредит не одобрен, потому что недостаточно данных о клиенте';
        RETURN NEW;
    END IF;

    age := AGE(NOW(), client_record.date_of_birth);
    IF EXTRACT(YEAR FROM age) < 18 THEN
        NEW.status := FALSE;
		RAISE NOTICE 'Кредит не одобрен, потому что клиенту меньше 18';
    ELSE
        NEW.status := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_credit_account()
	RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.status = TRUE THEN
        INSERT INTO Credit_Accounts (client_id, amount, repaid_amount, interest_rate, start_date, end_date)
        VALUES (
            NEW.client_id,
            (SELECT amount FROM Credit_Requests WHERE client_id = NEW.client_id),
            0,
            (SELECT interest_rate FROM Credit_Types WHERE id = NEW.credit_type_id),
            NOW(),
			NOW() + INTERVAL '1 month' * (SELECT term_months FROM Credit_Types WHERE id = NEW.credit_type_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_credit_transaction()
RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO Credit_Transactions (credit_account_id, amount, transaction_type_id, transaction_date)
    VALUES (
        NEW.id,
        NEW.amount,
        (SELECT id FROM Credit_Transaction_Types WHERE credit_trans_name = 'Выдача кредита'),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_credit_account()
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM Credit_Accounts WHERE client_id = OLD.client_id;
	DELETE FROM Credit_Transactions WHERE credit_account_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION new_credit_transaction() 
	RETURNS TRIGGER AS 
$$
DECLARE
    credit_acc_id UUID;
    amount_sum NUMERIC(10, 2);
    trans_type_id UUID;
	trans_name VARCHAR;
    client UUID;
    acc_id UUID;
BEGIN
    credit_acc_id := NEW.credit_account_id;
    amount_sum := NEW.amount;
    trans_type_id := NEW.transaction_type_id;
	
	SELECT credit_trans_name INTO trans_name FROM Credit_Transaction_Types WHERE id = trans_type_id;
    IF trans_name = 'Оплата кредита'
    THEN
		IF NOT EXISTS (SELECT 1 FROM Transaction_Categories WHERE category_name = 'Оплата кредита') 
		THEN
			INSERT INTO Transaction_Categories (category_type_id, category_name) 
				VALUES ((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), trans_name);
		END IF;
		
        SELECT client_id INTO client FROM Credit_Accounts WHERE id = credit_acc_id;

        SELECT id INTO acc_id FROM Bank_Accounts
        	WHERE client_id = client AND currency_id = (SELECT id FROM Currencies WHERE currency_code='BYN') 
			AND balance >= amount_sum
        	ORDER BY balance DESC LIMIT 1; -- выбираем счет с наибольшим балансом
			

        IF acc_id IS NOT NULL
        THEN
--             UPDATE Bank_Accounts SET balance = balance - amount_sum WHERE id = acc_id;
            UPDATE Credit_Accounts SET repaid_amount = repaid_amount + amount_sum WHERE id = credit_acc_id;

            INSERT INTO Transactions (from_account_id, to_account_id, amount, category_id, type_id)
            	VALUES (acc_id, NULL, amount_sum, 
						(SELECT id FROM Transaction_Categories WHERE category_name=trans_name), 
					    (SELECT id FROM Transaction_Types WHERE type_name='Расходы')); 
        ELSE
			RAISE EXCEPTION 'У данного пользователя недостаточно средств или нет открытых счетов';
		END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_deposit_account()
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM Deposit_Accounts WHERE client_id = OLD.client_id;
	DELETE FROM Deposit_Transactions WHERE deposit_account_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_deposit_request()
	RETURNS TRIGGER AS
$$
DECLARE
    v_min_amount NUMERIC;
    v_max_amount NUMERIC;
    v_manager_id UUID;
BEGIN
	SELECT min_amount, max_amount INTO v_min_amount, v_max_amount 
		FROM Deposit_Types WHERE id = NEW.deposit_type_id;
		
	IF NEW.amount < v_min_amount OR NEW.amount > v_max_amount THEN
        RAISE EXCEPTION 'Запрошенная сумма не соответствует допустимому диапазону для данного типа кредита';
    END IF;
	
	SELECT id INTO v_manager_id FROM Managers WHERE 
		department_id = (SELECT id FROM Departments WHERE city_id = NEW.city_id LIMIT 1);
	
	IF v_manager_id IS NULL THEN
        RAISE EXCEPTION 'Не найдено менеджеров в данном городе';
	ELSE
		NEW.manager_id := v_manager_id;
    END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_deposit_request_status()
	RETURNS TRIGGER AS
$$
DECLARE
	user_record Users%ROWTYPE;
    client_record Clients%ROWTYPE;
    age INTERVAL;
BEGIN
    SELECT * INTO user_record FROM Users WHERE id = NEW.client_id;
    SELECT * INTO client_record FROM Clients WHERE id = NEW.client_id;

    IF user_record IS NULL OR client_record IS NULL THEN
        RAISE EXCEPTION 'Пользователь не найден';
    END IF;

    -- Проверка на NULL для first_name и surname в Users
    IF user_record.first_name IS NULL OR user_record.surname IS NULL THEN
        NEW.status := FALSE;
        RAISE NOTICE 'Кредит не одобрен, потому что недостаточно данных о клиенте';
        RETURN NEW;
    END IF;

    -- Проверка на NULL для date_of_birth в Clients
    IF client_record.date_of_birth IS NULL THEN
        NEW.status := FALSE;
		RAISE NOTICE 'Вклад не одобрен, потому что недостаточно данных о клиенте';
        RETURN NEW;
    END IF;

    age := AGE(NOW(), client_record.date_of_birth);
    IF EXTRACT(YEAR FROM age) < 18 THEN
        NEW.status := FALSE;
		RAISE NOTICE 'Вклад не одобрен, потому что клиенту меньше 18';
    ELSE
        NEW.status := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_deposit_account()
	RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.status = TRUE THEN
        INSERT INTO Deposit_Accounts (client_id, amount, repaid_amount, interest_rate, start_date, end_date)
        VALUES (
            NEW.client_id,
            (SELECT amount FROM Deposit_Requests WHERE client_id = NEW.client_id),
            0,
            (SELECT interest_rate FROM Deposit_Types WHERE id = NEW.deposit_type_id),
            NOW(),
			NOW() + INTERVAL '1 month' * (SELECT term_months FROM Deposit_Types WHERE id = NEW.deposit_type_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_deposit_transaction()
RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO Deposit_Transactions (deposit_account_id, amount, transaction_type_id, transaction_date)
    VALUES (
        NEW.id,
        NEW.amount,
        (SELECT id FROM Deposit_Transaction_Types WHERE deposit_trans_name = 'Открытие вклада'),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION new_deposit_transaction() 
	RETURNS TRIGGER AS 
$$
DECLARE
    deposit_acc_id UUID;
    amount_sum NUMERIC(10, 2);
    trans_type_id UUID;
	trans_name VARCHAR;
    client UUID;
    acc_id UUID;
BEGIN
    deposit_acc_id := NEW.deposit_account_id;
    amount_sum := NEW.amount;
    trans_type_id := NEW.transaction_type_id;
	
	SELECT deposit_trans_name INTO trans_name FROM Deposit_Transaction_Types WHERE id = trans_type_id;
    IF trans_name = 'Пополнение вклада'
    THEN
		IF NOT EXISTS (SELECT 1 FROM Transaction_Categories WHERE category_name = 'Пополнение вклада') 
		THEN
			INSERT INTO Transaction_Categories (category_type_id, category_name) 
				VALUES ((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), trans_name);
		END IF;
		
        SELECT client_id INTO client FROM Deposit_Accounts WHERE id = deposit_acc_id;

        SELECT id INTO acc_id FROM Bank_Accounts
        	WHERE client_id = client AND currency_id = (SELECT id FROM Currencies WHERE currency_code='BYN') 
			AND balance >= amount_sum
        	ORDER BY balance DESC LIMIT 1; -- выбираем счет с наибольшим балансом
			

        IF acc_id IS NOT NULL
        THEN
            UPDATE Deposit_Accounts SET amount = amount + amount_sum WHERE id = deposit_acc_id;

            INSERT INTO Transactions (from_account_id, to_account_id, amount, category_id, type_id)
            	VALUES (acc_id, NULL, amount_sum, 
						(SELECT id FROM Transaction_Categories WHERE category_name=trans_name), 
					    (SELECT id FROM Transaction_Types WHERE type_name='Расходы')); 
        ELSE
			RAISE EXCEPTION 'У данного пользователя недостаточно средств или нет открытых счетов';
		END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
