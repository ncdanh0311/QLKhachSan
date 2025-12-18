USE QuanLyKhachSan_DatPhong;
GO

-- BƯỚC 1: Vô hiệu hóa tất cả các ràng buộc khóa ngoại (Foreign Keys)
-- Điều này giúp ta xóa dữ liệu ở bảng cha/con theo bất kỳ thứ tự nào mà không bị lỗi
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
GO

-- BƯỚC 2: Xóa sạch dữ liệu trong các bảng
DELETE FROM ChiTietHoaDon;
DELETE FROM HoaDon;
DELETE FROM ThanhToan;
DELETE FROM SuDungDichVu;
DELETE FROM ChiTietDatPhong;
DELETE FROM BaoTriPhong;
DELETE FROM LichSuTrangThai;
DELETE FROM DatPhong;
DELETE FROM BlackList;
DELETE FROM NguoiDung;
DELETE FROM LoaiNguoiDung;
DELETE FROM NhanVien;
DELETE FROM DichVu;
DELETE FROM Phong;
DELETE FROM LoaiPhong;
DELETE FROM KhachSan;
DELETE FROM KhachHang;
DELETE FROM NgayLe;
GO

-- BƯỚC 3: Reset bộ đếm Identity về 0 (để dòng nhập tiếp theo sẽ là 1)
-- Lưu ý: Chỉ chạy lệnh này cho các bảng có cột IDENTITY(1,1)

DBCC CHECKIDENT ('ChiTietHoaDon', RESEED, 0);
DBCC CHECKIDENT ('HoaDon', RESEED, 0);
DBCC CHECKIDENT ('ThanhToan', RESEED, 0);
DBCC CHECKIDENT ('SuDungDichVu', RESEED, 0);
DBCC CHECKIDENT ('ChiTietDatPhong', RESEED, 0);
DBCC CHECKIDENT ('BaoTriPhong', RESEED, 0);
DBCC CHECKIDENT ('LichSuTrangThai', RESEED, 0);
DBCC CHECKIDENT ('DatPhong', RESEED, 0);
-- Bảng BlackList dùng khóa chính là MaKH (không tự tăng) nên không cần reset
DBCC CHECKIDENT ('NguoiDung', RESEED, 0);
DBCC CHECKIDENT ('LoaiNguoiDung', RESEED, 0);
DBCC CHECKIDENT ('NhanVien', RESEED, 0);
DBCC CHECKIDENT ('DichVu', RESEED, 0);
DBCC CHECKIDENT ('Phong', RESEED, 0);
DBCC CHECKIDENT ('LoaiPhong', RESEED, 0);
DBCC CHECKIDENT ('KhachSan', RESEED, 0);
DBCC CHECKIDENT ('KhachHang', RESEED, 0);
-- Bảng NgayLe khóa chính là Date (không tự tăng) nên không cần reset
GO

-- BƯỚC 4: Kích hoạt lại tất cả các ràng buộc khóa ngoại
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";
GO

PRINT N'Đã xóa toàn bộ dữ liệu và reset ID thành công!';

INSERT INTO LoaiNguoiDung (TenLoaiND, MoTa) VALUES
(N'Admin hệ thống', N'Quản trị toàn bộ hệ thống'),
(N'Quản lý khách sạn', N'Quản lý một hoặc nhiều khách sạn'),
(N'Lễ tân', N'Nhân viên lễ tân xử lý đặt phòng'),
(N'Nhân viên', N'Nhân viên nội bộ khác'),
(N'Khách hàng', N'Tài khoản khách hàng đặt phòng online');



INSERT INTO KhachSan
(
    MaSo,
    TenKS,
    DiaChi,
    ThanhPho,
    QuocGia,
    MuiGio,
    SoDienThoai,
    Email,
    TrangThai
)
VALUES
-- Chi nhánh Hà Nội
(
    'VP-HN-01',
    N'Vinpearl Hotel Hà Nội',
    N'191 Bà Triệu, Hai Bà Trưng',
    N'Hà Nội',
    N'Việt Nam',
    N'Asia/Ho_Chi_Minh',
    '02439788888',
    'hanoi@vinpearl.com',
    N'Hoạt động'
),

-- Chi nhánh TP.HCM
(
    'VP-HCM-01',
    N'Vinpearl Landmark 81, TP.HCM',
    N'720A Điện Biên Phủ, Bình Thạnh',
    N'TP. Hồ Chí Minh',
    N'Việt Nam',
    N'Asia/Ho_Chi_Minh',
    '02839718888',
    'hcm@vinpearl.com',
    N'Hoạt động'
),

