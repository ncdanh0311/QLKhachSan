using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models;

namespace WebDatPhongKhachSan.Controllers
{
    public class DatPhongController : Controller
    {
        private readonly string conStr = ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        // GET: /DatPhong
        // /DatPhong?keyword=0912&trangThai=Đang giữ chỗ&tuNgay=2025-12-01&denNgay=2025-12-31
        public ActionResult Index(string keyword, string trangThai, DateTime? tuNgay, DateTime? denNgay)
        {
            var vm = new BookingListVM
            {
                Keyword = (keyword ?? "").Trim(),
                TrangThai = (trangThai ?? "").Trim(),
                TuNgay = tuNgay?.Date,
                DenNgay = denNgay?.Date
            };

            vm.Items = GetBookings(vm.Keyword, vm.TrangThai, vm.TuNgay, vm.DenNgay);
            return View(vm);
        }

        // GET: /DatPhong/ChiTiet/5
        public ActionResult ChiTiet(int id)
        {
            var item = GetBookingDetail(id);
            if (item == null) return HttpNotFound("Không tìm thấy mã đặt phòng.");
            return View(item);
        }

        // ================== DB ==================

        private List<BookingRowVM> GetBookings(string keyword, string trangThai, DateTime? tuNgay, DateTime? denNgay)
        {
            var list = new List<BookingRowVM>();

            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();

                // NOTE:
                // - ChiTietDatPhong có thể có nhiều dòng / 1 DatPhong (nhiều phòng).
                // - Ở list này, mình lấy 1 dòng đại diện (MIN MaCT) để hiển thị nhanh.
                //   Nếu bạn muốn hiển thị mỗi phòng 1 dòng, nói mình đổi query.
                var sql = @"
;WITH OneCT AS (
    SELECT ct.*
    FROM dbo.ChiTietDatPhong ct
    INNER JOIN (
        SELECT MaDatPhong, MIN(MaCT) AS MinMaCT
        FROM dbo.ChiTietDatPhong
        GROUP BY MaDatPhong
    ) x ON x.MaDatPhong = ct.MaDatPhong AND x.MinMaCT = ct.MaCT
)
SELECT
    dp.MaDatPhong, dp.NgayDat, dp.NgayNhan, dp.NgayTra, dp.TrangThai, dp.TongTien, dp.GhiChu,
    dp.MaKH,
    kh.HoTen, kh.CCCD, kh.SoDienThoai, kh.Email, kh.QuocTich, kh.GioiTinh,

    oct.MaPhong,
    CAST(p.SoPhong AS NVARCHAR(50)) AS TenPhong,
p.TrangThai AS TrangThaiPhong,


    lp.MaLoaiPhong,
    lp.TenLoai,
    oct.GiaCoBan,
    oct.SoNguoi,

    ks.MaKS,
    ks.TenKS, ks.DiaChi, ks.ThanhPho, ks.QuocGia
FROM dbo.DatPhong dp
LEFT JOIN dbo.KhachHang kh ON kh.MaKH = dp.MaKH
LEFT JOIN OneCT oct ON oct.MaDatPhong = dp.MaDatPhong
LEFT JOIN dbo.Phong p ON p.MaPhong = oct.MaPhong
LEFT JOIN dbo.LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
LEFT JOIN dbo.KhachSan ks ON ks.MaKS = lp.MaKS
WHERE 1=1
  AND (@TrangThai = N'' OR dp.TrangThai = @TrangThai)
  AND (@TuNgay IS NULL OR dp.NgayNhan >= @TuNgay)
  AND (@DenNgay IS NULL OR dp.NgayNhan < DATEADD(DAY, 1, @DenNgay))
  AND (
        @Keyword = N'' OR
        CAST(dp.MaDatPhong AS NVARCHAR(20)) LIKE N'%' + @Keyword + N'%' OR
        ISNULL(kh.HoTen, N'') LIKE N'%' + @Keyword + N'%' OR
        ISNULL(kh.CCCD, N'') LIKE N'%' + @Keyword + N'%' OR
        ISNULL(kh.SoDienThoai, N'') LIKE N'%' + @Keyword + N'%'
      )
ORDER BY dp.MaDatPhong DESC;";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@Keyword", SqlDbType.NVarChar, 100).Value = keyword ?? "";
                    cmd.Parameters.Add("@TrangThai", SqlDbType.NVarChar, 50).Value = trangThai ?? "";
                    cmd.Parameters.Add("@TuNgay", SqlDbType.Date).Value = (object)tuNgay ?? DBNull.Value;
                    cmd.Parameters.Add("@DenNgay", SqlDbType.Date).Value = (object)denNgay ?? DBNull.Value;

                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var ngayNhan = Convert.ToDateTime(rd["NgayNhan"]);
                            var ngayTra = Convert.ToDateTime(rd["NgayTra"]);
                            int soDem = Math.Max(0, (ngayTra.Date - ngayNhan.Date).Days);

