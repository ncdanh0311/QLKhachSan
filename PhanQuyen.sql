USE QuanLyKhachSan_DatPhong;
GO

-- =============================================
-- 1. TẠO LOGIN (Cấp Server)
-- =============================================
CREATE LOGIN AdminHeThong WITH PASSWORD = '123';
CREATE LOGIN NhanVienLeTan WITH PASSWORD = '123';
CREATE LOGIN KeToan WITH PASSWORD = '123';
CREATE LOGIN NhanVienTapVu WITH PASSWORD = '123';
CREATE LOGIN Khach WITH PASSWORD = '123';
GO

-- =============================================
-- 2. TẠO USER (Cấp Database)
-- =============================================
CREATE USER AdminHeThong FOR LOGIN AdminHeThong;
CREATE USER NhanVienLeTan FOR LOGIN NhanVienLeTan;
CREATE USER KeToan FOR LOGIN KeToan;
CREATE USER NhanVienTapVu FOR LOGIN NhanVienTapVu;
CREATE USER KhachHang FOR LOGIN Khach; -- User tên KhachHang map với Login Khach
GO

-- =============================================
-- 3. TẠO ROLE (NHÓM QUYỀN)
-- =============================================
CREATE ROLE Role_AdminHeThong;
CREATE ROLE Role_NhanVienLeTan;
CREATE ROLE Role_KeToan;
CREATE ROLE Role_NhanVienTapVu;
CREATE ROLE Role_KhachHang;
GO

-- =============================================
-- 4. THÊM USER VÀO ROLE
-- =============================================
ALTER ROLE Role_AdminHeThong ADD MEMBER AdminHeThong;
ALTER ROLE Role_NhanVienLeTan ADD MEMBER NhanVienLeTan;
ALTER ROLE Role_KeToan ADD MEMBER KeToan;
ALTER ROLE Role_NhanVienTapVu ADD MEMBER NhanVienTapVu;
ALTER ROLE Role_KhachHang ADD MEMBER KhachHang;
GO

-- =============================================
-- 5. CẤP QUYỀN CHO ROLE (GRANT)
-- =============================================

-- 5.1. ROLE: AdminHeThong (Toàn quyền)
GRANT CONTROL ON DATABASE::QuanLyKhachSan_DatPhong TO Role_AdminHeThong;

-- 5.2. ROLE: NhanVienLeTan
-- Xem danh mục
GRANT SELECT ON LoaiPhong TO Role_NhanVienLeTan;
GRANT SELECT ON DichVu TO Role_NhanVienLeTan;
GRANT SELECT ON Phong TO Role_NhanVienLeTan;
-- Nghiệp vụ đặt phòng & Khách
GRANT SELECT, INSERT, UPDATE ON KhachHang TO Role_NhanVienLeTan;
GRANT SELECT, INSERT, UPDATE ON DatPhong TO Role_NhanVienLeTan;
GRANT SELECT, INSERT, UPDATE ON ChiTietDatPhong TO Role_NhanVienLeTan;
GRANT SELECT, INSERT, UPDATE ON SuDungDichVu TO Role_NhanVienLeTan;
-- Lễ tân thường được quyền thu tiền (Tạo phiếu thanh toán)
GRANT SELECT, INSERT ON ThanhToan TO Role_NhanVienLeTan; 

-- 5.3. ROLE: KeToan
-- Kế toán cần xem hầu hết mọi thứ để đối soát
GRANT SELECT ON KhachHang TO Role_KeToan;
GRANT SELECT ON DatPhong TO Role_KeToan;
GRANT SELECT ON ChiTietDatPhong TO Role_KeToan;
GRANT SELECT ON SuDungDichVu TO Role_KeToan;
-- Quyền chính trên Hóa đơn & Thanh toán
GRANT SELECT, INSERT, UPDATE ON HoaDon TO Role_KeToan;
GRANT SELECT, INSERT, UPDATE ON ChiTietHoaDon TO Role_KeToan; -- Bổ sung bảng này
GRANT SELECT, INSERT, UPDATE ON ThanhToan TO Role_KeToan;     -- Bổ sung bảng này

-- 5.4. ROLE: NhanVienTapVu
-- Chỉ cần xem phòng nào dơ để dọn và cập nhật lại trạng thái
GRANT SELECT, UPDATE ON Phong TO Role_NhanVienTapVu; 
-- Có thể xem lịch bảo trì
GRANT SELECT ON BaoTriPhong TO Role_NhanVienTapVu;

-- 5.5. ROLE: KhachHang
-- Khách chỉ được xem thông tin cơ bản
GRANT SELECT ON LoaiPhong TO Role_KhachHang; 
GRANT SELECT ON DichVu TO Role_KhachHang;   

-- =============================================
-- 6. THU HỒI QUYỀN (REVOKE / DENY)
-- =============================================
-- Thu hồi quyền UPDATE phòng của Lễ Tân (Nếu quy định Lễ tân chỉ check-in, ko được sửa số phòng)
REVOKE UPDATE ON Phong FROM Role_NhanVienLeTan;

-- Cấm tuyệt đối Tạp vụ xem doanh thu (Bảng HoaDon)
DENY SELECT ON HoaDon TO Role_NhanVienTapVu;
DENY SELECT ON ThanhToan TO Role_NhanVienTapVu;