using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/ItensPedido" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class ItensPedidoController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public ItensPedidoController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de ItensPedido
        // GET: api/ItensPedido
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ItensPedido>>> GetItensPedido()
        {
            return await _context.ItensPedido.ToListAsync();
        }

        // Método para obter um registro de ItensPedido pelo OrderItemId
        // GET: api/ItensPedido/{orderItemId}
        [HttpGet("{orderItemId}")]
        public async Task<ActionResult<ItensPedido>> GetItensPedidoByOrderItemId(string orderItemId)
        {
            var itemPedido = await _context.ItensPedido.FirstOrDefaultAsync(i => i.OrderItemId == orderItemId);

            if (itemPedido == null)
            {
                return NotFound();
            }

            return itemPedido;
        }

        // Método para adicionar um novo registro de ItensPedido
        // POST: api/ItensPedido
        [HttpPost]
        public async Task<ActionResult<ItensPedido>> PostItensPedido(ItensPedido itemPedido)
        {
            // Verificar se o item de pedido já existe na base de dados
            var existingItemPedido = await _context.ItensPedido.FirstOrDefaultAsync(i => i.OrderItemId == itemPedido.OrderItemId);
            if (existingItemPedido != null)
            {
                return Conflict(new { message = "Item de pedido já existe." });
            }

            _context.ItensPedido.Add(itemPedido);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetItensPedidoByOrderItemId", new { orderItemId = itemPedido.OrderItemId }, itemPedido);
        }

        // Método para atualizar um registro de ItensPedido pelo OrderItemId
        // PUT: api/ItensPedido/{orderItemId}
        [HttpPut("{orderItemId}")]
        public async Task<IActionResult> PutItensPedido(string orderItemId, ItensPedido itemPedido)
        {
            if (orderItemId != itemPedido.OrderItemId)
            {
                return BadRequest();
            }

            _context.Entry(itemPedido).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ItensPedidoExists(orderItemId))
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

        // Método para deletar um registro de ItensPedido pelo OrderItemId
        // DELETE: api/ItensPedido/{orderItemId}
        [HttpDelete("{orderItemId}")]
        public async Task<IActionResult> DeleteItensPedido(string orderItemId)
        {
            var itemPedido = await _context.ItensPedido.FirstOrDefaultAsync(i => i.OrderItemId == orderItemId);
            if (itemPedido == null)
            {
                return NotFound();
            }

            _context.ItensPedido.Remove(itemPedido);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de ItensPedido existe pelo OrderItemId
        private bool ItensPedidoExists(string orderItemId)
        {
            return _context.ItensPedido.Any(e => e.OrderItemId == orderItemId);
        }
    }
}
