using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;
using WebDatPhongKhachSan.Models;

namespace WebDatPhongKhachSan.Controllers
{
    public class LoaiPhongController : Controller
    {
        private readonly string conStr = ConfigurationManager.ConnectionStrings["QuanLyKhachSan_DatPhong"].ConnectionString;

        public ActionResult ChiTiet(int maLoaiPhong, DateTime? ngayNhan, DateTime? ngayTra)
        {
            var vm = GetDetail(maLoaiPhong, ngayNhan?.Date);
            if (vm == null) return HttpNotFound("Không tìm thấy loại phòng.");

            vm.NgayNhan = ngayNhan?.Date;
            vm.NgayTra = ngayTra?.Date;

            ValidateAndTinh(vm);
            return View(vm);
        }

        public JsonResult GiaTheoNgay(int maLoaiPhong, DateTime? ngayNhan)
        {
            DateTime? d = ngayNhan?.Date;
            var vm = GetDetail(maLoaiPhong, d);
            if (vm == null) return Json(new { ok = false, message = "Không tìm thấy loại phòng." }, JsonRequestBehavior.AllowGet);

            var giaMoiDem = (vm.GiaTheoNgay ?? vm.GiaCoBan);

            return Json(new
            {
                ok = true,
                giaCoBan = vm.GiaCoBan,
                giaTheoNgay = vm.GiaTheoNgay,
                giaMoiDem = giaMoiDem
            }, JsonRequestBehavior.AllowGet);
        }

        // ✅ POST: bấm Đặt ngay -> INSERT DatPhong + ChiTietDatPhong
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DatPhong(LoaiPhongDetailVM model)
        {
            // reload DB để chống sửa giá
            var vm = GetDetail(model.MaLoaiPhong, model.NgayNhan?.Date);
            if (vm == null) return HttpNotFound("Không tìm thấy loại phòng.");

            // copy input
            vm.NgayNhan = model.NgayNhan?.Date;
            vm.NgayTra = model.NgayTra?.Date;
            vm.SoNguoiLon = model.SoNguoiLon;
            vm.SoTreEm = model.SoTreEm;
            vm.SoPhong = model.SoPhong;

            vm.HoTen = (model.HoTen ?? "").Trim();
            vm.SDT = (model.SDT ?? "").Trim();
            vm.GhiChu = model.GhiChu;
            vm.CCCD = (model.CCCD ?? "").Trim();
            vm.Email = (model.Email ?? "").Trim();
            vm.GioiTinh = string.IsNullOrWhiteSpace(model.GioiTinh) ? null : model.GioiTinh.Trim();
            vm.QuocTich = (model.QuocTich ?? "").Trim();

            // validate + tính
            bool ok = ValidateAndTinh(vm);
            ok = ok && ValidateThongTinNguoiDat(vm);

            if (!ok) return View("ChiTiet", vm);

            // giá áp dụng/đêm (theo ngày nhận)
            decimal giaMoiDem = vm.GiaTheoNgay ?? vm.GiaCoBan;

            // INSERT DB
            try
            {
                int maDatPhong = InsertDatPhongAndChiTiet(vm, giaMoiDem);

                vm.ThongBao = $"✅ Đã giữ chỗ thành công! Mã đặt phòng: {maDatPhong} (Trạng thái: Đang giữ chỗ).";
            }
            catch (Exception ex)
            {
                vm.ThongBao = "❌ Lỗi lưu đặt phòng: " + ex.Message;
            }

            // hiển thị lại trang chi tiết
            return View("ChiTiet", vm);
        }

        // ================== DB HELPERS ==================

