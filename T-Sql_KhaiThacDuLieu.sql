----------- BẢNG KhachSan ------------------
-- 1.1. Lấy danh sách tất cả khách sạn đang hoạt động
SELECT MaSo, TenKS, SoDienThoai, DiaChi 
FROM KhachSan 
WHERE TrangThai = N'Hoạt động';

-- 1.2. Tìm khách sạn ở một thành phố cụ thể (ví dụ: TP.HCM)
SELECT * FROM KhachSan 
WHERE ThanhPho = N'TP. Hồ Chí Minh';

-- 1.3. Đếm số lượng khách sạn theo từng trạng thái
SELECT TrangThai, COUNT(*) AS SoLuong 
FROM KhachSan 
GROUP BY TrangThai;

-------------- Bảng LoaiPhong ---------------
-- 2.1. Liệt kê các loại phòng có giá cơ bản dưới 1.000.000 VNĐ
SELECT TenLoai, GiaCoBan, SucChuaNguoiLon 
FROM LoaiPhong 
WHERE GiaCoBan < 1000000;

-- 2.2. Sắp xếp các loại phòng theo sức chứa người lớn giảm dần
SELECT * FROM LoaiPhong 
ORDER BY SucChuaNguoiLon DESC;

-- 2.3. Xem thông tin loại phòng kèm tên khách sạn (Kết nối bảng)
SELECT lp.TenLoai, lp.GiaCoBan, ks.TenKS 
FROM LoaiPhong lp
JOIN KhachSan ks ON lp.MaKS = ks.MaKS;

------------- Bảng Phong --------------------
-- 3.1. Tìm tất cả các phòng đang ở trạng thái 'Sẵn sàng' để đón khách
SELECT SoPhong, Tang, GhiChu 
FROM Phong 
WHERE TrangThai = N'Sẵn sàng';

-- 3.2. Thống kê số lượng phòng theo từng tầng
SELECT Tang, COUNT(MaPhong) AS TongSoPhong 
FROM Phong 
GROUP BY Tang;

-- 3.3. Lấy thông tin phòng kèm tên loại phòng và giá tiền
SELECT p.SoPhong, lp.TenLoai, lp.GiaCoBan 
FROM Phong p
JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong;

-------------- Bảng dịch vụ ------------------
-- 4.1. Tìm kiếm dịch vụ theo tên (ví dụ: các dịch vụ liên quan đến ăn uống)
SELECT TenDV, DonGia, DonViTinh 
FROM DichVu 
WHERE TenDV LIKE N'%Ăn%' OR TenDV LIKE N'%Uống%';

-- 4.2. Liệt kê top 5 dịch vụ có đơn giá cao nhất
SELECT TOP 5 TenDV, DonGia 
FROM DichVu 
ORDER BY DonGia DESC;

-- 4.3. Xem các dịch vụ đang bị ngưng cung cấp
SELECT * FROM DichVu 
WHERE TrangThai = N'Ngưng cung cấp';

---------- Bảng khách hàng ------------------
-- 5.1. Tìm khách hàng theo số CCCD/Passport
SELECT HoTen, SoDienThoai, Email
FROM KhachHang 
WHERE CCCD = '001060006666';

-- 5.2. Liệt kê các khách hàng có quốc tịch nước ngoài (Khác Việt Nam)
SELECT * FROM KhachHang 
WHERE QuocTich <> N'Việt Nam';

-- 5.3. Đếm số lượng khách hàng đăng ký mới trong năm nay
SELECT COUNT(*) AS KhachMoiNamNay 
FROM KhachHang 
WHERE YEAR(NgayTao) = YEAR(GETDATE());

---------- Bảng đặt phòng ------------------
-- 6.1. Liệt kê các đơn đặt phòng cần Check-out ngày X
SELECT MaDatPhong, NgayNhan, NgayTra, TongTien 
FROM DatPhong 
WHERE NgayTra <= CAST('2024-04-15' AS DATE) AND TrangThai = N'Đang ở';

-- 6.2. Tính tổng doanh thu dự kiến từ các đơn đã đặt (chưa hủy)
SELECT SUM(TongTien) AS DoanhThuDuKien 
FROM DatPhong 
WHERE TrangThai <> N'Đã hủy';

