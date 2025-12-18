using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebDatPhongKhachSan.Models
{
    public class CheckOutVM
    {
        public int MaDatPhong { get; set; }
        public string TenKhach { get; set; }
        public decimal TongTienPhong { get; set; }
        public decimal TongTienDV { get; set; }
        public decimal TongCong { get; set; }
    }
}