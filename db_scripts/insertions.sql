-- Больше ролей не должно быть..
INSERT INTO Roles(role_name) VALUES ('Клиент'),
									('Менеджер'),
									('Специалист технической поддержки');
									
INSERT INTO Cities(city_name) VALUES ('Минск'),
									 ('Брест'),
									 ('Гродно'),
									 ('Витебск'),
									 ('Могилев'),
									 ('Гомель');

INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Минск'), 'ул.Есенина, 16');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Минск'), 'пр.газеты «Звязда», 55');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Брест'), 'пл.Привокзальная, 1');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Брест'), 'ул.Жукова, 16');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Гродно'), 'пр.Клецкова, 34');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Гродно'), 'ул.Ожешко, 4');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Витебск'), 'ул.Гагарина, 11Д-4');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Витебск'), 'ул.Кирова, 10-45');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Могилев'), 'пр.Шмидта, 28');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Могилев'), 'ул.Островского, 1Б-1');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Гомель'), 'пр.Речицкий, 16');
INSERT INTO Departments(city_id, department_address) 
	VALUES ((SELECT id FROM Cities WHERE city_name='Гомель'), 'ул.Барыкина, 161');
SELECT * FROM Departments;
--     _username VARCHAR, 
--     _email VARCHAR, 
--     _password VARCHAR, 
--     _role_id UUID, 
--     _first_name VARCHAR DEFAULT NULL,             1
--     _surname VARCHAR DEFAULT NULL,                2
--     _phone_number VARCHAR DEFAULT NULL,           3
--     _date_of_birth TIMESTAMP DEFAULT NULL,        4
--     _support_status BOOLEAN DEFAULT NULL,         5
--     _department_id UUID DEFAULT NULL,             6
-- 	_last_online TIMESTAMP DEFAULT CURRENT_DATE,     7
-- 	_schedule_type_id UUID DEFAULT NULL)             8
SELECT insert_new_user('some_login', 'some_email@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Клиент'),
					  NULL, NULL, '+375291112233');
					  
SELECT * FROM Users;
SELECT * FROM Clients;

					  
SELECT insert_new_user('user', 'user@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Клиент'),
					  NULL, NULL, '+375294442233');
					  
SELECT insert_new_user('good_user', 'good_user@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Клиент'),
					  'Александр', 'Пушкин', '+375294445233', '2000-03-20');
					  

SELECT insert_new_user('small_user', 'small_user@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Клиент'),
					  'Вася', 'Пупкин', '+375294445533', '2010-03-20');
					  
SELECT insert_new_user('manager', 'manager@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Менеджер'),
					  NULL, NULL, NULL, NULL, FALSE, (SELECT id FROM Departments WHERE department_name='Отделение №500/5001'));
					  

SELECT insert_new_user('some_manager2', 'some_manager2@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Менеджер'),
					  NULL, NULL, NULL, NULL, FALSE, '5d69cfb3-87ad-4886-8f95-c6b7c077949b');

SELECT insert_new_user('some_supp', 'some_supp@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Специалист технической поддержки'),
					  NULL, NULL, NULL, NULL, TRUE, NULL, CURRENT_DATE, (SELECT id FROM Support_Schedules WHERE schedule_type_name='С перерывами'));
					  
SELECT insert_new_user('support', 'support@mail.ru', 'password', (SELECT id FROM Roles WHERE role_name='Специалист технической поддержки'),
					  NULL, NULL, NULL, NULL, TRUE, NULL, CURRENT_DATE, (SELECT id FROM Support_Schedules WHERE schedule_type_name='Без перерывов'));

INSERT INTO Support_Request_Statuses(request_status_name) VALUES ('Отправлен'),
																 ('Принят'),
																 ('Закрыт');
INSERT INTO Support_Request_Statuses(request_status_name) VALUES ('Закрыт');

INSERT INTO Support_Schedules(schedule_type_name) VALUES ('Без перерывов'),
														 ('С перерывами');


INSERT INTO Support_Requests (client_id, request_message) 
	VALUES ((SELECT id FROM Users WHERE username='some_login'), 'Как открыть кредит?');
INSERT INTO Support_Requests (client_id, request_message) 
	VALUES ((SELECT id FROM Users WHERE username='some_login'), 'Как открыть вклад?');
INSERT INTO Support_Requests (client_id, request_message) 
	VALUES ((SELECT id FROM Users WHERE username='some_login'), 'Как открыть новый счет?');

DELETE FROM Support_Requests WHERE request_message='Как открыть кредит?';

UPDATE Support_Responses SET response_message='Каком к верху' WHERE request_message='Как открыть кредит?';

INSERT INTO Currencies(currency_code, currency_name) VALUES ('BYN', 'Белорусский рубль'),
															('USD', 'Доллар США'),
															('EUR', 'Евро');

INSERT INTO Account_Statuses (status_name) VALUES ('Открыт'),
												  ('Заморожен'),
												  ('Закрыт');
												  
INSERT INTO Bank_Accounts (account_name, client_id, currency_id) VALUES
	('Основной', (SELECT id FROM Users WHERE username='user'), (SELECT id FROM Currencies WHERE currency_code='BYN')),
	('Валютный', (SELECT id FROM Users WHERE username='user'), (SELECT id FROM Currencies WHERE currency_code='USD'));
INSERT INTO Bank_Accounts (account_name, client_id, currency_id) VALUES
	('Студенческий', (SELECT id FROM Users WHERE username='user'), (SELECT id FROM Currencies WHERE currency_code='BYN'));
UPDATE Bank_Accounts SET balance=149.92, account_name='Студенческий' WHERE account_name='Студенческий';
DELETE FROM Transactions;
	
