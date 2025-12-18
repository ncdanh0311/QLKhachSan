USE master;
GO

-- 1. Xóa CSDL cũ nếu tồn tại để tạo mới sạch sẽ
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QuanLyKhachSan_DatPhong')
BEGIN
    ALTER DATABASE QuanLyKhachSan_DatPhong SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyKhachSan_DatPhong;
END
GO

-- 2. Tạo CSDL Mới
CREATE DATABASE QuanLyKhachSan_DatPhong;
GO
USE QuanLyKhachSan_DatPhong;
GO

-- =============================================
-- BƯỚC 1: TẠO CÁC BẢNG DANH MỤC / ÍT PHỤ THUỘC
-- =============================================

-- 1.1. Bảng Khách Sạn (Gốc)
CREATE TABLE KhachSan (
    MaKS            INT IDENTITY(1,1) PRIMARY KEY,
    MaSo            VARCHAR(20) NOT NULL UNIQUE,
    TenKS           NVARCHAR(200) NOT NULL,
    DiaChi          NVARCHAR(300),
    ThanhPho        NVARCHAR(100),
    QuocGia         NVARCHAR(100),
    MuiGio          NVARCHAR(64),
    SoDienThoai     NVARCHAR(20),
    Email           NVARCHAR(100),
    TrangThai       NVARCHAR(20)  NOT NULL CONSTRAINT DF_KS_TrangThai DEFAULT(N'Hoạt động'),
    NgayTao         DATETIME2(0)  NOT NULL CONSTRAINT DF_KS_NgayTao DEFAULT (SYSUTCDATETIME()),
    NgayCapNhat     DATETIME2(0)  NOT NULL CONSTRAINT DF_KS_NgayCapNhat DEFAULT (SYSUTCDATETIME())
);
GO

-- 1.2. Bảng Loại Người Dùng (Phân quyền)
CREATE TABLE LoaiNguoiDung (
    MaLoaiND    INT IDENTITY(1,1) PRIMARY KEY,
    TenLoaiND   NVARCHAR(50) NOT NULL UNIQUE,
    MoTa        NVARCHAR(200)
);
GO

-- 1.3. Bảng Khách Hàng
CREATE TABLE KhachHang (
    MaKH          INT IDENTITY(1,1) PRIMARY KEY,
    HoTen         NVARCHAR(150) NOT NULL,
    GioiTinh      NVARCHAR(4),
    Email         NVARCHAR(100),
    SoDienThoai   NVARCHAR(20),
    CCCD          NVARCHAR(20),
    QuocTich      NVARCHAR(50),
    GhiChu        NVARCHAR(200),
    NgayTao       DATETIME2(0)  NOT NULL CONSTRAINT DF_KH_NgayTao DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT UQ_CCCD UNIQUE(CCCD),
    CONSTRAINT CK_KH_CCCD_Passport CHECK (LEN(CCCD) >= 6)  
);
GO

-- 1.4. Bảng Ngày Lễ
CREATE TABLE NgayLe (
    Ngay DATE PRIMARY KEY,
    TenLe NVARCHAR(100)
);
GO

-- =============================================
-- BƯỚC 2: TẠO CÁC BẢNG CẤP 2 (Phụ thuộc bước 1)
-- =============================================

-- 2.1. Loại Phòng (Thuộc Khách sạn)
CREATE TABLE LoaiPhong (
    MaLoaiPhong      INT IDENTITY(1,1) PRIMARY KEY,
    MaKS             INT NOT NULL,
    TenLoai          NVARCHAR(100) NOT NULL,
    SucChuaNguoiLon  TINYINT NOT NULL,
    SucChuaTreEm     TINYINT NOT NULL CONSTRAINT DF_LP_SucChuaTreEm DEFAULT(0),
    GiaCoBan         DECIMAL(12,2) NOT NULL,
    MoTa             NVARCHAR(500),
    CONSTRAINT FK_LoaiPhong_KhachSan FOREIGN KEY (MaKS) REFERENCES dbo.KhachSan(MaKS),
    CONSTRAINT CK_LP_SucChuaNguoiLon CHECK (SucChuaNguoiLon >= 1),
    CONSTRAINT CK_LP_GiaCoBan CHECK (GiaCoBan >= 0)
);
GO

