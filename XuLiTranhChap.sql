------------------Xử Lí Tranh Chấp -----------
--- 1. Lễ tân đặt phòng trong khi bộ phận bảo trì chuyển phòng sang ‘Bảo trì’ (Write–Write Conflict)
--SESSION 1 – Lễ tân xếp phòng cho khách -> Trạng thái đang có khách ----
BEGIN TRAN;
    DECLARE @TrangThaiHienTai NVARCHAR(20);

    -- 1. Giữ chỗ bằng UPDLOCK để không ai sửa được lúc mình đang kiểm tra
    SELECT @TrangThaiHienTai = TrangThai
    FROM Phong WITH (UPDLOCK)
    WHERE MaPhong = 3;

    -- 2. Kiểm tra nghiệp vụ
    IF @TrangThaiHienTai = N'Sẵn sàng'
    BEGIN
        WAITFOR DELAY '00:00:10'; -- Giả lập lễ tân đang thao tác chậm
        
        UPDATE Phong
        SET TrangThai = N'Đang có khách'
        WHERE MaPhong = 3;

        COMMIT TRAN;
        PRINT N'T1: Đặt phòng thành công';
    END
    ELSE
    BEGIN
        ROLLBACK TRAN;
        PRINT N'T1: Thất bại - Phòng không sẵn sàng (Do bảo trì hoặc đã có khách)';
    END
GO

select * from Phong
-- SESSION 2 (Bảo trì - Bị BLOCK tại đây cho đến khi T1 COMMIT/ROLLBACK)
BEGIN TRAN;
    UPDATE Phong 
    SET TrangThai = N'Bảo trì'
    WHERE MaPhong = 3 
      AND TrangThai = N'Sẵn sàng'; -- CHỈ BẢO TRÌ KHI PHÒNG TRỐNG

    IF @@ROWCOUNT > 0
    BEGIN
        COMMIT TRAN;
        PRINT N'T2: Đã chuyển sang bảo trì thành công';
    END
    ELSE
    BEGIN
        -- Nếu T1 đã đặt phòng trước, dòng này sẽ chạy sau khi T1 commit
        -- Và vì trạng thái lúc này là 'Đang có khách', điều kiện WHERE sai -> Không update được
        ROLLBACK TRAN;
        PRINT N'T2: Thất bại - Phòng đang có khách, không thể bảo trì!';
    END
GO

--------------- 2. Hai lễ tân cùng lúc gán 1 phòng cho 2 khách khác nhau (Write–Write Conflict) ------------
DECLARE @MaPhong INT = 1;
DECLARE @MaCT INT = 1;
BEGIN TRAN;
select * from ChiTietDatPhong
-- Khóa phòng ngay lúc kiểm tra
IF NOT EXISTS (
    SELECT 1
    FROM dbo.Phong WITH (ROWLOCK, UPDLOCK, HOLDLOCK)
    WHERE MaPhong = @MaPhong
      AND TrangThai = N'Sẵn sàng'
)
BEGIN
    ROLLBACK;
    SELECT N'T1: Thất bại – phòng không sẵn sàng' AS ThongBao;
    RETURN;
END

-- Giữ lock để bạn kịp chạy Session 2
WAITFOR DELAY '00:00:10';

-- Gán phòng
UPDATE dbo.ChiTietDatPhong
SET MaPhong = @MaPhong
WHERE MaCT = @MaCT;

-- Đổi trạng thái phòng
UPDATE dbo.Phong
SET TrangThai = N'Đang có khách'
WHERE MaPhong = @MaPhong;

COMMIT;
SELECT N'T1: Gán phòng thành công' AS ThongBao;
GO



--------SESSION 2 (T2 – Lễ tân 2 cố gán cùng phòng, sẽ bị block/chờ)-
-- SESSION 2
DECLARE @MaPhong INT = 26;
DECLARE @MaCT INT = 3;

BEGIN TRAN;

-- Câu này sẽ bị BLOCK cho tới khi Session 1 COMMIT/ROLLBACK
IF NOT EXISTS (
    SELECT 1
    FROM dbo.Phong WITH (ROWLOCK, UPDLOCK, HOLDLOCK)
    WHERE MaPhong = @MaPhong
      AND TrangThai = N'Sẵn sàng'
)
BEGIN
    ROLLBACK;
    SELECT N'T2: Thất bại – phòng đã bị giữ/gán' AS ThongBao;
    RETURN;
END

UPDATE dbo.ChiTietDatPhong
SET MaPhong = @MaPhong
WHERE MaCT = @MaCT;

UPDATE dbo.Phong
SET TrangThai = N'Đang có khách'
WHERE MaPhong = @MaPhong;

COMMIT;
SELECT N'T2: Gán phòng thành công (không nên xảy ra nếu khóa đúng)' AS ThongBao;
GO

