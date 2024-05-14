CREATE DATABASE BazarTemTudo;

USE BazarTemTudo;

CREATE TABLE CargaTemp (
    order_id VARCHAR(50),
    order_item_id VARCHAR(50),
    purchase_date DATETIME,
    payments_date DATETIME,
    buyer_email VARCHAR(100),
    buyer_name VARCHAR(100),
    cpf VARCHAR(20),
    buyer_phone_number VARCHAR(20),
    sku VARCHAR(50),
    product_name VARCHAR(100),
    quantity_purchased INT,
    currency VARCHAR(10),
    item_price DECIMAL(10, 2),
    ship_service_level VARCHAR(50),
    recipient_name VARCHAR(100),
    ship_address_1 VARCHAR(200),
    ship_address_2 VARCHAR(200),
    ship_address_3 VARCHAR(200),
    ship_city VARCHAR(50),
    ship_state VARCHAR(50),
    ship_postal_code VARCHAR(20),
    ship_country VARCHAR(50),
    ioss_number VARCHAR(50)
);

-- Inserindo exemplos em CargaTemp e o Estoque
INSERT INTO CargaTemp (order_id, order_item_id, purchase_date, payments_date, buyer_email, buyer_name, cpf, buyer_phone_number, sku, product_name, quantity_purchased, currency, item_price, ship_service_level, recipient_name, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, ioss_number)
VALUES 
('O1001', 'OI1001', '2024-04-01', '2024-04-02', 'john@example.com', 'John', '12345678901', '98555-1234', 'SKU1001', 'Caneta chique', 2, 'USD', 20.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL),
('O1001', 'OI1002', '2024-04-01', '2024-04-02', 'john@example.com', 'John', '12345678909', '98555-1234', 'SKU1002', 'Sabonete daora', 2, 'USD', 5.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL),
('O1002', 'OI1003', '2024-04-03', '2024-04-03', 'john@example.com', 'John', '12345678904', '98555-1234', 'SKU1003', 'Refil de caneta', 5, 'USD', 3.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL),
('O1003', 'OI1004', '2024-04-04', '2024-04-04', 'alice@example.com', 'Alice', '23456789012', '9555-8765', 'SKU1003', 'Refil de caneta', 3, 'USD', 3.00, 'Day', 'Alice', '789 Pine St', NULL, NULL, 'Austin', 'TX', '73301', 'USA', NULL)

CREATE TABLE Produtos (		
	sku VARCHAR(50) NOT NULL,
	product_name VARCHAR(100) NOT NULL,
	item_price DECIMAL(10, 2) NOT NULL,
	ioss_number VARCHAR(50),
	PRIMARY KEY (sku)
);

CREATE TABLE Clientes (	
	client_id INT AUTO_INCREMENT,
	buyer_email VARCHAR(100) NOT NULL,
	buyer_name VARCHAR(100) NOT NULL,
	cpf VARCHAR(20) NOT NULL,
	buyer_phone_number VARCHAR(20) NOT NULL,   
	ship_address_1 VARCHAR(200),
	ship_address_2 VARCHAR(200),
	ship_address_3 VARCHAR(200),
	ship_city VARCHAR(50) NOT NULL,
	ship_state VARCHAR(50) NOT NULL,
	ship_postal_code VARCHAR(20) NOT NULL,
	ship_country VARCHAR(50) NOT NULL,
	currency VARCHAR(10) NOT NULL,
	PRIMARY KEY(client_id)
);

CREATE TABLE Pedidos (        
	order_id VARCHAR(50) UNIQUE,
	client_id INT,
	purchase_date DATETIME NOT NULL,
	payments_date DATETIME NOT NULL,
	total_pago DECIMAL(10, 2) NOT NULL,    
	ship_service_level VARCHAR(50) NOT NULL,
	recipient_name VARCHAR(100),
	PRIMARY KEY (order_id),
	FOREIGN KEY (client_id) REFERENCES Clientes(client_id)
);   


 -- Criação da stored procedure
