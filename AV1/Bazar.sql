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

-- Obter o preço total de todos os itens comprados por cada cliente em uma única sessão de compra (todos os pedidos no mesmo carrinho)


------------------- AUTOMATIZANDO OS PROCESSOS DO BANCO DE DADOS ----------------------------




