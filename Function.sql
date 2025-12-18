-- Tính giá phòng theo ngày
CREATE FUNCTION fn_TinhGiaPhongTheoNgay
(
    @Ngay DATE,
    @GiaCoBan INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Gia INT = @GiaCoBan;

    -- Kiểm tra ngày lễ trong bảng
    IF EXISTS (SELECT 1 FROM NgayLe WHERE Ngay = @Ngay)
    BEGIN
        SET @Gia = @GiaCoBan * 1.2;
        RETURN @Gia;
    END

    -- Cuối tuần
    IF DATENAME(WEEKDAY, @Ngay) IN ('Saturday', 'Sunday')
        SET @Gia = @GiaCoBan + 100000;

    RETURN @Gia;
END
GO

--Tính tổng tiền dịch vụ
CREATE FUNCTION fn_TinhTongTienDichVu
(
    @MaDatPhong INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Tong DECIMAL(18,2);

    SELECT @Tong =
        ISNULL(SUM(SDDV.ThanhTien), 0)
    FROM ChiTietDatPhong CT
    LEFT JOIN SuDungDichVu SDDV ON CT.MaCT = SDDV.MaCT
    WHERE CT.MaDatPhong = @MaDatPhong;

    RETURN @Tong;
END;
GO

--Tính tiền khi khách check out sớm
CREATE OR ALTER FUNCTION fn_TinhTienCheckOutSom
(
    @MaDatPhong INT,
    @GioTraThucTe DATETIME2
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE 
        @NgayTra DATE,
        @NgayCuoi DATE,
        @Gio TIME,
        @GiaCuoi DECIMAL(18,2),
        @Tien DECIMAL(18,2) = 0;

    -- Lấy ngày trả phòng đã đăng ký
    SELECT @NgayTra = NgayTra 
    FROM DatPhong 
    WHERE MaDatPhong = @MaDatPhong;

    IF @NgayTra IS NULL RETURN 0;

    -- Ngày cuối khách ở (vì NgayTra là ngày khách rời đi)
    SET @NgayCuoi = DATEADD(DAY, -1, @NgayTra);

    -- Giờ trả thực tế
    SET @Gio = CAST(@GioTraThucTe AS TIME);

    -- Tính tổng giá của tất cả phòng trong ngày cuối
    SELECT @GiaCuoi = ISNULL(SUM(GiaCoBan), 0)
    FROM ChiTietDatPhong
    WHERE MaDatPhong = @MaDatPhong;

    -- Không có phòng → trả 0
    IF @GiaCuoi = 0 RETURN 0;

    ---------------------------------------------------------
    -- RULE CHECK-OUT SOM / LATE CHECK-OUT
    --------------------------------------------------------- 

    -- Trả trước 06:00 → 50%
    IF @Gio < '06:00'
    BEGIN
        SET @Tien = @GiaCuoi * 0.5;
        RETURN @Tien;
    END

    -- Trả 06:00–11:59 → 20%
    IF @Gio >= '06:00' AND @Gio < '12:00'
    BEGIN
        SET @Tien = @GiaCuoi * 0.2;
        RETURN @Tien;
    END

    -- Trả sau 12:00 → LATE CHECK-OUT
    IF @Gio >= '12:00'
    BEGIN
        SET @Tien = @GiaCuoi * 0.3;
        RETURN @Tien;
    END

    RETURN 0;
END;
GO


------------Doanh thu theo tháng-------
CREATE OR ALTER FUNCTION dbo.fn_DoanhThuThang
(
    @Thang TINYINT,
    @Nam INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Start DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @EndExclusive DATE = DATEADD(day, 1, EOMONTH(@Start)); -- exclusive bound

    -- Doanh thu phòng: tính số đêm overlap * GiaMoiDem
    DECLARE @DoanhThuPhong DECIMAL(18,2) =
    (
        SELECT ISNULL(SUM(
            -- số đêm overlap
            CONVERT(DECIMAL(18,2),
                DATEDIFF(day,
                    CASE WHEN dp.NgayNhan < @Start THEN @Start ELSE dp.NgayNhan END,
                    CASE WHEN dp.NgayTra   > @EndExclusive THEN @EndExclusive ELSE dp.NgayTra END
                ) * ctp.GiaCoBan
            )
        ),0)
        FROM dbo.ChiTietDatPhong ctp
        INNER JOIN dbo.DatPhong dp ON ctp.MaDatPhong = dp.MaDatPhong
        WHERE 
            -- có overlap: start < endExclusive AND end > start
            dp.NgayNhan < @EndExclusive
            AND dp.NgayTra > @Start
    );

    -- Doanh thu dịch vụ: sum(ThanhTien) trong khoảng tháng
    DECLARE @DoanhThuDichVu DECIMAL(18,2) =
    (
        SELECT ISNULL(SUM(ThanhTien),0)
        FROM dbo.SuDungDichVu
        WHERE NgaySuDung >= @Start AND NgaySuDung < @EndExclusive
    );

    RETURN ROUND(@DoanhThuPhong + @DoanhThuDichVu, 2);
END;
GO

------Test fn_Doangthu---------
SELECT dbo.fn_DoanhThuThang(12, 2025) AS DoanhThu;
GO

--Số lần khách đến khách sạn---------
CREATE OR ALTER FUNCTION dbo.fn_DemSoLanKhachDen
(
    @MaKH INT
)
RETURNS INT
AS
BEGIN
    DECLARE @SoLan INT;

    SELECT @SoLan = COUNT(*)
    FROM DatPhong
    WHERE MaKH = @MaKH
      AND TrangThai IN (N'Đang ở', N'Đã trả');

    RETURN ISNULL(@SoLan, 0);
END;
GO

----------- Phân loại khách hàng ---------------
CREATE OR ALTER FUNCTION dbo.fn_PhanLoaiKhachHang
(
    @MaKH INT
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @SoLan INT;
    DECLARE @LoaiKhach NVARCHAR(20);

    -- Lấy số lần đến
    SET @SoLan = dbo.fn_DemSoLanKhachDen(@MaKH);

    -- Phân loại
    SET @LoaiKhach =
        CASE
            WHEN @SoLan >= 5 THEN N'VIP'
            WHEN @SoLan >= 2 THEN N'Thân thiết'
            ELSE N'Khách mới'
        END;

    RETURN @LoaiKhach;
END;
GO

--test
SELECT 
    MaKH,
    HoTen,
    dbo.fn_DemSoLanKhachDen(MaKH) AS SoLanDen,
    dbo.fn_PhanLoaiKhachHang(MaKH) AS LoaiKhach
FROM KhachHang;
GO

------------- Danh sách phòng trống theo ngày ---------------
CREATE OR ALTER FUNCTION dbo.fn_DanhSachPhongTrong
(
    @Ngay DATE,
    @LoaiPhong INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.MaPhong,
        p.MaLoaiPhong,
        p.TrangThai
    FROM Phong p
    WHERE
        p.TrangThai = N'Sẵn sàng'
        AND p.MaLoaiPhong = @LoaiPhong
        AND NOT EXISTS
        (
            SELECT 1
            FROM ChiTietDatPhong ct
            JOIN DatPhong dp ON dp.MaDatPhong = ct.MaDatPhong
            WHERE
                ct.MaPhong = p.MaPhong
                AND dp.TrangThai <> N'Hủy'
                AND @Ngay >= dp.NgayNhan
                AND @Ngay <  dp.NgayTra
        )
);
GO