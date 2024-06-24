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
* ����Ŀ����github��Դ					https://github.com/phtcloud-dev/SQLClass					*
-----------------------------------------------------------------------------------------------------
* �湣���湣�����ǵø�л�ڴ���Ŀ��������															*
* phtcloud-dev			��������		������Ϣְҵ����ѧԺ			һ��ֻ����Σ����С��		*
* Nah1a					��������		��ͷ��ѧҽѧԺ					�����ҩ��ѧ��ƿƵ���		*
* ����ѩ				bugѰ����		������Ϣְҵ����ѧԺ			����ô���أ�				*
* ۰ĳ��				�ṹ�Ż�		������Ϣְҵ����ѧԺ			С�����ҵ�С����			*
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
        PRINT '��ԱID: ' + CAST(@MemberID AS NVARCHAR(255)) +
              ', ��Ա��: ' + @MemberName +
              ', �������: ' + CONVERT(NVARCHAR(30), GETDATE(), 120) +
              ', �鼮����: ��' + @BookTitle +
              '��, ʣ������: ' + CAST(@Quantity AS NVARCHAR(255))

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
        PRINT '�鼮����: ��' + @BookTitle +
              '��, ��Ա��: ' + @MemberName +
              ', �Ƿ���: ' + CAST(@IsDamaged AS NVARCHAR(255)) +
              ', ��ע: ' + ISNULL(@Remarks, 'None') +
              ', ʣ������: ' + CAST(@RemainingQuantity AS NVARCHAR(255)) +
              ', �����¼�id: ' + CAST(@ReturnID AS NVARCHAR(255))

        FETCH NEXT FROM cursor_return INTO @BookTitle, @IsDamaged, @Remarks, @RemainingQuantity, @MemberName, @ReturnID
    END

    CLOSE cursor_return
    DEALLOCATE cursor_return
END
GO


INSERT INTO Books (BookID, Title, Author, Publisher, YearPublished, Quantity)
VALUES 
(1, '��R8������', 'simp1e', 'ϣ��˹����', 1999, 10),
(2, '�����ת�д�ȫ', '��ѩ��', '13վ������', 2022, 6),
(3, '��������1988', '����', 'ɱ���ر��ų�����', 1988, 2),
(4, 'Զ��������ä������', '����', '��ƤЦ��������', 2022, 1),
(5, '�ڶ�����·', '�����', 'SZIIT CA - G2 Publisher', 2024, 3),
(6, '���ʹ��AI���н�ѧ', 'ҽ����˿�', '�˹����ϳ�����', 2016, 99),
(7, '�ȳ�����', 'H360', 'H360��Ʒ������', 2016, 0);

INSERT INTO Members (MemberID, Name, Email, Phone, JoinDate)
VALUES 
(1, 'ְҵѡ����֣��', '1@example.com', '11111111111', '2024-01-01'),
(2, 'JVAV֮��', '2@example.com', '11111111112', '2024-02-01'),
(3, '��ǿ', '3@example.com', '11111111113', '2024-03-01'),
(4, '������԰�׶�԰ͼ���', '4@example.com', '11111111114', '2024-04-01'),
(5, '���', '5@example.com', '11111111115', '2024-05-01'),
(6, '��ΰ��', '6@example.com', '11111111116', '2024-06-01'),
(7, '������', '7@example.com', '11111111117', '2024-07-01');

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
(1, 1, '2024-07-11', 1, '����ˮ��͸'),
(2, 2, '2024-07-12', 1, '�ҵ��������'),
(3, 3, '2024-07-13', 1, '�����罦ѪҺ'),
(4, 4, '2024-07-14', 0, ''),
(5, 5, '2024-07-15', 0, '�����黹'),
(6, 6, '2024-07-16', 1, 'ȱҳ���ضദ�ʼ�'),
(7, 7, '2024-07-16', 0, 'δ���𵫾��������߼�ⷢ��');

select * from Books
select * from Members
select * from BorrowRecords
select * from ReturnRecords