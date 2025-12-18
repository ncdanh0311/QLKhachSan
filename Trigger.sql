CREATE OR Alter TRIGGER Tr_UpTienDatPhong
ON ChiTietDatPhong
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @MaDatPhong INT,
        @NgayNhan DATE,
        @NgayTra DATE,
        @GiaCoBan DECIMAL(18,2),
        @TongTienPhong DECIMAL(18,2),
        @TongTienDV DECIMAL(18,2),
        @TienCheckout DECIMAL(18,2),
        @Ngay DATE;

    ---------------------------------------------------------
    -- Lấy các MaDatPhong bị ảnh hưởng (đề phòng multi-row)
    ---------------------------------------------------------
    DECLARE cur CURSOR FOR
    SELECT DISTINCT i.MaDatPhong
    FROM inserted i;

    OPEN cur;

    FETCH NEXT FROM cur INTO @MaDatPhong;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        ---------------------------------------------------------
        -- Lấy ngày nhận / ngày trả
        ---------------------------------------------------------
        SELECT 
            @NgayNhan = NgayNhan,
            @NgayTra = NgayTra
        FROM DatPhong
        WHERE MaDatPhong = @MaDatPhong;

        ---------------------------------------------------------
        -- Tính tiền phòng theo từng ngày → logic chính
        ---------------------------------------------------------
        SET @TongTienPhong = 0;

        SET @Ngay = @NgayNhan;

        WHILE @Ngay < @NgayTra
        BEGIN
            DECLARE @GiaNgay DECIMAL(18,2) = 0;

            -----------------------------------------------------
            -- Lấy tổng giá base cho tất cả phòng trong ngày đó
            -- Vì 1 đơn đặt có thể gồm nhiều phòng
            -----------------------------------------------------
            SELECT @GiaCoBan = SUM(GiaCoBan)
            FROM ChiTietDatPhong
            WHERE MaDatPhong = @MaDatPhong;

            IF @GiaCoBan IS NULL SET @GiaCoBan = 0;

            -----------------------------------------------------
            -- Gọi fn tính giá phòng theo từng ngày
            -----------------------------------------------------
            SET @GiaNgay = dbo.fn_TinhGiaPhongTheoNgay(@Ngay, @GiaCoBan);

            SET @TongTienPhong += @GiaNgay;

            SET @Ngay = DATEADD(DAY, 1, @Ngay);
        END

        ---------------------------------------------------------
        -- Tính tổng tiền DV
        ---------------------------------------------------------
        SET @TongTienDV = dbo.fn_TinhTongTienDichVu(@MaDatPhong);

        ---------------------------------------------------------
        -- Tính tiền Check-out sớm / muộn (nếu có)
        -- Kiểm tra nếu DatPhong trạng thái = 'Đã trả'
        ---------------------------------------------------------
		DECLARE @TrangThai NVARCHAR(20), @GioTraThucTe DATETIME2;

		SELECT @TrangThai = TrangThai 
		FROM DatPhong 
		WHERE MaDatPhong = @MaDatPhong;

		-- Lấy giờ trả thực tế từ bảng ThanhToan
		SELECT TOP 1 @GioTraThucTe = NgayTT
		FROM ThanhToan
		WHERE MaDatPhong = @MaDatPhong
		ORDER BY NgayTT DESC;

		IF @TrangThai = N'Đã trả' AND @GioTraThucTe IS NOT NULL
		BEGIN
			SET @TienCheckout = dbo.fn_TinhTienCheckOutSom(@MaDatPhong, @GioTraThucTe);
		END
		ELSE 
			SET @TienCheckout = 0;


        ---------------------------------------------------------
        -- Tổng cuối cùng
        ---------------------------------------------------------
        UPDATE DatPhong
        SET TongTien = 
            @TongTienPhong +
            @TongTienDV +
            @TienCheckout
        WHERE MaDatPhong = @MaDatPhong;

        FETCH NEXT FROM cur INTO @MaDatPhong;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

----------- Set giá cơ bản cho CTDP -------------------

CREATE TRIGGER Tr_SetGiaCoBan
ON ChiTietDatPhong
AFTER INSERT
AS
BEGIN
    UPDATE c
    SET GiaCoBan = lp.GiaCoBan
    FROM inserted i
    JOIN ChiTietDatPhong c ON i.MaCT = c.MaCT
    JOIN Phong p ON c.MaPhong = p.MaPhong
    JOIN LoaiPhong lp ON p.MaLoaiPhong = lp.MaLoaiPhong;
