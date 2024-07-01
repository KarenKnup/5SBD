using System.ComponentModel.DataAnnotations;

namespace API.Models
{
    public class ItensPedidoNegados
    {
        public int Id { get; set; }
        public string OrderId { get; set; }
        public string OrderItemId { get; set; }
        public string CPF { get; set; }
        public string SKU { get; set; }
        public int QuantityPurchased { get; set; }
        public string Currency { get; set; }

        [DataType(DataType.Currency)]
        [DisplayFormat(DataFormatString = "{0:F2}", ApplyFormatInEditMode = true)]
        public decimal ItemPrice { get; set; }
    }
}
