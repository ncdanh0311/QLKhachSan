---quản trị
ALTER DATABASE QuanLyKhachSan_DatPhong
SET RECOVERY FULL;
GO
--backup cn
USE msdb;
GO

-- Xóa job cũ nếu tồn tại
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_FullBackup_QLKS')
    EXEC sp_delete_job @job_name = N'Job_FullBackup_QLKS';
GO

EXEC sp_add_job 
    @job_name = N'Job_FullBackup_QLKS';
GO

EXEC sp_add_jobstep
    @job_name = N'Job_FullBackup_QLKS',
    @step_name = N'Full Backup',
    @subsystem = N'TSQL',
    @command = N'
        BACKUP DATABASE QuanLyKhachSan_DatPhong
        TO DISK = ''QLKS_FULL.bak''
        WITH INIT;
    ';
GO

EXEC sp_add_schedule
    @schedule_name = N'Schedule_Full_Sunday_2AM',
    @freq_type = 8,              -- Weekly
    @freq_interval = 1,          -- Sunday
    @freq_recurrence_factor = 1,
    @active_start_time = 020000;
GO

EXEC sp_attach_schedule
    @job_name = N'Job_FullBackup_QLKS',
    @schedule_name = N'Schedule_Full_Sunday_2AM';
GO

EXEC sp_add_jobserver 
    @job_name = N'Job_FullBackup_QLKS';
GO

-----------------------------------------------DIFFERENTIAL BACKUP – THỨ 2 → THỨ 7 – 02:00
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_DiffBackup_QLKS')
    EXEC sp_delete_job @job_name = N'Job_DiffBackup_QLKS';
GO

EXEC sp_add_job 
    @job_name = N'Job_DiffBackup_QLKS';
GO

EXEC sp_add_jobstep
    @job_name = N'Job_DiffBackup_QLKS',
    @step_name = N'Differential Backup',
    @subsystem = N'TSQL',
    @command = N'
        BACKUP DATABASE QuanLyKhachSan_DatPhong
        TO DISK = ''QLKS_DIFF.bak''
        WITH DIFFERENTIAL, INIT;
    ';
GO

EXEC sp_add_schedule
    @schedule_name = N'Schedule_Diff_MonToSat_2AM',
    @freq_type = 8,               -- Weekly
    @freq_interval = 62,          -- Mon–Sat
    @freq_recurrence_factor = 1,
    @active_start_time = 020000;
GO

EXEC sp_attach_schedule
    @job_name = N'Job_DiffBackup_QLKS',
    @schedule_name = N'Schedule_Diff_MonToSat_2AM';
GO

EXEC sp_add_jobserver 
    @job_name = N'Job_DiffBackup_QLKS';
GO



----------------------------TRANSACTION LOG BACKUP – MỖI 30 PHÚT
USE msdb;
GO

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_LogBackup_QLKS')
    EXEC sp_delete_job @job_name = N'Job_LogBackup_QLKS';
GO
EXEC sp_add_job 
    @job_name = N'Job_LogBackup_QLKS';
GO

EXEC sp_add_jobstep
    @job_name = N'Job_LogBackup_QLKS',
    @step_name = N'Log Backup',
    @subsystem = N'TSQL',
    @command = N'
        BACKUP LOG QuanLyKhachSan_DatPhong
        TO DISK = ''QLKS_LOG.trn''
        WITH INIT;
    ';
GO

EXEC sp_add_schedule
    @schedule_name = N'Schedule_Log_30_Min',
    @freq_type = 4,                -- DAILY
    @freq_interval = 1,            -- 🔴 BẮT BUỘC (mỗi ngày)
    @freq_subday_type = 4,         -- MINUTES
    @freq_subday_interval = 30,    -- mỗi 30 phút
    @active_start_time = 000000;
GO

EXEC sp_attach_schedule
    @job_name = N'Job_LogBackup_QLKS',
    @schedule_name = N'Schedule_Log_30_Min';
GO

EXEC sp_add_jobserver 
    @job_name = N'Job_LogBackup_QLKS';
GO
--test
SELECT name 
FROM msdb.dbo.sysjobs
WHERE name = 'Job_LogBackup_QLKS';


---------ai dc backup copy role từ file long
USE QuanLyKhachSan_DatPhong;
GO

GRANT BACKUP DATABASE TO AdminHeThong;
GRANT BACKUP LOG TO AdminHeThong;
GO
--khong bat buoc thu hoi quyen backup
DENY BACKUP DATABASE TO NhanVienLeTan;
DENY BACKUP DATABASE TO KeToan;
DENY BACKUP DATABASE TO NhanVienTapVu;
DENY BACKUP DATABASE TO KhachHang;
GO