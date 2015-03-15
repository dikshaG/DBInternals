
Use master
if exists (select * from sys.databases where name = 'DBProject' )
	drop database "DBProject"
Create database DBProject;	--recreating DBProject database

GO
/*
* Creating 2 tables in DBProject database:
* 1. Student table with Student_Id as primary key.
*	 and non-clustered index on Dept_ID.
* 2. Department table with Dept_Id as primary key.
*/

DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
set statistics time on;
USE DBProject;
if exists (select * from sysobjects where id = object_id('Student') )
	drop table "Student"
if exists (select * from sysobjects where id = object_id('Department') )
	drop table "Department"

Create table Student(Student_Id int NOT NULL ,Dept_Id int NOT NULL,Student_Name varchar(50),Age int,
						City varchar(50),Grade varchar(5) CONSTRAINT PK_Student PRIMARY KEY (Student_Id));
Create table Department(Dept_Id int NOT NULL,Dept_Code char(5),Dept_Name varchar(30) CONSTRAINT PK_Dept PRIMARY KEY (Dept_Id));
Create index SDeptId on Student(Dept_Id);

/*
 drop table Student;
 drop table Department; 
*/


/*
* Inserting 10 rows in Student table 
* and 3 in Department table.
*/

--Department Table
Insert into Department values(100,'CS40','Computers');
Insert into Department values(200,'CS49','Algorithms');
Insert into Department values(300,'CS47','Database');

 --Select * from Department;

--Student Table:
Insert into Student values(1001,100,'N',60,'Redmond','B');
declare @i int, @c int
set @i = 1002
set @c=0
while @i <= 1010
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Seattle','A');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end
 


 -- Select * from Student;

 /*
  delete from Student;
  delete from Department;
 */
GO

/*
* Using the following query say Q1, execution plan generated is making following logical reads:
* Department table: 20 with 0 scan count.
* Student table: 4 with 2 scan count.
* But if we specify explicitly to query optimizer to use index PK_Student which is also used by Q1,
* the execution plan changes for query say Q2 (same as Q1 but only using statement-with(index(PK_Student)).
* Now, following are the logical reads:
* Department table: 2 with 0 scan count.
* Student table: 4 with 2 scan count.
* Also, if we analyze the relative query cost of both Q1 and Q2, Q1 amounts to 52% and Q2 amounts to 48%.
* Hence, we can conclude that with Q1, query optimizer made a wrong decision by joining the result from both 
* the table first then joining it with sub query result whereas at the same time if subquery result was first 
* joined with seek result of Department table and then scan result of Student table incurs less scans on 
* Department table, thereby generating less cost overall. The wrong decision of query optimizer may be because
* of incorrect decision of choice between various plans to generate the result, this generally happen when there
* are many plans to generate the result and query optimizer have to make a choice between many plans for one.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 1 ms with
		 SQL Server parse and compile time: CPU time = 16 ms, elapsed time = 82 ms.
* For Q2: CPU time = 0 ms,  elapsed time = 0 ms with
	SQL Server parse and compile time: CPU time = 6 ms, elapsed time = 6 ms.
* So, Query 2 takes less amount of time than Query 1.
* Execution Plan 1.
*/
GO
--Q1:

Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)

DBCC DROPCLEANBUFFERS;
--Q2:
Select s.Student_Name from Student s with(index(PK_Student)),Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO


--Adding rows to Student table to total up to 1138
declare @i int, @c int
set @i = 1011
set @c=0
while @i <= 1138
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Seattle','A');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end

   -- Select * from Student;

  GO

/*
* After inserting 128 more rows, there are total 138 rows in Student table and 3 in Department table.
* Query Q1 changes execution plan, now Hash join is used instead of nested loop joins. On the other 
* hand Query Q2 is using clustered index-PK_Student and loop join generating execution plan 1(as seen above).
* On comparing statistics of 2 plans both perform same number of scan and logical read but Q1 uses 2 additional
* temp. tables as it uses hash join. Also, if we analyze the relative query cost of both Q1 and Q2, Q1 amounts to
* 64% and Q2 amounts to 36%. Hence, we can conclude that with Q1, query optimizer made a wrong decision by using 
* hash join as it incurs more cost and space.
* The wrong decision of query optimizer may be because of the boundary condition where query optimizer
* tends to make a choice switch for better plan(hash join) for further data but in the process compromise the results for
* current execution resulting in wrong selection of join for execution plan.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 1 ms with
		 SQL Server parse and compile time: CPU time = 12 ms, elapsed time = 12 ms.
* For Q2: CPU time = 0 ms,  elapsed time = 0 ms with
		SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 3 ms.
* So, Query 2 takes less amount of time than Query 1.
* Execution Plan 2.
*/
--Q1
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)

