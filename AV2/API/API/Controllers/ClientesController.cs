using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Models;
using API.Data;

namespace API.Controllers
{
    // Define a rota base para o controlador como "api/Clientes" e indica que é um controlador de API
    [Route("api/[controller]")]
    [ApiController]
    public class ClientesController : ControllerBase
    {
        // Declaração do contexto do banco de dados
        private readonly AppDbContext _context;

        // Construtor que inicializa o contexto do banco de dados
        public ClientesController(AppDbContext context)
        {
            _context = context;
        }

        // Método para obter todos os registros de Clientes
        // GET: api/Clientes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Clientes>>> GetClientes()
        {
            return await _context.Clientes.ToListAsync();
        }

        // Método para obter um registro de Cliente pelo CPF
        // GET: api/Clientes/{cpf}
        [HttpGet("{cpf}")]
        public async Task<ActionResult<Clientes>> GetClienteByCpf(string cpf)
        {
            var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.CPF == cpf);

            if (cliente == null)
            {
                return NotFound();
            }

            return cliente;
        }

        // Método para adicionar um novo registro de Cliente
        // POST: api/Clientes
        [HttpPost]
        public async Task<ActionResult<Clientes>> PostCliente(Clientes cliente)
        {
            // Verificar se o cliente já existe na base de dados
            var existingCliente = await _context.Clientes.FirstOrDefaultAsync(c => c.CPF == cliente.CPF);
            if (existingCliente != null)
            {
                return Conflict(new { message = "Cliente já existe." });
            }

            _context.Clientes.Add(cliente);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetClienteByCpf", new { cpf = cliente.CPF }, cliente);
        }

        // Método para atualizar um registro de Cliente pelo CPF
        // PUT: api/Clientes/{cpf}
        [HttpPut("{cpf}")]
        public async Task<IActionResult> PutCliente(string cpf, Clientes cliente)
        {
            if (cpf != cliente.CPF)
            {
                return BadRequest();
            }

            _context.Entry(cliente).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ClienteExists(cpf))
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

        // Método para deletar um registro de Cliente pelo CPF
        // DELETE: api/Clientes/{cpf}
        [HttpDelete("{cpf}")]
        public async Task<IActionResult> DeleteCliente(string cpf)
        {
            var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.CPF == cpf);
            if (cliente == null)
            {
                return NotFound();
            }

            _context.Clientes.Remove(cliente);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Método privado para verificar se um registro de Cliente existe pelo CPF
        private bool ClienteExists(string cpf)
        {
            return _context.Clientes.Any(e => e.CPF == cpf);
        }
    }
}