        private int InsertDatPhongAndChiTiet(LoaiPhongDetailVM vm, decimal giaMoiDem)
        {
            using (var conn = new SqlConnection(conStr))
            {
                conn.Open();
                using (var tran = conn.BeginTransaction())
                {
                    try
                    {
                        // 0) Upsert khách hàng -> lấy MaKH
                        int maKH = UpsertKhachHang(conn, tran, vm);

                        // 1) Insert DatPhong (MaND có thể NULL)
                        const string sqlDatPhong = @"
INSERT INTO DatPhong (MaKH, NgayDat, NgayNhan, NgayTra, TrangThai, TongTien, GhiChu, MaND)
VALUES (@MaKH, GETDATE(), @NgayNhan, @NgayTra, N'Đang giữ chỗ', @TongTien, @GhiChu, @MaND);
SELECT CAST(SCOPE_IDENTITY() AS INT);";

                        object maND = DBNull.Value;
                        // Nếu bạn có login Admin/ND thì lấy từ Session (tùy bạn đang lưu key gì)
                        if (Session != null && Session["MaND"] != null)
                            maND = Session["MaND"];

                        string ghiChuDatPhong = BuildGhiChuDatPhong(vm);

                        int maDatPhong;
                        using (var cmd = new SqlCommand(sqlDatPhong, conn, tran))
                        {
                            cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH; // chắc chắn có
                            cmd.Parameters.Add("@NgayNhan", SqlDbType.Date).Value = vm.NgayNhan.Value.Date;
                            cmd.Parameters.Add("@NgayTra", SqlDbType.Date).Value = vm.NgayTra.Value.Date;
                            cmd.Parameters.Add("@TongTien", SqlDbType.Decimal).Value = vm.TongTienDuKien.Value;
                            cmd.Parameters.Add("@GhiChu", SqlDbType.NVarChar, 255).Value =
                                (object)Truncate(ghiChuDatPhong, 255) ?? DBNull.Value;
                            cmd.Parameters.Add("@MaND", SqlDbType.Int).Value = maND;

                            maDatPhong = (int)cmd.ExecuteScalar();
                        }

                        // 2) Insert ChiTietDatPhong (MaPhong = NULL đúng yêu cầu)
                        const string sqlCT = @"
INSERT INTO ChiTietDatPhong (MaDatPhong, MaPhong, GiaCoBan, SoNguoi, GhiChu)
VALUES (@MaDatPhong, NULL, @GiaCoBan, @SoNguoi, @GhiChu);";

                        using (var cmd = new SqlCommand(sqlCT, conn, tran))
                        {
                            cmd.Parameters.Add("@MaDatPhong", SqlDbType.Int).Value = maDatPhong;
                            cmd.Parameters.Add("@GiaCoBan", SqlDbType.Decimal).Value = giaMoiDem;
                            cmd.Parameters.Add("@SoNguoi", SqlDbType.Int).Value = vm.TongNguoi;
                            cmd.Parameters.Add("@GhiChu", SqlDbType.NVarChar, 255).Value =
                                (object)Truncate(vm.GhiChu, 255) ?? DBNull.Value;

                            cmd.ExecuteNonQuery();
                        }

                        tran.Commit();
                        return maDatPhong;
                    }
                    catch
                    {
                        tran.Rollback();
                        throw;
                    }
                }
            }
        }
        private int UpsertKhachHang(SqlConnection conn, SqlTransaction tran, LoaiPhongDetailVM vm)
        {
            using (var cmd = new SqlCommand("sp_UpsertKhachHang", conn, tran))
            {
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.Add("@HoTen", SqlDbType.NVarChar, 150).Value = (object)vm.HoTen ?? DBNull.Value;
                cmd.Parameters.Add("@CCCD", SqlDbType.NVarChar, 20).Value = (object)vm.CCCD ?? DBNull.Value;

                cmd.Parameters.Add("@SoDienThoai", SqlDbType.NVarChar, 20).Value =
                    string.IsNullOrWhiteSpace(vm.SDT) ? (object)DBNull.Value : vm.SDT;

                cmd.Parameters.Add("@GioiTinh", SqlDbType.NVarChar, 4).Value =
                    string.IsNullOrWhiteSpace(vm.GioiTinh) ? (object)DBNull.Value : vm.GioiTinh;

                cmd.Parameters.Add("@Email", SqlDbType.NVarChar, 100).Value =
                    string.IsNullOrWhiteSpace(vm.Email) ? (object)DBNull.Value : vm.Email;

                cmd.Parameters.Add("@QuocTich", SqlDbType.NVarChar, 50).Value =
                    string.IsNullOrWhiteSpace(vm.QuocTich) ? (object)DBNull.Value : vm.QuocTich;

                cmd.Parameters.Add("@GhiChu", SqlDbType.NVarChar, 200).Value =
                    string.IsNullOrWhiteSpace(vm.GhiChu) ? (object)DBNull.Value : Truncate(vm.GhiChu, 200);

                var outMaKH = new SqlParameter("@MaKH_Output", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outMaKH);

                cmd.ExecuteNonQuery();

                return (outMaKH.Value == DBNull.Value) ? 0 : Convert.ToInt32(outMaKH.Value);
            }
        }


        private static string BuildGhiChuDatPhong(LoaiPhongDetailVM vm)
        {
            // Bạn muốn lưu HoTen + SDT ở DatPhong nhưng DB không có cột -> gộp vào GhiChu.
            // Nếu bạn có bảng KhachHang/cột riêng thì nói mình đổi chuẩn.
            var baseInfo = $"Họ tên: {vm.HoTen} | SĐT: {vm.SDT}";
            if (string.IsNullOrWhiteSpace(vm.GhiChu)) return baseInfo;
            return baseInfo + " | Ghi chú: " + vm.GhiChu.Trim();
        }

        private static string Truncate(string s, int max)
        {
            if (string.IsNullOrWhiteSpace(s)) return null;
            s = s.Trim();
            return s.Length <= max ? s : s.Substring(0, max);
        }

        // ================== GET DETAIL + VALIDATE/TINH ==================