DBCC DROPCLEANBUFFERS;

--Q2
Select s.Student_Name from Student s with(index(PK_Student)),Department d where s.Dept_Id=d.Dept_Id 
					AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student) option(loop join)

GO

--Deleting 113 rows from Student Table:
delete from Student;
Insert into Student values(1001,100,'N',60,'Redmond','B');
declare @i int, @c int
set @i = 1002
set @c=0
while @i <= 1025
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Seattle','A');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end

GO
/*
* After deleting 113 rows in Student table (total rows:25) and 3 in Department table.
* Query Q1 changes execution plan, now there is non-clustered index- SDeptId bookmark lookup for fetching
* Student_Name on Student table. On the other hand Query Q2 is using clustered index-PK_Student and generating
* execution plan 1(as seen above). On comparing statistics of 2 plans,for query Q1:
* Student table makes 54 logical reads and 2 scan count.
* Department table makes 2 logical reads and 0 scan count.
* for query Q2:
* Student table makes 4 logical reads and 2 scan count.
* Department table makes 2 logical reads and 0 scan count.
* Also, if we analyze the relative query cost of both Q1 and Q2, Q1 amounts to 54% and Q2 amounts to 46%.
* Hence, we can conclude that with Q1, query optimizer made a wrong decision by using bookmark lookup on 
* Student table using non-clustered index as it incurs more cost than using clustered index only.
* The wrong decision of query optimizer may be because of the boundary condition where query optimizer
* tends to make a choice switch for better plan(bookmark lookup) for further data but in the process compromise
* the results for current execution by choosing bookmark lookup using non-clustered index instead of clustered index.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 0 ms with
		 SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 52 ms.
* For Q2: CPU time = 0 ms,  elapsed time = 0 ms with
		SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 32 ms.
* So, Query 2 takes less amount of time than Query 1.
* Execution Plan 3.
*/

GO

--Q1:
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
DBCC DROPCLEANBUFFERS;
--Q2:
Select s.Student_Name from Student s with(index(PK_Student)),Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

--Inserting 739 rows in Student table
declare @i int, @c int
set @i = 1026
set @c=0
while @i <= 1764
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Seattle','A');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end

   -- Select * from Student;

  GO

/*
* After inserting 739 more rows, there are total 764 rows in Student table and 3 in Department table.
* Query Q1 changes execution plan, now Hash aggregate is used instead of steam aggregate. On the other 
* hand with Query Q2, we are forcing query optimizer to use steam aggregation.
* On comparing statistics of 2 plans both perform same number of scan and logical read but Q1 uses 2 additional
* temp. tables as it uses hash aggregation. Also, if we analyze the relative query cost of both Q1 and Q2 both 
* are equal to 50%. Hence, we can conclude that with Q1, query optimizer made a wrong decision by using 
* hash join as it incurs more space for 2 temperory work table for build and probe functions.
* The wrong decision of query optimizer may be because of the boundary condition where query optimizer
* tends to make a choice switch for better plan(hash aggregate) for further data but in the process compromise the
* results for current execution resulting in wrong selection of aggregation operator for execution plan.
* Execution time:
* For Q1: CPU time = 16 ms,  elapsed time = 17 ms with
		 SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.
* For Q2: CPU time = 0 ms,  elapsed time = 24 ms with
	SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 0 ms.
* So, Query 2 takes less amount of time than Query 1.
* Execution Plan 4.
*/
GO

--Q1
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
DBCC DROPCLEANBUFFERS;
--Q2
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
									AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student) option(order group)
GO
/*
* For the following execution plan, SCity non-clustered index is created on City column of Student table.
* Now, if we run query, Q1- query optimizer chooses the best execution plan by doing a bookmark lookup as
* the query results in only 1 row out of 764 records in Student table. However, if I modify Q1 to Q2,
* execution plan changes to clustered index scan even for 1 record. The Query Optimizer doesn’t know what
* value the @City variable holds until runtime, and does not check statistics for variables before a query
* runs. When in doubt, the Query Optimizer will always choose a scan and thus generating an unoptimized plan.
* As seek cheaper operation than scan (Also, we have seen for Q1, optimizer choose to bookmark lookup)
* Q2 is modified to Q3, explicitly asking query optimizer to optimize plan for City='Redmond' so that more 
* cost effective bookmark mark lookup can be done as in this case.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 57 ms.
* For Q2: CPU time = 15 ms,  elapsed time = 14 ms.
* For Q3: CPU time = 0 ms,  elapsed time = 12 ms.
* Execution Plan 5.
* Source: http://blog.sqlauthority.com/2012/04/25/sql-server-introduction-to-basics-of-a-query-hint-a-primer/
*/
--select * from Student
GO

