using System;
using System.Collections.Generic;

namespace WebDatPhongKhachSan.Models
{
    public class ChiTietDatPhongVM
    {
        public int MaDatPhong { get; set; }
        public string HoTen { get; set; }
        public string SoDienThoai { get; set; }
        public int SoLuongPhong { get; set; }
        public int TongSoNguoi { get; set; }

        public decimal TongTienPhongDenHienTai { get; set; }
        public decimal TongTienDichVu { get; set; }
        public decimal TongTienHienTai { get; set; }

        // Danh sách các class con đã tách ở trên
        public List<ItemPhongVM> DanhSachPhong { get; set; } = new List<ItemPhongVM>();
        public List<ItemDichVuVM> DanhSachDichVu { get; set; } = new List<ItemDichVuVM>();
    }
}