-- 2.2. Dịch Vụ (Thuộc Khách sạn)
CREATE TABLE DichVu (
    MaDV        INT IDENTITY(1,1) PRIMARY KEY,
    MaKS        INT NOT NULL,
    MaSo        VARCHAR(20) NOT NULL UNIQUE,
    TenDV       NVARCHAR(150) NOT NULL,
    DonGia      DECIMAL(12,2) NOT NULL CONSTRAINT CK_DV_DonGia CHECK (DonGia >= 0),
    DonViTinh   NVARCHAR(50) NULL,
    MoTa        NVARCHAR(200) NULL,
    TrangThai   NVARCHAR(20) NOT NULL CONSTRAINT DF_DV_TrangThai DEFAULT(N'Hoạt động'),
    CONSTRAINT FK_DichVu_KhachSan FOREIGN KEY (MaKS) REFERENCES dbo.KhachSan(MaKS)
);
GO

-- 2.3. Nhân Viên (Thuộc Khách sạn)
CREATE TABLE NhanVien (
    MaNV            INT IDENTITY(1,1) PRIMARY KEY,
    MaKS            INT,
    HoTen           NVARCHAR(100) NOT NULL,
    NgaySinh        DATE,
    GioiTinh        NVARCHAR(10),
    SoDienThoai     VARCHAR(15) UNIQUE,
    CCCD            VARCHAR(20) UNIQUE NOT NULL,
    DiaChi          NVARCHAR(200),
    ChucVu          NVARCHAR(50), 
    LuongCoBan      DECIMAL(12,2) DEFAULT(0),
    NgayVaoLam      DATE DEFAULT(GETDATE()),
    TrangThai       NVARCHAR(20) DEFAULT(N'Đang làm việc'), 

    CONSTRAINT CK_NV_TrangThai CHECK (TrangThai IN (N'Đang làm việc', N'Đã nghỉ', N'Tạm nghỉ')),
    CONSTRAINT FK_NV_KS FOREIGN KEY (MaKS) REFERENCES KhachSan(MaKS)
);
GO

-- 2.4. BlackList (Thuộc Khách hàng)
CREATE TABLE BlackList (
    MaKH INT PRIMARY KEY,
    LyDo NVARCHAR(200),
    NgayTao DATE DEFAULT GETDATE(),
    MucDoViPham INT, -- 1=nhẹ, 2=vừa, 3=nặng
    CONSTRAINT FK_BLACKLST FOREIGN KEY(MaKH) REFERENCES KhachHang(MaKH)
);
GO

-- =============================================
-- BƯỚC 3: TẠO CÁC BẢNG CẤP 3 (Phụ thuộc bước 2)
-- =============================================

-- 3.1. Phong (Thuộc Loại phòng)
CREATE TABLE Phong (
    MaPhong       INT IDENTITY(1,1) PRIMARY KEY,
    MaLoaiPhong   INT NOT NULL,
    SoPhong       NVARCHAR(10) NOT NULL,
    Tang          INT,
    TrangThai     NVARCHAR(20) NOT NULL CONSTRAINT DF_Phong_TrangThai DEFAULT(N'Sẵn sàng'), 
    GhiChu        NVARCHAR(200),
    CONSTRAINT FK_Phong_LoaiPhong FOREIGN KEY (MaLoaiPhong) REFERENCES dbo.LoaiPhong(MaLoaiPhong),
);
GO

