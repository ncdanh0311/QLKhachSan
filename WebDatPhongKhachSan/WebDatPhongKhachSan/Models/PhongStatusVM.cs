using System;

namespace WebDatPhongKhachSan.Models
{
    public class PhongStatusVM
    {
        public int MaPhong { get; set; }
        public string SoPhong { get; set; }
        public int Tang { get; set; }
        public string LoaiPhong { get; set; }
        public string TrangThaiPhong { get; set; } // Sẵn sàng, Chờ dọn, Đang có khách
        public string CoKhach { get; set; }       // "Có" / "Không"

        // Thông tin khách (nếu có)
        public string TenKhach { get; set; }
        public string SoDienThoai { get; set; }
        public int SoNguoiO { get; set; }
        public DateTime? NgayCheckIn { get; set; }
        public DateTime? NgayCheckOut { get; set; }
        public string CoDungDichVu { get; set; }
    }
}