                            list.Add(new BookingRowVM
                            {
                                MaDatPhong = Convert.ToInt32(rd["MaDatPhong"]),
                                NgayDat = Convert.ToDateTime(rd["NgayDat"]),
                                NgayNhan = ngayNhan,
                                NgayTra = ngayTra,
                                SoDem = soDem,

                                TrangThai = rd["TrangThai"]?.ToString(),
                                TongTien = rd["TongTien"] == DBNull.Value ? 0 : Convert.ToDecimal(rd["TongTien"]),
                                GhiChu = rd["GhiChu"]?.ToString(),

                                MaKH = rd["MaKH"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaKH"]),
                                HoTen = rd["HoTen"]?.ToString(),
                                CCCD = rd["CCCD"]?.ToString(),
                                SoDienThoai = rd["SoDienThoai"]?.ToString(),
                                Email = rd["Email"]?.ToString(),
                                QuocTich = rd["QuocTich"]?.ToString(),
                                GioiTinh = rd["GioiTinh"]?.ToString(),

                                MaPhong = rd["MaPhong"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaPhong"]),
                                TenPhong = rd["TenPhong"]?.ToString(),
                                TrangThaiPhong = rd["TrangThaiPhong"]?.ToString(),

                                MaLoaiPhong = rd["MaLoaiPhong"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaLoaiPhong"]),
                                TenLoai = rd["TenLoai"]?.ToString(),
                                GiaCoBan = rd["GiaCoBan"] == DBNull.Value ? 0 : Convert.ToDecimal(rd["GiaCoBan"]),
                                SoNguoi = rd["SoNguoi"] == DBNull.Value ? 0 : Convert.ToInt32(rd["SoNguoi"]),

                                MaKS = rd["MaKS"] == DBNull.Value ? 0 : Convert.ToInt32(rd["MaKS"]),
                                TenKS = rd["TenKS"]?.ToString(),
                                DiaChiKS = rd["DiaChi"]?.ToString(),
                                ThanhPho = rd["ThanhPho"]?.ToString(),
                                QuocGia = rd["QuocGia"]?.ToString()
                            });
                        }
                    }
                }
            }

            return list;
        }

        private BookingRowVM GetBookingDetail(int maDatPhong)
        {
            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();

                // Chi tiết: trả ra nhiều dòng CT (nếu đặt nhiều phòng)
                // Ở đây mình vẫn map về 1 BookingRowVM đại diện + bạn có thể mở rộng thành list CT nếu muốn.
                var sql = @"
SELECT TOP 1
    dp.MaDatPhong, dp.NgayDat, dp.NgayNhan, dp.NgayTra, dp.TrangThai, dp.TongTien, dp.GhiChu,
    dp.MaKH,
    kh.HoTen, kh.CCCD, kh.SoDienThoai, kh.Email, kh.QuocTich, kh.GioiTinh,

    ct.MaPhong,
    CAST(p.SoPhong AS NVARCHAR(50)) AS TenPhong,
p.TrangThai AS TrangThaiPhong,


    lp.MaLoaiPhong,
    lp.TenLoai,
    ct.GiaCoBan,
    ct.SoNguoi,

    ks.MaKS,
    ks.TenKS, ks.DiaChi, ks.ThanhPho, ks.QuocGia
FROM dbo.DatPhong dp
LEFT JOIN dbo.KhachHang kh ON kh.MaKH = dp.MaKH
LEFT JOIN dbo.ChiTietDatPhong ct ON ct.MaDatPhong = dp.MaDatPhong
LEFT JOIN dbo.Phong p ON p.MaPhong = ct.MaPhong
LEFT JOIN dbo.LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
LEFT JOIN dbo.KhachSan ks ON ks.MaKS = lp.MaKS
WHERE dp.MaDatPhong = @MaDatPhong
ORDER BY ct.MaCT ASC;";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaDatPhong", SqlDbType.Int).Value = maDatPhong;

                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read()) return null;

                        var ngayNhan = Convert.ToDateTime(rd["NgayNhan"]);
                        var ngayTra = Convert.ToDateTime(rd["NgayTra"]);
                        int soDem = Math.Max(0, (ngayTra.Date - ngayNhan.Date).Days);

                        return new BookingRowVM
                        {
                            MaDatPhong = Convert.ToInt32(rd["MaDatPhong"]),
                            NgayDat = Convert.ToDateTime(rd["NgayDat"]),
                            NgayNhan = ngayNhan,
                            NgayTra = ngayTra,
                            SoDem = soDem,

                            TrangThai = rd["TrangThai"]?.ToString(),
                            TongTien = rd["TongTien"] == DBNull.Value ? 0 : Convert.ToDecimal(rd["TongTien"]),
                            GhiChu = rd["GhiChu"]?.ToString(),

                            MaKH = rd["MaKH"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaKH"]),
                            HoTen = rd["HoTen"]?.ToString(),
                            CCCD = rd["CCCD"]?.ToString(),
                            SoDienThoai = rd["SoDienThoai"]?.ToString(),
                            Email = rd["Email"]?.ToString(),
                            QuocTich = rd["QuocTich"]?.ToString(),
                            GioiTinh = rd["GioiTinh"]?.ToString(),

                            MaPhong = rd["MaPhong"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaPhong"]),
                            TenPhong = rd["TenPhong"]?.ToString(),
                            TrangThaiPhong = rd["TrangThaiPhong"]?.ToString(),

                            MaLoaiPhong = rd["MaLoaiPhong"] == DBNull.Value ? (int?)null : Convert.ToInt32(rd["MaLoaiPhong"]),
                            TenLoai = rd["TenLoai"]?.ToString(),
                            GiaCoBan = rd["GiaCoBan"] == DBNull.Value ? 0 : Convert.ToDecimal(rd["GiaCoBan"]),
                            SoNguoi = rd["SoNguoi"] == DBNull.Value ? 0 : Convert.ToInt32(rd["SoNguoi"]),

                            MaKS = rd["MaKS"] == DBNull.Value ? 0 : Convert.ToInt32(rd["MaKS"]),
                            TenKS = rd["TenKS"]?.ToString(),
                            DiaChiKS = rd["DiaChi"]?.ToString(),
                            ThanhPho = rd["ThanhPho"]?.ToString(),
                            QuocGia = rd["QuocGia"]?.ToString()
                        };
                    }
                }
            }
        }
    }
}