-- Chi nhánh Đà Nẵng
(
    'VP-DN-01',
    N'Vinpearl Condotel Riverfront Đà Nẵng',
    N'341 Trần Hưng Đạo, Sơn Trà',
    N'Đà Nẵng',
    N'Việt Nam',
    N'Asia/Ho_Chi_Minh',
    '02363998888',
    'danang@vinpearl.com',
    N'Hoạt động'
),

-- Chi nhánh Nha Trang
(
    'VP-NT-01',
    N'Vinpearl Resort Nha Trang',
    N'Đảo Hòn Tre',
    N'Nha Trang',
    N'Việt Nam',
    N'Asia/Ho_Chi_Minh',
    '02583998888',
    'nhatrang@vinpearl.com',
    N'Hoạt động'
),

-- Chi nhánh Phú Quốc
(
    'VP-PQ-01',
    N'Vinpearl Resort & Spa Phú Quốc',
    N'Bãi Dài, Gành Dầu',
    N'Phú Quốc',
    N'Việt Nam',
    N'Asia/Ho_Chi_Minh',
    '02973998888',
    'phuquoc@vinpearl.com',
    N'Hoạt động'
);


INSERT INTO LoaiPhong (MaKS, TenLoai, SucChuaNguoiLon, SucChuaTreEm, GiaCoBan, MoTa)
VALUES
-- KS 1: Hà Nội
(1, N'Standard', 2, 1, 800000,  N'Phòng tiêu chuẩn Hà Nội'),
(1, N'Deluxe',   2, 2, 1200000, N'Phòng cao cấp Hà Nội'),
(1, N'Suite',    4, 2, 2500000, N'Phòng hạng sang Hà Nội'),

-- KS 2: TP.HCM
(2, N'Standard', 2, 1, 900000,  N'Phòng tiêu chuẩn TP.HCM'),
(2, N'Deluxe',   2, 2, 1400000, N'Phòng cao cấp TP.HCM'),
(2, N'Suite',    4, 2, 3000000, N'Phòng hạng sang TP.HCM'),

-- KS 3: Đà Nẵng
(3, N'Standard', 2, 1, 750000,  N'Phòng tiêu chuẩn Đà Nẵng'),
(3, N'Deluxe',   2, 2, 1100000, N'Phòng hướng sông Hàn'),
(3, N'Family',   4, 2, 1800000, N'Phòng gia đình'),

-- KS 4: Nha Trang
(4, N'Standard', 2, 1, 850000,  N'Phòng view biển'),
(4, N'Deluxe',   2, 2, 1300000, N'Phòng cao cấp view biển'),
(4, N'Villa',    6, 4, 5000000, N'Biệt thự nghỉ dưỡng'),

-- KS 5: Phú Quốc
(5, N'Standard', 2, 1, 900000,  N'Phòng nghỉ dưỡng'),
(5, N'Bungalow', 2, 2, 2000000, N'Bungalow riêng biệt'),
(5, N'Villa',    6, 4, 5500000, N'Villa biển cao cấp');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(1, 101, 1, N'Phòng tiêu chuẩn Hà Nội'),
(1, 102, 1,  N'Khách công tác'),
(1, 103, 1,  N'Khách vừa trả phòng');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(2, 201, 2, N'Phòng cao cấp Hà Nội'),
(2, 202, 2,  N'Khách du lịch'),
(2, 203, 2, N'Bảo trì nội thất');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(3, 301, 3,  N'Phòng hạng sang Hà Nội'),
(3, 302, 3,  N'Khách VIP'),
(3, 303, 3,  N'Dọn phòng sau checkout');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(4, 401, 4, N'Phòng tiêu chuẩn TP.HCM'),
(4, 402, 4,  N'Khách ở ngắn hạn'),
(4, 403, 4,  N'Đang chờ dọn phòng');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(5, 501, 5, N'Phòng cao cấp TP.HCM'),
(5, 502, 5,  N'Khách gia đình'),
(5, 503, 5, N'Sửa điều hòa');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(6, 601, 6, N'Phòng hạng sang TP.HCM'),
(6, 602, 6,  N'Khách VIP'),
(6, 603, 6,  N'Dọn phòng cao cấp');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(7, 701, 7, N'Phòng tiêu chuẩn Đà Nẵng'),
(7, 702, 7,  N'Khách du lịch'),
(7, 703, 7,  N'Chuẩn bị phòng mới');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(8, 801, 8, N'Phòng hướng sông Hàn'),
(8, 802, 8,  N'Khách gia đình'),
(8, 803, 8, N'Bảo trì ban công');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(9, 901, 9, N'Phòng gia đình'),
(9, 902, 9,  N'Gia đình 4 người'),
(9, 903, 9,  N'Dọn phòng gia đình');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(10, 1001, 10, N'Phòng view biển'),
(10, 1002, 10,  N'Khách nghỉ dưỡng'),
(10, 1003, 10,  N'Vệ sinh phòng');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(11, 1101, 11, N'Phòng cao cấp view biển'),
(11, 1102, 11,  N'Khách cặp đôi'),
(11, 1103, 11, N'Bảo trì cửa kính');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(12, 1201, 12, N'Biệt thự nghỉ dưỡng'),
(12, 1202, 12,  N'Khách VIP'),
(12, 1203, 12,  N'Dọn biệt thự');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(13, 1301, 13, N'Phòng nghỉ dưỡng'),
(13, 1302, 13,  N'Khách dài ngày'),
(13, 1303, 13,  N'Dọn phòng');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(14, 1401, 14, N'Bungalow riêng biệt'),
(14, 1402, 14,  N'Khách cặp đôi'),
(14, 1403, 14, N'Bảo trì mái');

