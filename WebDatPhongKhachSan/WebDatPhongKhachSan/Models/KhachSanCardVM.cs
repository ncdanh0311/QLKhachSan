using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebDatPhongKhachSan.Models
{
    public class KhachSanCardVM
    {
        public int MaKS { get; set; }
        public string MaSo { get; set; }
        public string TenKS { get; set; }
        public string DiaChi { get; set; }
        public string ThanhPho { get; set; }
        public string QuocGia { get; set; }
        public string TrangThai { get; set; }

        // Fake fields cho UI
        public string ImageUrl { get; set; }
        public double Rating { get; set; }
        public int ReviewCount { get; set; }
        public int StarCount { get; set; }
        public string BadgeText { get; set; }
        public string TypeText { get; set; }
    }
}