using System;

namespace WebDatPhongKhachSan.Models
{
    public class BookingRowVM
    {
        public int MaDatPhong { get; set; }
        public DateTime NgayDat { get; set; }
        public DateTime NgayNhan { get; set; }
        public DateTime NgayTra { get; set; }
        public int SoDem { get; set; }

        public string TrangThai { get; set; }
        public decimal TongTien { get; set; }
        public string GhiChu { get; set; }

        public int? MaKH { get; set; }
        public string HoTen { get; set; }
        public string CCCD { get; set; }
        public string SoDienThoai { get; set; }
        public string Email { get; set; }
        public string QuocTich { get; set; }
        public string GioiTinh { get; set; }

        public int? MaPhong { get; set; }
        public string TenPhong { get; set; }
        public string TrangThaiPhong { get; set; }

        public int? MaLoaiPhong { get; set; }
        public string TenLoai { get; set; }
        public decimal GiaCoBan { get; set; }
        public int SoNguoi { get; set; }

        public int MaKS { get; set; }
        public string TenKS { get; set; }
        public string DiaChiKS { get; set; }
        public string ThanhPho { get; set; }
        public string QuocGia { get; set; }
    }
}
