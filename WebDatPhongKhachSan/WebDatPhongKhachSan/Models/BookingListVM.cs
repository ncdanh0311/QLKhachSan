using System;
using System.Collections.Generic;

namespace WebDatPhongKhachSan.Models
{
    public class BookingListVM
    {
        public string Keyword { get; set; }      // tìm theo mã đặt/CCCD/SDT/họ tên
        public string TrangThai { get; set; }    // lọc trạng thái
        public DateTime? TuNgay { get; set; }
        public DateTime? DenNgay { get; set; }

        public List<BookingRowVM> Items { get; set; } = new List<BookingRowVM>();
    }
}