-- 3.2. Người Dùng (Thuộc Nhân viên & Loại Người Dùng)
CREATE TABLE NguoiDung (
    MaND            INT IDENTITY(1,1) PRIMARY KEY,
    MaNV            INT,
    TenDangNhap     NVARCHAR(50) NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(255) NOT NULL,
    HoTen           NVARCHAR(100) NOT NULL,
    MaLoaiND        INT NOT NULL,
    TrangThai       NVARCHAR(20) NOT NULL CONSTRAINT DF_ND_TrangThai DEFAULT(N'Hoạt động'),
    LanDangNhapCuoi DATETIME2(0),
    CONSTRAINT FK_NguoiDung_NhanVien FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV),
    CONSTRAINT FK_NguoiDung_LoaiND FOREIGN KEY (MaLoaiND) REFERENCES LoaiNguoiDung(MaLoaiND),
    CONSTRAINT UQ_MaND UNIQUE(MaNV) -- 1 NV chỉ có 1 Tài khoản
);
GO

-- =============================================
-- BƯỚC 4: TẠO CÁC BẢNG NGHIỆP VỤ (Đặt phòng, Bảo trì...)
-- =============================================

-- 4.1. Đặt Phòng (Thuộc Khách hàng & Người dùng)
CREATE TABLE DatPhong (
    MaDatPhong   INT IDENTITY(1,1) PRIMARY KEY,
    MaKH         INT NOT NULL,
    MaND         INT,
	MaLoaiPhong  INT NOT NULL,
	MaKS         INT NOT NULL,
    NgayDat      DATETIME2(0) NOT NULL CONSTRAINT DF_DP_NgayDat DEFAULT (SYSUTCDATETIME()),
    NgayNhan     DATETIME NOT NULL,
    NgayTra      DATETIME NOT NULL,
    TrangThai    NVARCHAR(20) NOT NULL CONSTRAINT DF_DP_TrangThai DEFAULT(N'Đang giữ chỗ'), 
    TongTien     DECIMAL(12,2) NOT NULL CONSTRAINT DF_DP_TongTien DEFAULT(0),
    GhiChu       NVARCHAR(200) ,
    CONSTRAINT FK_DatPhong_KhachHang FOREIGN KEY (MaKH) REFERENCES dbo.KhachHang(MaKH),
    CONSTRAINT FK_NGUOIDUNG_DATPHONG FOREIGN KEY(MaND) REFERENCES NguoiDung(MaND),
	CONSTRAINT FK_DatPhong_KhachSan FOREIGN KEY (MaKS) REFERENCES KhachSan(MaKS),
	Constraint fk_DatPhong_LoaiPhong foreign key(MaLoaiPhong) references LoaiPhong(MaLoaiPhong),
	constraint ck_dk2 check (ngaydat <= ngaynhan),
    CONSTRAINT CK_DP_Ngay CHECK (NgayNhan < NgayTra)
);
GO

-- 4.2. Lịch sử trạng thái phòng (Thuộc Phòng)
CREATE TABLE LichSuTrangThai (
    MaLichSu      INT IDENTITY(1,1) PRIMARY KEY,
    MaPhong       INT,
    TrangThai     NVARCHAR(20) NOT NULL, 
    NguoiCapNhat  NVARCHAR(100) NULL,
    NgayCapNhat   DATETIME2(0) NOT NULL CONSTRAINT DF_LSTS_Ngay DEFAULT (SYSUTCDATETIME()),
    GhiChu        NVARCHAR(200) ,
    CONSTRAINT FK_LSTS_Phong FOREIGN KEY (MaPhong) REFERENCES dbo.Phong(MaPhong)
);
GO

-- 4.3. Bảo trì phòng (Thuộc Phòng)
CREATE TABLE BaoTriPhong (
    MaBaoTri    INT IDENTITY(1,1) PRIMARY KEY,
    MaPhong     INT NOT NULL,
    MoTa        NVARCHAR(200) NOT NULL,
    TrangThai   NVARCHAR(20) NOT NULL CONSTRAINT DF_BTP_TrangThai DEFAULT(N'Đang sửa'),
    NgayBatDau  DATE NOT NULL,
    NgayKetThuc DATE ,
    CONSTRAINT FK_BTP_Phong FOREIGN KEY (MaPhong) REFERENCES dbo.Phong(MaPhong),
    CONSTRAINT CK_BTP_Ngay CHECK (NgayKetThuc IS NULL OR NgayBatDau <= NgayKetThuc)
);
GO