INSERT INTO Phong (MaLoaiPhong, SoPhong, Tang, GhiChu)VALUES
(15, 1501, 15, N'Villa biển cao cấp'),
(15, 1502, 15, N'Gia đình VIP'),
(15, 1503, 15, N'Chuẩn bị đón khách mới');


INSERT INTO DichVu (MaKS, MaSo, TenDV, DonGia, DonViTinh, MoTa)
VALUES
-- KS 1: Hà Nội
(1, 'HN-AN',   N'Ăn sáng buffet', 200000, N'Người', N'Buffet sáng'),
(1, 'HN-GYM',  N'Phòng Gym',      100000, N'Lượt',  N'Gym cao cấp'),

-- KS 2: TP.HCM
(2, 'HCM-SPA', N'Spa thư giãn',    600000, N'Lần',   N'Spa cao cấp'),
(2, 'HCM-BAR', N'Bar SkyView',     300000, N'Lần',   N'Bar tầng cao'),

-- KS 3: Đà Nẵng
(3, 'DN-AN',   N'Ăn sáng',         180000, N'Người', N'Ăn sáng nhà hàng'),
(3, 'DN-TOUR', N'Tour Bà Nà',      1200000, N'Chuyến',N'Tour tham quan'),

-- KS 4: Nha Trang
(4, 'NT-SPA',  N'Spa biển',        550000, N'Lần',   N'Spa view biển'),
(4, 'NT-LAN',  N'Lặn biển',        800000, N'Lần',   N'Lặn ngắm san hô'),

-- KS 5: Phú Quốc
(5, 'PQ-DUA',  N'Đưa đón sân bay', 400000, N'Lượt',  N'Xe riêng'),
(5, 'PQ-TOUR', N'Tour đảo',        1500000, N'Chuyến',N'Tour 4 đảo');





