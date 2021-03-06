USE [CHUNGKHOAN]
GO
/****** Object:  Table [dbo].[BANG_GIA_TRUC_TUYEN]    Script Date: 29/04/2022 10:59:07 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BANG_GIA_TRUC_TUYEN](
	[MACP] [char](7) NOT NULL,
	[DM_GIA3] [float] NULL,
	[DM_SL3] [int] NULL,
	[DM_GIA2] [float] NULL,
	[DM_SL2] [int] NULL,
	[DM_GIA1] [float] NULL,
	[DM_SL1] [int] NULL,
	[KL_GIA] [float] NULL,
	[KL_SL] [int] NULL,
	[DB_GIA1] [float] NULL,
	[DB_SL1] [int] NULL,
	[DB_GIA2] [float] NULL,
	[DB_SL2] [int] NULL,
	[DB_GIA3] [float] NULL,
	[DB_SL3] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LENHDAT]    Script Date: 29/04/2022 10:59:07 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LENHDAT](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MACP] [nchar](7) NOT NULL,
	[NGAYDAT] [datetime] NOT NULL,
	[LOAIGD] [nchar](1) NOT NULL,
	[LOAILENH] [nchar](10) NOT NULL,
	[SOLUONG] [int] NOT NULL,
	[GIADAT] [float] NOT NULL,
	[TRANGTHAILENH] [nvarchar](30) NOT NULL,
 CONSTRAINT [PK_LENHDAT] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LENHKHOP]    Script Date: 29/04/2022 10:59:07 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LENHKHOP](
	[IDKHOP] [int] IDENTITY(1,1) NOT NULL,
	[NGAYKHOP] [datetime] NOT NULL,
	[SOLUONGKHOP] [int] NOT NULL,
	[GIAKHOP] [float] NOT NULL,
	[IDLENHDAT] [int] NOT NULL,
 CONSTRAINT [PK_lenhkhop] PRIMARY KEY CLUSTERED 
(
	[IDKHOP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LENHKHOP]  WITH CHECK ADD  CONSTRAINT [FK_lenhkhop_LENHDAT] FOREIGN KEY([IDLENHDAT])
REFERENCES [dbo].[LENHDAT] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[LENHKHOP] CHECK CONSTRAINT [FK_lenhkhop_LENHDAT]
GO
ALTER TABLE [dbo].[LENHDAT]  WITH CHECK ADD  CONSTRAINT [CK_LENHDAT_LOAIGD] CHECK  (([LOAIGD]='B' OR [LOAIGD]='M'))
GO
ALTER TABLE [dbo].[LENHDAT] CHECK CONSTRAINT [CK_LENHDAT_LOAIGD]
GO
/****** Object:  StoredProcedure [dbo].[CURSOR_GD_THEO_LOAI]    Script Date: 29/04/2022 10:59:07 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[CURSOR_GD_THEO_LOAI]
  @OUTPUT_CURSOR CURSOR VARYING OUTPUT, 
  @MACP NVARCHAR(10),
  @NGAY NVARCHAR(50),
  @LOAIGD CHAR 
AS
SET DATEFORMAT DMY 
IF (@LOAIGD='M') 
  SET @OUTPUT_CURSOR = CURSOR KEYSET FOR 
  SELECT ID, NGAYDAT, SOLUONG, GIADAT FROM LENHDAT 
  WHERE MACP=@MACP 
    AND DAY(NGAYDAT)=DAY(@NGAY)AND MONTH(NGAYDAT)= MONTH(@NGAY) AND YEAR(NGAYDAT)=YEAR(@NGAY)  
    AND LOAIGD=@LOAIGD AND SOLUONG >0  
	
    ORDER BY GIADAT DESC, NGAYDAT DESC
ELSE
  SET @OUTPUT_CURSOR=CURSOR KEYSET FOR 
  SELECT ID,NGAYDAT, SOLUONG, GIADAT FROM LENHDAT 
  WHERE MACP=@MACP 
    AND DAY(NGAYDAT)=DAY(@NGAY)AND MONTH(NGAYDAT)= MONTH(@NGAY) AND YEAR(NGAYDAT)=YEAR(@NGAY)  
    AND LOAIGD=@LOAIGD AND SOLUONG >0  
	
    ORDER BY GIADAT, NGAYDAT 
OPEN @OUTPUT_CURSOR

GO
/****** Object:  StoredProcedure [dbo].[SP_DAILY_RESET_BANGGIA]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_DAILY_RESET_BANGGIA]
AS
BEGIN
	DELETE FROM BANG_GIA_TRUC_TUYEN
END
GO
/****** Object:  StoredProcedure [dbo].[SP_KHOPLENH_LO]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[SP_KHOPLENH_LO]
    @maCP NVARCHAR(10),
    @ngay NVARCHAR(50),
    @loaiGD CHAR,
    @soLuongMB INT,
    @giaDatMB FLOAT
AS 
--Viết SP tính số lượng cổ phiếu khớp theo thuật toán khớp lệnh liên tục khi có 1 lệnh mua hoặc bán được gởi đến bảng LENHDAT
    DECLARE @ngay_Convert DATETIME
    SET @ngay_Convert = CONVERT(DATETIME, @ngay)
	SET DATEFORMAT DMY
    DECLARE @cursorVar CURSOR,
        @ngayDat NVARCHAR(50),
        @soLuong INT,
        @giadat FLOAT,
        @soLuongkhop INT,
        @giaKhop FLOAT,
        @idLenhDat INT,
        @soLuongDaKhop INT --so luong khop dc cua lenh gui vao

    SET @soLuongDaKhop = 0

    IF ( @loaiGD = 'B' )
	-- lệnh bán thì lấy cursor mua và ngược lại
        EXEC CURSOR_GD_THEO_LOAI @cursorVar OUTPUT, @maCP, @ngay, 'M'
    ELSE
        EXEC CURSOR_GD_THEO_LOAI @cursorVar OUTPUT, @maCP, @ngay, 'B'
  
    FETCH NEXT FROM @cursorVar INTO @idLenhDat, @ngayDat, @soLuong, @giadat

    WHILE ( @@FETCH_STATUS <> -1  AND @soLuongMB > 0 )
        BEGIN
    --  Trường hợp lệnh gởi vào là lệnh bán
            IF ( @loaiGD = 'B' )
			
                IF ( @giaDatMB <= @giadat )
                    BEGIN
					
                       IF @soLuongMB >= @soLuong
							BEGIN
								SET @soLuongkhop = @soLuong
								--giá khớp = giá mua trong cursor (
								SET @giaKhop = @giadat
								SET @soLuongMB = @soLuongMB - @soLuong

								-- xem đk if @soLuongMB>@soLuong, chứng tỏ lệnh mua trong cursor đã mua đủ
								UPDATE  dbo.LENHDAT
								SET SOLUONG = 0, TRANGTHAILENH = N'Khớp hết'
								WHERE CURRENT OF @cursorVar
                            END
                        ELSE
                            BEGIN
                                SET @soLuongkhop = @soLuongMB
                                SET @giaKhop = @giadat
       
                                UPDATE  dbo.LENHDAT
                                SET SOLUONG = SOLUONG - @soLuongMB , TRANGTHAILENH = N'Khớp lệnh 1 phần'
                                WHERE CURRENT OF @cursorVar
                                SET @soLuongMB = 0
                            END
	   		 -- cập nhật tổng số lượng khớp của lệnh gưi vào
                       SET @soLuongDaKhop = @soLuongDaKhop + @soLuongkhop
                       
			 -- Cập nhật table LENHKHOP
                        INSERT INTO dbo.LENHKHOP
								(NGAYKHOP,
                                  SOLUONGKHOP,
                                  GIAKHOP,
                                  IDLENHDAT)
                        VALUES (GETDATE() , -- NGAYKHOP - datetime   
                                  @soLuongkhop , -- SOLUONGKHOP - int
                                  @giaKhop , -- GIAKHOP - float
                                  @idLenhDat -- IDLENHDAT - int
	                            )
			 --Câp nhật thông tin giá và số lượng vừa khớp vào 	[dbo].[BANG_GIA_TRUC_TUYEN]
						IF EXISTS(SELECT * FROM dbo.BANG_GIA_TRUC_TUYEN WHERE MACP = @maCP)
							BEGIN
								UPDATE dbo.BANG_GIA_TRUC_TUYEN
								SET KL_GIA = @giaKhop, KL_SL = @soLuongkhop
								WHERE MACP = @maCP
							END
						ELSE
							BEGIN
                        		INSERT INTO dbo.BANG_GIA_TRUC_TUYEN
														(MACP, KL_GIA, KL_SL)
                       						VALUES  (@maCP, @giaKhop, @soLuongkhop)
							END
                    END
                ELSE
                    GOTO THOAT

    -- Còn Trường hợp lệnh gởi vào là lệnh mua
            IF ( @loaiGD = 'M' )
                IF ( @giaDatMB >= @giadat )
                    BEGIN
                        IF @soLuongMB >= @soLuong
                            BEGIN
                                SET @soLuongkhop = @soLuong
                                SET @giaKhop = @giadat
                                SET @soLuongMB = @soLuongMB - @soLuong
                               
							    UPDATE  dbo.LENHDAT
                                SET SOLUONG = 0, TRANGTHAILENH = N'Khớp hết'
                                WHERE CURRENT OF @cursorVar
                            END
                        ELSE
                            BEGIN
                                SET @soLuongkhop = @soLuongMB

                                SET @giaKhop = @giadat
       
                                UPDATE  dbo.LENHDAT
                                SET     SOLUONG = SOLUONG - @soLuongMB, TRANGTHAILENH = N'Khớp lệnh 1 phần'
                                WHERE CURRENT OF @cursorVar
                                SET @soLuongMB = 0
                            END
                      
					  -- cập nhật tổng số lượng khớp của lệnh gưi vào
                        SET @soLuongDaKhop = @soLuongDaKhop + @soLuongkhop
                                
			 -- Cập nhật table LENHKHOP
                        INSERT  INTO dbo.LENHKHOP
                                ( NGAYKHOP ,
                                  SOLUONGKHOP ,
                                  GIAKHOP ,
                                  IDLENHDAT
	                            )
                        VALUES  ( GETDATE() , -- NGAYKHOP - datetime   
                                  @soLuongkhop , -- SOLUONGKHOP - int
                                  @giaKhop , -- GIAKHOP - float
                                  @idLenhDat -- IDLENHDAT - int
	                            )

		     	-- Câp nhật thông tin giá và số lượng vừa khớp vào 	[dbo].[BANG_GIA_TRUC_TUYEN]
						IF EXISTS(SELECT * FROM dbo.BANG_GIA_TRUC_TUYEN WHERE MACP = @maCP)
						BEGIN
							UPDATE dbo.BANG_GIA_TRUC_TUYEN
							SET KL_GIA = @giaKhop, KL_SL = @soLuongkhop
							WHERE MACP = @maCP
						END
						ELSE
                        BEGIN
                        	INSERT INTO dbo.BANG_GIA_TRUC_TUYEN( MACP ,  KL_GIA , KL_SL )
                        	VALUES  ( @maCP, @giaKhop, @soLuongkhop )
                        	       
                        END

                    END
                ELSE
                    GOTO THOAT
 
           FETCH NEXT FROM @cursorVar INTO @idLenhDat, @ngayDat, @soLuong, @giadat
        
		END
    THOAT:
	-- nếu lệnh gửi vào không khớp hết, và tổng số khớp được >0 (khớp 1 phần)
    IF ( @soLuongMB > 0  AND @soLuongDaKhop > 0)
        BEGIN
            INSERT INTO LENHDAT
                   ( MACP, NGAYDAT, LOAIGD, LOAILENH, SOLUONG, GIADAT, TRANGTHAILENH )
            VALUES ( @maCP, @ngayDat, @loaiGD, N'LO', @soLuongMB, @giaDatMB, N'Khớp lệnh 1 phần')
        END
		-- nếu lệnh gửi vào không khớp hết, và tổng số khớp được = 0 (không khớp đc gì)
	ELSE IF ( @soLuongMB > 0  AND @soLuongDaKhop = 0)
		BEGIN
		 INSERT INTO LENHDAT 
					( MACP, NGAYDAT, LOAIGD, LOAILENH, SOLUONG, GIADAT, TRANGTHAILENH)
            VALUES ( @maCP, @ngay_Convert, @loaiGD, N'LO', @soLuongMB, @giaDatMB, N'Chờ khớp')
		END
		-- nếu lệnh gửi vào khớp hết
	ELSE IF ( @soLuongMB = 0 )
		BEGIN
		 INSERT INTO LENHDAT 
					( MACP, NGAYDAT, LOAIGD, LOAILENH, SOLUONG, GIADAT, TRANGTHAILENH)
            VALUES ( @maCP, @ngay_Convert, @loaiGD, N'LO', @soLuongMB, @giaDatMB, N'Khớp hết')
		END
	-- in ra kết quả  số lượng cổ phiếu khớp theo thuật toán khớp lệnh liên tục khi có 1 lệnh mua hoặc bán được gởi đến bảng LENHDAT
    PRINT N'Số lương cổ phiếu khớp: ' + CAST(@soLuongDaKhop AS NVARCHAR(10))
    CLOSE @cursorVar
    DEALLOCATE @cursorVar

GO
/****** Object:  StoredProcedure [dbo].[SP_REFRESH_BANGGIA_TRUCTUYEN]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Batch submitted through debugger: SQLQuery64.sql|7|0|C:\Users\phong\AppData\Local\Temp\~vs9095.sql
CREATE PROCEDURE [dbo].[SP_REFRESH_BANGGIA_TRUCTUYEN] 
 @LoaiGD NCHAR(1), -- vừa khớp lệnh nào
 @MACP CHAR(10),
 @NGAYDAT DATETIME,
 @GIADAT FLOAT 
AS

BEGIN --beginsp

-- Xóa table ảo nếu tồn tại
        IF EXISTS ( SELECT  *
                    FROM    tempdb.sys.tables
                    WHERE   name like '#TEMP_BGLD%' )
            DROP TABLE #TEMP_BGLD

		IF EXISTS ( SELECT  *
						FROM    tempdb.sys.tables
						WHERE   name like '#TEMP_BGLB_TOP3%' )
			DROP TABLE #TEMP_BGLB_TOP3

		IF EXISTS ( SELECT  *
						FROM    tempdb.sys.tables
						WHERE   name like '#TEMP_BGLM_TOP3%' )
			DROP TABLE #TEMP_BGLM_TOP3

			-- lấy ra danh sách LÊNH ĐẶT cần thao tác (cungf loại lệnh cùng ngày đặt và chưa khớp hết) bỏ vào tảng tạm #TEMP_BGLD
			SELECT  MACP, GIADAT, Sum(ISNULL(SOLUONG, 0)) AS SL
			INTO    #TEMP_BGLD
			FROM    dbo.LENHDAT
			WHERE   MACP = @MACP
					AND DAY(NGAYDAT) = DAY(@NGAYDAT)
					AND MONTH(NGAYDAT) = MONTH(@NGAYDAT)
					AND YEAR(NGAYDAT) = YEAR(@NGAYDAT)
					AND LOAIGD = @LoaiGD
					AND SOLUONG > 0
			GROUP BY MACP, GIADAT
			
			IF (@LoaiGD = 'M')
				BEGIN
				-- lấy 3 dòng đầu của #TEMP_BGLD
				   SELECT *
					INTO #TEMP_BGLM_TOP3
					FROM (SELECT *, ROW_NUMBER() 
							-- vì bảng giá sắp lệnh mua giá cao trước (giá mua 3, 2, 1)
							OVER (ORDER BY GIADAT DESC) AS Row_Number
							  FROM #TEMP_BGLD ) Temp
					WHERE Row_Number <= 3

					-- trường hợp đặc biệt(xử lý display BGTT): xóa giá trị các record trước khi insert mới vào trong BGTT
								
					UPDATE  dbo.BANG_GIA_TRUC_TUYEN
					SET     DM_GIA3 = 0, DM_GIA2 = 0, DM_GIA1 = 0, DM_SL1 = 0,
							DM_SL2 = 0, DM_SL3 = 0
					WHERE   MACP = @MACP

					IF EXISTS (SELECT * FROM #TEMP_BGLM_TOP3 WHERE Row_Number = 1)
						BEGIN  -- merge operation
							IF EXISTS (SELECT * FROM dbo.BANG_GIA_TRUC_TUYEN
												WHERE MACP = @MACP)
								BEGIN
									-- giá mua cao thì để ở SL1, GIA1
									UPDATE dbo.BANG_GIA_TRUC_TUYEN
									SET DM_GIA1 = ( SELECT  GIADAT
														FROM    #TEMP_BGLM_TOP3
														WHERE   Row_Number = 1
														) ,
											DM_SL1 = ( SELECT   SL
														FROM     #TEMP_BGLM_TOP3
														WHERE     Row_Number = 1
														)
									WHERE MACP = @MACP
								END
							ELSE
								BEGIN
								--nếu chưa có cổ phiếu đó trong bảng giá thì thêm vào
									INSERT INTO dbo.BANG_GIA_TRUC_TUYEN
											(MACP,
											  DM_GIA1,
											  DM_SL1)
											SELECT MACP ,
												   GIADAT ,
												   SL
											FROM #TEMP_BGLM_TOP3
											WHERE Row_Number = 1
								END
					END 
					 --cập nhật giá 2, sl 2 
					IF EXISTS (SELECT * FROM #TEMP_BGLM_TOP3 WHERE Row_Number = 2)
						BEGIN
							UPDATE  dbo.BANG_GIA_TRUC_TUYEN
								SET     DM_GIA2 = (SELECT GIADAT
													FROM #TEMP_BGLM_TOP3
													WHERE Row_Number = 2),
										DM_SL2 = (SELECT SL
													FROM #TEMP_BGLM_TOP3
													WHERE Row_Number = 2)
								WHERE   MACP = @MACP
						END
			--cập nhật giá 3, sl 3 
					IF EXISTS (SELECT * FROM #TEMP_BGLM_TOP3 WHERE Row_Number = 3)
						BEGIN
							UPDATE  dbo.BANG_GIA_TRUC_TUYEN
								SET     DM_GIA3 = (SELECT GIADAT
													FROM #TEMP_BGLM_TOP3
													WHERE Row_Number = 3),
										DM_SL3 = (SELECT SL
													FROM #TEMP_BGLM_TOP3
													WHERE Row_Number = 3)
								WHERE   MACP = @MACP
						END
		END
	ELSE
		BEGIN
					 SELECT  *
						INTO #TEMP_BGLB_TOP3
						FROM (SELECT * , 
									-- sắp đi lên vì bảng giá tt sắp lệnh bán giá thấp trước
										ROW_NUMBER() OVER ( ORDER BY GIADAT ASC) AS Row_Number
								  FROM #TEMP_BGLD) Temp
						WHERE Row_Number <= 3

             
					-- trường hợp đặc biệt(xử lý display BGTT): xóa giá trị các record trước khi insert mới vào trong BGTT
								
					UPDATE  dbo.BANG_GIA_TRUC_TUYEN
					SET     DB_GIA3=0, DB_GIA2 = 0,DB_GIA1 = 0, DB_SL1 = 0,
							DB_SL2 = 0, DB_SL3=0
					WHERE   MACP = @MACP

					--
					 IF EXISTS (SELECT * FROM #TEMP_BGLB_TOP3 WHERE Row_Number = 1)
						BEGIN  -- merge operation
							IF EXISTS ( SELECT  *
										FROM    dbo.BANG_GIA_TRUC_TUYEN
										WHERE   MACP = @MACP )
								BEGIN
									UPDATE  dbo.BANG_GIA_TRUC_TUYEN
									SET     DB_GIA1 = ( SELECT  GIADAT
														FROM    #TEMP_BGLB_TOP3
													   WHERE   Row_Number = 1
													  ) ,
											DB_SL1 = ( SELECT   SL
													   FROM     #TEMP_BGLB_TOP3
													   WHERE   Row_Number = 1
													 )
									WHERE   MACP = @MACP

								END
							ELSE
								BEGIN
									INSERT  INTO dbo.BANG_GIA_TRUC_TUYEN
											( MACP ,
											  DB_GIA1 ,
											  DB_SL1)
											SELECT  MACP ,
													GIADAT ,
													SL
											FROM    #TEMP_BGLB_TOP3
											WHERE   Row_Number = 1
								END
						END 
				 IF EXISTS (SELECT * FROM #TEMP_BGLB_TOP3 WHERE Row_Number = 2)
							BEGIN
						
									UPDATE  dbo.BANG_GIA_TRUC_TUYEN
									SET     DB_GIA2 = ( SELECT  GIADAT
														FROM    #TEMP_BGLB_TOP3
														WHERE  Row_Number = 2
													  ) ,
											DB_SL2 = ( SELECT   SL
													   FROM     #TEMP_BGLB_TOP3
													   WHERE  Row_Number = 2
													 )
									WHERE   MACP = @MACP
							END
				IF EXISTS (SELECT * FROM #TEMP_BGLB_TOP3 WHERE Row_Number = 3)
							BEGIN
						
									UPDATE  dbo.BANG_GIA_TRUC_TUYEN
									SET     DB_GIA3 = ( SELECT  GIADAT
														FROM    #TEMP_BGLB_TOP3
														WHERE  Row_Number = 3
													  ) ,
											DB_SL3 = ( SELECT   SL
													   FROM     #TEMP_BGLB_TOP3
													   WHERE  Row_Number = 3
													 )
									WHERE   MACP = @MACP
							END
			

		END

-- xóa mã cổ phiếu trong bảng nếu không còn lệnh đặt (không còn số lượng cần khớp)
	DECLARE @check BIGINT
		  
	SELECT @check = SUM(ISNULL(DM_SL3, 0)+ISNULL(DM_SL2, 0) +    ISNULL(DM_SL1, 0) +  ISNULL(DB_SL1, 0) + ISNULL(DB_SL2, 0)+ ISNULL(DB_SL3, 0))
	FROM dbo.BANG_GIA_TRUC_TUYEN
	WHERE MACP = @MACP

	IF (@check = 0)
	BEGIN
		DELETE FROM dbo.BANG_GIA_TRUC_TUYEN WHERE MACP = @MACP
	END

END --endsp
GO
/****** Object:  Trigger [dbo].[TRIGGER_AFTER_DELETE_LENHDAT]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRIGGER_AFTER_DELETE_LENHDAT] 
			ON [dbo].[LENHDAT]
			AFTER DELETE
AS
BEGIN
		
	 DECLARE 
			@loaiGD_Deleted NCHAR(1),
			@maCP_Deleted CHAR(7),
            @ngayDat_Deleted DATETIME,
            @giaDat_Deleted FLOAT,
			@soLuong_Deleted INT
	
	DECLARE @ngayHienTai DATETIME
	SET @ngayHienTai = GETDATE()
	 
		-- gán các giá trị cần thiết...
		SELECT  @loaiGD_Deleted = Deleted.LOAIGD,
                @maCP_Deleted = Deleted.MACP ,
                @ngayDat_Deleted= Deleted.NGAYDAT,
				@giaDat_Deleted = Deleted.GIADAT ,
				@soLuong_Deleted = Deleted.SOLUONG
        FROM   Deleted
		

	IF (DAY(@ngayHienTai)=DAY(@NGAYDAT_Deleted) AND MONTH(@ngayHienTai)= MONTH(@NGAYDAT_Deleted) AND YEAR(@ngayHienTai)=YEAR(@NGAYDAT_Deleted)  
    AND @soLuong_Deleted  > 0 )
	BEGIN
		EXEC [dbo].[SP_REFRESH_BANGGIA_TRUCTUYEN] @loaiGD_Deleted, @maCP_Deleted, @ngayDat_Deleted, @giaDat_Deleted		
	END

  




		
			

  
END 
GO
ALTER TABLE [dbo].[LENHDAT] ENABLE TRIGGER [TRIGGER_AFTER_DELETE_LENHDAT]
GO
/****** Object:  Trigger [dbo].[TRIGGER_AFTER_INSERT_LENHDAT]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRIGGER_AFTER_INSERT_LENHDAT] 
			ON [dbo].[LENHDAT]
			AFTER INSERT
AS
BEGIN
	 DECLARE 
			@loaiGD_Inserted NCHAR(1),
			@maCP_Inserted CHAR(7),
            @ngayDat_Inserted DATETIME,
            @giaDat_Inserted FLOAT,
			@soLuong_Inserted INT
	
	IF UPDATE(SOLUONG)
		BEGIN
	 
			-- gán các giá trị cần thiết...
			SELECT  @loaiGD_Inserted = Inserted.LOAIGD,
					@maCP_Inserted = Inserted.MACP,
					@ngayDat_Inserted= Inserted.NGAYDAT,
					@giaDat_Inserted = Inserted.GIADAT,
					@soLuong_Inserted = Inserted.SOLUONG
			FROM   Inserted

			EXEC [dbo].[SP_REFRESH_BANGGIA_TRUCTUYEN] @loaiGD_Inserted, @maCP_Inserted, @ngayDat_Inserted, @giaDat_Inserted		
		END
END 
GO
ALTER TABLE [dbo].[LENHDAT] ENABLE TRIGGER [TRIGGER_AFTER_INSERT_LENHDAT]
GO
/****** Object:  Trigger [dbo].[TRIGGER_AFTER_UPDATE_LENHDAT]    Script Date: 29/04/2022 10:59:08 am ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TRIGGER_AFTER_UPDATE_LENHDAT] 
			ON [dbo].[LENHDAT]
			AFTER UPDATE
AS
BEGIN
	 DECLARE 
			@loaiGD_Updated NCHAR(1),
			@maCP_Updated CHAR(7),
            @ngayDat_Updated DATETIME,
            @giaDat_Updated FLOAT,
			@soLuong_Updated INT
	
	IF UPDATE(SOLUONG)
		BEGIN
	 
			-- gán các giá trị cần thiết...
			SELECT  @loaiGD_Updated = Inserted.LOAIGD,  -- Inserted vì sql update theo kiểu insert new row to delete old row
					@maCP_Updated = Inserted.MACP ,
					@ngayDat_Updated= Inserted.NGAYDAT,
					@giaDat_Updated = Inserted.GIADAT ,
					@soLuong_Updated = Inserted.SOLUONG
			FROM   Inserted

			EXEC [dbo].[SP_REFRESH_BANGGIA_TRUCTUYEN] @loaiGD_Updated, @maCP_Updated, @ngayDat_Updated, @giaDat_Updated		
		END
END 
GO
ALTER TABLE [dbo].[LENHDAT] ENABLE TRIGGER [TRIGGER_AFTER_UPDATE_LENHDAT]
GO
