using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/Pedidos" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class PedidosController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public PedidosController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de Pedidos
        // GET: api/Pedidos
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Pedidos>>> GetPedidos()
        {
            return await _context.Pedidos.ToListAsync();
        }

        // Método para obter um registro de Pedido pelo OrderId
        // GET: api/Pedidos/{orderId}
        [HttpGet("{orderId}")]
        public async Task<ActionResult<Pedidos>> GetPedidoByOrderId(string orderId)
        {
            var pedido = await _context.Pedidos.FirstOrDefaultAsync(p => p.OrderId == orderId);

            if (pedido == null)
            {
                return NotFound();
            }

            return pedido;
        }

        // Método para adicionar um novo registro de Pedido
        // POST: api/Pedidos
        [HttpPost]
        public async Task<ActionResult<Pedidos>> PostPedido(Pedidos pedido)
        {
            // Verificar se o pedido já existe na base de dados
            var existingPedido = await _context.Pedidos.FirstOrDefaultAsync(p => p.OrderId == pedido.OrderId);
            if (existingPedido != null)
            {
                return Conflict(new { message = "Pedido já existe." });
            }

            _context.Pedidos.Add(pedido);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetPedidoByOrderId", new { orderId = pedido.OrderId }, pedido);
        }

        // Método para atualizar um registro de Pedido pelo OrderId
        // PUT: api/Pedidos/{orderId}
        [HttpPut("{orderId}")]
        public async Task<IActionResult> PutPedido(string orderId, Pedidos pedido)
        {
            if (orderId != pedido.OrderId)
            {
                return BadRequest();
            }

            _context.Entry(pedido).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!PedidoExists(orderId))
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

        // Método para deletar um registro de Pedido pelo OrderId
        // DELETE: api/Pedidos/{orderId}
        [HttpDelete("{orderId}")]
        public async Task<IActionResult> DeletePedido(string orderId)
        {
            var pedido = await _context.Pedidos.FirstOrDefaultAsync(p => p.OrderId == orderId);
            if (pedido == null)
            {
                return NotFound();
            }

            _context.Pedidos.Remove(pedido);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de Pedido existe pelo OrderId
        private bool PedidoExists(string orderId)
        {
            return _context.Pedidos.Any(e => e.OrderId == orderId);
        }
    }
}