-- =============================================
-- 1. INSERT KHÁCH HÀNG (25 khách - Dữ liệu sạch)
-- =============================================
INSERT INTO KhachHang (HoTen, GioiTinh, Email, SoDienThoai, CCCD, QuocTich, GhiChu) VALUES
(N'Nguyễn Văn Hùng', N'Nam', 'hung.nguyen@gmail.com', '0912345678', '001090012345', N'Việt Nam', N'Khách VIP'),
(N'Trần Thị Mai', N'Nữ', 'mai.tran@yahoo.com', '0987654321', '079189000001', N'Việt Nam', NULL),
(N'Lê Văn Đạt', N'Nam', 'dat.le@outlook.com', '0909123456', '001200009999', N'Việt Nam', N'Thích phòng yên tĩnh'),
(N'Phạm Thị Thanh', N'Nữ', 'thanh.pham@gmail.com', '0933888999', '044185001234', N'Việt Nam', NULL),
(N'Hoàng Minh Tuấn', N'Nam', 'tuan.hoang@company.vn', '0977111222', '036095005678', N'Việt Nam', N'Đi công tác'),
(N'Vũ Thị Lan Anh', N'Nữ', 'lananh.vu@gmail.com', '0918000111', '001192008888', N'Việt Nam', NULL),
(N'Đặng Văn Lâm', N'Nam', 'lam.dang@sport.vn', '0945678901', '034093007777', N'Việt Nam', N'Cầu thủ'),
(N'Ngô Bảo Châu', N'Nam', 'chau.ngo@math.edu', '0903456789', '001080004444', N'Việt Nam', N'Giáo sư'),
(N'Bùi Thị Xuân', N'Nữ', 'xuan.bui@history.vn', '0988777666', '079188002222', N'Việt Nam', NULL),
(N'Đỗ Nam Trung', N'Nam', 'trung.do@realestate.com', '0911222333', '001070003333', N'Việt Nam', NULL),
(N'John Wick', N'Nam', 'john.wick@continental.com', '0999666666', '555000111222', N'Mỹ', N'Yêu cầu đặc biệt về an ninh'),
(N'Tony Stark', N'Nam', 'tony@stark.com', '0909000001', '123456789012', N'Mỹ', N'Phòng tổng thống'),
(N'Natasha Romanoff', N'Nữ', 'natasha@shield.gov', '0909000002', '987654321098', N'Nga', NULL),
(N'Lý Tử Thất', N'Nữ', 'liziqi@china.cn', '0909000003', '079190005555', N'Trung Quốc', N'Thích không gian xanh'),
(N'Park Hang Seo', N'Nam', 'mr.park@korea.kr', '0909000004', '001060006666', N'Hàn Quốc', N'HLV Trưởng'),
(N'Trương Phi', N'Nam', 'phi.truong@tamquoc.vn', '0912333444', '001050007777', N'Việt Nam', N'Tính nóng'),
(N'Quan Vũ', N'Nam', 'vu.quan@tamquoc.vn', '0912555666', '001050008888', N'Việt Nam', N'Thích màu đỏ'),
(N'Lưu Bị', N'Nam', 'bi.luu@tamquoc.vn', '0912777888', '001050009999', N'Việt Nam', N'Khách quen'),
(N'Nguyễn Thúc Thùy Tiên', N'Nữ', 'tien.nguyen@miss.vn', '0934567890', '079198001111', N'Việt Nam', N'Hoa hậu'),
(N'Trấn Thành', N'Nam', 'thanh.tran@showbiz.vn', '0901234567', '079187002222', N'Việt Nam', N'MC'),
(N'Hồ Ngọc Hà', N'Nữ', 'ha.ho@singer.vn', '0909888777', '079184003333', N'Việt Nam', N'Ca sĩ'),
(N'Sơn Tùng MTP', N'Nam', 'tung.nguyen@mtp.vn', '0912345679', '034094004444', N'Việt Nam', N'Ca sĩ VIP'),
(N'Mỹ Tâm', N'Nữ', 'tam.my@hoa-mi.vn', '0987654322', '044181005555', N'Việt Nam', NULL),
(N'Đen Vâu', N'Nam', 'den.vau@rap.vn', '0909999888', '022089006666', N'Việt Nam', N'Thích view biển'),
(N'Bích Phương', N'Nữ', 'phuong.bich@idol.vn', '0912222333', '033089007777', N'Việt Nam', NULL);
GO

-- =============================================
-- 2. INSERT NHÂN VIÊN (25 nhân viên cho 5 KS)
-- =============================================
INSERT INTO NhanVien (MaKS, HoTen, NgaySinh, GioiTinh, SoDienThoai, CCCD, DiaChi, ChucVu, LuongCoBan, TrangThai) VALUES
-- KS 1: Hà Nội
(1, N'Phan Văn Khải', '1985-01-01', N'Nam', '0911000001', '001085000001', N'Ba Đình, Hà Nội', N'Giám đốc', 30000000, N'Đang làm việc'),
(1, N'Nguyễn Thu Hà', '1995-02-02', N'Nữ', '0911000002', '001095000002', N'Đống Đa, Hà Nội', N'Lễ tân', 8000000, N'Đang làm việc'),
(1, N'Trần Đức Bo', '1998-03-03', N'Nam', '0911000003', '001098000003', N'Cầu Giấy, Hà Nội', N'Phục vụ', 6000000, N'Đang làm việc'),
(1, N'Lê Thị Mận', '1990-04-04', N'Nữ', '0911000004', '001090000004', N'Hoàn Kiếm, Hà Nội', N'Buồng phòng', 6500000, N'Đang làm việc'),
(1, N'Hoàng Văn Thụ', '1992-05-05', N'Nam', '0911000005', '001092000005', N'Tây Hồ, Hà Nội', N'Bảo vệ', 7000000, N'Đang làm việc'),

