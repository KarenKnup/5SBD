using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/Produtos" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class ProdutosController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public ProdutosController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de Produtos
        // GET: api/Produtos
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Produtos>>> GetProdutos()
        {
            return await _context.Produtos.ToListAsync();
        }

        // Método para obter um registro de Produto pelo SKU
        // GET: api/Produtos/{sku}
        [HttpGet("{sku}")]
        public async Task<ActionResult<Produtos>> GetProdutoBySku(string sku)
        {
            var produto = await _context.Produtos.FirstOrDefaultAsync(p => p.SKU == sku);

            if (produto == null)
            {
                return NotFound();
            }

            return produto;
        }

        // Método para adicionar um novo registro de Produto
        // POST: api/Produtos
        [HttpPost]
        public async Task<ActionResult<Produtos>> PostProduto(Produtos produto)
        {
            // Verificar se o produto já existe na base de dados
            var existingProduto = await _context.Produtos.FirstOrDefaultAsync(p => p.SKU == produto.SKU);
            if (existingProduto != null)
            {
                return Conflict(new { message = "Produto já existe." });
            }

            _context.Produtos.Add(produto);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProdutoBySku", new { sku = produto.SKU }, produto);
        }

        // Método para atualizar um registro de Produto pelo SKU
        // PUT: api/Produtos/{sku}
        [HttpPut("{sku}")]
        public async Task<IActionResult> PutProduto(string sku, Produtos produto)
        {
            if (sku != produto.SKU)
            {
                return BadRequest();
            }

            _context.Entry(produto).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ProdutoExists(sku))
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

        // Método para deletar um registro de Produto pelo SKU
        // DELETE: api/Produtos/{sku}
        [HttpDelete("{sku}")]
        public async Task<IActionResult> DeleteProduto(string sku)
        {
            var produto = await _context.Produtos.FirstOrDefaultAsync(p => p.SKU == sku);
            if (produto == null)
            {
                return NotFound();
            }

            _context.Produtos.Remove(produto);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de Produto existe pelo SKU
        private bool ProdutoExists(string sku)
        {
            return _context.Produtos.Any(e => e.SKU == sku);
        }
    }
}