        private LoaiPhongDetailVM GetDetail(int maLoaiPhong, DateTime? ngayNhan)
        {
            using (var conn = new SqlConnection(conStr))
            {
                const string sql = @"
SELECT
    lp.MaLoaiPhong, lp.MaKS, lp.TenLoai, lp.SucChuaNguoiLon, lp.SucChuaTreEm,
    lp.GiaCoBan,
    CASE WHEN @NgayNhan IS NULL THEN NULL
         ELSE dbo.fn_TinhGiaPhongTheoNgay(@NgayNhan, lp.GiaCoBan)
    END AS GiaTheoNgay,
    lp.MoTa,
    ks.TenKS, ks.DiaChi, ks.ThanhPho, ks.QuocGia
FROM LoaiPhong lp
JOIN KhachSan ks ON ks.MaKS = lp.MaKS
WHERE lp.MaLoaiPhong = @MaLoaiPhong;";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaLoaiPhong", maLoaiPhong);
                    cmd.Parameters.AddWithValue("@NgayNhan", (object)ngayNhan ?? DBNull.Value);

                    conn.Open();
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read()) return null;

                        int maLoai = (int)rd["MaLoaiPhong"];

                        var gallery = new[]
                        {
                            $"https://source.unsplash.com/1600x1000/?hotel-room,bedroom&sig={maLoai * 11}",
                            $"https://source.unsplash.com/1600x1000/?hotel-room,bathroom&sig={maLoai * 13}",
                            $"https://source.unsplash.com/1600x1000/?hotel-room,interior&sig={maLoai * 17}",
                            $"https://source.unsplash.com/1600x1000/?hotel,view&sig={maLoai * 19}",
                        };

                        return new LoaiPhongDetailVM
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
                            DiaChi = rd["DiaChi"]?.ToString(),
                            ThanhPho = rd["ThanhPho"]?.ToString(),
                            QuocGia = rd["QuocGia"]?.ToString(),

                            Gallery = gallery
                        };
                    }
                }
            }
        }

        private bool ValidateThongTinNguoiDat(LoaiPhongDetailVM vm)
        {
            if (string.IsNullOrWhiteSpace(vm.HoTen))
            {
                vm.ThongBao = "Vui lòng nhập họ tên người đặt.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(vm.SDT))
            {
                vm.ThongBao = "Vui lòng nhập số điện thoại.";
                return false;
            }
            if (string.IsNullOrWhiteSpace(vm.CCCD))
            {
                vm.ThongBao = "Vui lòng nhập CCCD.";
                return false;
            }

            // chỉ lấy số
            var cccdDigits = "";
            foreach (var ch in vm.CCCD) if (char.IsDigit(ch)) cccdDigits += ch;

            // CCCD thường 9 hoặc 12 số (tuỳ bạn siết 12)
            if (cccdDigits.Length != 12 && cccdDigits.Length != 9)
            {
                vm.ThongBao = "CCCD không hợp lệ (9 hoặc 12 chữ số).";
                return false;
            }
            vm.CCCD = cccdDigits;

            // ràng buộc đơn giản: chỉ cho số + dài 9-11
            var digits = "";
            foreach (var ch in vm.SDT) if (char.IsDigit(ch)) digits += ch;

            if (digits.Length < 9 || digits.Length > 11)
            {
                vm.ThongBao = "Số điện thoại không hợp lệ (9–11 chữ số).";
                return false;
            }

            vm.SDT = digits; // chuẩn hoá
            return true;
        }

        private bool ValidateAndTinh(LoaiPhongDetailVM vm)
        {
            vm.SoDem = 0;
            vm.TongTienDuKien = null;

            if (vm.SoPhong <= 0) vm.SoPhong = 1;
            if (vm.SoNguoiLon <= 0) vm.SoNguoiLon = 1;
            if (vm.SoTreEm < 0) vm.SoTreEm = 0;

            // sức chứa theo 1 phòng
            if (vm.SoNguoiLon > vm.SucChuaNguoiLon)
            {
                vm.ThongBao = $"Số người lớn tối đa cho loại phòng này là {vm.SucChuaNguoiLon}.";
                return false;
            }
            if (vm.SoTreEm > vm.SucChuaTreEm)
            {
                vm.ThongBao = $"Số trẻ em tối đa cho loại phòng này là {vm.SucChuaTreEm}.";
                return false;
            }

            if (!vm.NgayNhan.HasValue || !vm.NgayTra.HasValue)
            {
                vm.ThongBao = "Vui lòng chọn đầy đủ ngày nhận và ngày trả.";
                return false;
            }
            if (vm.NgayTra.Value.Date <= vm.NgayNhan.Value.Date)
            {
                vm.ThongBao = "Ngày trả phải lớn hơn ngày nhận.";
                return false;
            }

            vm.SoDem = (vm.NgayTra.Value.Date - vm.NgayNhan.Value.Date).Days;
            var giaMoiDem = vm.GiaTheoNgay ?? vm.GiaCoBan;

            vm.TongTienDuKien = giaMoiDem * vm.SoDem * vm.SoPhong;
            return true;
        }
    }
}