-- KS 2: TP.HCM
(2, N'Nguyễn Phương Hằng', '1975-06-06', N'Nữ', '0902000001', '079175000001', N'Quận 1, TP.HCM', N'CEO', 50000000, N'Đang làm việc'),
(2, N'Huỳnh Uy Dũng', '1970-07-07', N'Nam', '0902000002', '079170000002', N'Bình Thạnh, TP.HCM', N'Quản lý', 35000000, N'Đang làm việc'),
(2, N'Trần Thanh Tâm', '2000-08-08', N'Nữ', '0902000003', '079200000003', N'Gò Vấp, TP.HCM', N'Marketing', 12000000, N'Đang làm việc'),
(2, N'Lê Dương Bảo Lâm', '1993-09-09', N'Nam', '0902000004', '079193000004', N'Quận 7, TP.HCM', N'Tổ chức sự kiện', 15000000, N'Đang làm việc'),
(2, N'Khả Như', '1994-10-10', N'Nữ', '0902000005', '079194000005', N'Quận 3, TP.HCM', N'Lễ tân', 8500000, N'Đang làm việc'),

-- KS 3: Đà Nẵng
(3, N'Phạm Nhật Vượng', '1968-11-11', N'Nam', '0903000001', '001068000001', N'Hải Châu, Đà Nẵng', N'Chủ tịch', 1, N'Đang làm việc'), -- Lương tượng trưng
(3, N'Đặng Lê Nguyên Vũ', '1971-12-12', N'Nam', '0903000002', '001071000002', N'Sơn Trà, Đà Nẵng', N'Cố vấn', 20000000, N'Đang làm việc'),
(3, N'Mai Phương Thúy', '1988-01-13', N'Nữ', '0903000003', '001088000003', N'Thanh Khê, Đà Nẵng', N'Kế toán', 18000000, N'Đang làm việc'),
(3, N'Võ Hoàng Yến', '1989-02-14', N'Nữ', '0903000004', '001089000004', N'Ngũ Hành Sơn, Đà Nẵng', N'Giám sát', 14000000, N'Đang làm việc'),
(3, N'Phạm Hương', '1991-03-15', N'Nữ', '0903000005', '001091000005', N'Liên Chiểu, Đà Nẵng', N'Lễ tân', 8000000, N'Đang làm việc'),

-- KS 4: Nha Trang
(4, N'H' + N'Hen Niê', '1992-04-16', N'Nữ', '0904000001', '001092000016', N'Nha Trang', N'Quản lý sảnh', 15000000, N'Đang làm việc'),
(4, N'Mâu Thủy', '1992-05-17', N'Nữ', '0904000002', '001092000017', N'Cam Ranh', N'Lễ tân', 8000000, N'Đang làm việc'),
(4, N'Hoàng Thùy', '1992-06-18', N'Nữ', '0904000003', '001092000018', N'Ninh Hòa', N'Buồng phòng', 6500000, N'Đang làm việc'),
(4, N'Lan Khuê', '1992-07-19', N'Nữ', '0904000004', '001092000019', N'Nha Trang', N'Spa Manager', 12000000, N'Đang làm việc'),
(4, N'Minh Tú', '1991-08-20', N'Nữ', '0904000005', '001091000020', N'Nha Trang', N'Bếp phó', 10000000, N'Đang làm việc'),

-- KS 5: Phú Quốc
(5, N'Hương Giang', '1991-09-21', N'Nữ', '0905000001', '001091000021', N'Dương Đông', N'Quản lý', 25000000, N'Đang làm việc'),
(5, N'Đức Phúc', '1996-10-22', N'Nam', '0905000002', '001096000022', N'An Thới', N'Hoạt náo viên', 9000000, N'Đang làm việc'),
(5, N'Erik', '1997-11-23', N'Nam', '0905000003', '001097000023', N'Dương Đông', N'Ca sĩ phòng trà', 15000000, N'Đang làm việc'),
(5, N'Hòa Minzy', '1995-12-24', N'Nữ', '0905000004', '001095000024', N'Gành Dầu', N'Chăm sóc khách hàng', 10000000, N'Đang làm việc'),
(5, N'Trường Giang', '1983-01-25', N'Nam', '0905000005', '001083000025', N'Dương Đông', N'Bếp trưởng', 20000000, N'Đang làm việc');
GO

