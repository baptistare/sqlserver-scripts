/*
ALTER DATABASE database_name   
{  
    <add_or_modify_files>  
  | <add_or_modify_filegroups>  
}  
[;]  

<add_or_modify_files>::=  
{  
    ADD FILE <filespec> [ ,...n ]   
        [ TO FILEGROUP { filegroup_name } ]  
  | ADD LOG FILE <filespec> [ ,...n ]   
  | REMOVE FILE logical_file_name   
  | MODIFY FILE <filespec>  
}  

<filespec>::=   
(  
    NAME = logical_file_name    
    [ , NEWNAME = new_logical_name ]   
    [ , FILENAME = {'os_file_name' | 'filestream_path' | 'memory_optimized_data_path' } ]   
    [ , SIZE = size [ KB | MB | GB | TB ] ]   
    [ , MAXSIZE = { max_size [ KB | MB | GB | TB ] | UNLIMITED } ]   
    [ , FILEGROWTH = growth_increment [ KB | MB | GB | TB| % ] ]   
    [ , OFFLINE ]  
)   

<add_or_modify_filegroups>::=  
{  
    | ADD FILEGROUP filegroup_name   
        [ CONTAINS FILESTREAM | CONTAINS MEMORY_OPTIMIZED_DATA ]  
    | REMOVE FILEGROUP filegroup_name   
    | MODIFY FILEGROUP filegroup_name  
        { <filegroup_updatability_option>  
        | DEFAULT  
        | NAME = new_filegroup_name   
        | { AUTOGROW_SINGLE_FILE | AUTOGROW_ALL_FILES }  
        }  
}  
<filegroup_updatability_option>::=  
{  
    { READONLY | READWRITE }   
    | { READ_ONLY | READ_WRITE }  
}  
*/
use dbTestes
go

select * from sys.database_files
select * from sys.filegroups

--data file
alter database dbTestes add file (name= 'dbTestes_Data3', filename = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\dbTestes_Data3.ndf', size = 512MB, maxsize=unlimited, filegrowth = 128 MB) to filegroup fg_teste

alter database dbTestes remove file dbTestes_Data3

alter database dbTestes modify file (name='dbTestes_Data3', size=640 MB, maxsize=2 GB, filegrowth=64 MB)

alter database dbTestes modify file (name='dbTestes_Data3', newname='dbTestes_Data_3')

--filegroup
alter database dbTestes add filegroup fg_teste

alter database dbTestes remove filegroup fg_teste

alter database dbTestes modify filegroup fg_teste default
alter database dbTestes modify filegroup [primary] default

