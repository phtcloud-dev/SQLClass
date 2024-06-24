/*
-----------------------------------------------------------------------------------------------------
*					~!@#$%^&*......																	*
*					Stop looking my project!!!														*
*					It just like a shit!!!															*
*					To be honest,I'am not good at SQL!!!											*
*					So pls close this file now try to write some code by yourself!					*
*					Good luck!																		*
*																		---By Phtcloud_Dev 2024		*
-----------------------------------------------------------------------------------------------------
*					Upload this file to ftp://meme@149.28.221.15/SQL								*
*					password is 000456@sql															*
*																		---By Phtcloud_Dev Github	*
-----------------------------------------------------------------------------------------------------
* 该项目已在github开源					https://github.com/phtcloud-dev/SQLClass					*
-----------------------------------------------------------------------------------------------------
* 玩梗归玩梗，还是得感谢在此项目付出的人															*
* phtcloud-dev			主负责人		深圳信息职业技术学院			一个只会打高危洞的小白		*
* Nah1a					技术顾问		汕头大学医学院					你见过药理学玩计科的吗		*
* 寒江雪				bug寻找者		深圳信息职业技术学院			那怎么办呢？				*
* 郯某人				结构优化		深圳信息职业技术学院			小美！我的小美！			*
-----------------------------------------------------------------------------------------------------
*/
IF OBJECT_ID('dbo.ReturnRecords', 'U') IS NOT NULL DROP TABLE dbo.ReturnRecords;
IF OBJECT_ID('dbo.BorrowRecords', 'U') IS NOT NULL DROP TABLE dbo.BorrowRecords;
IF OBJECT_ID('dbo.Members', 'U') IS NOT NULL DROP TABLE dbo.Members;
IF OBJECT_ID('dbo.Books', 'U') IS NOT NULL DROP TABLE dbo.Books;

CREATE TABLE Books (
    BookID INT PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    Author NVARCHAR(255) NOT NULL,
    Publisher NVARCHAR(255) NOT NULL,
    YearPublished INT CHECK (YearPublished > 0),
    Quantity INT CHECK (Quantity >= 0)
);

CREATE TABLE Members (
    MemberID INT PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(11) NULL,
    JoinDate DATE DEFAULT GETDATE()
);

CREATE TABLE BorrowRecords (
    BorrowID INT PRIMARY KEY,
    BookID INT,
    MemberID INT,
    BorrowDate DATE DEFAULT GETDATE(),
    DueDate DATE NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

CREATE TABLE ReturnRecords (
    ReturnID INT PRIMARY KEY,
    BorrowID INT,
    ReturnDate DATE DEFAULT GETDATE(),
    IsDamaged BIT DEFAULT 0,
    Remarks NVARCHAR(255) NULL,
    FOREIGN KEY (BorrowID) REFERENCES BorrowRecords(BorrowID) ON DELETE CASCADE
);

GO
IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'dbo.PrintBorrowDetails'))
BEGIN
    DROP TRIGGER dbo.PrintBorrowDetails;
END
GO

CREATE TRIGGER dbo.PrintBorrowDetails
ON dbo.BorrowRecords
AFTER INSERT
AS
BEGIN
    DECLARE @MemberName NVARCHAR(255)
    DECLARE @MemberID INT
    DECLARE @BookTitle NVARCHAR(255)
    DECLARE @Quantity INT

    DECLARE cursor_borrow CURSOR FOR
    SELECT m.Name, b.Title, b.Quantity, i.MemberID
    FROM inserted i
    INNER JOIN Members m ON i.MemberID = m.MemberID
    INNER JOIN Books b ON i.BookID = b.BookID

    OPEN cursor_borrow
    FETCH NEXT FROM cursor_borrow INTO @MemberName, @BookTitle, @Quantity, @MemberID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '会员ID: ' + CAST(@MemberID AS NVARCHAR(255)) +
              ', 会员名: ' + @MemberName +
              ', 借出日期: ' + CONVERT(NVARCHAR(30), GETDATE(), 120) +
              ', 书籍名字: 《' + @BookTitle +
              '》, 剩余数量: ' + CAST(@Quantity AS NVARCHAR(255))

        FETCH NEXT FROM cursor_borrow INTO @MemberName, @BookTitle, @Quantity, @MemberID
    END

    CLOSE cursor_borrow
    DEALLOCATE cursor_borrow
END
GO

IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'dbo.PrintReturnDetails'))
BEGIN
    DROP TRIGGER dbo.PrintReturnDetails;
END
GO