-- =============================================
-- 3. INSERT NGƯỜI DÙNG (Tạo tài khoản cho NV - Password: 123456)
-- =============================================
INSERT INTO NguoiDung (MaNV, TenDangNhap, MatKhauHash, HoTen, MaLoaiND, TrangThai) VALUES
(1, 'admin_hn', '123456', N'Phan Văn Khải', 2, N'Hoạt động'),
(2, 'letan_hn', '123456', N'Nguyễn Thu Hà', 3, N'Hoạt động'),
(6, 'admin_hcm', '123456', N'Nguyễn Phương Hằng', 2, N'Hoạt động'),
(7, 'ql_hcm', '123456', N'Huỳnh Uy Dũng', 2, N'Hoạt động'),
(10, 'letan_hcm', '123456', N'Khả Như', 3, N'Hoạt động'),
(11, 'admin_dn', '123456', N'Phạm Nhật Vượng', 1, N'Hoạt động'), -- Admin hệ thống
(12, 'cov_dn', '123456', N'Đặng Lê Nguyên Vũ', 2, N'Hoạt động'),
(15, 'letan_dn', '123456', N'Phạm Hương', 3, N'Hoạt động'),
(16, 'admin_nt', '123456', N'H Hen Niê', 2, N'Hoạt động'),
(17, 'letan_nt', '123456', N'Mâu Thủy', 3, N'Hoạt động'),
(21, 'admin_pq', '123456', N'Hương Giang', 2, N'Hoạt động'),
(22, 'nv_pq_1', '123456', N'Đức Phúc', 4, N'Hoạt động'),
(3, 'nv_hn_1', '123456', N'Trần Đức Bo', 4, N'Hoạt động'),
(4, 'nv_hn_2', '123456', N'Lê Thị Mận', 4, N'Hoạt động'),
(5, 'nv_hn_3', '123456', N'Hoàng Văn Thụ', 4, N'Hoạt động'),
(8, 'nv_hcm_1', '123456', N'Trần Thanh Tâm', 4, N'Hoạt động'),
(9, 'nv_hcm_2', '123456', N'Lê Dương Bảo Lâm', 4, N'Hoạt động'),
(13, 'nv_dn_1', '123456', N'Mai Phương Thúy', 4, N'Hoạt động'),
(14, 'nv_dn_2', '123456', N'Võ Hoàng Yến', 4, N'Hoạt động'),
(18, 'nv_nt_1', '123456', N'Hoàng Thùy', 4, N'Hoạt động'),
(19, 'nv_nt_2', '123456', N'Lan Khuê', 4, N'Hoạt động'),
(20, 'nv_nt_3', '123456', N'Minh Tú', 4, N'Hoạt động'),
(23, 'nv_pq_2', '123456', N'Erik', 4, N'Hoạt động'),
(24, 'nv_pq_3', '123456', N'Hòa Minzy', 4, N'Hoạt động'),
(25, 'nv_pq_4', '123456', N'Trường Giang', 4, N'Hoạt động');
GO

