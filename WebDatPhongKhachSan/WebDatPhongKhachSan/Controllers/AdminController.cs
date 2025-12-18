using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models; // Sử dụng các model đã tách

namespace WebDatPhongKhachSan.Controllers
{
    public class AdminController : Controller
    {
        private readonly string conStr = ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        // ==========================================
        // 1. SƠ ĐỒ TÌNH TRẠNG PHÒNG (Dành cho Lễ Tân)
        // Gọi: sp_BaoCaoTinhTrangPhongTheoNgay
        // ==========================================
        public ActionResult SoDoPhong(DateTime? date)
        {
            // 1. Kiểm tra quyền & Lấy MaKS
            if (Session["MaND"] == null) return RedirectToAction("DangNhap", "TaiKhoan");

            int? maKS = Session["MaKS"] as int?;

            // Nếu tài khoản không thuộc KS nào (ví dụ Admin hệ thống chưa gán KS),
            // Bạn có thể xử lý gán mặc định KS 1 hoặc báo lỗi. Ở đây mình gán tạm = 1 để test.
            if (maKS == null) maKS = 1;

            DateTime targetDate = date ?? DateTime.Today;
            var list = new List<PhongStatusVM>();

            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();
                using (var cmd = new SqlCommand("sp_BaoCaoTinhTrangPhongTheoNgay", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Ngay", targetDate);
                    cmd.Parameters.AddWithValue("@MaKS", maKS); // <--- Truyền tham số mới

                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var p = new PhongStatusVM
                            {
                                MaPhong = (int)rd["MaPhong"],
                                SoPhong = rd["SoPhong"].ToString(),
                                Tang = rd["Tang"] != DBNull.Value ? Convert.ToInt32(rd["Tang"]) : 0,
                                LoaiPhong = rd["LoaiPhong"].ToString(),
                                TrangThaiPhong = rd["TrangThaiPhong"].ToString(),
                                CoKhach = rd["CoKhach"].ToString(),
                                TenKhach = rd["TenKhach"]?.ToString(),
                                SoDienThoai = rd["SoDienThoai"]?.ToString(),
                                SoNguoiO = rd["SoNguoiO"] != DBNull.Value ? Convert.ToInt32(rd["SoNguoiO"]) : 0,
                                NgayCheckIn = rd["NgayCheckIn"] as DateTime?,
                                NgayCheckOut = rd["NgayCheckOut"] as DateTime?,
                                CoDungDichVu = rd["CoDungDichVuTrongNgay"].ToString()
                            };

                            // Thêm MaDatPhong nếu Model của bạn đã cập nhật (để dùng cho nút Thanh toán)
                            // if (rd["MaDatPhong"] != DBNull.Value) p.MaDatPhong = (int)rd["MaDatPhong"];

                            list.Add(p);
                        }
                    }
                }

                // Bonus: Lấy tên khách sạn để hiển thị lên View cho đẹp
                string sqlGetTenKS = "SELECT TenKS FROM KhachSan WHERE MaKS = @id";
                using (var cmd2 = new SqlCommand(sqlGetTenKS, conn))
                {
                    cmd2.Parameters.AddWithValue("@id", maKS);
                    ViewBag.TenKS = cmd2.ExecuteScalar()?.ToString();
                }
            }

