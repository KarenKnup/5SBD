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

CREATE TABLE Clientes (
    client_id INT AUTO_INCREMENT,
    cpf VARCHAR(20) UNIQUE,
    buyer_name VARCHAR(100),
    buyer_email VARCHAR(100),
    buyer_phone_number VARCHAR(20),
    PRIMARY KEY(client_id)
);

CREATE TABLE Produtos (
    product_id VARCHAR(50) UNIQUE,
    sku VARCHAR(50),
    product_name VARCHAR(100),
    stock INT DEFAULT 0,
    PRIMARY KEY (product_id)
);

CREATE TABLE Pedidos (
    order_id VARCHAR(50) UNIQUE,
    purchase_date DATETIME,
    payments_date DATETIME,
    client_id VARCHAR(50),
    total_price DECIMAL(10, 2),
    PRIMARY KEY(order_id),
    FOREIGN KEY (client_id) REFERENCES Clientes(client_id)
);

CREATE TABLE ItensPedido (
    order_item_id VARCHAR(50) UNIQUE,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    quantity_purchased INT,
    item_price DECIMAL(10, 2),
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id) REFERENCES Pedidos(order_id),
    FOREIGN KEY (product_id) REFERENCES Produtos(product_id),
);

-- Inserindo exemplos em CargaTemp e Produtos
INSERT INTO CargaTemp (order_id, order_item_id, purchase_date, payments_date, buyer_email, buyer_name, cpf, buyer_phone_number, sku, product_name, quantity_purchased, currency, item_price, ship_service_level, recipient_name, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, ioss_number)
VALUES 
('O1001', 'OI1001', '2024-04-01', '2024-04-02', 'john@example.com', 'John', '12345678901', '555-1234', 'SKU1001', 'A', 2, 'USD', 20.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL),
('O1002', 'OI1002', '2024-04-01', '2024-04-02', 'jane@example.com', 'Jane', '98765432109', '555-5678', 'SKU1002', 'B', 1, 'USD', 45.50, 'Express', 'Jane', '456 Oak St', NULL, NULL, 'Columbus', 'OH', '43210', 'USA', NULL),
('O1003', 'OI1003', '2024-04-03', '2024-04-04', 'alice@example.com', 'Alice', '23456789012', '555-8765', 'SKU1003', 'C', 3, 'USD', 15.75, 'Day', 'Alice', '789 Pine St', NULL, NULL, 'Austin', 'TX', '73301', 'USA', NULL),
('O1004', 'OI1003', '2024-04-03', '2024-04-04', 'alice@example.com', 'Alice', '23456789012', '555-8765', 'SKU1003', 'C', 5, 'USD', 15.75, 'Day', 'Alice', '789 Pine St', NULL, NULL, 'Austin', 'TX', '73301', 'USA', NULL),
('O1005', 'OI1002', '2024-04-04', '2024-04-04', 'alice@example.com', 'Alice', '23456789012', '555-8765', 'SKU1003', 'C', 3, 'USD', 15.75, 'Day', 'Alice', '789 Pine St', NULL, NULL, 'Austin', 'TX', '73301', 'USA', NULL),
('O1006', 'OI1003', '2024-04-01', '2024-04-02', 'john@example.com', 'John', '12345678901', '555-1234', 'SKU1001', 'A', 2, 'USD', 20.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL);

INSERT INTO Produtos(product_id, sku, product_name, stock)
VALUES
('OI1001', 'SKU1001', 'Relógio', '15'),
('OI1002', 'SKU1002', 'Vestido', '10'),
('OI1003', 'SKU1003', 'Balão', '20');

-- Inserindo em Clientes que estão na CargaTemp em Clientes [Não vai inserir o mesmo cliente 2 vezes porque o CPF é único e há o DISTINCT]
INSERT INTO Clientes (cpf, buyer_name, buyer_email, buyer_phone_number)
SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number
FROM CargaTemp
WHERE cpf NOT IN (SELECT cpf FROM Clientes);

-- Inserindo em Pedidos os que estão em CargaTemp, ele também calcula o total de cada pedido 
INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id, total_price)
SELECT order_id, purchase_date, payments_date, cpf, (item_price * quantity_purchased) AS total_price
FROM CargaTemp;

