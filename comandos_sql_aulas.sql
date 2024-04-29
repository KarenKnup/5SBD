-- Inserir clientes
CALL AddCliente('jdoe', 'John Doe', 'john.doe@example.com', '11122233344', '12345-678');
CALL AddCliente('asmith', 'Alice Smith', 'alice.smith@example.com', '22233344455', '54321-987');

-- Inserir produtos
CALL AddProduto('Camiseta', 25.00);
CALL AddProduto('Calça Jeans', 50.00);
CALL AddProduto('Tênis', 80.00);

-- Inserir pedidos
CALL AddPedido(1, 1, 2); -- Pedido do cliente John Doe com 2 camisetas
CALL AddPedido(2, 3, 1); -- Pedido da cliente Alice Smith com 1 par de tênis

-- Inserir ItemPedidos
CALL AddItemPedido(1, 1); -- Adiciona camiseta ao pedido de John Doe
CALL AddItemPedido(2, 3); -- Adiciona par de tênis ao pedido de Alice Smith

-- Inserir Carga
CALL AddCarga(1, '2024-04-28', '2024-05-02', 'Em trânsito', 'Pedido a ser entregue via transportadora A');
CALL AddCarga(2, '2024-04-29', '2024-05-03', 'Em trânsito', 'Pedido a ser entregue via transportadora B');

-- Atualizar o valor total de um pedido de determinado cliente
UPDATE Pedido SET valor_pedido = (
    SELECT SUM(preco * quantidade_produto)
    FROM Produto
    JOIN ItemPedido ON Produto.id = ItemPedido.IDproduto
    WHERE ItemPedido.IDpedido = 1
)
WHERE id = 1;

-- Informar o valor total que o cliente pagou de todos os pedidos (estavam todos no carrinho juntos) 
-- feitos em determinada data_pedido
SELECT Cliente.nome, SUM(Pedido.valor_pedido) AS total_pago
FROM Cliente
JOIN Pedido ON Cliente.id = Pedido.IDcliente
JOIN ItemPedido ON Pedido.id = ItemPedido.IDpedido
WHERE DATE(ItemPedido.data_pedido) = '2024-04-28'
GROUP BY Cliente.nome;
