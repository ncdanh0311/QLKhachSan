CREATE OR ALTER PROCEDURE sp_ThongTinDatPhong
(
    @MaDatPhong INT
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------
    -- Lấy thông tin cơ bản
    ---------------------------------------------------
    DECLARE 
        @TenKhach NVARCHAR(150),
        @SoDT NVARCHAR(20),
        @NgayNhan DATE,
        @NgayTra DATE,
        @Today DATE = CAST(GETDATE() AS DATE);

    SELECT 
        @TenKhach = kh.HoTen,
        @SoDT = kh.SoDienThoai,
        @NgayNhan = dp.NgayNhan,
        @NgayTra = dp.NgayTra
    FROM DatPhong dp
    JOIN KhachHang kh ON dp.MaKH = kh.MaKH
    WHERE dp.MaDatPhong = @MaDatPhong;

    ---------------------------------------------------
    -- 1) Tổng số phòng
    ---------------------------------------------------
    DECLARE @SoPhong INT =
        (SELECT COUNT(*) 
         FROM ChiTietDatPhong 
         WHERE MaDatPhong = @MaDatPhong);

    ---------------------------------------------------
    -- 2) Tổng số người
    ---------------------------------------------------
    DECLARE @TongSoNguoi INT =
        (SELECT SUM(SoNguoi) 
         FROM ChiTietDatPhong 
         WHERE MaDatPhong = @MaDatPhong);

    ---------------------------------------------------
    -- 3) Tổng tiền phòng đến hiện tại
    ---------------------------------------------------
    ;WITH NgayO AS (
        SELECT @NgayNhan AS Ngay
        UNION ALL
        SELECT DATEADD(DAY, 1, Ngay)
        FROM NgayO
        WHERE Ngay < IIF(@NgayTra < @Today, @NgayTra, @Today)
    )
    SELECT 
        TongTienPhong = SUM(dbo.fn_TinhGiaPhongTheoNgay(Ngay, ct.GiaCoBan))
    INTO #TienPhong
    FROM NgayO n
    CROSS JOIN ChiTietDatPhong ct
    WHERE ct.MaDatPhong = @MaDatPhong
    OPTION (MAXRECURSION 500);

    ---------------------------------------------------
    -- 4) Tổng tiền dịch vụ
    ---------------------------------------------------
    DECLARE @TienDV INT = dbo.fn_TinhTongTienDichVu(@MaDatPhong);

    ---------------------------------------------------
    -- 5) Tổng tiền đến hiện tại
    ---------------------------------------------------
    DECLARE @TienPhong INT = (SELECT ISNULL(TongTienPhong, 0) FROM #TienPhong);
    DECLARE @Tong INT = @TienPhong + @TienDV;

    ---------------------------------------------------
    -- OUTPUT
    ---------------------------------------------------
    SELECT
        HoTen = @TenKhach,
        SoDienThoai = @SoDT,
        SoLuongPhong = @SoPhong,
        TongSoNguoi = @TongSoNguoi,
        TongTienPhongDenHienTai = @TienPhong,
        TongTienDichVu = @TienDV,
        TongTienHienTai = @Tong;

END;
GO

EXEC sp_ThongTinDatPhong 3
GO
---Doanh thu theo ngày---------
CREATE OR ALTER PROCEDURE sp_DoanhThuNgay
(
    @Ngay DATE
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------
    -- 1) Danh sách các booking đã checkout trong ngày
    -------------------------------------------------------
    SELECT 
        dp.MaDatPhong,
        dp.MaKH,
        kh.HoTen,
        dp.TongTien,
        dp.NgayNhan,
        dp.NgayTra
    INTO #Booking
    FROM DatPhong dp
    JOIN KhachHang kh ON dp.MaKH = kh.MaKH
    WHERE CAST(dp.NgayTra AS DATE) = @Ngay;

    -------------------------------------------------------
    -- 2) Tổng doanh thu phòng + dịch vụ (đã tính sẵn)
    -------------------------------------------------------
    DECLARE @TongDoanhThu DECIMAL(18,2) =
        (SELECT ISNULL(SUM(TongTien),0) FROM #Booking);

    -------------------------------------------------------
    -- 3) Tổng số booking checkout
    -------------------------------------------------------
    DECLARE @SoBookingCheckout INT =
        (SELECT COUNT(*) FROM #Booking);

    -------------------------------------------------------
    -- 4) Tổng số phòng checkout
    -------------------------------------------------------
    DECLARE @SoPhongCheckout INT =
        (SELECT COUNT(*) 
         FROM #Booking b
         JOIN ChiTietDatPhong ct ON b.MaDatPhong = ct.MaDatPhong);

    -------------------------------------------------------
    -- 5) TỔNG HỢP TRẢ VỀ 1 BẢNG DUY NHẤT
    -------------------------------------------------------
    SELECT
        Ngay = @Ngay,
        SoBookingCheckout = @SoBookingCheckout,
        SoPhongCheckout = @SoPhongCheckout,
        DoanhThu = @TongDoanhThu;

END;
GO

EXEC sp_DoanhThuNgay '2025-12-20';
GO
---------- Dịch vụ bán chạy ----------------
CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoDichVuBanChay
    @Thang TINYINT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Start DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @EndExclusive DATE = DATEADD(day,1,EOMONTH(@Start));

    ;WITH S AS
    (
        SELECT 
            sd.MaDV,
            dv.TenDV, 
            COUNT(*) AS SoLuot, 
            SUM(sd.ThanhTien) AS DoanhThu
        FROM dbo.SuDungDichVu sd
        INNER JOIN dbo.DichVu dv ON sd.MaDV = dv.MaDV
        WHERE sd.NgaySuDung >= @Start AND sd.NgaySuDung < @EndExclusive
        GROUP BY sd.MaDV, dv.TenDV
    ),
    Total AS
    (
        SELECT ISNULL(SUM(DoanhThu),0) AS TotalDichVu FROM S
    )
    SELECT
        s.TenDV,
        s.SoLuot,
        s.DoanhThu,
        CASE 
            WHEN t.TotalDichVu = 0 THEN 0 
            ELSE ROUND(s.DoanhThu * 100.0 / t.TotalDichVu, 2) 
        END AS PhanTram
    FROM S CROSS JOIN Total t
    WHERE s.DoanhThu > 0
    ORDER BY s.DoanhThu DESC, s.SoLuot DESC;
END;
GO
select * from SuDungDichVu

----------TEST------------
EXEC dbo.sp_BaoCaoDichVuBanChay 12, 2025
GO
------------------------