-- =============================================
-- BƯỚC 5: TẠO CÁC BẢNG CHI TIẾT & HÓA ĐƠN
-- =============================================

-- 5.1. Chi tiết đặt phòng (Thuộc Đặt phòng & Phòng)
CREATE TABLE ChiTietDatPhong (
    MaCT            INT IDENTITY(1,1),
    MaDatPhong      INT NOT NULL,
    MaPhong         INT, 
    GiaCoBan        DECIMAL(12,2),
    SoNguoi         TINYINT NOT NULL CONSTRAINT DF_CTDP_SoNguoi DEFAULT(1),
    GhiChu          NVARCHAR(200),
    CONSTRAINT PK_CTDP PRIMARY KEY(MaCT),
    CONSTRAINT FK_CTDP_DatPhong   FOREIGN KEY (MaDatPhong)  REFERENCES dbo.DatPhong(MaDatPhong),
    CONSTRAINT FK_CTDP_Phong      FOREIGN KEY (MaPhong)     REFERENCES dbo.Phong(MaPhong),
    CONSTRAINT CK_CTDP_Gia CHECK (GiaCoBan >= 0)
);
GO

-- 5.2. Thanh Toán (Thuộc Đặt phòng)
CREATE TABLE ThanhToan (
    MaTT        INT IDENTITY(1,1) PRIMARY KEY,
    MaDatPhong  INT NOT NULL,
    PhuongThuc  NVARCHAR(30) NOT NULL,
    SoTien      DECIMAL(12,2) NOT NULL,
    NgayTT      DATETIME2(0) NOT NULL CONSTRAINT DF_TT_NgayTT DEFAULT (SYSUTCDATETIME()),
    TrangThai   NVARCHAR(20) NOT NULL CONSTRAINT DF_TT_TrangThai DEFAULT(N'Đã thanh toán'), 
    GhiChu      NVARCHAR(200) NULL,
    CONSTRAINT FK_TT_DatPhong FOREIGN KEY (MaDatPhong) REFERENCES dbo.DatPhong(MaDatPhong),
    CONSTRAINT CK_TT_SoTien CHECK (SoTien >= 0)
);
GO

-- 5.3. Hóa Đơn (Thuộc Đặt phòng)
CREATE TABLE HoaDon (
    MaHD        INT IDENTITY(1,1) PRIMARY KEY,
    MaDatPhong  INT NOT NULL UNIQUE, 
    NgayLap     DATETIME2(0) NOT NULL CONSTRAINT DF_HD_NgayLap DEFAULT (SYSUTCDATETIME()),
    TongTien    DECIMAL(12,2) NOT NULL,
    TinhTrang   NVARCHAR(20) NOT NULL CONSTRAINT DF_HD_TinhTrang DEFAULT(N'Đã xuất'),
    CONSTRAINT FK_HD_DatPhong FOREIGN KEY (MaDatPhong) REFERENCES dbo.DatPhong(MaDatPhong),
    CONSTRAINT CK_HD_TongTien CHECK (TongTien >= 0)
);
GO

-- =============================================
-- BƯỚC 6: TẠO CÁC BẢNG CUỐI CÙNG
-- =============================================

-- 6.1. Sử dụng dịch vụ (Thuộc Chi tiết đặt phòng & Dịch vụ)
CREATE TABLE SuDungDichVu (
    MaSDDV      INT IDENTITY(1,1) PRIMARY KEY,
    MaCT        INT NOT NULL,
    MaDV        INT NOT NULL,
    SoLuong     DECIMAL(12,2) NOT NULL CONSTRAINT DF_SDDV_SoLuong DEFAULT(1),
    DonGia      DECIMAL(12,2),
    NgaySuDung  DATETIME2(0) NOT NULL CONSTRAINT DF_SDDV_Ngay DEFAULT (SYSUTCDATETIME()),
    GhiChu      NVARCHAR(200),
    ThanhTien   AS (ROUND(SoLuong * DonGia, 2)) PERSISTED,
    CONSTRAINT FK_SDDV_DatPhong FOREIGN KEY (MaCT) REFERENCES dbo.ChiTietDatPhong(MaCT),
    CONSTRAINT FK_SDDV_DichVu FOREIGN KEY (MaDV) REFERENCES dbo.DichVu(MaDV),
    CONSTRAINT CK_SDDV_SoLuong CHECK (SoLuong > 0)
);
GO

