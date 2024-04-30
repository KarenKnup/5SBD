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
    client_id INT PRIMARY KEY IDENTITY(1,1),
    cpf VARCHAR(20) UNIQUE,
    buyer_name VARCHAR(100),
    buyer_email VARCHAR(100),
    buyer_phone_number VARCHAR(20)
);

CREATE TABLE Produtos (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    sku VARCHAR(50),
    product_name VARCHAR(100),
    stock INT DEFAULT 0
);

CREATE TABLE Pedidos (
    order_id VARCHAR(50) PRIMARY KEY,
    purchase_date DATETIME,
    payments_date DATETIME,
    client_id INT,
    total_price DECIMAL(10, 2),
    FOREIGN KEY (client_id) REFERENCES Clientes(client_id)
);

CREATE TABLE ItensPedido (
    order_item_id VARCHAR(50),
    order_id VARCHAR(50),
    product_id INT,
    quantity_purchased INT,
    item_price DECIMAL(10, 2),
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id) REFERENCES Pedidos(order_id),
    FOREIGN KEY (product_id) REFERENCES Produtos(product_id)
);

INSERT INTO CargaTemp (order_id, order_item_id, purchase_date, payments_date, buyer_email, buyer_name, cpf, buyer_phone_number, sku, product_name, quantity_purchased, currency, item_price, ship_service_level, recipient_name, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, ioss_number)
VALUES 
('O1001', 'OI1001', '2024-04-01', '2024-04-02', 'john@example.com', 'John', '12345678901', '555-1234', 'SKU1001', 'A', 2, 'USD', 20.00, 'Standard', 'John', '123 Elm St', 'Apt 4', NULL, 'Springfield', 'IL', '62701', 'USA', NULL),
('O1002', 'OI1002', '2024-04-01', '2024-04-02', 'jane@example.com', 'Jane', '98765432109', '555-5678', 'SKU1002', 'B', 1, 'USD', 45.50, 'Express', 'Jane', '456 Oak St', NULL, NULL, 'Columbus', 'OH', '43210', 'USA', NULL),
('O1003', 'OI1003', '2024-04-03', '2024-04-04', 'alice@example.com', 'Alice', '23456789012', '555-8765', 'SKU1003', 'C', 3, 'USD', 15.75, 'Day', 'Alice', '789 Pine St', NULL, NULL, 'Austin', 'TX', '73301', 'USA', NULL);

-- Inserção de novos clientes
INSERT INTO Clientes (cpf, buyer_name, buyer_email, buyer_phone_number)
SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number
FROM CargaTemp
WHERE cpf NOT IN (SELECT cpf FROM Clientes);

-- Inserção de novos produtos
INSERT INTO Produtos (sku, product_name)
SELECT DISTINCT sku, product_name
FROM CargaTemp
WHERE sku NOT IN (SELECT sku FROM Produtos);

-- Inserção de novos pedidos
INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id, total_price)
SELECT ct.order_id, ct.purchase_date, ct.payments_date, c.client_id, SUM(ct.item_price * ct.quantity_purchased) AS total_price
FROM CargaTemp ct
JOIN Clientes c ON ct.cpf = c.cpf
GROUP BY ct.order_id, ct.purchase_date, ct.payments_date, c.client_id;

-- Inserção de Itens de Pedido
INSERT INTO ItensPedido (order_item_id, order_id, product_id, quantity_purchased, item_price)
SELECT ct.order_item_id, ct.order_id, p.product_id, ct.quantity_purchased, ct.item_price
FROM CargaTemp ct
JOIN Produtos p ON ct.sku = p.sku;

-- Atualizando o estoque
UPDATE Produtos
SET stock = stock - ip.quantity_purchased
FROM Produtos p
INNER JOIN ItensPedido ip ON p.product_id = ip.product_id;

-- Insere novos clientes impedindo cpfs repetidos
INSERT INTO Clientes (cpf, buyer_name, buyer_email, buyer_phone_number)
SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number
FROM CargaTemp
WHERE cpf NOT IN (SELECT cpf FROM Clientes);

-- Insere novos pedidos usando dados de CargaTemp e Clientes
INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id)
SELECT ct.order_id, ct.purchase_date, ct.payments_date, c.client_id
FROM CargaTemp ct
JOIN Clientes c ON ct.cpf = c.cpf;

-- Obter o preço total de todos os itens comprados por um cliente em uma única sessão de compra
-- (ou seja, todos os itens que foram adicionados ao mesmo carrinho e comprados juntos)
CREATE PROCEDURE ObterPrecoTotalPorPedido
    @order_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.order_id,
        SUM(ip.item_price * ip.quantity_purchased) AS TotalPrice
    FROM 
        Pedidos p
        INNER JOIN ItensPedido ip ON p.order_id = ip.order_id
    WHERE 
        p.order_id = @order_id
    GROUP BY 
        p.order_id;
END;
GO

SELECT 
    p.order_id,
    SUM(ip.item_price * ip.quantity_purchased) AS TotalPrice
FROM 
    Pedidos p
    JOIN ItensPedido ip ON p.order_id = ip.order_id
GROUP BY 
    p.order_id;

BULK INSERT CargaTemp
FROM 'C:\Users\Karen\Documents\Bazar.csv'
WITH
(
    FIELDTERMINATOR = ',',  
    ROWTERMINATOR = '\n',   
    FIRSTROW = 2           
);

-- Inserção de Clientes
CREATE PROCEDURE TransformarEInserirClientes AS
BEGIN
    INSERT INTO Clientes (cpf, buyer_name, buyer_email, buyer_phone_number)
    SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number
    FROM CargaTemp
    WHERE cpf NOT IN (SELECT cpf FROM Clientes);
END;


-- Inserção de Produtos
CREATE PROCEDURE TransformarEInserirProdutos AS
BEGIN
    INSERT INTO Produtos (sku, product_name)
    SELECT DISTINCT sku, product_name
    FROM CargaTemp
    WHERE sku NOT IN (SELECT sku FROM Produtos);
END;

-- Inserção de Pedidos e ItensPedido
CREATE PROCEDURE TransformarEInserirPedidosEItens AS
BEGIN
    INSERT INTO Pedidos (order_id, purchase_date, payments_date, client_id)
    SELECT ct.order_id, ct.purchase_date, ct.payments_date, c.client_id
    FROM CargaTemp ct
    JOIN Clientes c ON ct.cpf = c.cpf;

    INSERT INTO ItensPedido (order_item_id, order_id, product_id, quantity_purchased, item_price)
    SELECT ct.order_item_id, ct.order_id, p.product_id, ct.quantity_purchased, ct.item_price
    FROM CargaTemp ct
    JOIN Produtos p ON ct.sku = p.sku;
END;