--------TEST LẠI-----
--------------------- Báo cáo tình trạng phòng theo ngày --------------------
CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTinhTrangPhongTheoNgay
    @Ngay DATE,
    @MaKS INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TargetDate DATE = @Ngay;

    SELECT 
        p.MaPhong,
        p.SoPhong,
        p.Tang,
        lp.TenLoai AS LoaiPhong,
        p.TrangThai AS TrangThaiPhong,
        
        -- Kiểm tra có khách
        CASE 
            WHEN dp_info.MaDatPhong IS NOT NULL THEN N'Có' 
            ELSE N'Không' 
        END AS CoKhach,

        kh.HoTen AS TenKhach,
        kh.SoDienThoai,
        ISNULL(dp_info.SoNguoi, 0) AS SoNguoiO,
        dp_info.NgayNhan AS NgayCheckIn,
        dp_info.NgayTra AS NgayCheckOut,

        -- Kiểm tra sử dụng dịch vụ
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM dbo.SuDungDichVu sddv
                WHERE sddv.MaCT = dp_info.MaCT
                AND CAST(sddv.NgaySuDung AS DATE) = @TargetDate
            ) THEN N'Có' 
            ELSE N'Không' 
        END AS CoDungDichVuTrongNgay

    FROM dbo.Phong p
    LEFT JOIN dbo.LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
    
    -- LEFT JOIN tìm đơn đặt phòng (giữ nguyên logic cũ)
    LEFT JOIN (
        SELECT 
            ct.MaPhong, 
            dp.MaDatPhong, 
            dp.MaKH, 
            dp.NgayNhan, 
            dp.NgayTra, 
            ct.MaCT,
            ct.SoNguoi
        FROM dbo.ChiTietDatPhong ct
        INNER JOIN dbo.DatPhong dp ON ct.MaDatPhong = dp.MaDatPhong
        WHERE 
            dp.TrangThai IN (N'Đang giữ chỗ', N'Đang ở', N'Đã trả') 
            AND dp.NgayNhan <= @TargetDate 
            AND dp.NgayTra > @TargetDate
    ) AS dp_info ON p.MaPhong = dp_info.MaPhong

    LEFT JOIN dbo.KhachHang kh ON dp_info.MaKH = kh.MaKH

    -- 2. Thêm điều kiện lọc theo Khách Sạn
    WHERE lp.MaKS = @MaKS

    ORDER BY p.Tang, p.SoPhong;
END;
GO


---------- Báo cáo cuối ngày (cursor) ---------------------
CREATE OR ALTER PROCEDURE dbo.sp_BaoCaoTongHopCuoiNgay
    @Ngay DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @SoPhongTrong INT = 0,
        @SoKhachDangO INT = 0,
        @DoanhThuPhong DECIMAL(18,2) = 0,
        @DoanhThuDichVu DECIMAL(18,2) = 0,
        @TongDoanhThu DECIMAL(18,2) = 0,
        @MaPhong INT,
        @SoPhongCur NVARCHAR(50); -- Biến hứng số phòng (đã sửa lỗi type)

    -- Xác định khung giờ ngày báo cáo
    DECLARE @DayStart DATETIME2(0) = CONVERT(DATETIME2(0), @Ngay);
    DECLARE @NextDay DATETIME2(0) = DATEADD(day, 1, @DayStart);

    -- Tạm table
    IF OBJECT_ID('tempdb..#PerRoom') IS NOT NULL DROP TABLE #PerRoom;
    CREATE TABLE #PerRoom
    (
        MaPhong INT PRIMARY KEY,
        SoPhong NVARCHAR(50),
        CoKhach BIT,
        SoKhach INT,
        DoanhThuPhong DECIMAL(18,2) DEFAULT 0,
        DoanhThuDichVu DECIMAL(18,2) DEFAULT 0,
        PhuPhiCheckOut DECIMAL(18,2) DEFAULT 0 -- Thêm cột để dễ theo dõi
    );

    ---------------------------------------------------------
    -- Cursor duyệt tất cả phòng
    ---------------------------------------------------------
    DECLARE cur_phong CURSOR LOCAL FAST_FORWARD FOR
        SELECT MaPhong, SoPhong FROM dbo.Phong;

    OPEN cur_phong;
    FETCH NEXT FROM cur_phong INTO @MaPhong, @SoPhongCur; 
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Các biến cục bộ cho từng phòng
        DECLARE @MaDatPhong INT = NULL;
        DECLARE @GiaCoBanGoc DECIMAL(18,2) = 0;
        DECLARE @NgayTraThucTe DATETIME2(0) = NULL;
        DECLARE @DTPhongPhong DECIMAL(18,2) = 0;
        DECLARE @DTDichVuPhong DECIMAL(18,2) = 0;
        DECLARE @TienPhuPhi DECIMAL(18,2) = 0;
        DECLARE @SoNguoi INT = 0;

        -- 1. Tìm thông tin đơn đặt phòng đang active tại phòng này vào ngày báo cáo
        SELECT TOP 1 
            @MaDatPhong = dp.MaDatPhong,
            @GiaCoBanGoc = ctp.GiaCoBan,
            @NgayTraThucTe = dp.NgayTra,
            @SoNguoi = ctp.SoNguoi
        FROM dbo.ChiTietDatPhong ctp
        INNER JOIN dbo.DatPhong dp ON ctp.MaDatPhong = dp.MaDatPhong
        WHERE ctp.MaPhong = @MaPhong
          AND dp.NgayNhan < @NextDay -- Checkin trước ngày mai
          AND dp.NgayTra > @DayStart -- Checkout sau đầu ngày hôm nay
          AND dp.TrangThai IN (N'Đang ở', N'Đã trả'); -- Chỉ tính khách đang ở hoặc vừa trả hôm nay

        -- Nếu tìm thấy khách (@MaDatPhong không NULL)
        IF @MaDatPhong IS NOT NULL
        BEGIN
            -- A. TÍNH DOANH THU PHÒNG (Sử dụng Function 1: fn_TinhGiaPhongTheoNgay)
            -- Logic: Thay vì lấy GiaCoBan, ta ném vào hàm để tính giá đúng theo Lễ/Cuối tuần
            SET @DTPhongPhong = dbo.fn_TinhGiaPhongTheoNgay(@Ngay, @GiaCoBanGoc);

            -- B. TÍNH PHỤ PHÍ CHECKOUT (Sử dụng Function 3: fn_TinhTienCheckOutSom)
            -- Logic: Chỉ tính nếu khách trả phòng trong ngày báo cáo
            IF CAST(@NgayTraThucTe AS DATE) = @Ngay
            BEGIN
                SET @TienPhuPhi = dbo.fn_TinhTienCheckOutSom(@MaDatPhong, @NgayTraThucTe);
                -- Cộng phụ phí vào doanh thu phòng
                SET @DTPhongPhong = @DTPhongPhong + @TienPhuPhi;
            END

            -- C. TÍNH DOANH THU DỊCH VỤ (Giữ nguyên logic cũ, KHÔNG dùng Function 2)
            -- Logic: Chỉ cộng những dịch vụ phát sinh trong ngày @Ngay
            SELECT @DTDichVuPhong = ISNULL(SUM(sdd.ThanhTien), 0)
            FROM dbo.SuDungDichVu sdd
            INNER JOIN dbo.ChiTietDatPhong ctp2 ON sdd.MaCT = ctp2.MaCT
            WHERE ctp2.MaPhong = @MaPhong -- Dịch vụ của đúng phòng này
              AND ctp2.MaDatPhong = @MaDatPhong -- Của đúng đơn này
              AND CAST(sdd.NgaySuDung AS DATE) = @Ngay; 
        END

        -- Insert vào temp
        INSERT INTO #PerRoom(MaPhong, SoPhong, CoKhach, SoKhach, DoanhThuPhong, DoanhThuDichVu, PhuPhiCheckOut)
        VALUES (
            @MaPhong, 
            @SoPhongCur, 
            CASE WHEN @MaDatPhong IS NOT NULL THEN 1 ELSE 0 END, 
            @SoNguoi, 
            @DTPhongPhong, 
            @DTDichVuPhong,
            @TienPhuPhi
        );

        FETCH NEXT FROM cur_phong INTO @MaPhong, @SoPhongCur;
    END

    CLOSE cur_phong;
    DEALLOCATE cur_phong;

    -- Tổng hợp báo cáo cuối ngày
    SELECT 
        (SELECT COUNT(1) FROM #PerRoom WHERE CoKhach = 0) AS SoPhongTrong,
        (SELECT SUM(SoKhach) FROM #PerRoom WHERE CoKhach = 1) AS SoKhachDangO,
        
        -- Tổng doanh thu phòng (Đã bao gồm giá lễ/cuối tuần + phụ phí checkout)
        (SELECT ISNULL(SUM(DoanhThuPhong),0) FROM #PerRoom) AS DoanhThuPhongNgay,
        
        -- Tổng doanh thu dịch vụ (Chỉ tính phát sinh trong ngày)
        (SELECT ISNULL(SUM(DoanhThuDichVu),0) FROM #PerRoom) AS DoanhThuDichVuNgay,
        
        -- Tổng cộng
        (SELECT ISNULL(SUM(DoanhThuPhong),0) + ISNULL(SUM(DoanhThuDichVu),0) FROM #PerRoom) AS TongDoanhThu;

    -- SELECT * FROM #PerRoom; -- Debug xem chi tiết từng phòng
END;
GO
-----------------------test-------------------
EXEC dbo.sp_BaoCaoTongHopCuoiNgay '2025-12-14';
GO


-------------- Thông tin của 1 khách hàng -------------
CREATE OR ALTER PROCEDURE dbo.sp_ThongTinKhachHang
    @MaKH INT
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- 1. Lịch sử đặt phòng (INNER JOIN CHUẨN)
    -------------------------------------------------
    SELECT
        dp.MaDatPhong,
        dp.NgayNhan,
        dp.NgayTra,
        dp.TrangThai,
        p.SoPhong,
        lp.TenLoai AS LoaiPhong,

        -- Số ngày ở (ít nhất 1)
        CASE 
            WHEN DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) <= 0 THEN 1
            ELSE DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra)
        END AS SoNgayO,

        -- Tiền phòng
        CASE 
            WHEN DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) <= 0 
                THEN ctp.GiaCoBan
            ELSE DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) * ctp.GiaCoBan
        END AS TienPhong,

        -- Tiền dịch vụ
        ISNULL(dv.TienDichVu, 0) AS TienDichVu,

        -- Tổng tiền mỗi lần
        CASE 
            WHEN DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) <= 0 
                THEN ctp.GiaCoBan
            ELSE DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) * ctp.GiaCoBan
        END + ISNULL(dv.TienDichVu, 0) AS TongTienMoiLan

    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctp ON dp.MaDatPhong = ctp.MaDatPhong
    INNER JOIN Phong p             ON ctp.MaPhong = p.MaPhong
    INNER JOIN LoaiPhong lp        ON p.MaLoaiPhong = lp.MaLoaiPhong

    LEFT JOIN
    (
        SELECT
            ctp2.MaDatPhong,
            SUM(sdd.ThanhTien) AS TienDichVu
        FROM SuDungDichVu sdd
        INNER JOIN ChiTietDatPhong ctp2 ON sdd.MaCT = ctp2.MaCT
        GROUP BY ctp2.MaDatPhong
    ) dv ON dp.MaDatPhong = dv.MaDatPhong

    WHERE dp.MaKH = @MaKH
    ORDER BY dp.NgayNhan DESC;

    -------------------------------------------------
    -- 2. Tổng tiền khách đã tiêu
    -------------------------------------------------
    SELECT
        kh.HoTen,
        SUM(
            CASE 
                WHEN DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) <= 0 
                    THEN ctp.GiaCoBan
                ELSE DATEDIFF(DAY, dp.NgayNhan, dp.NgayTra) * ctp.GiaCoBan
            END + ISNULL(dv.TienDichVu, 0)
        ) AS TongTienDaTieu
    FROM DatPhong dp
    INNER JOIN ChiTietDatPhong ctp ON dp.MaDatPhong = ctp.MaDatPhong
    INNER JOIN KhachHang kh        ON dp.MaKH = kh.MaKH

    LEFT JOIN
    (
        SELECT
            ctp2.MaDatPhong,
            SUM(sdd.ThanhTien) AS TienDichVu
        FROM SuDungDichVu sdd
        INNER JOIN ChiTietDatPhong ctp2 ON sdd.MaCT = ctp2.MaCT
        GROUP BY ctp2.MaDatPhong
    ) dv ON dp.MaDatPhong = dv.MaDatPhong

    WHERE dp.MaKH = @MaKH
    GROUP BY kh.HoTen;

    -------------------------------------------------
    -- 3. Số lần vi phạm
    -------------------------------------------------
    SELECT COUNT(*) AS SoLanViPham
    FROM BlackList
    WHERE MaKH = @MaKH;