Create index SCity on Student(City);

--Q1
SELECT * FROM Student WHERE City = 'Redmond'

DBCC DROPCLEANBUFFERS;
--Q2
DECLARE @City VARCHAR ( 50 )
SET @City = 'Redmond'
SELECT * FROM Student WHERE City = @City 

DBCC DROPCLEANBUFFERS;
--Q3
DECLARE @City3 VARCHAR ( 50 )
SET @City3 = 'Redmond'
SELECT * FROM Student WHERE City = @City3 OPTION ( OPTIMIZE FOR ( @City3 = 'Redmond' ));

GO


--Table RandomDataTable is created having non-uniform data
if exists (select * from sysobjects where id = object_id('RandomDataTable') )
	drop table "RandomDataTable"
CREATE TABLE RandomDataTable ( MyKeyField VARCHAR(10) NOT NULL, MyDate1 DATETIME NOT NULL, MyDate2 DATETIME NOT NULL,
							 MyDate3 DATETIME NOT NULL, MyDate4 DATETIME NOT NULL, MyDate5 DATETIME NOT NULL )
--Delete from RandomDataTable;
-- select * from RandomDataTable;

--Script for inserting 100000 records in RandomDataTable.
DECLARE @RowCount INT
DECLARE @RowString VARCHAR(10)
DECLARE @Random INT
DECLARE @Upper INT
DECLARE @Lower INT
DECLARE @InsertDate DATETIME

SET @Lower = -730
SET @Upper = -1
SET @RowCount = 0

WHILE @RowCount < 1265
	BEGIN 
	SET @RowString = CAST(@RowCount AS VARCHAR(10))
	SELECT @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
	SET @InsertDate = DATEADD(dd, @Random, GETDATE())
	INSERT INTO RandomDataTable VALUES (REPLICATE('0', 10 - DATALENGTH(@RowString)) + @RowString ,
										 @InsertDate ,
										 DATEADD(dd, 1, @InsertDate) ,
										 DATEADD(dd, 2, @InsertDate) ,
										 DATEADD(dd, 3, @InsertDate) ,
										 DATEADD(dd, 4, @InsertDate))
	 SET @RowCount = @RowCount + 1 
	 END

GO

/*
* On executing the following query Q1, we observe that statistics estimation made by query optimizer are
* different from that of Actual statistics.
* Estimated Number of Rows:207.86
* Actual Number of Rows:226
* Now, this wrong estimation of statistics may be the result of
* query optimizer assumption about the data in table. Query Optimizer assumes that data stored in the table
* is uniformly distributed and hence the estimations are also made on that basis while in this case we have
* inserted non-uniform data which resulted in wrong estimation.
* For Query 2, same type of query is used on table Student where data is uniformly distributed and hence the
* estimations done by the optimizer are also correct.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 55 ms.
* For Q2: CPU time = 0 ms,  elapsed time = 1 ms.
* Execution Plan 6.
*/ 


DBCC DROPCLEANBUFFERS;
--Q1
	 select MyDate2 from RandomDataTable where MyKeyField between 1000 and 1265;

--Q2
	Select Dept_Id From Student where Student_Id between 1000 and 1265;


--Inserting 500 more rows for different dept ids in Student table

declare @i int, @c int,@did int
set @i = 1765
set @c=0
set @did=301
while @i <= 2265
  begin
    Insert into Student values(@i,@did,CHAR(@c+ASCII('a')),40,'Seattle','A');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
	set @did=@did+1
  end

GO

/*
* When a qery is written with Multi-Column Restrictions, query optimizer tende to make mistakes in estimating
* number of columns in output as Optimizers assume column value independence. Independence is rarely the right
* choice – there is usually correlation amongst columns. Hence optimizer made wrong statistic estimation of 39.63
* while 31 rows are selected in output.
* Execution time:
* For Q1: CPU time = 0 ms,  elapsed time = 57 ms.
* Execution Plan 7.
*/

GO

DBCC DROPCLEANBUFFERS;
--Q1
select Student_Name from Student where Dept_Id=100 and Student_Name='b'


GO

--END OF PROJECT