INSERT INTO Bank_Accounts (account_name, client_id, currency_id) VALUES
	('Основной', (SELECT id FROM Users WHERE username='good_user'), (SELECT id FROM Currencies WHERE currency_code='BYN'));
UPDATE Bank_Accounts SET balance=410.56 where account_name='Основной' and client_id=(SELECT id FROM Users WHERE username='good_user');
	


INSERT INTO Transaction_Types(type_name) VALUES ('Расходы'),
												('Доходы');
												
INSERT INTO Transaction_Categories (category_type_id, category_name) VALUES
	((SELECT id FROM Transaction_Types WHERE type_name='Доходы'), 'Стипендия'),
	((SELECT id FROM Transaction_Types WHERE type_name='Доходы'), 'Заработная плата'),
	((SELECT id FROM Transaction_Types WHERE type_name='Доходы'), 'Аванс'),
	((SELECT id FROM Transaction_Types WHERE type_name='Доходы'), 'Денежные переводы'),
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Продукты'),
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Бытовая химия'),
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Развлечения'),
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Транспорт'),
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Подарки');
INSERT INTO Transaction_Categories (category_type_id, category_name) VALUES
	((SELECT id FROM Transaction_Types WHERE type_name='Расходы'), 'Оплата кредита');


INSERT INTO Transactions (from_account_id, to_account_id, amount, category_id, type_id) VALUES
	((SELECT id FROM Bank_Accounts WHERE account_name='Студенческий' 
	  and client_id=(SELECT id FROM Users WHERE username='user')),
	 (SELECT id FROM Bank_Accounts WHERE account_name='Основной' 
	  and client_id=(SELECT id FROM Users WHERE username='user')),
	 10, 
	 (SELECT id FROM Transaction_Categories WHERE category_name='Денежные переводы'),
	 (SELECT id FROM Transaction_Types WHERE type_name='Доходы'));
	 
INSERT INTO Transactions (from_account_id, to_account_id, amount, category_id, type_id) VALUES
	((SELECT id FROM Bank_Accounts WHERE account_name='Студенческий' 
	  and client_id=(SELECT id FROM Users WHERE username='user')),
	 (SELECT id FROM Bank_Accounts WHERE account_name='Валютный' 
	  and client_id=(SELECT id FROM Users WHERE username='user')),
	 10, 
	 (SELECT id FROM Transaction_Categories WHERE category_name='Денежные переводы'),
	 (SELECT id FROM Transaction_Types WHERE type_name='Расходы'));
	 

INSERT INTO Credit_types (credit_name, min_amount, max_amount, interest_rate, term_months) VALUES 
	('Автокредит', 30000, 150000, 12.5, 120),
	('Потребительский кредит', 20000, 70000, 9.9, 84),
	('Ипотека', 100000, 500000, 14.4, 240);
	
INSERT INTO Credit_requests (credit_type_id, amount, client_id, city_id) VALUES
	((SELECT id FROM Credit_types WHERE credit_name='Автокредит'),
	 100000,
	 (SELECT id FROM Users WHERE username='user'),
	 (SELECT id FROM Cities WHERE city_name='Минск'));

SELECT id  FROM Managers WHERE 
		department_id = (SELECT id FROM Departments WHERE city_id = (SELECT id FROM Cities WHERE city_name='Минск') LIMIT 1);
	 
INSERT INTO Credit_requests (credit_type_id, amount, client_id, city_id) VALUES
	((SELECT id FROM Credit_types WHERE credit_name='Автокредит'),
	 100000,
	 (SELECT id FROM Users WHERE username='good_user'),
	 (SELECT id FROM Cities WHERE city_name='Минск'));
	 

INSERT INTO Credit_requests (credit_type_id, amount, client_id, city_id) VALUES
	((SELECT id FROM Credit_types WHERE credit_name='Автокредит'),
	 100000,
	 (SELECT id FROM Users WHERE username='small_user'),
	 (SELECT id FROM Cities WHERE city_name='Минск'));
	 
	 
DELETE FROM Credit_requests where client_id=(SELECT id FROM Users WHERE username='good_user');
DELETE FROM Credit_accounts;

INSERT INTO Credit_transaction_Types(credit_trans_name) VALUES ('Выдача кредита'),
															   ('Оплата кредита'),
															   ('Начисление процентов');
															   
INSERT INTO Credit_transactions (credit_account_id, amount, transaction_type_id) VALUES
	('1cd86dca-b156-44e0-a627-35a63a2898d8',
	 100,
	 (SELECT id FROM Credit_Transaction_Types WHERE credit_trans_name = 'Оплата кредита'));
	 

INSERT INTO Deposit_types (deposit_name, min_amount, max_amount, interest_rate, term_months) VALUES 
	('Срочный депозит', 50, 5000, 5.5, 7),
	('Сберегательный депозит', 500, 50000, 13, 36);


INSERT INTO Deposit_transaction_Types(deposit_trans_name) VALUES ('Открытие вклада'),
															   ('Пополнение вклада'),
															   ('Начисление процентов');
															   

INSERT INTO Deposit_requests (deposit_type_id, amount, client_id, city_id) VALUES
	((SELECT id FROM Deposit_types WHERE deposit_name='Сберегательный депозит'),
	 500,
	 (SELECT id FROM Users WHERE username='good_user'),
	 (SELECT id FROM Cities WHERE city_name='Минск'));
	 
DELETE FROM Deposit_requests where client_id=(SELECT id FROM Users WHERE username='good_user');

							
INSERT INTO Deposit_transactions (deposit_account_id, amount, transaction_type_id) VALUES
	('b6d9015f-3d1b-4eee-82cb-a7c0525fd7c9',
	 10,
	 (SELECT id FROM Deposit_Transaction_Types WHERE deposit_trans_name = 'Пополнение вклада'));
	 