END;
GO
-----TEST------
EXEC dbo.sp_ThongTinKhachHang @MaKH = 3;
GO

-------------- Nhắc nhở các khách hàng có lịch đặt phòng sắp đến (Cursor) ---------
CREATE OR ALTER PROCEDURE dbo.sp_SendPreCheckinReminders
    @DaysBefore INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tính ngày mục tiêu (chỉ lấy phần ngày, giờ là 00:00:00)
    DECLARE @TargetDate DATE;
    SET @TargetDate = DATEADD(DAY, @DaysBefore, CAST(GETDATE() AS DATE));

    -- BẢNG TẠM LƯU KẾT QUẢ
    DECLARE @Result TABLE
    (
        MaDatPhong INT,
        TenKhach NVARCHAR(150),
        Email NVARCHAR(100),
        SoDienThoai NVARCHAR(20),
        NgayNhan DATETIME,
        NgayTra DATETIME,
        NoiDungThongBao NVARCHAR(500)
    );

    -- BIẾN CURSOR
    DECLARE
        @MaDatPhong INT,
        @TenKhach NVARCHAR(150),
        @Email NVARCHAR(100),
        @SoDienThoai NVARCHAR(20),
        @NgayNhan DATETIME,
        @NgayTra DATETIME,
        @NoiDung NVARCHAR(500);

    -- CURSOR
    DECLARE curReminder CURSOR FOR
        SELECT
            dp.MaDatPhong,
            kh.HoTen,
            kh.Email,
            kh.SoDienThoai,
            dp.NgayNhan,
            dp.NgayTra
        FROM DatPhong dp
        INNER JOIN KhachHang kh ON dp.MaKH = kh.MaKH
        WHERE 
            CAST(dp.NgayNhan AS DATE) = @TargetDate
            AND dp.TrangThai = N'Đang giữ chỗ';

    OPEN curReminder;

    FETCH NEXT FROM curReminder
    INTO @MaDatPhong, @TenKhach, @Email, @SoDienThoai, @NgayNhan, @NgayTra;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @NoiDung = 
            N'Nhắc check-in: Khách ' + @TenKhach +
            N', đơn #' + CAST(@MaDatPhong AS NVARCHAR) +
            N', ngày nhận ' + CONVERT(NVARCHAR, @NgayNhan, 120); -- Format 120 (yyyy-mm-dd hh:mi:ss) cho rõ ràng

        INSERT INTO @Result
        VALUES
        (
            @MaDatPhong,
            @TenKhach,
            @Email,
            @SoDienThoai,
            @NgayNhan,
            @NgayTra,
            @NoiDung
        );

        FETCH NEXT FROM curReminder
        INTO @MaDatPhong, @TenKhach, @Email, @SoDienThoai, @NgayNhan, @NgayTra;
    END

    CLOSE curReminder;
    DEALLOCATE curReminder;

    -- TRẢ KẾT QUẢ RA BẢNG
    SELECT *
    FROM @Result
    ORDER BY NgayNhan, TenKhach;