-- =============================================
-- 4. INSERT BẢO TRÌ PHÒNG (Dữ liệu ngẫu nhiên sạch)
-- =============================================
INSERT INTO BaoTriPhong (MaPhong, MoTa, TrangThai, NgayBatDau, NgayKetThuc) VALUES
(1, N'Thay bóng đèn bị cháy', N'Hoàn thành', '2023-01-10', '2023-01-10'),
(2, N'Sửa điều hòa rò rỉ nước', N'Hoàn thành', '2023-02-15', '2023-02-16'),
(3, N'Sơn lại tường bị bẩn', N'Hoàn thành', '2023-03-20', '2023-03-22'),
(4, N'Thay vòi hoa sen', N'Hoàn thành', '2023-04-05', '2023-04-05'),
(5, N'Kiểm tra hệ thống PCCC', N'Hoàn thành', '2023-05-12', '2023-05-12'),
(6, N'Giặt rèm cửa', N'Hoàn thành', '2023-06-01', '2023-06-02'),
(7, N'Sửa khóa từ cửa ra vào', N'Hoàn thành', '2023-06-15', '2023-06-15'),
(8, N'Thông cống nhà vệ sinh', N'Hoàn thành', '2023-07-20', '2023-07-20'),
(9, N'Thay ga nệm định kỳ', N'Hoàn thành', '2023-08-01', '2023-08-01'),
(10, N'Bảo trì tủ lạnh', N'Hoàn thành', '2023-09-10', '2023-09-11'),
(11, N'Sửa tivi mất tín hiệu', N'Hoàn thành', '2023-10-05', '2023-10-05'),
(12, N'Chống thấm trần nhà', N'Hoàn thành', '2023-11-01', '2023-11-05'),
(13, N'Vệ sinh hồ bơi riêng (Villa)', N'Hoàn thành', '2023-12-20', '2023-12-20'),
(14, N'Thay pin két sắt', N'Hoàn thành', '2024-01-15', '2024-01-15'),
(15, N'Sửa cửa sổ kẹt', N'Hoàn thành', '2024-02-28', '2024-02-29'),
(1, N'Khử khuẩn phòng', N'Hoàn thành', '2024-03-10', '2024-03-10'),
(2, N'Kiểm tra máy nước nóng', N'Đang sửa', '2024-04-01', NULL), -- Đang sửa
(3, N'Thay sofa mới', N'Hoàn thành', '2024-03-15', '2024-03-15'),
(4, N'Sửa sàn gỗ bị phồng', N'Đang sửa', '2024-04-02', NULL), -- Đang sửa
(5, N'Bảo trì định kỳ quý 1', N'Hoàn thành', '2024-03-30', '2024-03-30'),
(6, N'Thay gương phòng tắm', N'Hoàn thành', '2024-01-20', '2024-01-20'),
(7, N'Sửa ấm đun siêu tốc', N'Hoàn thành', '2024-02-10', '2024-02-10'),
(8, N'Vệ sinh máy lạnh', N'Hoàn thành', '2024-03-05', '2024-03-05'),
(9, N'Kiểm tra ban công', N'Hoàn thành', '2024-03-12', '2024-03-12'),
(10, N'Thay thảm trải sàn', N'Đã hủy', '2024-04-01', '2024-04-01');
GO

-- =============================================
-- 5. INSERT ĐẶT PHÒNG (25 Đơn - TongTien để mặc định 0)
-- =============================================
INSERT INTO DatPhong
(MaKH, MaKS, NgayNhan, NgayTra, TrangThai, GhiChu, MaND, MaLoaiPhong)
VALUES
(1, 2, '2026-01-05', '2026-01-07', N'Đang giữ chỗ',  N'Khách đặt trước',      1, 1),
(2, 3, '2026-01-06', '2026-01-08', N'Đang giữ chỗ',  N'Khách chưa check-in',  2, 2),
(3, 1, '2026-01-07', '2026-01-10', N'Đang giữ chỗ',  N'Khách VIP',            1, 3),
(4, 1, '2026-01-08', '2026-01-09', N'Đang giữ chỗ',  N'Khách công tác',       2, 4),
(5, 2, '2026-01-10', '2026-01-12', N'Đang giữ chỗ',  N'Gia đình 4 người',     1, 5),
(6, 1, '2026-01-11', '2026-01-14', N'Đang giữ chỗ',  N'Khách nghỉ dưỡng',     3, 6),
(7, 3, '2026-01-12', '2026-01-13', N'Đang giữ chỗ',   N'Đặt phòng ngắn hạn',   2, 7),
(8, 2, '2026-01-13', '2026-01-16', N'Đang giữ chỗ',  N'Khách du lịch',        3, 8),
(9, 4, '2026-01-14', '2026-01-15', N'Đang giữ chỗ',  N'Đặt gấp trong ngày',   1, 9),
(10,4,'2026-01-15', '2026-01-18', N'Đang giữ chỗ', N'Khách villa cao cấp',  3, 15);

delete from DatPhong

-- =============================================
-- 6. INSERT CHI TIẾT ĐẶT PHÒNG (50 dòng - 2 phòng/đơn)
-- =============================================
-- Lưu ý: GiaCoBan để NULL để Trigger Tr_SetGiaCoBan của bạn tự điền (nếu chạy).
-- Nếu Trigger lỗi, bạn cần update tay sau. Ở đây tôi để NULL cho đúng bài.
INSERT INTO ChiTietDatPhong (MaDatPhong, MaPhong, GiaCoBan, SoNguoi, GhiChu) VALUES
-- Đơn 1
(1, 1, NULL, 2, N'Phòng sạch'), (1, 2, NULL, 2, N'Gần nhau'),
-- Đơn 2
(2, 4, NULL, 2, NULL), (2, 5, NULL, 2, NULL),
-- Đơn 3
(3, 7, NULL, 2, NULL), (3, 8, NULL, 2, NULL),
-- Đơn 4
(4, 10, NULL, 2, NULL), (4, 11, NULL, 2, NULL),
-- Đơn 5
(5, 13, NULL, 2, NULL), (5, 14, NULL, 2, NULL),
-- Đơn 6
(6, 3, NULL, 4, N'Giường đôi'), (6, 1, NULL, 2, NULL),
-- Đơn 7
(7, 6, NULL, 4, NULL), (7, 4, NULL, 2, NULL),
-- Đơn 8
(8, 9, NULL, 4, NULL), (8, 7, NULL, 2, NULL),
-- Đơn 9
(9, 12, NULL, 4, NULL), (9, 10, NULL, 2, NULL),
-- Đơn 10
(10, 15, NULL, 4, NULL), (10, 13, NULL, 2, NULL)
GO