-- 6.2. Chi tiết hóa đơn (Thuộc Hóa đơn)
CREATE TABLE ChiTietHoaDon (
    MaCTHD      INT IDENTITY(1,1) PRIMARY KEY,
    MaHD        INT NOT NULL,
    LoaiMuc     NVARCHAR(30) NOT NULL, 
    MoTa        NVARCHAR(200) ,
    SoLuong     DECIMAL(12,2) NOT NULL CONSTRAINT DF_CTHD_SoLuong DEFAULT(1),
    DonGia      DECIMAL(12,2) NOT NULL,
    ThanhTien   AS (ROUND(SoLuong * DonGia, 2)) PERSISTED,
    CONSTRAINT FK_CTHD_HoaDon FOREIGN KEY (MaHD) REFERENCES dbo.HoaDon(MaHD),
    CONSTRAINT CK_CTHD_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_CTHD_DonGia CHECK (DonGia >= 0)
);
GO

-- =============================================
-- BƯỚC 7: Các bảng liên quan đến nội thất, vật dụng trong khách sạn
-- =============================================
-- 7.1. Bảng vật dụng
CREATE TABLE VatDung
(
    MaVatDung INT IDENTITY PRIMARY KEY,
    TenVatDung NVARCHAR(200) NOT NULL,
    DonViTinh NVARCHAR(50) NOT NULL,       -- cái, bộ, chiếc...
    GiaNhap DECIMAL(12,2) NOT NULL,        -- giá nhập kho
    GiaDenBu DECIMAL(12,2) NOT NULL,       -- giá khách phải đền
    TrangThai NVARCHAR(20) DEFAULT N'Đang sử dụng'
);

-- 7.2. Bảng Nhập Vật Dụng
CREATE TABLE NhapVatDung
(
    MaNhap INT IDENTITY PRIMARY KEY,
    MaNV INT NOT NULL,
    NgayNhap DATETIME2 DEFAULT SYSDATETIME(),
    GhiChu NVARCHAR(300)
	CONSTRAINT FK_NhapHang_NhanVien FOREIGN KEY(MaNV) REFERENCES NhanVien(MaNV)
);

-- 7.3. Bảng Chi tiết nhập vật dụng
CREATE TABLE ChiTietNhapVatDung
(
    MaNhap INT NOT NULL,
    MaVatDung INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGiaNhap DECIMAL(12,2) NOT NULL,

    PRIMARY KEY (MaNhap, MaVatDung),
    CONSTRAINT FK_CTNH_NH FOREIGN KEY (MaNhap)
        REFERENCES NhapVatDung(MaNhap),
    CONSTRAINT FK_CTNH_VD FOREIGN KEY (MaVatDung)
        REFERENCES VatDung(MaVatDung)
);

-- 7.4. Bảng vật dụng trong phòng
CREATE TABLE VatDungPhong
(
    MaPhong INT NOT NULL,
    MaVatDung INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong >= 0),

    CONSTRAINT PK_VatDungPhong PRIMARY KEY (MaPhong, MaVatDung),
    CONSTRAINT FK_VDP_Phong FOREIGN KEY (MaPhong)
        REFERENCES Phong(MaPhong),
    CONSTRAINT FK_VDP_VatDung FOREIGN KEY (MaVatDung)
        REFERENCES VatDung(MaVatDung)
);