--------Write–Write ghi đè TongTien (2 giao dịch cùng tính tiền)----------------

---------SESSION 1 (T1 – khóa DatPhong, update TongTien, giữ lock 10s)---------
-- SESSION 1
DECLARE @MaDatPhong INT = 2;

BEGIN TRAN;

-- Khóa dòng DatPhong
SELECT 1
FROM dbo.DatPhong WITH (ROWLOCK, UPDLOCK, HOLDLOCK)
WHERE MaDatPhong = @MaDatPhong;

-- Update TongTien (tính lại từ nguồn)
UPDATE dbo.DatPhong
SET TongTien =
    (SELECT ISNULL(SUM(GiaCoBan),0)
     FROM dbo.ChiTietDatPhong
     WHERE MaDatPhong = @MaDatPhong)
    + dbo.fn_TinhTongTienDichVu(@MaDatPhong)
WHERE MaDatPhong = @MaDatPhong;

WAITFOR DELAY '00:00:10';

COMMIT;
SELECT N'T1: Cập nhật TongTien xong' AS ThongBao;
GO



------------------SESSION 2 (T2 – cũng muốn update TongTien → bị BLOCK)------------
-- SESSION 2
DECLARE @MaDatPhong INT = 2;

BEGIN TRAN;

-- Sẽ bị BLOCK cho tới khi Session 1 COMMIT
SELECT 1
FROM dbo.DatPhong WITH (ROWLOCK, UPDLOCK, HOLDLOCK)
WHERE MaDatPhong = @MaDatPhong;

UPDATE dbo.DatPhong
SET TongTien =
    (SELECT ISNULL(SUM(GiaCoBan),0)
     FROM dbo.ChiTietDatPhong
     WHERE MaDatPhong = @MaDatPhong)
    + dbo.fn_TinhTongTienDichVu(@MaDatPhong)
WHERE MaDatPhong = @MaDatPhong;

COMMIT;
SELECT N'T2: Cập nhật TongTien xong (chạy sau T1)' AS ThongBao;
GO

---------------- 2 Nhân viên cùng chuyển phòng cho 1 khách hàng ------------
------------------------------nv1 và nv2 cùng nhập 1 phòng
----------------------------------------------------------------------code này là của nv1
BEGIN TRAN;

DECLARE @Phong INT;
-- NV1 chiếm khóa cập nhật
SELECT @Phong = MaPhong
FROM ChiTietDatPhong WITH (UPDLOCK, HOLDLOCK)
WHERE MaCT = 1;

WAITFOR DELAY '00:00:10';
Select * from Phong
UPDATE ChiTietDatPhong
SET MaPhong = 3
WHERE MaCT = 1;

Update Phong 
Set TrangThai = N'Đang có khách'
where MaPhong = 3

Update Phong 
Set TrangThai = N'Sẵn sàng'
where MaPhong = 1

COMMIT TRAN;
PRINT N'NV1 chuyển phòng xong';
Select * from Phong
----------------------------------------------------------code này của nv2 nhập ở querry khác
SET LOCK_TIMEOUT 0; -- không chờ, bị khóa là báo lỗi

BEGIN TRY
    BEGIN TRAN;

    DECLARE @Phong INT;

    -- NV2 cố lấy cùng khóa
    SELECT @Phong = MaPhong
    FROM ChiTietDatPhong WITH (UPDLOCK, HOLDLOCK)
    WHERE MaCT = 3;

    -- Nếu tới được đây → NV1 đã xong
    UPDATE ChiTietDatPhong
    SET MaPhong = 2
    WHERE MaCT = 1;

    COMMIT TRAN;
    PRINT N'NV2 chuyển phòng';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT N'NV2 bị từ chối – NV khác đang xử lý';
END CATCH;
---------------- Khách thanh toán xong nhưng Trigger tính tiền chạy chưa xong ----------------
-- TAB 1: T1 (Chạy chậm)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- Đảm bảo khóa hoàn toàn
BEGIN TRAN;

-- Cập nhật tạm
UPDATE DatPhong
SET TongTien = 2000000
WHERE MaDatPhong = 2;
-- ...
WAITFOR DELAY '00:00:15';
-- ...
UPDATE DatPhong
SET TongTien = 14000000
WHERE MaDatPhong = 2;

COMMIT TRAN;

------ Nhân viên lấy tổng tiền ----------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT MaDatPhong, TongTien
FROM DatPhong
WHERE MaDatPhong = 2;

