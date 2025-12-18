using System;
using System.Collections.Generic;

namespace WebDatPhongKhachSan.Models
{
    public class BaoCaoTongHopVM
    {
        public DateTime NgayBaoCao { get; set; }
        public int Thang { get; set; }
        public int Nam { get; set; }

        public BaoCaoNgayVM DoanhThuNgay { get; set; }
        public decimal DoanhThuThang { get; set; } // Tính từ Function fn_DoanhThuThang
        public List<DichVuTopVM> DichVuBanChay { get; set; }
    }
}