-- Inserção de Itens de Pedido [se o produto já existir na lista, soma a quantidade comprada com a que se deseja inserir]
INSERT INTO ItensPedido (order_item_id, order_id, product_id, quantity_purchased, item_price)
SELECT ct.order_item_id, ct.order_id, p.product_id, ct.quantity_purchased, ct.item_price
FROM CargaTemp ct
JOIN Produtos p ON ct.sku = p.sku
ON DUPLICATE KEY UPDATE
    quantity_purchased = ItensPedido.quantity_purchased + VALUES(quantity_purchased);

-- Atualizando o estoque de Produtos baseado em cada quantidade comprada pelos clientes nos pedidos [diz o total de quantos itens foram comprados de cada produto]
UPDATE Produtos p
INNER JOIN ItensPedido ip ON p.product_id = ip.product_id
SET p.stock = p.stock - ip.quantity_purchased;


------------------- AUTOMATIZANDO OS PROCESSOS DO BANCO DE DADOS ----------------------------

--> Procedures (Procedimentos): conjunto de instruções SQL que você pode salvar no banco de dados para executar operações complexas ou repetitivas

-->  Procedimento que insere um novo pedido, atualiza o estoque de produtos e contabiliza os itenspedido

DELIMITER //

CREATE PROCEDURE AddNewOrder(
    IN p_order_id VARCHAR(50),
    IN p_purchase_date DATETIME,
    IN p_payments_date DATETIME,
    IN p_cpf VARCHAR(20),
    IN p_total_price DECIMAL(10, 2)
)
BEGIN
    DECLARE v_client_id INT;

    -- Encontrar o client_id baseado no CPF
    SELECT client_id INTO v_client_id
    FROM Clientes
    WHERE cpf = p_cpf;

    -- Inserir o novo pedido
    INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id, total_price)
    VALUES (p_order_id, p_purchase_date, p_payments_date, v_client_id, p_total_price);

END //
DELIMITER ;

-- CALL AddNewOrder('O1234', '2024-05-05 12:00:00', '2024-05-05 12:30:00', '12345678901', 150.00);

--> Transferir os dados da tabela CargaTemp que é temporária para as permanentes e limpar ela

DELIMITER //

CREATE PROCEDURE MigrateAndCleanTempData()
BEGIN
    -- Inserindo novos clientes na tabela Clientes
    INSERT INTO Clientes (cpf, buyer_name, buyer_email, buyer_phone_number)
    SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number
    FROM CargaTemp
    WHERE cpf NOT IN (SELECT cpf FROM Clientes);

    -- Inserindo novos produtos na tabela Produtos
    INSERT INTO Produtos (product_id, sku, product_name, stock)
    SELECT DISTINCT order_item_id, sku, product_name, 0
    FROM CargaTemp
    WHERE sku NOT IN (SELECT sku FROM Produtos)
    GROUP BY sku;

    -- Inserindo novos pedidos na tabela Pedidos
    INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id, total_price)
    SELECT ct.order_id, ct.purchase_date, ct.payments_date, c.client_id,
           SUM(ct.item_price * ct.quantity_purchased) AS total_price
    FROM CargaTemp ct
    JOIN Clientes c ON ct.cpf = c.cpf
    GROUP BY ct.order_id;

    -- Inserindo itens de pedidos na tabela ItensPedido
    INSERT INTO ItensPedido (order_item_id, order_id, product_id, quantity_purchased, item_price)
    SELECT ct.order_item_id, ct.order_id, p.product_id, ct.quantity_purchased, ct.item_price
    FROM CargaTemp ct
    JOIN Produtos p ON ct.sku = p.sku
    WHERE NOT EXISTS (
        SELECT 1 FROM ItensPedido ip WHERE ip.order_item_id = ct.order_item_id
    );

    -- Atualizando o estoque na tabela Produtos
    UPDATE Produtos p
    JOIN (
        SELECT sku, SUM(quantity_purchased) AS total_purchased
        FROM CargaTemp
        GROUP BY sku
    ) q ON p.sku = q.sku
    SET p.stock = p.stock - q.total_purchased;

    -- Limpeza da tabela temporária CargaTemp
    DELETE FROM CargaTemp;

    -- Committing the transaction
    COMMIT;
END //
DELIMITER ;

--> Gatilho para atualizar o estoque depois de inserir algo em ItensPedido

DELIMITER //

CREATE TRIGGER AfterItemInsert
AFTER INSERT ON ItensPedido
FOR EACH ROW
BEGIN
    UPDATE Produtos
    SET stock = stock - NEW.quantity_purchased
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;
