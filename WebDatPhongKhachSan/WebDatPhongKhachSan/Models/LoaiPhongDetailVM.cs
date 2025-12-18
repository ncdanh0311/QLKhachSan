using System;

namespace WebDatPhongKhachSan.Models
{
    public class LoaiPhongDetailVM
    {
        // ===== DB: loại phòng =====
        public int MaLoaiPhong { get; set; }
        public int MaKS { get; set; }
        public string TenLoai { get; set; }

        public int SucChuaNguoiLon { get; set; }
        public int SucChuaTreEm { get; set; }

        public decimal GiaCoBan { get; set; }
        public decimal? GiaTheoNgay { get; set; } // dựa theo ngày nhận
        public string MoTa { get; set; }

        // ===== DB: khách sạn =====
        public string TenKS { get; set; }
        public string DiaChi { get; set; }
        public string ThanhPho { get; set; }
        public string QuocGia { get; set; }

        public string[] Gallery { get; set; }

        // ===== Input đặt phòng =====
        public DateTime? NgayNhan { get; set; }
        public DateTime? NgayTra { get; set; }

        public int SoNguoiLon { get; set; } = 2;
        public int SoTreEm { get; set; } = 0;
        public int SoPhong { get; set; } = 1;

        // ✅ Bắt buộc
        public string HoTen { get; set; }
        public string SDT { get; set; }

        public string GhiChu { get; set; }

        // ===== Output tính toán =====
        public int SoDem { get; set; }
        public decimal? TongTienDuKien { get; set; }
        public string ThongBao { get; set; }

        // tiện
        public int TongNguoi => Math.Max(0, SoNguoiLon) + Math.Max(0, SoTreEm);
        public string CCCD { get; set; }
        public string Email { get; set; }
        public string GioiTinh { get; set; }   // "Nam"/"Nữ" hoặc null
        public string QuocTich { get; set; }

    }
}