-- 6.3. Lấy danh sách đặt phòng kèm tên khách hàng
SELECT dp.MaDatPhong, kh.HoTen, dp.NgayNhan, dp.NgayTra 
FROM DatPhong dp
JOIN KhachHang kh ON dp.MaKH = kh.MaKH;

---------------- Bảng ChiTietDatPhong -------------------
-- 7.1. Xem chi tiết các phòng của một Mã Đặt Phòng cụ thể (VD: Mã 10)
SELECT MaPhong, GiaCoBan, SoNguoi 
FROM ChiTietDatPhong 
WHERE MaDatPhong = 10;

-- 7.2. Liệt kê các chi tiết đặt phòng có số người ở ghép > 2
SELECT * FROM ChiTietDatPhong 
WHERE SoNguoi > 2;

-- 7.3. Kết nối để xem Số phòng thực tế khách đang ở trong chi tiết đặt phòng
SELECT ctdp.MaCT, p.SoPhong, ctdp.GiaCoBan 
FROM ChiTietDatPhong ctdp
JOIN Phong p ON ctdp.MaPhong = p.MaPhong;

-------------- Bảng SuDungDichVu ----------------------
-- 8.1. Tính tổng tiền dịch vụ đã sử dụng cho một chi tiết phòng (MaCT)
SELECT SUM(ThanhTien) AS TongTienDichVu 
FROM SuDungDichVu 
WHERE MaCT = 1;

-- 8.2. Liệt kê các lần sử dụng dịch vụ trong ngày hôm nay
SELECT * FROM SuDungDichVu 
WHERE CAST(NgaySuDung AS DATE) = CAST(GETDATE() AS DATE);

-- 8.3. Xem tên dịch vụ và số lượng khách đã gọi
SELECT dv.TenDV, SUM(sddv.SoLuong), SUM(sddv.ThanhTien)
FROM SuDungDichVu sddv
JOIN DichVu dv ON sddv.MaDV = dv.MaDV
Group by dv.TenDV, sddv.SoLuong, sddv.ThanhTien

---------------- Bảng ThanhToan ----------------------
-- 9.1. Thống kê tổng số tiền đã thu được theo từng phương thức thanh toán
SELECT PhuongThuc, SUM(SoTien) AS TongTien 
FROM ThanhToan 
GROUP BY PhuongThuc;

-- 9.2. Tìm các giao dịch thanh toán bị lỗi hoặc chờ xử lý
SELECT * FROM ThanhToan 
WHERE TrangThai IN (N'Lỗi', N'Chờ xử lý');

-- 9.3. Liệt kê các khoản thanh toán lớn hơn 5.000.000
SELECT * FROM ThanhToan 
WHERE SoTien > 5000000;

------------------- Bảng HoaDon -----------------------
-- 10.1. Lấy danh sách hóa đơn xuất trong tháng hiện tại
SELECT * FROM HoaDon 
WHERE MONTH(NgayLap) = MONTH(GETDATE()) AND YEAR(NgayLap) = YEAR(GETDATE());

-- 10.2. Tìm hóa đơn có tổng tiền cao nhất
SELECT TOP 1 * FROM HoaDon 
ORDER BY TongTien DESC;

-- 10.3. Xem hóa đơn kèm tên khách hàng (cần JOIN qua bảng DatPhong và KhachHang)
SELECT hd.MaHD, hd.NgayLap, hd.TongTien, kh.HoTen
FROM HoaDon hd
JOIN DatPhong dp ON hd.MaDatPhong = dp.MaDatPhong
JOIN KhachHang kh ON dp.MaKH = kh.MaKH;

---------------- Bảng ChiTietHoaDon -----------------------
-- 11.1. Xem chi tiết các mục thanh toán của hóa đơn số 5
SELECT LoaiMuc, MoTa, SoLuong, DonGia, ThanhTien 
FROM ChiTietHoaDon 
WHERE MaHD = 5;

-- 11.2. Thống kê doanh thu từ tiền phòng và tiền dịch vụ (dựa vào LoaiMuc)
SELECT LoaiMuc, SUM(ThanhTien) AS DoanhThu
FROM ChiTietHoaDon
GROUP BY LoaiMuc;

-- 11.3. Tìm các chi tiết hóa đơn có giá trị > 1.000.000
SELECT * FROM ChiTietHoaDon WHERE ThanhTien > 1000000;