            ViewBag.TargetDate = targetDate;
            return View(list);
        }

        // Action: XÁC NHẬN DỌN PHÒNG
        // Gọi: sp_XacNhanDonPhong
        [HttpPost]
        public ActionResult CleanRoom(int maPhong)
        {
            try
            {
                using (var conn = new SqlConnection(conStr))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("sp_XacNhanDonPhong", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@MaPhong", maPhong);
                        cmd.ExecuteNonQuery();
                    }
                }
                TempData["Msg"] = "Đã cập nhật phòng thành Sẵn sàng!";
            }
            catch (Exception ex)
            {
                TempData["Err"] = "Lỗi: " + ex.Message;
            }
            return RedirectToAction("SoDoPhong");
        }

        // ==========================================
        // 2. CHECK-IN NHANH
        // Gọi: sp_CheckIn
        // ==========================================
        public ActionResult CheckIn()
        {
            return View();
        }

        [HttpPost]
        public ActionResult CheckIn(int maDatPhong)
        {
            try
            {
                using (var conn = new SqlConnection(conStr))
                {
                    conn.Open();
                    using (var cmd = new SqlCommand("sp_CheckIn", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@MaDatPhong", maDatPhong);
                        // Lấy tên người check-in từ Session hoặc để mặc định
                        cmd.Parameters.AddWithValue("@NguoiCheckIn", Session["HoTen"] ?? "Admin/LeTan");
                        cmd.ExecuteNonQuery();
                    }
                }
                ViewBag.Msg = $"✅ Check-in thành công cho đơn #{maDatPhong}!";
            }
            catch (Exception ex)
            {
                ViewBag.Err = "❌ Lỗi: " + ex.Message;
            }
            return View();
        }

        // --- THÊM VÀO AdminController.cs ---

        // ==========================================
        // 4. CHUYỂN PHÒNG (Sử dụng Store Procedure: sp_ChuyenPhong)
        // ==========================================
        [HttpPost]
        public ActionResult ChuyenPhong(int maDatPhong, int phongCu, int phongMoi, string ghiChu)
        {
            try
            {
                using (var conn = new SqlConnection(conStr))
                {
                    conn.Open();
                    // Gọi SP sp_ChuyenPhong đã có trong file SQL
                    using (var cmd = new SqlCommand("sp_ChuyenPhong", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@MaDatPhong", maDatPhong);
                        cmd.Parameters.AddWithValue("@PhongA", phongCu);
                        cmd.Parameters.AddWithValue("@PhongB", phongMoi);
                        cmd.Parameters.AddWithValue("@NguoiCapNhat", Session["HoTen"] ?? "Admin");
                        cmd.Parameters.AddWithValue("@GhiChu", ghiChu ?? "Admin chuyển phòng");

                        cmd.ExecuteNonQuery();
                    }
                }
                TempData["Msg"] = $"Đã chuyển đơn #{maDatPhong} sang phòng mới thành công!";
            }
            catch (Exception ex)
            {
                TempData["Err"] = "Lỗi chuyển phòng: " + ex.Message;
            }
            return RedirectToAction("SoDoPhong");
        }

        // ==========================================
        // 5. TRẢ PHÒNG & THANH TOÁN (Trigger Demo)
        // Trigger: trg_CheckOut_UpdateTrangThaiPhong (Tự động đổi trạng thái phòng -> Chờ dọn)
        // Function: fn_TinhTienCheckOutSom (Tính phụ phí)
        // ==========================================
        public ActionResult CheckOut(int maDatPhong)
        {
            // Lấy chi tiết hóa đơn tạm tính để hiển thị
            var model = new CheckOutVM();
            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();
                // Gọi SP sp_ThongTinDatPhong để lấy tổng tiền tính đến hiện tại
                using (var cmd = new SqlCommand("sp_ThongTinDatPhong", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@MaDatPhong", maDatPhong);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            model.MaDatPhong = maDatPhong;
                            model.TenKhach = rd["HoTen"].ToString();
                            model.TongTienPhong = Convert.ToDecimal(rd["TongTienPhongDenHienTai"]);
                            model.TongTienDV = Convert.ToDecimal(rd["TongTienDichVu"]);
                            model.TongCong = Convert.ToDecimal(rd["TongTienHienTai"]);
                        }
                    }
                }
            }
            return View(model);
        }

        [HttpPost]
        public ActionResult ConfirmCheckOut(int maDatPhong, decimal tongTien, string phuongThuc)
        {
            try
            {
                using (var conn = new SqlConnection(conStr))
                {
                    conn.Open();
                    // 1. Cập nhật trạng thái DatPhong -> Đã trả
                    string sqlUpdate = "UPDATE DatPhong SET TrangThai = N'Đã trả', NgayTra = GETDATE() WHERE MaDatPhong = @id";
                    using (var cmd = new SqlCommand(sqlUpdate, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", maDatPhong);
                        cmd.ExecuteNonQuery();
                    }

                    // 2. Insert vào ThanhToan 
                    // HÀNH ĐỘNG NÀY SẼ KÍCH HOẠT TRIGGER [trg_CheckOut_UpdateTrangThaiPhong] trong file Trigger.sql
                    // Trigger sẽ tự động chuyển phòng sang 'Chờ dọn'
                    string sqlPay = @"INSERT INTO ThanhToan (MaDatPhong, PhuongThuc, SoTien, TrangThai) 
                              VALUES (@id, @pt, @tien, N'Đã thanh toán')";
                    using (var cmd = new SqlCommand(sqlPay, conn))
                    {
                        cmd.Parameters.AddWithValue("@id", maDatPhong);
                        cmd.Parameters.AddWithValue("@pt", phuongThuc);
                        cmd.Parameters.AddWithValue("@tien", tongTien);
                        cmd.ExecuteNonQuery();
                    }
                }
                TempData["Msg"] = "Thanh toán thành công! Phòng đã chuyển sang trạng thái 'Chờ dọn'.";
            }
            catch (Exception ex)
            {
                TempData["Err"] = "Lỗi: " + ex.Message;
            }
            return RedirectToAction("SoDoPhong");
        }


        // ==========================================
        // 3. BÁO CÁO THỐNG KÊ (Dành cho Quản lý)
        // Gọi: sp_DoanhThuNgay, fn_DoanhThuThang, sp_BaoCaoDichVuBanChay
        // ==========================================
        public ActionResult BaoCao(DateTime? ngay, int? thang, int? nam)
        {
            DateTime d = ngay ?? DateTime.Today;
            int m = thang ?? DateTime.Today.Month;
            int y = nam ?? DateTime.Today.Year;

            var model = new BaoCaoTongHopVM
            {
                NgayBaoCao = d,
                Thang = m,
                Nam = y,
                DichVuBanChay = new List<DichVuTopVM>()
            };

            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();

                // 1. Gọi sp_DoanhThuNgay (Lấy thông tin ngày)
                using (var cmd = new SqlCommand("sp_DoanhThuNgay", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Ngay", d);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            model.DoanhThuNgay = new BaoCaoNgayVM
                            {
                                Ngay = Convert.ToDateTime(rd["Ngay"]),
                                SoBookingCheckout = Convert.ToInt32(rd["SoBookingCheckout"]),
                                SoPhongCheckout = Convert.ToInt32(rd["SoPhongCheckout"]),
                                DoanhThu = Convert.ToDecimal(rd["DoanhThu"])
                            };
                        }
                    }
                }

                // 2. Gọi Function fn_DoanhThuThang (Lấy tổng tháng)
                string sqlFn = "SELECT dbo.fn_DoanhThuThang(@T, @N)";
                using (var cmd = new SqlCommand(sqlFn, conn))
                {
                    cmd.Parameters.AddWithValue("@T", m);
                    cmd.Parameters.AddWithValue("@N", y);
                    object result = cmd.ExecuteScalar();
                    model.DoanhThuThang = result != DBNull.Value ? Convert.ToDecimal(result) : 0;
                }

                // 3. Gọi sp_BaoCaoDichVuBanChay (Lấy top dịch vụ)
                using (var cmd = new SqlCommand("sp_BaoCaoDichVuBanChay", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@Thang", m);
                    cmd.Parameters.AddWithValue("@Nam", y);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            model.DichVuBanChay.Add(new DichVuTopVM
                            {
                                TenDV = rd["TenDV"].ToString(),
                                SoLuot = Convert.ToInt32(rd["SoLuot"]),
                                DoanhThu = Convert.ToDecimal(rd["DoanhThu"]),
                                PhanTram = Convert.ToDecimal(rd["PhanTram"])
                            });
                        }
                    }
                }
            }

            return View(model);
        }
    }
}