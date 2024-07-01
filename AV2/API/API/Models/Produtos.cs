using System.ComponentModel.DataAnnotations;

namespace API.Models
{
    public class Produtos
    {
        public int Id { get; set; }
        public string SKU { get; set; }
        public int Stock { get; set; }
        public string ProductName { get; set; }

        [DataType(DataType.Currency)]
        [DisplayFormat(DataFormatString = "{0:F2}", ApplyFormatInEditMode = true)]
        public decimal ItemPrice { get; set; }
    }
}