END;

--------------- Set giá vào SuDungDichVu ----------------
GO
CREATE TRIGGER Tr_SetDonGiaDichVu
ON SuDungDichVu
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.DonGia = dv.DonGia
    FROM SuDungDichVu s
    JOIN inserted i ON s.MaSDDV = i.MaSDDV
    JOIN DichVu dv ON dv.MaDV = i.MaDV;
END;
GO



------------- Thêm vào BlackList ------------
CREATE TRIGGER dbo.tr_ThemVaoDsDen
ON dbo.ChiTietHoaDon
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.BlackList (MaKH, LyDo, NgayTao, MucDoViPham)
    SELECT DISTINCT
        dp.MaKH,
        N'Đền bù thiệt hại > 50 triệu',
        CAST(GETDATE() AS DATE),
        2
    FROM inserted i
    INNER JOIN dbo.HoaDon hd   ON i.MaHD = hd.MaHD
    INNER JOIN dbo.DatPhong dp ON hd.MaDatPhong = dp.MaDatPhong
    WHERE i.LoaiMuc = N'Đền bù'
      AND i.ThanhTien > 50000000
      AND NOT EXISTS (
            SELECT 1
            FROM dbo.BlackList bl
            WHERE bl.MaKH = dp.MaKH
      );
END;
GO
--TEST


------------ Cập nhật Trạng thái phòng thành 'Chờ dọn' sau khi khách thanh toán trả phòng -----------
CREATE OR ALTER TRIGGER Tr_ThanhToanHoanTat
ON HoaDon
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ chạy khi hóa đơn chuyển sang trạng thái 'Đã xuất'
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.MaHD = d.MaHD
        WHERE i.TinhTrang = N'Đã xuất'
          AND d.TinhTrang <> N'Đã xuất'
    )
    BEGIN
        UPDATE HD
        SET TongTien = DP.TongTien
        FROM HoaDon HD
        JOIN DatPhong DP ON HD.MaDatPhong = DP.MaDatPhong
        JOIN inserted i ON i.MaHD = HD.MaHD;
        
    END
END
GO

------------------ Cập nhật trạng thái phòng khi khách CheckIn ----------------
CREATE OR ALTER TRIGGER dbo.trg_CheckIn_UpdateTrangThaiPhong
ON dbo.ChiTietDatPhong
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Gom các dòng "check-in thật" (có MaPhong và vừa được gán mới/đổi phòng)
    DECLARE @X TABLE (
        MaPhong INT NOT NULL,
        MaDatPhong INT NOT NULL -- Thêm cái này để check trạng thái đơn
    );

    INSERT INTO @X (MaPhong, MaDatPhong)
    SELECT DISTINCT i.MaPhong, i.MaDatPhong
    FROM inserted i
    LEFT JOIN deleted d ON d.MaCT = i.MaCT
    WHERE
        i.MaPhong IS NOT NULL
        AND (d.MaPhong IS NULL OR d.MaPhong <> i.MaPhong);

    -- Nếu không có dòng nào hợp lệ thì thoát
    IF NOT EXISTS (SELECT 1 FROM @X) RETURN;

    -- 1) Update trạng thái phòng
    UPDATE p
    SET p.TrangThai = N'Đang có khách'
    FROM dbo.Phong p
    JOIN @X x ON x.MaPhong = p.MaPhong
    JOIN dbo.DatPhong dp ON x.MaDatPhong = dp.MaDatPhong -- Join để check trạng thái
    WHERE p.TrangThai = N'Sẵn sàng'
      AND dp.TrangThai = N'Đang ở'; -- Thêm điều kiện này để tránh lỗi đặt trước (Future Booking)

    -- 2) Log lịch sử trạng thái (Chỉ log những phòng thực sự được update)
    INSERT INTO dbo.LichSuTrangThai (MaPhong, TrangThai, NguoiCapNhat, NgayCapNhat, GhiChu)
    SELECT
        x.MaPhong,
        N'Đang có khách',
        NULL,
        GETDATE(),
        N'Check-in (Đơn #' + CAST(x.MaDatPhong AS NVARCHAR(20)) + N')'
    FROM @X x
    JOIN dbo.DatPhong dp ON x.MaDatPhong = dp.MaDatPhong
    WHERE dp.TrangThai = N'Đang ở'
      AND EXISTS (SELECT 1 FROM Phong p WHERE p.MaPhong = x.MaPhong AND p.TrangThai = N'Đang có khách'); -- Chỉ log nếu update thành công
