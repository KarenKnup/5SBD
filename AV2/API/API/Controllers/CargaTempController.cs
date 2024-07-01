using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/CargaTemp" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class CargaTempController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public CargaTempController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de CargaTemp
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CargaTemp>>> GetCargaTemp()
        {
            return await _context.CargaTemp.ToListAsync();
        }

        // Método para obter um registro de CargaTemp pelo OrderId
        [HttpGet("{orderId}")]
        public async Task<ActionResult<CargaTemp>> GetCargaTempByOrderId(string orderId)
        {
            var cargaTemp = await _context.CargaTemp.FirstOrDefaultAsync(c => c.OrderId == orderId);

            if (cargaTemp == null)
            {
                return NotFound();
            }

            return cargaTemp;
        }

        // Método para adicionar um novo registro de CargaTemp
        [HttpPost]
        public async Task<ActionResult<CargaTemp>> PostCargaTemp(CargaTemp cargaTemp)
        {
            _context.CargaTemp.Add(cargaTemp);
            await _context.SaveChangesAsync();

            // Chama o método para distribuir os dados de CargaTemp
            await DistributeCargaTempData();

            return CreatedAtAction("GetCargaTempByOrderId", new { orderId = cargaTemp.OrderId }, cargaTemp);
        }

        // Método para atualizar um registro de CargaTemp pelo OrderId
        [HttpPut("{orderId}")]
        public async Task<IActionResult> PutCargaTemp(string orderId, CargaTemp cargaTemp)
        {
            if (orderId != cargaTemp.OrderId)
            {
                return BadRequest();
            }

            _context.Entry(cargaTemp).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!CargaTempExists(orderId))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // Método para deletar um registro de CargaTemp pelo OrderId
        [HttpDelete("{orderId}")]
        public async Task<IActionResult> DeleteCargaTemp(string orderId)
        {
            var cargaTemp = await _context.CargaTemp.FirstOrDefaultAsync(c => c.OrderId == orderId);
            if (cargaTemp == null)
            {
                return NotFound();
            }

            _context.CargaTemp.Remove(cargaTemp);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de CargaTemp existe pelo OrderId
        private bool CargaTempExists(string orderId)
        {
            return _context.CargaTemp.Any(e => e.OrderId == orderId);
        }

        // Método privado para distribuir os dados de CargaTemp para outras tabelas
        private async Task DistributeCargaTempData()
        {
            var cargaTempList = await _context.CargaTemp.ToListAsync();

            foreach (var cargaTemp in cargaTempList)
            {
                // Adiciona à tabela Clientes se o CPF não existir
                if (!_context.Clientes.Any(c => c.CPF == cargaTemp.Cpf))
                {
                    var cliente = new Clientes
                    {
                        BuyerEmail = cargaTemp.BuyerEmail,
                        BuyerName = cargaTemp.BuyerName,
                        CPF = cargaTemp.Cpf,
                        BuyerPhoneNumber = cargaTemp.BuyerPhoneNumber
                    };
                    _context.Clientes.Add(cliente);
                }

                // Adiciona à tabela Pedidos se o OrderId não existir
                if (!_context.Pedidos.Any(p => p.OrderId == cargaTemp.OrderId))
                {
                    var pedido = new Pedidos
                    {
                        OrderId = cargaTemp.OrderId,
                        PurchaseDate = cargaTemp.PurchaseDate,
                        PaymentsDate = cargaTemp.PaymentsDate,
                        CPF = cargaTemp.Cpf,
                        ShipServiceLevel = cargaTemp.ShipServiceLevel,
                        RecipientName = cargaTemp.RecipientName,
                        ShipAddress1 = cargaTemp.ShipAddress1,
                        ShipAddress2 = cargaTemp.ShipAddress2,
                        ShipAddress3 = cargaTemp.ShipAddress3,
                        ShipCity = cargaTemp.ShipCity,
                        ShipState = cargaTemp.ShipState,
                        ShipPostalCode = cargaTemp.ShipPostalCode,
                        ShipCountry = cargaTemp.ShipCountry,
                        IOSSNumber = cargaTemp.IossNumber
                    };
                    _context.Pedidos.Add(pedido);
                } 

                // Busca o produto pelo SKU e atualiza estoque ou adiciona item negado
                var produto = await _context.Produtos.FirstOrDefaultAsync(p => p.SKU == cargaTemp.Sku);
                if (produto != null)
                {
                        if (cargaTemp.QuantityPurchased > produto.Stock)
                    {
                        if (!_context.ItensPedidoNegados.Any(p => p.OrderId == cargaTemp.OrderId))
                        {
                            var itemPedidoNegado = new ItensPedidoNegados
                            {
                                OrderId = cargaTemp.OrderId,
                                OrderItemId = cargaTemp.OrderItemId,
                                CPF = cargaTemp.Cpf,
                                SKU = cargaTemp.Sku,
                                QuantityPurchased = cargaTemp.QuantityPurchased,
                                Currency = cargaTemp.Currency,
                                ItemPrice = cargaTemp.ItemPrice
                            };
                            _context.ItensPedidoNegados.Add(itemPedidoNegado);
                        }
                    }
                    else
                    {
                        if (!_context.ItensPedido.Any(p => p.OrderId == cargaTemp.OrderId))
                        {
                            var itemPedido = new ItensPedido
                            {
                                OrderId = cargaTemp.OrderId,
                                OrderItemId = cargaTemp.OrderItemId,
                                CPF = cargaTemp.Cpf,
                                SKU = cargaTemp.Sku,
                                QuantityPurchased = cargaTemp.QuantityPurchased,
                                Currency = cargaTemp.Currency,
                                ItemPrice = cargaTemp.ItemPrice
                            };
                            _context.ItensPedido.Add(itemPedido);
                            produto.Stock -= cargaTemp.QuantityPurchased;
                            _context.Entry(produto).State = EntityState.Modified;
                        }
                    }
                }
            }

            await _context.SaveChangesAsync();

            // Limpa a tabela CargaTemp
            _context.CargaTemp.RemoveRange(cargaTempList);
            await _context.SaveChangesAsync();
        }
    }
}
