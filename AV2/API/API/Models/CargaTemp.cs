using System;
using System.ComponentModel.DataAnnotations;

namespace API.Models
{
    public class CargaTemp
    {
        public int Id { get; set; }
        public string OrderId { get; set; }
        public string OrderItemId { get; set; }
        public DateTime PurchaseDate { get; set; }
        public DateTime PaymentsDate { get; set; }
        public string BuyerEmail { get; set; }
        public string BuyerName { get; set; }
        public string Cpf { get; set; }
        public string BuyerPhoneNumber { get; set; }
        public string Sku { get; set; }
        public string ProductName { get; set; }
        public int QuantityPurchased { get; set; }
        public string Currency { get; set; }

        [DataType(DataType.Currency)]
        [DisplayFormat(DataFormatString = "{0:F2}", ApplyFormatInEditMode = true)]
        public decimal ItemPrice { get; set; }
        public string ShipServiceLevel { get; set; }
        public string RecipientName { get; set; }
        public string ShipAddress1 { get; set; }
        public string ShipAddress2 { get; set; }
        public string ShipAddress3 { get; set; }
        public string ShipCity { get; set; }
        public string ShipState { get; set; }
        public string ShipPostalCode { get; set; }
        public string ShipCountry { get; set; }
        public string IossNumber { get; set; }
    }
}