END
GO

USE QuanLyKhachSan_DatPhong;
GO

DECLARE @Output_MaKH INT;


USE QuanLyKhachSan_DatPhong;
GO


------------------ Cập nhật trạng thái phòng khi khách CheckOut ----------------
CREATE OR ALTER TRIGGER dbo.trg_CheckOut_UpdateTrangThaiPhong
ON dbo.ThanhToan
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ xử lý khi trạng thái chuyển sang 'Đã thanh toán'
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN deleted d ON d.MaTT = i.MaTT
        WHERE i.TrangThai = N'Đã thanh toán'
          AND (d.MaTT IS NULL OR ISNULL(d.TrangThai, N'') <> N'Đã thanh toán')
    )
        RETURN;

    -- 1) Cập nhật phòng: Đang có khách -> Chờ dọn
    UPDATE p
    SET p.TrangThai = N'Chờ dọn'
    FROM Phong p
    JOIN ChiTietDatPhong ct ON ct.MaPhong = p.MaPhong
    JOIN inserted i ON i.MaDatPhong = ct.MaDatPhong
    WHERE p.TrangThai = N'Đang có khách';


    -- 2) Ghi log
    INSERT INTO LichSuTrangThai (MaPhong, TrangThai, NguoiCapNhat, NgayCapNhat, GhiChu)
    SELECT DISTINCT
        p.MaPhong,
        N'Chờ dọn',
        NULL,
        GETDATE(),
        N'Check-out (Đã thanh toán)'
    FROM Phong p
    JOIN ChiTietDatPhong ct ON ct.MaPhong = p.MaPhong
    JOIN inserted i ON i.MaDatPhong = ct.MaDatPhong
    WHERE p.TrangThai = N'Chờ dọn';
END
GO


/* =========================================
   4. TRIGGER: Chặn sửa/xóa HóaĐơn sau checkout
========================================= */
create or ALTER TRIGGER dbo.trg_BlockEditHoaDon
ON dbo.HoaDon
AFTER UPDATE, DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN DatPhong dp ON d.MaDatPhong = dp.MaDatPhong
        WHERE dp.TrangThai = N'Đã trả'
    )
    BEGIN
        RAISERROR(N'Không được sửa hoặc xóa hóa đơn sau khi checkout!',16,1);
        ROLLBACK;
    END
END;
GO

/* =========================================
   5. TRIGGER: Chặn thêm đền bù sau checkout
========================================= */
ALTER TRIGGER dbo.trg_BlockInsertHuHong
ON dbo.HuHongTaiSan
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT / UPDATE
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DatPhong dp ON i.MaDatPhong = dp.MaDatPhong
        WHERE dp.TrangThai = N'Đã trả'
    )
    BEGIN
        RAISERROR(N'Không được thêm hoặc chỉnh sửa đền bù sau khi checkout!',16,1);
        ROLLBACK;
        RETURN;
    END

    -- DELETE
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN DatPhong dp ON d.MaDatPhong = dp.MaDatPhong
        WHERE dp.TrangThai = N'Đã trả'
    )
    BEGIN
        RAISERROR(N'Không được xóa đền bù sau khi checkout!',16,1);
        ROLLBACK;
        RETURN;
    END
END;
GO

/* =========================================
   6. TRIGGER: Khóa ChiTietHoaDon sau checkout
========================================= */
CREATE OR ALTER TRIGGER dbo.trg_Lock_ChiTietHoaDon_AfterCheckout
ON dbo.ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN HoaDon hd ON i.MaHD = hd.MaHD
        JOIN DatPhong dp ON hd.MaDatPhong = dp.MaDatPhong
        WHERE dp.TrangThai = N'Đã trả'
		)
    OR EXISTS (
        SELECT 1
        FROM deleted d
        JOIN HoaDon hd ON d.MaHD = hd.MaHD
        JOIN DatPhong dp ON hd.MaDatPhong = dp.MaDatPhong
        WHERE dp.TrangThai = N'Đã trả'
    )
    BEGIN
        RAISERROR(N'Đặt phòng đã checkout, không được chỉnh sửa chi tiết hóa đơn!',16,1);
        ROLLBACK;
    END
END;
GO