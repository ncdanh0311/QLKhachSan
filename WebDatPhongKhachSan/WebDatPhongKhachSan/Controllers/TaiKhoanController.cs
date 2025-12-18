using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Security.Policy;
using System.Text;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models;

namespace WebDatPhongKhachSan.Controllers
{
    public class TaiKhoanController : Controller
    {
        private readonly string conStr =
            ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        // =========================
        // PHÂN QUYỀN – ĐẶT TẠI ĐÂY
        // =========================
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            string action = filterContext.ActionDescriptor.ActionName;

            // ✅ CHO PHÉP TRUY CẬP TỰ DO
            if (action == "DangNhap" || action == "DangKi" || action == "DangXuat")
            {
                base.OnActionExecuting(filterContext);
                return;
            }

            // ❌ CHƯA LOGIN
            if (Session["MaND"] == null)
            {
                filterContext.Result = RedirectToAction("DangNhap", "TaiKhoan");
                return;
            }

            // ❌ KHÁCH KHÔNG ĐƯỢC VÀO ADMIN
            int maLoaiND = Convert.ToInt32(Session["MaLoaiND"]);
            if (maLoaiND == 5)
            {
                filterContext.Result = RedirectToAction("Index", "Home");
                return;
            }

            base.OnActionExecuting(filterContext);
        }

        // =========================
        // GET: /TaiKhoan/DangNhap
        // =========================
        public ActionResult DangNhap()
        {
            if (Session["MaND"] != null && Session["MaLoaiND"] != null)
            {
                int role = Convert.ToInt32(Session["MaLoaiND"]);
                if (role == 5)
                    return RedirectToAction("Index", "Home");
                else
                    return RedirectToAction("SoDoPhong", "Admin");
            }

            return View(new LoginVM());
        }

        // =========================
        // POST: /TaiKhoan/DangNhap
        // =========================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DangNhap(LoginVM model)
        {
            if (!ModelState.IsValid)
                return View(model);

            var hash = model.MatKhau;


            using (var conn = new SqlConnection(conStr))
            {
                string sql = @"
SELECT TOP 1
    MaND,
    TenDangNhap,
    HoTen,
    MaLoaiND,
    MaNV,
    TrangThai
FROM NguoiDung
WHERE TenDangNhap = @u
  AND MatKhauHash = @p;";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@u", model.TenDangNhap.Trim());
                    cmd.Parameters.AddWithValue("@p", hash);

                    conn.Open();
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read())
                        {
                            ModelState.AddModelError("", "Sai tên đăng nhập hoặc mật khẩu.");
                            return View(model);
                        }

                        string trangThai = rd["TrangThai"] == DBNull.Value
                            ? "Hoạt động"
                            : rd["TrangThai"].ToString();

                        if (!string.Equals(trangThai, "Hoạt động", StringComparison.OrdinalIgnoreCase))
                        {
                            ModelState.AddModelError("", "Tài khoản đang bị khóa.");
                            return View(model);
                        }

                        // SET SESSION
                        int maLoaiND = Convert.ToInt32(rd["MaLoaiND"]);
                        Session["MaND"] = Convert.ToInt32(rd["MaND"]);
                        Session["TenDangNhap"] = rd["TenDangNhap"].ToString();
                        Session["HoTen"] = rd["HoTen"].ToString();
                        Session["MaLoaiND"] = maLoaiND;
                        Session["MaNV"] = rd["MaNV"] == DBNull.Value
                            ? (int?)null
                            : Convert.ToInt32(rd["MaNV"]);

                        // REDIRECT
                        if (maLoaiND == 5)
                            return RedirectToAction("Index", "Home");
                        else
                            return RedirectToAction("SoDoPhong", "Admin");
                    }
                }
            }
        }

        // =========================
        // GET: /TaiKhoan/DangKi
        // =========================
        public ActionResult DangKi()
        {
            if (Session["MaND"] != null)
                return RedirectToAction("Index", "Home");

            return View(new RegisterVM());
        }

        // =========================
        // POST: /TaiKhoan/DangKi
        // =========================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DangKi(RegisterVM model)
        {
            if (!ModelState.IsValid)
                return View(model);

            string tenDN = model.TenDangNhap.Trim();
            string hash = Sha256(model.MatKhau);

            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();

                string checkSql = "SELECT COUNT(1) FROM NguoiDung WHERE TenDangNhap = @u";
                using (var check = new SqlCommand(checkSql, conn))
                {
                    check.Parameters.AddWithValue("@u", tenDN);
                    if ((int)check.ExecuteScalar() > 0)
                    {
                        ModelState.AddModelError("", "Tên đăng nhập đã tồn tại.");
                        return View(model);
                    }
                }

                string insertSql = @"
INSERT INTO NguoiDung (TenDangNhap, MatKhauHash, HoTen, MaLoaiND, TrangThai)
VALUES (@TenDN, @Hash, @HoTen, 5, N'Hoạt động');";

                using (var cmd = new SqlCommand(insertSql, conn))
                {
                    cmd.Parameters.AddWithValue("@TenDN", tenDN);
                    cmd.Parameters.AddWithValue("@Hash", hash);
                    cmd.Parameters.AddWithValue("@HoTen", model.HoTen.Trim());
                    cmd.ExecuteNonQuery();
                }

                return RedirectToAction("DangNhap");
            }
        }

        // =========================
        // /TaiKhoan/DangXuat
        // =========================
        public ActionResult DangXuat()
        {
            Session.Clear();
            Session.Abandon();
            return RedirectToAction("DangNhap");
        }

        // =========================
        // HASH SHA256
        // =========================
        private static string Sha256(string input)
        {
            if (string.IsNullOrEmpty(input))
                input = "";

            using (SHA256 sha = SHA256.Create())
            {
                byte[] bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(input));
                StringBuilder sb = new StringBuilder();
                foreach (byte b in bytes)
                    sb.Append(b.ToString("x2"));
                return sb.ToString();
            }
        }
    }
}