---------------- Bảng LichSuTrangThai -----------------------
-- 12.1. Xem lịch sử thay đổi trạng thái của phòng 101
SELECT ls.* FROM LichSuTrangThai ls
JOIN Phong p ON ls.MaPhong = p.MaPhong
WHERE p.SoPhong = '101'
ORDER BY ls.NgayCapNhat DESC;

-- 12.2. Tìm các lần cập nhật trạng thái thực hiện bởi nhân viên 'admin'
SELECT * FROM LichSuTrangThai 
WHERE NguoiCapNhat = 'admin';

-- 12.3. Đếm số lần phòng bị chuyển sang trạng thái 'Bảo trì'
SELECT COUNT(*) AS SoLanBaoTri 
FROM LichSuTrangThai 
WHERE TrangThai = N'Bảo trì';

------------------ Bảng BaoTriPhong ----------------------
-- 13.1. Danh sách các phòng đang trong quá trình bảo trì (chưa kết thúc)
SELECT * FROM BaoTriPhong 
WHERE TrangThai = N'Đang sửa';

-- 13.2. Xem thông tin bảo trì kèm số phòng
SELECT p.SoPhong, bt.MoTa, bt.NgayBatDau 
FROM BaoTriPhong bt
JOIN Phong p ON bt.MaPhong = p.MaPhong;

-- 13.3. Liệt kê các đợt bảo trì đã hoàn thành trong năm nay
SELECT * FROM BaoTriPhong 
WHERE TrangThai = N'Hoàn thành' AND YEAR(NgayKetThuc) = YEAR(GETDATE());

----------------- Bảng NhanVien ---------------------
-- 14.1. Lấy danh sách nhân viên đang làm việc, sắp xếp theo tên
SELECT HoTen, ChucVu, SoDienThoai 
FROM NhanVien 
WHERE TrangThai = N'Đang làm việc'
ORDER BY HoTen;

-- 14.2. Thống kê số lượng nhân viên theo từng chức vụ
SELECT ChucVu, COUNT(*) AS SoLuong 
FROM NhanVien 
GROUP BY ChucVu;

-- 14.3. Tìm nhân viên có mức lương cơ bản trên 10 triệu
SELECT HoTen, ChucVu, LuongCoBan 
FROM NhanVien 
WHERE LuongCoBan > 10000000;

--------------- Bảng NguoiDung -------------------------
-- 15.1. Tìm tài khoản người dùng theo tên đăng nhập
SELECT * FROM NguoiDung 
WHERE TenDangNhap = 'admin';

-- 15.2. Liệt kê các tài khoản đang hoạt động kèm tên nhân viên sở hữu
SELECT nd.TenDangNhap, nd.VaiTro, nv.HoTen 
FROM NguoiDung nd
JOIN NhanVien nv ON nd.MaNV = nv.MaNV
WHERE nd.TrangThai = N'Hoạt động';

-- 15.3. Kiểm tra các tài khoản chưa đăng nhập trong 30 ngày qua
SELECT TenDangNhap, LanDangNhapCuoi 
FROM NguoiDung 
WHERE LanDangNhapCuoi < DATEADD(day, -30, GETDATE());

----------------- Bảng BlackList ------------------------
-- 16.1. Lấy danh sách khách hàng bị đưa vào danh sách đen kèm lý do
SELECT kh.HoTen, kh.CCCD, bl.LyDo, bl.MucDoViPham
FROM BlackList bl
JOIN KhachHang kh ON bl.MaKH = kh.MaKH;

-- 16.2. Tìm các vi phạm mức độ nặng (Mức 3)
SELECT * FROM BlackList WHERE MucDoViPham = 2;

-- 16.3. Đếm số lượng khách trong Blacklist theo từng mức độ
SELECT MucDoViPham, COUNT(*) AS SoLuong 
FROM BlackList 
GROUP BY MucDoViPham;

--------------------- Bảng NgayLe ----------------------
-- 17.1. Lấy tất cả các ngày lễ trong năm
SELECT * FROM NgayLe ORDER BY Ngay;

-- 17.2. Tìm ngày lễ trong tháng 12
SELECT * FROM NgayLe WHERE MONTH(Ngay) = 12;

-- 17.3. Tìm xem ngày cụ thể (ví dụ 02/09) có phải ngày lễ không
SELECT TenLe FROM NgayLe 
WHERE DAY(Ngay) = 2 AND MONTH(Ngay) = 9;