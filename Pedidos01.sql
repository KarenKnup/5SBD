CREATE TABLE Cliente (
	id INT NOT NULL AUTO_INCREMENT,
	usuario VARCHAR(50) NOT NULL,
	nome VARCHAR(50) NOT NULL,
	email VARCHAR(80) NOT NULL,
	cpf VARCHAR(20) NOT NULL,
	cep VARCHAR(15) NOT NULL,
	PRIMARY KEY (id)
);

DELIMITER //
CREATE PROCEDURE AddCliente(IN p_usuario VARCHAR(50), IN p_nome VARCHAR(50), IN p_email VARCHAR(80), IN p_cpf VARCHAR(20), IN p_cep VARCHAR(15))
BEGIN
    INSERT INTO Cliente (usuario, nome, email, cpf, cep) VALUES (p_usuario, p_nome, p_email, p_cpf, p_cep);
END //
DELIMITER ;

CALL AddCliente('jdoe', 'John Doe', 'john.doe@example.com', '11122233344', '12345-678');

CREATE TABLE Produto (
	id INT NOT NULL AUTO_INCREMENT,
	nome_produto VARCHAR(50) NOT NULL,
	preco DECIMAL(10, 2),  -- 10 dígitos no total, 2 após a vírgula
	PRIMARY KEY (id)
);

DELIMITER //
CREATE PROCEDURE AddProduto(IN p_nome_produto VARCHAR(50), IN p_preco DECIMAL(10, 2))
BEGIN
    INSERT INTO Produto (nome_produto, preco) VALUES (p_nome_produto, p_preco);
END //
DELIMITER ;

CREATE TABLE Pedido (
	id INT NOT NULL AUTO_INCREMENT,
	IDcliente INT,
	IDproduto INT,
	quantidade_produto INT NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (IDcliente) REFERENCES Cliente(id),
	FOREIGN KEY (IDproduto) REFERENCES Produto(id)
);

DELIMITER //
CREATE PROCEDURE AddPedido(IN p_IDcliente INT, IN p_IDproduto INT, IN p_quantidade_produto INT)
BEGIN
    INSERT INTO Pedido (IDcliente, IDproduto, quantidade_produto) VALUES (p_IDcliente, p_IDproduto, p_quantidade_produto);
END //
DELIMITER ;

CREATE TABLE ItemPedido (
	id INT NOT NULL AUTO_INCREMENT,
	IDpedido INT,
	IDproduto INT,
	PRIMARY KEY (id),
	FOREIGN KEY (IDpedido) REFERENCES Pedido(id),
	FOREIGN KEY (IDproduto) REFERENCES Produto(id)
);

DELIMITER //
CREATE PROCEDURE AddItemPedido(IN p_IDpedido INT, IN p_IDproduto INT)
BEGIN
    INSERT INTO ItemPedido (IDpedido, IDproduto) VALUES (p_IDpedido, p_IDproduto);
END //
DELIMITER ;

CREATE TABLE Carga (
       id INT NOT NULL AUTO_INCREMENT,
       IDpedido INT NOT NULL,
       data_envio DATE NOT NULL,
       data_entrega DATE NOT NULL,
       status VARCHAR(50) NOT NULL,
       observacoes TEXT,
       PRIMARY KEY (id),
       FOREIGN KEY (IDpedido) REFERENCES Pedido(id)
);

DELIMITER //
CREATE PROCEDURE AddCarga(IN p_IDpedido INT, IN p_data_envio DATE, IN p_data_entrega DATE, IN p_status VARCHAR(50), IN p_observacoes TEXT)
BEGIN
    INSERT INTO Carga (IDpedido, data_envio, data_entrega, status, observacoes) VALUES (p_IDpedido, p_data_envio, p_data_entrega, p_status, p_observacoes);
END //
DELIMITER ;

