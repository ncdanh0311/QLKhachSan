namespace WebDatPhongKhachSan.Models
{
    public class LoaiPhongCardVM
    {
        public int MaLoaiPhong { get; set; }
        public int MaKS { get; set; }

        public string TenLoai { get; set; }
        public int SucChuaNguoiLon { get; set; }
        public int SucChuaTreEm { get; set; }

        // Giá
        public decimal GiaCoBan { get; set; }
        public decimal? GiaTheoNgay { get; set; } // chỉ có khi có ngayNhan

        public string MoTa { get; set; }

        // Thông tin KS
        public string TenKS { get; set; }
        public string ThanhPho { get; set; }
        public string QuocGia { get; set; }

        // Fake UI
        public string ImageUrl { get; set; }
        public double Rating { get; set; }
        public int ReviewCount { get; set; }
        public int StarCount { get; set; }
        public bool IsGenius { get; set; }
    }
}