END;
GO
exec sp_DatPhong 15, 2, 14, '2025-12-16 18:00', '2025-12-19 12:00'
exec sp_SendPreCheckinReminders 2
GO
---------------- Thông tin phòng theo trạng thái ----------------
CREATE OR ALTER PROCEDURE dbo.sp_ThongTinPhongTheoTrangThai
    @TrangThai NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        P.MaPhong,
        P.SoPhong,
        P.Tang,
        LP.TenLoai,
        P.TrangThai
    FROM Phong P
    JOIN LoaiPhong LP ON P.MaLoaiPhong = LP.MaLoaiPhong
    WHERE P.TrangThai = @TrangThai
    ORDER BY P.SoPhong;
END
GO

Exec sp_ThongTinPhongTheoTrangThai N'Đang có khách'
------------- Đặt phòng ------------------
GO
CREATE OR ALTER PROCEDURE dbo.sp_DatPhong
(
    @MaKH INT,
    @MaKS INT,
    @SoLuongKhach INT,
    @LoaiPhong INT,
    @NgayDen DATETIME,
    @NgayDi  DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @MaDatPhong INT,
        @GiaCoBan DECIMAL(12,2),
        @TongPhong INT,
        @PhongDaDat INT,
        @PhongBaoTri INT,
        @PhongConLai INT;

    /* =====================
       VALIDATE TIME (QUAN TRỌNG)
    ===================== */

    -- Không cho đặt ở quá khứ (tính cả GIỜ)
    IF (@NgayDen < GETDATE())
        THROW 50000, N'Không thể đặt phòng với thời gian đã qua.', 1;

    -- Ngày đi phải lớn hơn ngày đến (tính cả time)
    IF (@NgayDi <= @NgayDen)
        THROW 50001, N'Ngày đi phải lớn hơn ngày đến.', 1;

    IF (@SoLuongKhach <= 0)
        THROW 50002, N'Số lượng khách không hợp lệ.', 1;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        /* =====================
           KIỂM TRA LOẠI PHÒNG
        ===================== */
        SELECT @GiaCoBan = lp.GiaCoBan
        FROM LoaiPhong lp WITH (UPDLOCK, HOLDLOCK)
        WHERE lp.MaLoaiPhong = @LoaiPhong
          AND lp.MaKS = @MaKS;

        IF @@ROWCOUNT = 0
            THROW 50003, N'Loại phòng không tồn tại trong khách sạn này.', 1;

        /* =====================
           TỔNG PHÒNG (ĐÚNG KS)
        ===================== */
        SELECT @TongPhong = COUNT(*)
        FROM Phong p
        JOIN LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
        WHERE p.MaLoaiPhong = @LoaiPhong
          AND lp.MaKS = @MaKS;

        /* =====================
           PHÒNG ĐÃ GIỮ CHỖ
        ===================== */
        SELECT @PhongDaDat = COUNT(*)
        FROM DatPhong dp
        WHERE dp.MaKS = @MaKS
          AND dp.MaLoaiPhong = @LoaiPhong
          AND dp.TrangThai IN (N'Đang giữ chỗ', N'Đang ở')
          AND dp.NgayNhan < @NgayDi
          AND dp.NgayTra  > @NgayDen;

        /* =====================
           PHÒNG BẢO TRÌ
        ===================== */
        SELECT @PhongBaoTri = COUNT(DISTINCT bt.MaPhong)
        FROM BaoTriPhong bt
        JOIN Phong p ON p.MaPhong = bt.MaPhong
        JOIN LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
        WHERE lp.MaKS = @MaKS
          AND p.MaLoaiPhong = @LoaiPhong
          AND bt.TrangThai = N'Đang sửa'
          AND bt.NgayBatDau < @NgayDi
          AND ISNULL(bt.NgayKetThuc, '9999-12-31') > @NgayDen;

        /* =====================
           CHECK TỒN PHÒNG
        ===================== */
        IF (@TongPhong - @PhongDaDat - @PhongBaoTri <= 0)
            THROW 50004, N'Loại phòng này đã hết trong khoảng thời gian yêu cầu.', 1;

        /* =====================
           INSERT ĐẶT PHÒNG
        ===================== */
        INSERT INTO DatPhong
        (
            MaKH, MaKS, MaLoaiPhong,
            NgayDat, NgayNhan, NgayTra,
            TrangThai, TongTien
        )
        VALUES
        (
            @MaKH, @MaKS, @LoaiPhong,
            GETDATE(), @NgayDen, @NgayDi,
            N'Đang giữ chỗ', 0
        );

        SET @MaDatPhong = SCOPE_IDENTITY();

        INSERT INTO ChiTietDatPhong
        (
            MaDatPhong, MaPhong, GiaCoBan, SoNguoi
        )
        VALUES
        (
            @MaDatPhong, NULL, @GiaCoBan, @SoLuongKhach
        );

        /* =====================
           PHÒNG CÒN LẠI (SAU KHI GIỮ)
        ===================== */
        SET @PhongConLai =
            @TongPhong - (@PhongDaDat + 1) - @PhongBaoTri;

        COMMIT;

        SELECT
            @MaDatPhong AS MaDatPhong,
            @MaKS AS MaKS,
            @LoaiPhong AS MaLoaiPhong,
            @PhongConLai AS SoPhongConLai,
            @GiaCoBan AS GiaCoBan;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

GO

GO
select * from LoaiPhong
select * from Phong
exec sp_DatPhong 13, 2, 13, '2025-12-20 12:00', '2025-12-26 12:00'
select * from DatPhong

----------------- Chuyển phòng ----------------------
CREATE OR ALTER PROCEDURE dbo.sp_ChuyenPhong
(
    @MaDatPhong INT,
    @PhongA INT, -- Phòng cũ
    @PhongB INT, -- Phòng mới
    @NguoiCapNhat NVARCHAR(100) = NULL,
    @GhiChu NVARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NgayNhan DATE, @NgayTra DATE, @TrangThaiDon NVARCHAR(20);
    DECLARE @LoaiPhongA INT, @LoaiPhongB INT;
    DECLARE @MaKS_A INT, @MaKS_B INT; -- Biến lưu mã khách sạn

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        -- 1) Lấy thông tin đơn đặt phòng
        SELECT @NgayNhan = dp.NgayNhan, 
               @NgayTra = dp.NgayTra, 
               @TrangThaiDon = dp.TrangThai
        FROM DatPhong dp WITH (UPDLOCK, HOLDLOCK)
        WHERE dp.MaDatPhong = @MaDatPhong
          AND ISNULL(dp.TrangThai, N'') NOT IN (N'Hủy', N'Đã hủy', N'Vắng mặt', N'Đã trả');

        IF @NgayNhan IS NULL
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Đơn đặt phòng không tồn tại hoặc trạng thái không hợp lệ.', 16, 1);
            RETURN;
        END

        -- 2) Kiểm tra Phòng A có thuộc đơn này không
        IF NOT EXISTS (SELECT 1 FROM ChiTietDatPhong WHERE MaDatPhong = @MaDatPhong AND MaPhong = @PhongA)
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Phòng cũ (A) không nằm trong đơn đặt phòng này.', 16, 1);
            RETURN;
        END

        -- 3) Kiểm tra Phòng B có bị trùng trong đơn này không
        IF EXISTS (SELECT 1 FROM ChiTietDatPhong WHERE MaDatPhong = @MaDatPhong AND MaPhong = @PhongB)
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Phòng mới (B) đã có trong danh sách phòng của đơn này rồi.', 16, 1);
            RETURN;
        END

        -- ==========================================================================================
        -- 4) KIỂM TRA KHÁCH SẠN (MỚI BỔ SUNG) & LOẠI PHÒNG
        -- ==========================================================================================
        
        -- Lấy thông tin Loại phòng và Mã Khách Sạn của Phòng A
        SELECT @LoaiPhongA = p.MaLoaiPhong, @MaKS_A = lp.MaKS
        FROM Phong p 
        JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
        WHERE p.MaPhong = @PhongA;

        -- Lấy thông tin Loại phòng và Mã Khách Sạn của Phòng B
        SELECT @LoaiPhongB = p.MaLoaiPhong, @MaKS_B = lp.MaKS
        FROM Phong p 
        JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong
        WHERE p.MaPhong = @PhongB;

        -- Check 1: Khác khách sạn -> CHẶN NGAY
        IF @MaKS_A <> @MaKS_B
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Lỗi: Không thể chuyển khách sang phòng thuộc Khách sạn khác.', 16, 1);
            RETURN;
        END

        -- Check 2: Khác loại phòng -> Tùy chính sách (Ở đây đang chặn)
        IF @LoaiPhongA <> @LoaiPhongB
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Phòng mới khác Loại phòng với phòng cũ. Vui lòng chọn phòng cùng loại.', 16, 1);
            RETURN;
        END

        -- ==========================================================================================
        -- 5) KIỂM TRA LỊCH BẢO TRÌ CỦA PHÒNG B
        -- ==========================================================================================
        IF EXISTS (
            SELECT 1 
            FROM BaoTriPhong bt WITH (UPDLOCK, HOLDLOCK)
            WHERE bt.MaPhong = @PhongB
              AND ISNULL(bt.TrangThai, N'') NOT IN (N'Đã hủy', N'Hoàn thành')
              AND bt.NgayBatDau < @NgayTra
              AND (bt.NgayKetThuc IS NULL OR bt.NgayKetThuc > @NgayNhan)
        )
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Phòng mới đang có lịch Bảo trì trong khoảng thời gian này.', 16, 1);
            RETURN;
        END

        -- ==========================================================================================
        -- 6) KIỂM TRA TRÙNG LỊCH VỚI KHÁCH KHÁC
        -- ==========================================================================================
        IF EXISTS (
            SELECT 1
            FROM ChiTietDatPhong ct2 WITH (UPDLOCK, HOLDLOCK)
            JOIN DatPhong dp2 WITH (UPDLOCK, HOLDLOCK) ON dp2.MaDatPhong = ct2.MaDatPhong
            WHERE ct2.MaPhong = @PhongB
              AND dp2.MaDatPhong <> @MaDatPhong
              AND ISNULL(dp2.TrangThai, N'') NOT IN (N'Hủy', N'Đã hủy', N'Vắng mặt')
              AND dp2.NgayNhan < @NgayTra
              AND dp2.NgayTra  > @NgayNhan
        )
        BEGIN
            ROLLBACK TRAN;
            RAISERROR(N'Phòng mới đã được khách khác đặt trong khoảng thời gian này.', 16, 1);
            RETURN;
        END

        -- ==========================================================================================
        -- 7) THỰC HIỆN CHUYỂN ĐỔI VÀ CẬP NHẬT TRẠNG THÁI
        -- ==========================================================================================
        
        -- A. Cập nhật bảng Chi tiết
        UPDATE ChiTietDatPhong
        SET MaPhong = @PhongB
        WHERE MaDatPhong = @MaDatPhong AND MaPhong = @PhongA;

        -- B. Cập nhật trạng thái vật lý của phòng
        IF @TrangThaiDon = N'Đang ở'
        BEGIN
            UPDATE Phong SET TrangThai = N'Chờ dọn' WHERE MaPhong = @PhongA;
            UPDATE Phong SET TrangThai = N'Đang có khách' WHERE MaPhong = @PhongB;
        END
        ELSE IF @TrangThaiDon = N'Đang giữ chỗ'
        BEGIN
            UPDATE Phong SET TrangThai = N'Sẵn sàng' WHERE MaPhong = @PhongA;
            UPDATE Phong SET TrangThai = N'Sẵn sàng' WHERE MaPhong = @PhongB AND TrangThai <> N'Sẵn sàng';
        END

        -- 8) Ghi log Lịch sử
        INSERT INTO LichSuTrangThai (MaPhong, TrangThai, NguoiCapNhat, NgayCapNhat, GhiChu)
        VALUES
        (@PhongA, CASE WHEN @TrangThaiDon = N'Đang ở' THEN N'Chờ dọn' ELSE N'Sẵn sàng' END, 
         @NguoiCapNhat, GETDATE(), ISNULL(@GhiChu, N'Chuyển đi: Đơn #' + CAST(@MaDatPhong AS NVARCHAR))),
         
        (@PhongB, CASE WHEN @TrangThaiDon = N'Đang ở' THEN N'Đang có khách' ELSE N'Sẵn sàng' END, 
         @NguoiCapNhat, GETDATE(), ISNULL(@GhiChu, N'Chuyển đến: Đơn #' + CAST(@MaDatPhong AS NVARCHAR)));

        COMMIT TRAN;

        SELECT N'Chuyển phòng thành công' AS ThongBao,
               @MaDatPhong AS MaDatPhong,
               @PhongA AS PhongCu,
               @PhongB AS PhongMoi;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        DECLARE @Msg NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR(@Msg, 16, 1);
    END CATCH
