--PROJECT phase 2


--Dropping the database if it already exists.

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
USE DBProject;
if exists (select * from sysobjects where id = object_id('Student') )
	drop table "Student"
if exists (select * from sysobjects where id = object_id('Department') )
	drop table "Department"

Create table Student(Student_Id int NOT NULL PRIMARY KEY,Dept_Id int NOT NULL,Student_Name varchar(50),Age int,
						City varchar(50),Grade varchar(5));
Create table Department(Dept_Id int NOT NULL PRIMARY KEY,Dept_Code char(5),Dept_Name varchar(30));
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
* Using the following query say Q, execution plan is 
* 1) Clustered index Scan on Student table for 
*	 subquery which uses Steam aggregation for Sum 
*	 and Distinct Sort for DISTINCT, result is nested
*	 loop joined with the result in following point 2).
* 2) The Clustered index scan on Student table (all rows 
*	 with Dept_Id=100,hence scan is used) uses Nested
*	 Loop join to join with Department table on which  
*	 Clustered index seek is done.
* Nested Loop join are used as there are only 10 rows in 
* Student table and these are useful when there are relatively 
* small inputs with an index on the inner table on the join key.
* 1st Execution Plan
*/ 

Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

--Inserting 101 more rows
 declare @i int, @c int
set @i = 1011
set @c=0
while @i <= 1112
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Redmond','B');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end

   -- Select * from Student;

  GO

--Still 1st Execution Plan
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

/*
* On inserting 112th row with Student_Id=1113,
* Merge join is used instead of Nested Loop Join
* to join the result from subquery to orginal query
* as merge joins are best where medium inputs with
* indexes are present to provide order on the equijoin
* keys or where we require order after the join.
* 2nd Execution Plan.
*/

Insert into Student values(1113,100,'a',40,'Bellevue','A');
GO
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					  	AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

--Inserting 23 more rows
declare @i int, @c int
set @i = 1114
set @c=0
while @i <= 1137
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Redmond','B');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end

-- Select * from Student;

  GO

--Still 2nd Execution Plan.
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					  	AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

/*
* After inserting 23 rows, total rows in Student table
* are 136.On inserting 137th row, Hash join is used 
* instead of Merge Join to join the result from subquery
* to orginal query as hash joins are best where large
* inputs with indexes are present to provide order on the
* equijoin keys or there is parallel execution that scales 
* linearly.
* 3rd Execution Plan.
*/

Insert into Student values(1138,100,'a',40,'Bellevue','A');
GO
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					  	AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student) 
GO

-- Inserting 370 more rows in Student table
declare @i int, @c int
set @i = 1139
set @c=0
while @i <= 1509
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Tacoma','B');
    set @i = @i + 1
		IF @c>24 
			Set @c=0;
	Set @c=@c+1;
  end
 
 -- Select * from Student;

 GO

--Back to 1st Execution Plan.
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO
 
/* After inserting 370 more rows, there are total
* 508 rows. On inserting 509th row and executing
* query Q, query optimizer chooses to bookmark 
* lookup for Student_Name as it perform fewer
* random I/Os and touch fewer rows  using a
* non-clustered index seek with a more 
* selective predicate.
* 4th Execution Plan. 
*/

Insert into Student values(1510,100,'a',40,'Bellevue','A');
GO 
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO


 --Inserting 253 more rows
declare @i int,@c int
set @i = 1511
set @c=0
while @i <= 1763
  begin
    Insert into Student values(@i,100,CHAR(@c+ASCII('a')),40,'Redmond','B');
    set @i = @i + 1
		IF @c>24 
			Set @c=0
	Set @c=@c+1;
  end

-- Select * from Student;

  GO

--Still 4th Execution Plan
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					  	AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student)
GO

/* After insertion,total rows in Student table are 762.
 * On inserting 763rd row, Sort Distinct changes to Hash
 * Match because when the table gets big enough and the
 * number of groups(in this case there is only 1 group
 * with dept_Id=100) remains small,eventually the 
 * optimizer will decide that it is cheaperto use the
 * hash aggregate and sort after aggregation.
 * 5th Execution Plan.
 */

Insert into Student values(1764,100,'a',40,'Bellevue','A');
GO
Select s.Student_Name from Student s,Department d where s.Dept_Id=d.Dept_Id 
					  	AND s.Dept_Id=(Select SUM(DISTINCT Age) from Student) 

GO
--END OF PHASE 2.