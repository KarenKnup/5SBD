using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/ItensPedidoNegados" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class ItensPedidoNegadosController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public ItensPedidoNegadosController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de ItensPedidoNegados
        // GET: api/ItensPedidoNegados
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ItensPedidoNegados>>> GetItensPedidoNegados()
        {
            return await _context.ItensPedidoNegados.ToListAsync();
        }

        // Método para obter um registro de ItensPedidoNegados pelo OrderItemId
        // GET: api/ItensPedidoNegados/{orderItemId}
        [HttpGet("{orderItemId}")]
        public async Task<ActionResult<ItensPedidoNegados>> GetItensPedidoNegadosByOrderItemId(string orderItemId)
        {
            var itemPedidoNegado = await _context.ItensPedidoNegados.FirstOrDefaultAsync(i => i.OrderItemId == orderItemId);

            if (itemPedidoNegado == null)
            {
                return NotFound();
            }

            return itemPedidoNegado;
        }

        // Método para adicionar um novo registro de ItensPedidoNegados
        // POST: api/ItensPedidoNegados
        [HttpPost]
        public async Task<ActionResult<ItensPedidoNegados>> PostItensPedidoNegados(ItensPedidoNegados itemPedidoNegado)
        {
            // Verificar se o item de pedido negado já existe na base de dados
            var existingItemPedidoNegado = await _context.ItensPedidoNegados.FirstOrDefaultAsync(i => i.OrderItemId == itemPedidoNegado.OrderItemId);
            if (existingItemPedidoNegado != null)
            {
                return Conflict(new { message = "Item de pedido negado já existe." });
            }

            _context.ItensPedidoNegados.Add(itemPedidoNegado);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetItensPedidoNegadosByOrderItemId", new { orderItemId = itemPedidoNegado.OrderItemId }, itemPedidoNegado);
        }

        // Método para atualizar um registro de ItensPedidoNegados pelo OrderItemId
        // PUT: api/ItensPedidoNegados/{orderItemId}
        [HttpPut("{orderItemId}")]
        public async Task<IActionResult> PutItensPedidoNegados(string orderItemId, ItensPedidoNegados itemPedidoNegado)
        {
            if (orderItemId != itemPedidoNegado.OrderItemId)
            {
                return BadRequest();
            }

            _context.Entry(itemPedidoNegado).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ItensPedidoNegadosExists(orderItemId))
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

        // Método para deletar um registro de ItensPedidoNegados pelo OrderItemId
        // DELETE: api/ItensPedidoNegados/{orderItemId}
        [HttpDelete("{orderItemId}")]
        public async Task<IActionResult> DeleteItensPedidoNegados(string orderItemId)
        {
            var itemPedidoNegado = await _context.ItensPedidoNegados.FirstOrDefaultAsync(i => i.OrderItemId == orderItemId);
            if (itemPedidoNegado == null)
            {
                return NotFound();
            }

            _context.ItensPedidoNegados.Remove(itemPedidoNegado);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de ItensPedidoNegados existe pelo OrderItemId
        private bool ItensPedidoNegadosExists(string orderItemId)
        {
            return _context.ItensPedidoNegados.Any(e => e.OrderItemId == orderItemId);
        }
    }
}