CREATE TRIGGER dbo.PrintReturnDetails
ON ReturnRecords
AFTER INSERT
AS
BEGIN
    DECLARE @BookTitle NVARCHAR(255)
    DECLARE @IsDamaged BIT
    DECLARE @Remarks NVARCHAR(255)
    DECLARE @RemainingQuantity INT
    DECLARE @MemberName NVARCHAR(255)
    DECLARE @ReturnID INT

    DECLARE cursor_return CURSOR FOR
    SELECT b.Title, i.IsDamaged, i.Remarks, b.Quantity - COUNT(r.ReturnID) OVER (PARTITION BY br.BookID) AS RemainingQuantity, m.Name AS MemberName, r.ReturnID
    FROM inserted i
    INNER JOIN BorrowRecords br ON i.BorrowID = br.BorrowID
    INNER JOIN Books b ON br.BookID = b.BookID
    INNER JOIN Members m ON br.MemberID = m.MemberID
    LEFT JOIN ReturnRecords r ON br.BorrowID = r.BorrowID
    GROUP BY b.Title, i.IsDamaged, i.Remarks, b.Quantity, br.BookID, m.Name, r.ReturnID

    OPEN cursor_return
    FETCH NEXT FROM cursor_return INTO @BookTitle, @IsDamaged, @Remarks, @RemainingQuantity, @MemberName, @ReturnID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '书籍名字: 《' + @BookTitle +
              '》, 会员名: ' + @MemberName +
              ', 是否损坏: ' + CAST(@IsDamaged AS NVARCHAR(255)) +
              ', 备注: ' + ISNULL(@Remarks, 'None') +
              ', 剩余数量: ' + CAST(@RemainingQuantity AS NVARCHAR(255)) +
              ', 还书事件id: ' + CAST(@ReturnID AS NVARCHAR(255))

        FETCH NEXT FROM cursor_return INTO @BookTitle, @IsDamaged, @Remarks, @RemainingQuantity, @MemberName, @ReturnID
    END

    CLOSE cursor_return
    DEALLOCATE cursor_return
END
GO


INSERT INTO Books (BookID, Title, Author, Publisher, YearPublished, Quantity)
VALUES 
(1, '从R8到陀螺', 'simp1e', '希爱斯锅服', 1999, 10),
(2, '计算机转行大全', '张雪峰', '13站出版社', 2022, 6),
(3, '沈阳旧事1988', '虎哥', '杀马特兵团出版社', 1988, 2),
(4, '远离赛博文盲宣传册', '陈泽', '嬉皮笑脸出版社', 2022, 1),
(5, '挖洞与跑路', '彭昊天', 'SZIIT CA - G2 Publisher', 2024, 3),
(6, '如何使用AI进行教学', '医聋麻丝氪', '人工智障出版社', 2016, 99),
(7, '腥城少铝', 'H360', 'H360精品出版社', 2016, 0);

INSERT INTO Members (MemberID, Name, Email, Phone, JoinDate)
VALUES 
(1, '职业选手吕郑豪', '1@example.com', '11111111111', '2024-01-01'),
(2, 'JVAV之父', '2@example.com', '11111111112', '2024-02-01'),
(3, '华强', '3@example.com', '11111111113', '2024-03-01'),
(4, '反斗花园幼儿园图书馆', '4@example.com', '11111111114', '2024-04-01'),
(5, '蝗睿', '5@example.com', '11111111115', '2024-05-01'),
(6, '刘伟儿', '6@example.com', '11111111116', '2024-06-01'),
(7, '辣椒油', '7@example.com', '11111111117', '2024-07-01');

INSERT INTO BorrowRecords (BorrowID, BookID, MemberID, BorrowDate, DueDate)
VALUES 
(1, 1, 1, '2024-06-11', '2024-07-11'),
(2, 2, 2, '2024-06-12', '2024-07-12'),
(3, 3, 3, '2024-06-13', '2024-07-13'),
(4, 4, 4, '2024-06-14', '2024-07-14'),
(5, 5, 5, '2024-06-15', '2024-07-15'),
(6, 6, 6, '2024-06-16', '2024-07-16'),
(7, 7, 7, '2024-06-17', '2024-07-17');

INSERT INTO ReturnRecords (ReturnID, BorrowID, ReturnDate, IsDamaged, Remarks)
VALUES 
(1, 1, '2024-07-11', 1, '被汗水浸透'),
(2, 2, '2024-07-12', 1, '找到多出油渍'),
(3, 3, '2024-07-13', 1, '疑似喷溅血液'),
(4, 4, '2024-07-14', 0, ''),
(5, 5, '2024-07-15', 0, '公安归还'),
(6, 6, '2024-07-16', 1, '缺页严重多处笔记'),
(7, 7, '2024-07-16', 0, '未破损但经过紫外线检测发光');

select * from Books
select * from Members
select * from BorrowRecords
select * from ReturnRecords