using System;

namespace WebDatPhongKhachSan.Models
{
    public class LichSuDatPhongVM
    {
        public int MaDatPhong { get; set; }
        public DateTime NgayNhan { get; set; }
        public DateTime NgayTra { get; set; }
        public string TrangThai { get; set; }
        public string SoPhong { get; set; }
        public string LoaiPhong { get; set; }
        public int SoNgayO { get; set; }
        public decimal TienPhong { get; set; }
        public decimal TienDichVu { get; set; }
        public decimal TongTienMoiLan { get; set; }
    }
}