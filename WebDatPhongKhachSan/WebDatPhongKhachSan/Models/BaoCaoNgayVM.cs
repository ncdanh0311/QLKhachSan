using System;

namespace WebDatPhongKhachSan.Models
{
    public class BaoCaoNgayVM
    {
        public DateTime Ngay { get; set; }
        public int SoBookingCheckout { get; set; }
        public int SoPhongCheckout { get; set; }
        public decimal DoanhThu { get; set; }
    }
}