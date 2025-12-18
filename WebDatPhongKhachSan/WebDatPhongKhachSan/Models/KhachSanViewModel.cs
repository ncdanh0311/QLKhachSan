using System;

namespace WebDatPhongKhachSan.Models
{
    public class KhachSanViewModel
    {
        public int MaKS { get; set; }
        public string MaSo { get; set; }
        public string TenKS { get; set; }
        public string DiaChi { get; set; }
        public string ThanhPho { get; set; }
        public string QuocGia { get; set; }
        public string MuiGio { get; set; }
        public string SoDienThoai { get; set; }
        public string Email { get; set; }
        public string TrangThai { get; set; }
        public DateTime NgayTao { get; set; }
        public DateTime NgayCapNhat { get; set; }
    }
}