-- =============================================
-- 7. INSERT SỬ DỤNG DỊCH VỤ (50 dòng)
-- =============================================
-- DonGia để NULL để Trigger Tr_SetDonGiaDichVu tự xử lý
INSERT INTO SuDungDichVu (MaCT, MaDV, SoLuong, DonGia, GhiChu) VALUES
-- Chi tiết đặt phòng 1 & 2
(1, 1, 2, NULL, N'Ăn sáng'), (1, 2, 1, NULL, N'Gym'),
(2, 1, 2, NULL, NULL), (2, 2, 1, NULL, NULL),
-- Chi tiết 3 & 4
(3, 3, 1, NULL, N'Spa'), (3, 4, 2, NULL, N'Bar'),
(4, 3, 1, NULL, NULL), (4, 4, 2, NULL, NULL),
-- Chi tiết 5 & 6
(5, 5, 2, NULL, N'Ăn sáng'), (5, 6, 1, NULL, N'Tour'),
(6, 5, 2, NULL, NULL), (6, 6, 1, NULL, NULL),
-- Chi tiết 7 & 8
(7, 7, 1, NULL, N'Spa'), (7, 8, 2, NULL, N'Lặn'),
(8, 7, 1, NULL, NULL), (8, 8, 2, NULL, NULL),
-- Chi tiết 9 & 10
(9, 9, 1, NULL, N'Đưa đón'), (9, 10, 1, NULL, N'Tour đảo'),
(10, 9, 1, NULL, NULL), (10, 10, 1, NULL, NULL)
GO

INSERT INTO VatDung (TenVatDung, DonViTinh, GiaNhap, GiaDenBu, TrangThai)
VALUES
(N'Máy giặt',        N'Cái', 7000000, 9000000,  N'Đang sử dụng'),
(N'Tủ lạnh',         N'Cái', 6000000, 8000000,  N'Đang sử dụng'),
(N'Bàn làm việc',    N'Cái', 2000000, 3000000,  N'Đang sử dụng'),
(N'Tivi',            N'Cái', 8000000, 10000000, N'Đang sử dụng'),
(N'Bồn nước',        N'Cái', 3000000, 4500000,  N'Đang sử dụng'),
(N'Giường ngủ',      N'Cái', 5000000, 7000000,  N'Đang sử dụng'),
(N'Máy nước nóng',   N'Cái', 2500000, 4000000,  N'Đang sử dụng'),
(N'Quạt điện',       N'Cái', 800000,  1200000,  N'Đang sử dụng'),
(N'Điều hòa',        N'Cái', 12000000,15000000, N'Đang sử dụng'),
(N'Đèn chiếu sáng',  N'Cái', 300000,  500000,   N'Đang sử dụng');


select * from DichVu
select * from Phong

------------ Quy Trình Đặt Phòng ------------------
declare @l Int
exec sp_UpsertKhachHang
	@HoTen = N'Nguyễn Duy Linh',
	@CCCD = '079205020446',
	@SoDienThoai = '0898107921',
	@GioiTinh = N'Nam',
	@MaKH_Output = @l output
select * from KhachHang

exec sp_DatPhong 26, 3, 5, 9, '2025-12-17 19:00', '2025-12-18 12:00'
select * from DatPhong


exec sp_CheckIn 11, 25
select * from Phong
where MaLoaiPhong = 9

select * from DatPhong

exec sp_ThemDichVu 25, 3, 2

select * from SuDungDichVu

exec sp_ThemDenBu 11, 25, 4, 1, N'Vỡ màn hình'

exec sp_CheckOut 11

exec sp_ThanhToan 11,N'Tiền mặt'
select * from HoaDon
select * from ChiTietHoaDon

Select * from DatPhong

exec sp_XacNhanDonPhong 25
select * from DatPhong

select * from HoaDon