DELIMITER //

CREATE PROCEDURE ProcessarPedido()
BEGIN   
    -- Cada item de cada pedido (1 pedido pode ter vários itens)
    DROP TABLE IF EXISTS ItensPedido;

    CREATE TABLE IF NOT EXISTS ItensPedido_ordenado (        
    	order_id VARCHAR(50),
    	order_item_id VARCHAR(50),
    	produto VARCHAR(50),
    	quantity_purchased INT NOT NULL,
    	preco_item DECIMAL(10, 2) NOT NULL,
    	PRIMARY KEY (order_item_id),
    	FOREIGN KEY (order_id) REFERENCES Pedidos(order_id),
    	FOREIGN KEY (produto) REFERENCES Produtos(sku)
    );

    -- Inserindo os produtos na tabela Produtos [um produto com o mesmo sku não será inserido]
	INSERT INTO Produtos (sku, product_name, item_price, ioss_number)
	SELECT DISTINCT  sku, product_name, item_price, ioss_number
	FROM CargaTemp
	WHERE sku NOT IN (SELECT sku FROM Produtos);
    
    -- Inserindo os clientes na tabela Clientes [um cliente com o mesmo CPF não será inserido]
	INSERT INTO Clientes (buyer_email, buyer_name, cpf, buyer_phone_number, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, currency)
	SELECT DISTINCT buyer_email, buyer_name, cpf, buyer_phone_number, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, currency
	FROM CargaTemp
	WHERE cpf NOT IN (SELECT cpf FROM Clientes);
    
    -- Inserindo em Pedidos os que estão em CargaTemp, ele também calcula o total_pago de cada pedido [todo o carrinho]
	INSERT INTO Pedidos (order_id, client_id, purchase_date, payments_date, ship_service_level, recipient_name, total_pago)
	SELECT DISTINCT c.order_id, (SELECT client_id FROM Clientes AS cli WHERE cli.cpf = c.cpf), c.purchase_date, c.payments_date, c.ship_service_level, c.recipient_name, 
		(SELECT SUM(c1.item_price*c1.quantity_purchased) FROM CargaTemp AS c1 WHERE c1.order_id = c.order_id) AS total_pago
	FROM CargaTemp AS c
    WHERE c.order_id NOT IN (SELECT order_id FROM Pedidos);
    
    -- Inserindo os itens de cada pedido na tabela ItensPedido [a inserção é feita com base nos itens que possuem maior qtde]
	INSERT INTO ItensPedido_ordenado (order_item_id, order_id, produto, quantity_purchased, preco_item) 
	SELECT DISTINCT order_item_id, order_id, sku, quantity_purchased, 
	(quantity_purchased * (SELECT p.item_price FROM Produtos AS p WHERE p.sku = CargaTemp.sku))
	FROM CargaTemp
	WHERE order_item_id NOT IN (SELECT order_item_id FROM ItensPedido_ordenado);

	CREATE TABLE ItensPedido AS
	SELECT * FROM ItensPedido_ordenado
	ORDER BY quantity_purchased DESC;

    -- Limpa a tabela temporária 
    DROP TABLE IF EXISTS ItensPedido_ordenado;    
END;
//

DELIMITER ;

CALL ProcessarPedido();

INSERT INTO CargaTemp (order_id, order_item_id, purchase_date, payments_date, buyer_email, buyer_name, cpf, buyer_phone_number, sku, product_name, quantity_purchased, currency, item_price, ship_service_level, recipient_name, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, ioss_number)
VALUES 
('O1004', 'OI1005', '2024-04-03', '2024-04-03', 'joseph@example.com', 'Joseph', '12345678955', '98555-1234', 'SKU1001', 'Caneta chique', 3, 'USD', 20.00, 'Standard', 'Joseph', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL)

CALL ProcessarPedido();

SELECT * FROM Clientes;
