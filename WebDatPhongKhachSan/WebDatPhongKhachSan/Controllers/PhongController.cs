using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models;

namespace WebDatPhongKhachSan.Controllers
{
    public class PhongController : Controller
    {
        private readonly string conStr = ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        // /Phong/LoaiPhong?maKS=1&ngayNhan=2025-12-20
        public ActionResult LoaiPhong(int maKS, DateTime? ngayNhan)
        {
            var list = new List<LoaiPhongCardVM>();
            DateTime? pickedDate = ngayNhan?.Date;

            using (var conn = new SqlConnection(conStr))
            {
                const string sql = @"
                    SELECT
                        lp.MaLoaiPhong,
                        lp.MaKS,
                        lp.TenLoai,
                        lp.SucChuaNguoiLon,
                        lp.SucChuaTreEm,
                        lp.GiaCoBan,
                        CASE 
                            WHEN @NgayNhan IS NULL THEN NULL
                            ELSE dbo.fn_TinhGiaPhongTheoNgay(@NgayNhan, lp.GiaCoBan)
                        END AS GiaTheoNgay,
                        lp.MoTa,
                        ks.TenKS,
                        ks.ThanhPho,
                        ks.QuocGia
                    FROM LoaiPhong lp
                    JOIN KhachSan ks ON ks.MaKS = lp.MaKS
                    WHERE lp.MaKS = @MaKS
                    ORDER BY lp.GiaCoBan ASC, lp.MaLoaiPhong DESC;";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKS", maKS);
                    cmd.Parameters.AddWithValue("@NgayNhan", (object)pickedDate ?? DBNull.Value);

                    conn.Open();
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            int maLoai = (int)rd["MaLoaiPhong"];

                            // Fake UI
                            var rating = Math.Round(8.0 + (maLoai % 10) * 0.1, 1);
                            var reviews = 50 + (maLoai % 950);
                            var stars = 4 + (maLoai % 2);
                            var isGenius = (maLoai % 3 == 0);

                            list.Add(new LoaiPhongCardVM
                            {
                                MaLoaiPhong = maLoai,
                                MaKS = (int)rd["MaKS"],
                                TenLoai = rd["TenLoai"]?.ToString(),
                                SucChuaNguoiLon = rd["SucChuaNguoiLon"] == DBNull.Value ? 0 : Convert.ToInt32(rd["SucChuaNguoiLon"]),
                                SucChuaTreEm = rd["SucChuaTreEm"] == DBNull.Value ? 0 : Convert.ToInt32(rd["SucChuaTreEm"]),
                                GiaCoBan = rd["GiaCoBan"] == DBNull.Value ? 0 : Convert.ToDecimal(rd["GiaCoBan"]),
                                GiaTheoNgay = rd["GiaTheoNgay"] == DBNull.Value ? (decimal?)null : Convert.ToDecimal(rd["GiaTheoNgay"]),
                                MoTa = rd["MoTa"]?.ToString(),
                                TenKS = rd["TenKS"]?.ToString(),
                                ThanhPho = rd["ThanhPho"]?.ToString(),
                                QuocGia = rd["QuocGia"]?.ToString(),

                                ImageUrl = "https://source.unsplash.com/1200x800/?hotel-room,bedroom&sig=" + (maLoai * 37),
                                Rating = rating,
                                ReviewCount = reviews,
                                StarCount = stars,
                                IsGenius = isGenius
                            });
                        }
                    }
                }
            }

            // ===== ViewBag clean & KHÔNG bị lỗi DateTime? =====
            ViewBag.MaKS = maKS;
            ViewBag.TenKS = list.Count > 0 ? list[0].TenKS : "Khách sạn";
            ViewBag.Location = list.Count > 0 ? $"{list[0].ThanhPho}, {list[0].QuocGia}" : "";

            // Đưa xuống View bằng string để không bị lỗi cast DateTime?
            ViewBag.NgayNhanStr = pickedDate?.ToString("yyyy-MM-dd"); // dùng cho link query
            ViewBag.NgayNhanText = pickedDate?.ToString("dd/MM/yyyy"); // dùng để hiển thị đẹp

            return View(list);
        }
    }
}
