using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models;

namespace WebDatPhongKhachSan.Controllers
{
    public class HomeController : Controller
    {
        private readonly string conStr = ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        public ActionResult TrangChu()
        {
            var list = new List<KhachSanViewModel>();

            using (SqlConnection conn = new SqlConnection(conStr))
            {
                string sql = @"
                    SELECT 
                        MaKS, MaSo, TenKS, DiaChi, ThanhPho, QuocGia,
                        MuiGio, SoDienThoai, Email, TrangThai,
                        NgayTao, NgayCapNhat
                    FROM KhachSan
                    WHERE TrangThai = N'Hoạt động'
                    ORDER BY MaKS DESC;
                ";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (SqlDataReader rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            list.Add(new KhachSanViewModel
                            {
                                MaKS = (int)rd["MaKS"],
                                MaSo = rd["MaSo"].ToString(),
                                TenKS = rd["TenKS"].ToString(),
                                DiaChi = rd["DiaChi"]?.ToString(),
                                ThanhPho = rd["ThanhPho"]?.ToString(),
                                QuocGia = rd["QuocGia"]?.ToString(),
                                MuiGio = rd["MuiGio"]?.ToString(),
                                SoDienThoai = rd["SoDienThoai"]?.ToString(),
                                Email = rd["Email"]?.ToString(),
                                TrangThai = rd["TrangThai"]?.ToString(),
                                NgayTao = (DateTime)rd["NgayTao"],
                                NgayCapNhat = (DateTime)rd["NgayCapNhat"]
                            });
                        }
                    }
                }
            }

            return View(list); // ✅ đúng kiểu với View
        }
        public ActionResult DangNhap() {
        
            return View();
        }
        public ActionResult DangKi()
        {

            return View();
        }
    }
}