------------- Thêm dịch vụ khi Kho cập nhật 'Ngưng cung cấp' ---------------
-- Dùng mức mặc định (READ COMMITTED) -> Đọc xong thả khóa ngay
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRAN;

    DECLARE @TrangThai NVARCHAR(50);
    DECLARE @DonGia DECIMAL(12,2);
    DECLARE @MaCT INT;

    -- 1. Đọc màn hình (Lúc này thấy 'Hoạt động')
    -- Khóa Shared-Lock được thả ra NGAY SAU KHI lệnh này chạy xong
    SELECT @TrangThai = TrangThai, @DonGia = DonGia
    FROM DichVu
    WHERE MaDV = 1;

    PRINT N'T1: Thấy "Hoạt động". Đang gõ máy... (15s)';
    
    -- Trong 15s này, Kho (T2) sẽ nhảy vào cập nhật
    WAITFOR DELAY '00:00:15';

    -- 2. KHOẢNH KHẮC QUYẾT ĐỊNH (Double Check)
    -- Trước khi Insert, ta KHÓA LẠI để kiểm tra lần cuối
    DECLARE @TrangThaiHienTai NVARCHAR(50);
    
    SELECT @TrangThaiHienTai = TrangThai
    FROM DichVu WITH (UPDLOCK) -- Khóa cập nhật phút chót
    WHERE MaDV = 1;

    PRINT N'T1: Kiểm tra lại thấy trạng thái là: ' + @TrangThaiHienTai;

    IF @TrangThaiHienTai = N'Hoạt động'
    BEGIN
        SELECT TOP 1 @MaCT = MaCT FROM ChiTietDatPhong WHERE MaPhong = 1;
        INSERT INTO SuDungDichVu (MaCT, MaDV, SoLuong, DonGia)
        VALUES (@MaCT, 1, 2, @DonGia);
        PRINT N'T1: Thành công!';
    END
    ELSE
    BEGIN
        -- Nếu Kho đã đổi thành Ngưng cung cấp -> Lễ tân phải Fail
        PRINT N'T1: THẤT BẠI! Kho báo hết hàng lúc mình đang nhập.';
        ROLLBACK TRAN; -- Hủy giao dịch
        RETURN;
    END

COMMIT TRAN;
---------- Nhân viên kho update ngưng cung cấp------------
UPDATE DichVu
SET TrangThai = N'Ngưng cung cấp'
WHERE MaDV = 1;
select * from DichVu

------------ Lịch bảo trì phòng nhập sai ngày làm lệch quá trình booking (Write–Write Conflict) ------------
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; 

BEGIN TRAN;

    PRINT N'T1: Đang cập nhật ngày kết thúc bảo trì lên "2025-01-05"...';
    
    -- Lệnh này sẽ KHÓA dòng bảo trì của P101
    UPDATE BaoTriPhong
    SET NgayKetThuc = '2025-01-05', -- Gia hạn thêm
        MoTa = N'Sửa thêm ống nước'
    WHERE MaPhong = 1;

    -- Giả lập nhân viên bảo trì đang thao tác chậm
    WAITFOR DELAY '00:00:15';

COMMIT TRAN;
PRINT N'T1: Cập nhật lịch bảo trì hoàn tất.';
------------- Lễ tân Đặt Phòng -------------
DECLARE @CheckIn DATE = '2025-01-02';
DECLARE @CheckOut DATE = '2025-01-04';
DECLARE @MaPhong INT = 1; -- P101

BEGIN TRAN;
    
    PRINT N'T2: Đang kiểm tra lịch bảo trì để đặt phòng...';

    -- [QUAN TRỌNG] Kiểm tra xung đột bảo trì
    -- Vì T1 đang UPDATE dòng này, nên lệnh SELECT này sẽ bị BLOCK (TREO)
    -- Nó phải chờ T1 Commit xong mới đọc được dữ liệu mới nhất.
    DECLARE @BiBaoTri INT;
    
    SELECT @BiBaoTri = COUNT(*) 
    FROM BaoTriPhong 
    WHERE MaPhong = @MaPhong
      AND TrangThai = N'Đang sửa'
      AND (NgayBatDau <= @CheckOut AND NgayKetThuc >= @CheckIn);

    -- Code sẽ dừng ở dòng trên 15s. Sau khi T1 xong, dòng này mới chạy tiếp.
    
    IF @BiBaoTri > 0
    BEGIN
        PRINT N'T2: KHÔNG THỂ ĐẶT! Phòng đang bảo trì trong thời gian này.';
        ROLLBACK TRAN;
    END
    ELSE
    BEGIN
        -- Nếu không bị trùng thì mới cho đặt
        INSERT INTO DatPhong (MaKH, NgayNhan, NgayTra, TrangThai, TongTien)
        VALUES (1, @CheckIn, @CheckOut, N'Đang giữ chỗ', 0);
        
        INSERT INTO ChiTietDatPhong (MaDatPhong, MaPhong, GiaCoBan)
        VALUES (SCOPE_IDENTITY(), @MaPhong, 500000);
        
        PRINT N'T2: Đặt phòng thành công!';
        COMMIT TRAN;
    END