-- 7.5. Bảng hư hỏng tài sản
CREATE TABLE HuHongTaiSan
(
    MaHuHong INT IDENTITY PRIMARY KEY,
    MaDatPhong INT NOT NULL,
    MaPhong INT NOT NULL,
    MaVatDung INT NOT NULL,

    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(12,2) NOT NULL,    
    MoTa NVARCHAR(300),

    NgayGhiNhan DATETIME2 DEFAULT SYSDATETIME(),
    TrangThai NVARCHAR(20) DEFAULT N'Chưa tính tiền',

    CONSTRAINT FK_HH_DP FOREIGN KEY (MaDatPhong)
        REFERENCES DatPhong(MaDatPhong),
    CONSTRAINT FK_HH_Phong FOREIGN KEY (MaPhong)
        REFERENCES Phong(MaPhong),
    CONSTRAINT FK_HH_VatDung FOREIGN KEY (MaVatDung)
        REFERENCES VatDung(MaVatDung)
);

-- =============================================
-- BƯỚC 8: THÊM CÁC RÀNG BUỘC CHECK (BUSINESS LOGIC)
-- =============================================

-- 8.1. Check trạng thái Khách Sạn
ALTER TABLE KhachSan
ADD CONSTRAINT CK_KhachSan_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Tạm ngưng', N'Bảo trì'));
GO

-- 8.2. Check trạng thái Phòng
ALTER TABLE Phong
ADD CONSTRAINT CK_Phong_TrangThai 
CHECK (TrangThai IN (N'Sẵn sàng', N'Đang có khách', N'Chờ dọn', N'Bảo trì'));
GO

-- 8.3. Check trạng thái Dịch Vụ
ALTER TABLE DichVu
ADD CONSTRAINT CK_DichVu_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Ngưng cung cấp', N'Hết hàng'));
GO

-- 8.4. Check trạng thái Đặt Phòng
ALTER TABLE DatPhong
ADD CONSTRAINT CK_DatPhong_TrangThai 
CHECK (TrangThai IN (N'Đang giữ chỗ', N'Đang ở', N'Đã trả', N'Đã hủy', N'Vắng mặt'));
GO

-- 8.5. Check tình trạng Hóa Đơn
ALTER TABLE HoaDon
ADD CONSTRAINT CK_HoaDon_TinhTrang 
CHECK (TinhTrang IN (N'Đã xuất', N'Đã hủy'));
GO

-- 8.6. Check trạng thái Thanh Toán
ALTER TABLE ThanhToan
ADD CONSTRAINT CK_ThanhToan_TrangThai 
CHECK (TrangThai IN (N'Đã thanh toán', N'Chờ xử lý', N'Hoàn tiền', N'Lỗi'));
GO

-- 8.7. Check trạng thái Bảo Trì
ALTER TABLE BaoTriPhong
ADD CONSTRAINT CK_BaoTri_TrangThai 
CHECK (TrangThai IN (N'Đang sửa', N'Hoàn thành', N'Đã hủy'));
GO

-- 8.8. Check trạng thái Người Dùng
ALTER TABLE NguoiDung
ADD CONSTRAINT CK_NguoiDung_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Đã khóa'));
GO

-- 8.9. Check trạng thái Vật Dụng
ALTER TABLE VatDung
ADD CONSTRAINT CHK_VatDung check(TrangThai in (N'Đang sử dụng', N'Ngừng sử dụng'))

-- 8.10 Check Giá Nhập vật dụng
ALTER TABLE ChiTietNhapVatDung
ADD CONSTRAINT CHK_DonGiaNhap check (DonGiaNhap > 0)

PRINT N'Tạo CSDL thành công!';

-- 8.11 Check Hư Hỏng Tài Sản
ALTER TABLE HuHongTaiSan
ADD CONSTRAINT CK_DonGia CHECK (DonGia > 0),
	CONSTRAINT CK_HuHongTaiSan_NgayGhiNhan CHECK (NgayGhiNhan <= GETDATE()),
	CONSTRAINT CK_TrangThai CHECK (TrangThai in (N'Chưa tính tiền', N'Đã tính tiền'))