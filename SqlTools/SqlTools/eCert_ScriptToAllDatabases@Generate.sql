
ALTER procedure [dbo].[eCert_ScriptToAllDatabases@Generate]
       @DatabaseName nvarchar(256 ),
       @ScriptToExecute nvarchar(2048 )
as
        create table #databasesName ( databasename nvarchar( 512), Script nvarchar(2048 ))
   
        insert into #databasesName ( databasename)
        exec('
       select name   
       from sysdatabases
       where [name] like ''' + @DatabaseName +'%'' order by [name]');

        --select databasename from #databasesName

        DECLARE @DatabaseNameValue nvarchar (256), @text nvarchar( max)
        set @text = '';

        DECLARE databasecursor CURSOR FOR  
        SELECT databasename
        FROM #databasesName
 
        OPEN databasecursor 
 
        FETCH NEXT FROM databasecursor  
        INTO @DatabaseNameValue
       
        WHILE @@FETCH_STATUS = 0 
     BEGIN 
               set @text = 'use ' + @DatabaseNameValue + '; ' + CHAR (13);
               set @text = @text + @ScriptToExecute + '; ' + CHAR(13 );              

               update #databasesName set Script = @text
               where databasename = @DatabaseNameValue

        FETCH NEXT FROM databasecursor INTO @DatabaseNameValue      
        END  
        CLOSE databasecursor;  
        DEALLOCATE databasecursor;  

        select Script from #databasesName

        drop table #databasesName

        --select @text

go
