CREATE DATABASE BazarTemTudo;

USE BazarTemTudo;

DELIMITER //

CREATE PROCEDURE CriarEstrutura()
BEGIN    
    -- Criação da tabela de Carga Temporária
    CREATE TABLE IF NOT EXISTS CargaTemp (
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

    -- Criação da tabela de Produtos
    CREATE TABLE IF NOT EXISTS Produtos (
        sku VARCHAR(50) NOT NULL,
        product_name VARCHAR(100) NOT NULL,
        item_price DECIMAL(10, 2) NOT NULL,
        ioss_number VARCHAR(50),
        estoque INT DEFAULT 0,
        PRIMARY KEY (sku)
    );

    -- Criação da tabela de Clientes
    CREATE TABLE IF NOT EXISTS Clientes (
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
        PRIMARY KEY(client_id),
        UNIQUE (cpf)
    );

    -- Criação da tabela de Pedidos
    CREATE TABLE IF NOT EXISTS Pedidos (
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

    -- Criação da tabela de Itens do Pedido
    CREATE TABLE IF NOT EXISTS ItensPedido (
        order_item_id VARCHAR(50),
        order_id VARCHAR(50),
        produto VARCHAR(50),
        quantity_purchased INT NOT NULL,
        preco_item DECIMAL(10, 2) NOT NULL,
        PRIMARY KEY (order_item_id),
        FOREIGN KEY (order_id) REFERENCES Pedidos(order_id),
        FOREIGN KEY (produto) REFERENCES Produtos(sku)
    );
	
    CREATE TABLE IF NOT EXISTS PedidosAtendidos (
		order_item_id VARCHAR(50),
        FOREIGN KEY (order_item_id) REFERENCES ItensPedido(order_item_id)
		);
        
	CREATE TABLE IF NOT EXISTS PedidosRejeitados(
		order_item_id VARCHAR(50),
        FOREIGN KEY (order_item_id) REFERENCES ItensPedido(order_item_id)
		);
END //

DELIMITER ;

CALL CriarEstrutura();

LOAD DATA INFILE 'C:/Users/Karen/Downloads/Bazar/Estoque.csv'
INTO TABLE Produtos
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(sku,product_name,item_price,ioss_number,estoque);


DELIMITER //

CREATE PROCEDURE ProcessarPedido()
BEGIN
    -- Inserindo os clientes na tabela Clientes (se não existir)
    INSERT INTO Clientes (buyer_email, buyer_name, cpf, buyer_phone_number, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, currency)
    SELECT DISTINCT buyer_email, buyer_name, cpf, buyer_phone_number, ship_address_1, ship_address_2, ship_address_3, ship_city, ship_state, ship_postal_code, ship_country, currency
    FROM CargaTemp
    WHERE cpf NOT IN (SELECT cpf FROM Clientes);

    -- Inserindo os pedidos na tabela Pedidos
    INSERT INTO Pedidos (order_id, client_id, purchase_date, payments_date, ship_service_level, recipient_name, total_pago)
    SELECT DISTINCT c.order_id, 
                    (SELECT client_id FROM Clientes WHERE cpf = c.cpf), 
                    c.purchase_date, 
                    c.payments_date, 
                    c.ship_service_level, 
                    c.recipient_name, 
                    (SELECT SUM(ct.item_price * ct.quantity_purchased) 
                     FROM CargaTemp AS ct 
                     WHERE ct.order_id = c.order_id) AS total_pago
    FROM CargaTemp AS c
    WHERE c.order_id NOT IN (SELECT order_id FROM Pedidos);

    -- Inserindo os itens do pedido na tabela ItensPedido
    INSERT INTO ItensPedido (order_item_id, order_id, produto, quantity_purchased, preco_item)
    SELECT order_item_id, order_id, sku, quantity_purchased, item_price
    FROM CargaTemp;
    
    -- Atualiza o estoque dos Produtos de acordo com os quantity_purchased
    -- e insere os ItensPedidos atendidos na tabela de PedidosAtendidos
    -- [prioriza inserir primeiro os itenspedidos de maior item_price*quantity_purchased,
    -- e não permite o estoque ficar negativo, se não houver estoque o suficiente,
    -- nao insere a linha, ele insere os itens rejeitados em PedidosRejeitados]

    -- Atualiza o estoque dos produtos e insere os itens atendidos
    INSERT INTO PedidosAtendidos (order_item_id)
    SELECT ip.order_item_id
    FROM ItensPedido ip
    JOIN (
        SELECT order_item_id, preco_item * quantity_purchased AS total_price
        FROM ItensPedido
        ORDER BY total_price DESC
    ) ip_sorted ON ip.order_item_id = ip_sorted.order_item_id
    JOIN Produtos p ON ip.produto = p.sku
    WHERE p.estoque >= ip.quantity_purchased;

    -- Atualiza o estoque dos produtos
    UPDATE Produtos p
    JOIN (
        SELECT produto, SUM(quantity_purchased) AS total_quantity
        FROM ItensPedido
        GROUP BY produto
    ) ip ON p.sku = ip.produto
    SET p.estoque = CASE 
        WHEN p.estoque >= ip.total_quantity THEN p.estoque - ip.total_quantity
        ELSE p.estoque
    END;

    -- Insere os itens rejeitados em PedidosRejeitados
    INSERT INTO PedidosRejeitados (order_item_id)
    SELECT ip.order_item_id
    FROM ItensPedido ip
    LEFT JOIN PedidosAtendidos pa ON ip.order_item_id = pa.order_item_id
    WHERE pa.order_item_id IS NULL;

    -- Limpa a tabela temporária
    TRUNCATE TABLE CargaTemp;
END //

DELIMITER ;


DELIMITER //

CREATE EVENT ProcessarPedidosEvent
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    CALL ProcessarPedido();
   
END //

DELIMITER ;


LOAD DATA INFILE 'C:/Users/Karen/Downloads/Bazar/CargaTemp.csv'
INTO TABLE CargaTemp
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id ,
    order_item_id ,
    purchase_date ,
    payments_date ,
    buyer_email ,
    buyer_name,
    cpf ,
    buyer_phone_number,
    sku ,
    product_name ,
    quantity_purchased ,
    currency ,
    item_price ,
    ship_service_level,
    recipient_name,
    ship_address_1 ,
    ship_address_2 ,
    ship_address_3 ,
    ship_city ,
    ship_state ,
    ship_postal_code,
    ship_country ,
    ioss_number);

-- Exibir os resultados
SELECT * FROM CargaTemp;
SELECT * FROM Clientes;
SELECT * FROM Pedidos;
SELECT * FROM ItensPedido ORDER BY quantity_purchased * preco_item DESC; -- exibir pelos mais caros
SELECT * FROM Produtos;
SELECT * FROM PedidosAtendidos;
SELECT * FROM PedidosRejeitados;
