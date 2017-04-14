alter procedure eCert_InsTextCreator
       @PK uniqueidentifier ,
       @Tablename nvarchar (256 )
as
       declare @object_id int , @PKColumName nvarchar (256 ), @PKColumnName nvarchar(max ), @SelectText nvarchar(max ), @Text nvarchar( max)
       select @object_id = object_id
       from sys .objects
       where [Type] = 'U' and sys .objects.name = @Tablename
      
       create table #columnNames (Name nvarchar( max), system_type_id int )
      
       insert into #columnNames(Name, system_type_id)  
       SELECT Name, system_type_id   
       FROM sys .columns WHERE object_id = @object_id
      
       SELECT         
          top 1 @PKColumName = c.NAME
       FROM
        sys.objects  so
       INNER JOIN
          sys.key_constraints kc on so.object_id = kc.parent_object_id
       INNER JOIN
          sys.index_columns ic ON kc.parent_object_id = ic.object_id
       INNER JOIN
          sys.columns c ON ic.object_id = c. object_id AND ic.column_id = c.column_id 
       INNER join
          sys.sysobjects sob on sob.xtype = 'PK' and sob.parent_obj = so.object_id
       WHERE
          kc. type = 'PK' and so.name = @Tablename --and c.name like 'PK_%'
      
       declare @columnName nvarchar (256 ), @columnValue nvarchar(max ), @columnSystemTypeid int , @maxValue int , @counter int
      
       set @counter = 0
       select @maxValue = count (* )
       from #columnNames cn
      
       set @Text = 'insert into ' + @Tablename + ' ( '
      
       while(@counter < @maxValue )
       begin
             select top 1 @columnName = Name from #columnNames                       
             if( @counter + 1 = @maxValue )
                   set @Text = @Text + '[' + @columnName + '])'
             else
                   set @Text = @Text + '[' + @columnName + '], '
             delete #columnNames where Name = @columnName
             set @counter = @counter + 1
       end
      
       set @counter = 0
       set @Text = @Text + CHAR (13 ) + CHAR (10 ) + ' values ( '
      
       insert into #columnNames(Name, system_type_id)  
       SELECT Name, system_type_id   
       FROM sys .columns WHERE object_id = @object_id
            
       while(@counter < @maxValue )
       begin       
             select top 1 @columnName = Name, @columnSystemTypeid = system_type_id from #columnNames                
             set @SelectText = 'select cast([' + @columnName + '] as nvarchar(max)) [Value] into ##value from (select * from ' + @Tablename + ' where [' + @PKColumName + '] = ''' + cast (@PK as nvarchar (36 )) + ''') alias ';          
             exec(@SelectText )
             select @columnValue = [Value]
             from ##value            
             if( @counter + 1 = @maxValue )
             begin
                   if( @columnValue is null )
                         set @Text = @Text + 'NULL' + ')'
                   else
                   begin
                         if( @columnSystemTypeid = 231 or @columnSystemTypeid = 36 or @columnSystemTypeid = 61 )             
                               set @Text = @Text + '''' + cast(@columnValue as nvarchar (max )) + ''')'                 
                         else
                               set @Text = @Text + cast (@columnValue as nvarchar(max )) + ')'
                   end
             end
             else
             begin
                   if( @columnValue is null )
                         set @Text = @Text + 'NULL' + ', '
                   else
                   begin
                         if( @columnSystemTypeid = 231 or @columnSystemTypeid = 36 or @columnSystemTypeid = 61 ) 
                               set @Text = @Text + '''' + cast(@columnValue as nvarchar (max )) + ''','
                         else
                               set @Text = @Text + cast (@columnValue as nvarchar(max )) + ', '
                   end
             end         
             delete #columnNames where Name = @columnName
             set @counter = @counter + 1
             drop table ##value
             --print @Text
       end
       select @Text