END
GO
GO
select * from Phong
Execute sp_ChuyenPhong 4, 11,  18, 'Admin', N'Chuyển Phòng Cho khách'
--------------- Gia hạn phòng ----------------
CREATE OR ALTER PROCEDURE dbo.sp_GiaHanPhong
(
    @MaDatPhong INT,
    @NgayTraMoi DATE,
    @NguoiCapNhat NVARCHAR(100) = N'Admin', -- Thêm tham số người làm
    @GhiChu NVARCHAR(200) = NULL            -- Thêm ghi chú nếu cần
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @NgayNhan DATE,
        @NgayTraCu DATE,
        @StrNgayTraCu NVARCHAR(20),
        @StrNgayTraMoi NVARCHAR(20);

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        -- 1. Lấy thông tin & Validate (Giữ nguyên logic cũ)
        SELECT 
            @NgayNhan = dp.NgayNhan,
            @NgayTraCu = dp.NgayTra
        FROM dbo.DatPhong dp WITH (UPDLOCK, HOLDLOCK)
        WHERE dp.MaDatPhong = @MaDatPhong
          AND ISNULL(dp.TrangThai, N'') NOT IN (N'Hủy', N'Đã hủy', N'Vắng mặt');

        IF @NgayNhan IS NULL
        BEGIN
            RAISERROR(N'Không tồn tại đặt phòng hoặc đặt phòng không hợp lệ.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        IF @NgayTraMoi <= @NgayTraCu
        BEGIN
            SET @StrNgayTraCu = CONVERT(NVARCHAR, @NgayTraCu, 103); 
            RAISERROR(N'Ngày trả mới phải lớn hơn ngày trả hiện tại (%s).', 16, 1, @StrNgayTraCu);
            ROLLBACK TRAN; RETURN;
        END

        -- 2. Kiểm tra xung đột (Giữ nguyên logic cũ)
        IF EXISTS
        (
            SELECT 1
            FROM dbo.ChiTietDatPhong ctHienTai WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.ChiTietDatPhong ctKhac WITH (UPDLOCK, HOLDLOCK)    
                  ON ctHienTai.MaPhong = ctKhac.MaPhong
            JOIN dbo.DatPhong dpKhac WITH (UPDLOCK, HOLDLOCK)           
                  ON ctKhac.MaDatPhong = dpKhac.MaDatPhong
            WHERE ctHienTai.MaDatPhong = @MaDatPhong       
              AND dpKhac.MaDatPhong <> @MaDatPhong         
              AND ISNULL(dpKhac.TrangThai, N'') NOT IN (N'Hủy', N'Đã hủy') 
              AND dpKhac.NgayNhan < @NgayTraMoi 
              AND dpKhac.NgayTra  > @NgayTraCu
        )
        BEGIN
            RAISERROR(N'Không thể gia hạn: Có phòng đã bị khách khác đặt trước trong khoảng thời gian gia hạn.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        -- 3. Cập nhật ngày trả mới
        UPDATE dbo.DatPhong
        SET NgayTra = @NgayTraMoi
        WHERE MaDatPhong = @MaDatPhong;

        -- 4. [MỚI] GHI LOG LỊCH SỬ TRẠNG THÁI CHO TẤT CẢ CÁC PHÒNG
        -- Format ngày để ghi chú cho đẹp
        SET @StrNgayTraCu  = CONVERT(NVARCHAR, @NgayTraCu, 103);
        SET @StrNgayTraMoi = CONVERT(NVARCHAR, @NgayTraMoi, 103);

        -- Insert một lần cho tất cả phòng thuộc đơn này
        INSERT INTO dbo.LichSuTrangThai 
        (
            MaPhong, 
            TrangThai, 
            NguoiCapNhat, 
            NgayCapNhat, 
            GhiChu
        )
        SELECT 
            ct.MaPhong,
            p.TrangThai, -- Giữ nguyên trạng thái hiện tại (Đang có khách)
            @NguoiCapNhat,
            GETDATE(),
            ISNULL(@GhiChu, N'Gia hạn phòng: ' + @StrNgayTraCu + N' -> ' + @StrNgayTraMoi)
        FROM dbo.ChiTietDatPhong ct
        JOIN dbo.Phong p ON ct.MaPhong = p.MaPhong
        WHERE ct.MaDatPhong = @MaDatPhong;

        COMMIT TRAN;

        SELECT 
            N'Gia hạn thành công' AS ThongBao,
            @MaDatPhong AS MaDatPhong,
            @NgayTraCu AS NgayTraCu,
            @NgayTraMoi AS NgayTraMoi;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@Msg, 16, 1);
    END CATCH
END
GO

----------------- Tạp Vụ Xác nhận dọn xong phòng -------------------
CREATE OR ALTER PROCEDURE dbo.sp_XacNhanDonPhong
(
    @MaPhong INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    UPDATE Phong
    SET TrangThai = N'Sẵn sàng'
    WHERE MaPhong = @MaPhong
      AND TrangThai = N'Chờ dọn';

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRAN;
        RAISERROR(N'Không thể cập nhật: phòng không ở trạng thái Chờ dọn.', 16, 1);
        RETURN;
    END

    INSERT INTO LichSuTrangThai (MaPhong, TrangThai, NguoiCapNhat, NgayCapNhat, GhiChu)
    VALUES (@MaPhong, N'Sẵn sàng', NULL, GETDATE(), N'Tạp vụ xác nhận dọn xong');

    COMMIT TRAN;
END
GO

------------- Cập nhật trạng thái nếu quá 1 tiếng khách chưa check in -------------------
CREATE OR ALTER PROCEDURE dbo.sp_CapNhatTrangThaiQuaHan
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @MaDatPhong INT,
        @NgayNhan   DATETIME2(0),
        @MaPhong    INT;

    BEGIN TRY
        BEGIN TRAN;

        -- Cursor ngoài: duyệt các đặt phòng đang giữ chỗ nhưng đã quá giờ nhận phòng
        DECLARE curDatPhong CURSOR LOCAL FAST_FORWARD FOR
        SELECT MaDatPhong, NgayNhan
        FROM dbo.DatPhong WITH (UPDLOCK, HOLDLOCK)
        WHERE TrangThai = N'Đang giữ chỗ'
          AND NgayNhan < SYSDATETIME();   -- quá hạn vì đã tới giờ nhận phòng

        OPEN curDatPhong;
        FETCH NEXT FROM curDatPhong INTO @MaDatPhong, @NgayNhan;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- 1) Chuyển trạng thái đặt phòng -> Vắng mặt
            UPDATE dbo.DatPhong
            SET TrangThai = N'Vắng mặt',
                GhiChu = COALESCE(GhiChu + N' | ', N'') + N'Tự động chuyển vắng mặt do quá hạn check-in'
            WHERE MaDatPhong = @MaDatPhong
              AND TrangThai = N'Đang giữ chỗ';

            -- 2) Cursor lồng: trả tất cả phòng thuộc đặt phòng đó về "Sẵn sàng"
            DECLARE curPhong CURSOR LOCAL FAST_FORWARD FOR
            SELECT CT.MaPhong
            FROM dbo.ChiTietDatPhong CT WITH (UPDLOCK, HOLDLOCK)
            WHERE CT.MaDatPhong = @MaDatPhong;

            OPEN curPhong;
            FETCH NEXT FROM curPhong INTO @MaPhong;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                UPDATE dbo.Phong
                SET TrangThai = N'Sẵn sàng'
                WHERE MaPhong = @MaPhong;

                FETCH NEXT FROM curPhong INTO @MaPhong;
            END

            CLOSE curPhong;
            DEALLOCATE curPhong;

            FETCH NEXT FROM curDatPhong INTO @MaDatPhong, @NgayNhan;
        END

        CLOSE curDatPhong;
        DEALLOCATE curDatPhong;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

---------------- Thêm khách hàng nếu CCCD tồn tại trong hệ thống thì cập nhật thông tin mới -------------
CREATE OR ALTER PROCEDURE sp_UpsertKhachHang
    @HoTen          NVARCHAR(150),
    @CCCD           NVARCHAR(20),
    @SoDienThoai    NVARCHAR(20) = NULL, -- Cho phép NULL nếu không có
    @GioiTinh       NVARCHAR(4)  = NULL,
    @Email          NVARCHAR(100)= NULL,
    @QuocTich       NVARCHAR(50) = NULL,
    @GhiChu         NVARCHAR(200)= NULL,
    @MaKH_Output    INT OUTPUT           -- Biến đầu ra chứa ID khách hàng
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem CCCD đã tồn tại chưa
    DECLARE @MaKH_TimThay INT;
    
    SELECT @MaKH_TimThay = MaKH 
    FROM KhachHang 
    WHERE CCCD = @CCCD;

    -- Xử lý Logic
    IF @MaKH_TimThay IS NOT NULL
    BEGIN
        -- === TRƯỜNG HỢP 1: ĐÃ TỒN TẠI => CẬP NHẬT ===
        UPDATE KhachHang
        SET 
            HoTen       = @HoTen,       -- Cập nhật tên mới nhất
            SoDienThoai = ISNULL(@SoDienThoai, SoDienThoai), -- Nếu input NULL thì giữ nguyên số cũ, ko thì cập nhật
            GioiTinh    = ISNULL(@GioiTinh, GioiTinh),
            Email       = ISNULL(@Email, Email),
            QuocTich    = ISNULL(@QuocTich, QuocTich),
            GhiChu      = @GhiChu       -- Ghi chú thì cập nhật mới luôn
            -- Không update CCCD vì nó là key dùng để tìm
        WHERE MaKH = @MaKH_TimThay;

        -- Gán giá trị đầu ra là ID cũ
        SET @MaKH_Output = @MaKH_TimThay;
        
        -- (Optional) In ra thông báo để test
        -- PRINT N'Đã cập nhật thông tin khách hàng cũ: ' + @CCCD;
    END
    ELSE
    BEGIN
        -- === TRƯỜNG HỢP 2: CHƯA TỒN TẠI => THÊM MỚI ===
        INSERT INTO KhachHang (HoTen, CCCD, SoDienThoai, GioiTinh, Email, QuocTich, GhiChu)
        VALUES (@HoTen, @CCCD, @SoDienThoai, @GioiTinh, @Email, @QuocTich, @GhiChu);

        -- Lấy ID vừa sinh ra gán vào biến đầu ra
        SET @MaKH_Output = SCOPE_IDENTITY();
    END
END;
GO
select * from KhachHang where MaKH = 3
DECLARE @MaKH_KetQua INT;

-- BƯỚC 2: Thực thi Procedure
EXEC sp_UpsertKhachHang 
    @HoTen = N'Nguyễn Duy Linh', 
    @CCCD = '079205020446', 
    @SoDienThoai = '0962336000', 
    @GioiTinh = N'Nam', 
    @Email = 'duysh9123@gmail.com', 
    @QuocTich = N'Việt Nam', 
    @GhiChu = N'Khách hàng test',
    @MaKH_Output = @MaKH_KetQua OUTPUT; -- Quan trọng: Phải có chữ OUTPUT ở đây

-- BƯỚC 3: Xem kết quả ID trả về
SELECT @MaKH_KetQua AS [ID Khách Hàng Trả Về];

-- BƯỚC 4: Kiểm tra lại dữ liệu trong bảng để chắc chắn
SELECT * FROM KhachHang WHERE MaKH = @MaKH_KetQua;

GO
CREATE OR ALTER PROCEDURE dbo.sp_CheckIn
(
    @MaDatPhong INT,
    @MaPhong INT,              -- ⭐ PHÒNG DO LỄ TÂN CHỌN
    @NguoiCheckIn NVARCHAR(100) = N'Lễ tân'
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE 
            @TrangThaiDatPhong NVARCHAR(20),
            @MaLoaiPhong INT,
            @MaKS INT;

        -- ==========================
        -- 1. KIỂM TRA ĐƠN ĐẶT PHÒNG
        -- ==========================
        SELECT 
            @TrangThaiDatPhong = TrangThai,
            @MaLoaiPhong = MaLoaiPhong,
            @MaKS = MaKS
        FROM DatPhong WITH (UPDLOCK, HOLDLOCK)
        WHERE MaDatPhong = @MaDatPhong;

        IF @TrangThaiDatPhong IS NULL
            THROW 51001, N'Không tìm thấy đơn đặt phòng.', 1;

        IF @TrangThaiDatPhong <> N'Đang giữ chỗ'
            THROW 51002, N'Chỉ được Check-in đơn đang giữ chỗ.', 1;

        -- ==========================
        -- 2. KIỂM TRA PHÒNG ĐƯỢC CHỌN
        -- ==========================
        IF NOT EXISTS
        (
            SELECT 1
            FROM Phong p
            JOIN LoaiPhong lp ON lp.MaLoaiPhong = p.MaLoaiPhong
            WHERE p.MaPhong = @MaPhong
              AND p.TrangThai = N'Sẵn sàng'
              AND p.MaLoaiPhong = @MaLoaiPhong
              AND lp.MaKS = @MaKS
        )
        BEGIN
            THROW 51003, 
            N'Phòng không hợp lệ (không sẵn sàng / sai loại phòng / sai khách sạn).', 
            1;
        END

        -- ==========================
        -- 3. KIỂM TRA BẢO TRÌ
        -- ==========================
        IF EXISTS
        (
            SELECT 1
            FROM BaoTriPhong
            WHERE MaPhong = @MaPhong
              AND TrangThai = N'Đang sửa'
              AND NgayBatDau <= GETDATE()
              AND ISNULL(NgayKetThuc, '9999-12-31') >= GETDATE()
        )
        BEGIN
            THROW 51004, N'Phòng đang trong thời gian bảo trì.', 1;
        END

        -- ==========================
        -- 4. GÁN PHÒNG VÀO CHI TIẾT
        -- ==========================
        UPDATE ChiTietDatPhong
        SET MaPhong = @MaPhong
        WHERE MaDatPhong = @MaDatPhong;

        -- ==========================
        -- 5. CẬP NHẬT TRẠNG THÁI
        -- ==========================
        UPDATE DatPhong
        SET TrangThai = N'Đang ở',
            NgayNhan = GETDATE()
        WHERE MaDatPhong = @MaDatPhong;

        UPDATE Phong
        SET TrangThai = N'Đang có khách'
        WHERE MaPhong = @MaPhong;

        -- ==========================
        -- 6. GHI LỊCH SỬ
        -- ==========================
        INSERT INTO LichSuTrangThai
        (
            MaPhong,
            TrangThai,
            NguoiCapNhat,
            NgayCapNhat,
            GhiChu
        )
        VALUES
        (
            @MaPhong,
            N'Đang có khách',
            @NguoiCheckIn,
            GETDATE(),
            N'Check-in đơn #' + CAST(@MaDatPhong AS NVARCHAR)
        );

        COMMIT TRAN;

        SELECT N'Check-in thành công. Phòng đã được gán và chuyển sang trạng thái có khách.' AS ThongBao;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO


/* =========================================
   2. STORED PROCEDURE: sp_ThemDenBu
========================================= */
create or ALTER PROCEDURE dbo.sp_ThemDenBu
(
    @MaDatPhong INT,
    @MaPhong INT,
    @MaVatDung INT,
    @SoLuong INT,
    @MoTa NVARCHAR(300) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Không cho thêm nếu đã checkout
    IF EXISTS (
        SELECT 1
        FROM DatPhong
        WHERE MaDatPhong = @MaDatPhong
          AND TrangThai = N'Đã trả'
    )
    BEGIN
        RAISERROR (N'Khách đã checkout, không thể thêm đền bù!', 16, 1);
        RETURN;
    END

    -- Lấy đơn giá đền bù
    DECLARE @DonGia DECIMAL(12,2);

    SELECT @DonGia = GiaDenBu
    FROM VatDung
    WHERE MaVatDung = @MaVatDung;

    IF @DonGia IS NULL
    BEGIN
        RAISERROR (N'Vật dụng không tồn tại!', 16, 1);
        RETURN;
    END

    -- Thêm hư hỏng tài sản
    INSERT INTO HuHongTaiSan
    (
        MaDatPhong,
        MaPhong,
        MaVatDung,
        SoLuong,
        DonGia,
        MoTa,
        NgayGhiNhan,
        TrangThai
    )
    VALUES
    (
        @MaDatPhong,
        @MaPhong,
        @MaVatDung,
        @SoLuong,
        @DonGia,
        @MoTa,
        GETDATE(),
        N'Chưa tính tiền'
    );
END;
GO

/* =========================================
   3. STORED PROCEDURE: sp_CheckOut
========================================= */
create or ALTER PROCEDURE dbo.sp_CheckOut
(
    @MaDatPhong INT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- Đã checkout chưa
        IF EXISTS (
            SELECT 1
            FROM DatPhong
            WHERE MaDatPhong = @MaDatPhong
              AND TrangThai = N'Đã trả'
        )
        BEGIN
            RAISERROR(N'Đặt phòng đã checkout trước đó!',16,1);
            RETURN;
        END

        -- Đã có hóa đơn chưa
        IF EXISTS (
            SELECT 1
            FROM HoaDon
            WHERE MaDatPhong = @MaDatPhong
        )
        BEGIN
            RAISERROR(N'Đặt phòng này đã có hóa đơn!',16,1);
            RETURN;
        END

        -- Tạo hóa đơn
        INSERT INTO HoaDon (MaDatPhong, TongTien)
        VALUES (@MaDatPhong, 0);

        DECLARE @MaHD INT = SCOPE_IDENTITY();

        -- Tiền phòng
        DECLARE @TienPhong DECIMAL(12,2);
        SELECT @TienPhong = TongTien
        FROM DatPhong
        WHERE MaDatPhong = @MaDatPhong;

        INSERT INTO ChiTietHoaDon (MaHD, LoaiMuc, MoTa, SoLuong, DonGia)
        VALUES (@MaHD, N'Tiền phòng', N'Tổng tiền đặt phòng', 1, ISNULL(@TienPhong,0));
		-- Tiền dịch vụ
        DECLARE @TienDV DECIMAL(12,2);
        SELECT @TienDV = SUM(sd.ThanhTien)
        FROM SuDungDichVu sd
        JOIN ChiTietDatPhong ct ON sd.MaCT = ct.MaCT
        WHERE ct.MaDatPhong = @MaDatPhong;

        INSERT INTO ChiTietHoaDon (MaHD, LoaiMuc, MoTa, SoLuong, DonGia)
        VALUES (@MaHD, N'Dịch vụ', N'Tổng tiền dịch vụ', 1, ISNULL(@TienDV,0));

        -- Tiền đền bù
        DECLARE @TienDenBu DECIMAL(12,2);
        SELECT @TienDenBu = SUM(SoLuong * DonGia)
        FROM HuHongTaiSan
        WHERE MaDatPhong = @MaDatPhong
          AND TrangThai = N'Chưa tính tiền';

        INSERT INTO ChiTietHoaDon (MaHD, LoaiMuc, MoTa, SoLuong, DonGia)
        VALUES (@MaHD, N'Đền bù', N'Hư hỏng tài sản', 1, ISNULL(@TienDenBu,0));

        -- Tổng tiền
        UPDATE HoaDon
        SET TongTien =
            ISNULL(@TienPhong,0) +
            ISNULL(@TienDV,0) +
            ISNULL(@TienDenBu,0)
        WHERE MaHD = @MaHD;

        -- Đánh dấu đền bù đã tính tiền
        UPDATE HuHongTaiSan
        SET TrangThai = N'Đã tính tiền'
        WHERE MaDatPhong = @MaDatPhong
          AND TrangThai = N'Chưa tính tiền';

        -- Checkout cuối cùng
        UPDATE DatPhong
        SET TrangThai = N'Đã trả'
        WHERE MaDatPhong = @MaDatPhong;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

---------------------
CREATE OR ALTER PROCEDURE dbo.sp_ThanhToan
(
    @MaDatPhong INT,
    @PhuongThuc NVARCHAR(30),      -- Tiền mặt / Chuyển khoản / Thẻ
    @GhiChu NVARCHAR(200) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        -- ==============================
        -- 1. Kiểm tra đã checkout chưa
        -- ==============================
        IF NOT EXISTS (
            SELECT 1
            FROM DatPhong
            WHERE MaDatPhong = @MaDatPhong
              AND TrangThai = N'Đã trả'
        )
        BEGIN
            RAISERROR(N'Đặt phòng chưa checkout, không thể thanh toán!',16,1);
            RETURN;
        END

        -- ==============================
        -- 2. Kiểm tra đã thanh toán chưa
        -- ==============================
        IF EXISTS (
            SELECT 1
            FROM ThanhToan
            WHERE MaDatPhong = @MaDatPhong
              AND TrangThai = N'Đã thanh toán'
        )
        BEGIN
            RAISERROR(N'Đặt phòng này đã được thanh toán!',16,1);
            RETURN;
        END

        -- ==============================
        -- 3. Lấy tổng tiền từ hóa đơn
        -- ==============================
        DECLARE @SoTien DECIMAL(12,2);

        SELECT @SoTien = TongTien
        FROM HoaDon
        WHERE MaDatPhong = @MaDatPhong;

        IF @SoTien IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy hóa đơn để thanh toán!',16,1);
            RETURN;
        END

        -- ==============================
        -- 4. Ghi nhận thanh toán
        -- ==============================
        INSERT INTO ThanhToan
        (
            MaDatPhong,
            PhuongThuc,
            SoTien,
            NgayTT,
            TrangThai,
            GhiChu
        )
        VALUES
        (
            @MaDatPhong,
            @PhuongThuc,
            @SoTien,
            GETDATE(),
            N'Đã thanh toán',
            @GhiChu
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

