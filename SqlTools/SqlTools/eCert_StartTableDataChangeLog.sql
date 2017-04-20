
alter procedure eCert_DisplayTableDataChangedLog
       @tablename nvarchar (256 )
as
       exec (' select * from ##' + @tablename + '  except select * from ' + @tablename )
      
       exec (' select * from ' + @tablename + '  except select * from ##' + @tablename )
go

create procedure eCert_DisplayTableDataBeforeChangedLog
       @tablename nvarchar (256 )
as
       exec (' select * from ##' + @tablename + '  except select * from ' + @tablename )
go

create procedure eCert_DisplayTableDataAfterChangedLog
       @tablename nvarchar (256 )
as
       exec (' select * from ' + @tablename + '  except select * from ##' + @tablename )
go


ALTER procedure eCert_StartTableDataChangeLog
       @tablename nvarchar (256 )
as
       declare @columnstring nvarchar (max )
       set @columnstring = ''   
      
       create table #columns (column_name nvarchar( 512), data_type nvarchar(512 ),
            character_maximum_length nvarchar(512 ), numeric_precision nvarchar(512 ),
            numeric_scale nvarchar(512 ))
      
       insert #columns
      (
          column_name,
          data_type,
          character_maximum_length,
          numeric_precision,
          numeric_scale
      )     
       select column_name, data_type, character_maximum_length, numeric_precision, numeric_scale
       from INFORMATION_SCHEMA .COLUMNS
       where table_name = @tablename  
      
       declare @column_name nvarchar (512 ),
             @data_type nvarchar (512 ),
             @character_maximum_length nvarchar (512 ),
             @numeric_precision nvarchar (512 ),
             @numeric_scale nvarchar (512 ),
             @counter int
      
       select @counter = count (* ) from #columns
      
       print @counter
      
       while(@counter > 0 )
       begin
             select top 1
                   @column_name = c.column_name,
                   @data_type = c.data_type,
                   @character_maximum_length = c.character_maximum_length,
                   @numeric_precision = numeric_precision,
                   @numeric_scale = numeric_scale
             from
                  #columns c
                        
            
             if(( @data_type = 'numeric' or @data_type = 'decimal' ) and @numeric_precision is not null )
             begin
                   set @columnstring = @columnstring + @column_name + ' ' +  @data_type + '(' + @numeric_precision + ',' + @numeric_scale + ')' + ','
             end
             else if (@character_maximum_length is null )
             begin
                   set @columnstring = @columnstring + @column_name + ' ' + @data_type + ','
             end
             else
             begin
                   set @columnstring = @columnstring + @column_name + ' ' + @data_type + '(' + @character_maximum_length + ')' + ','
             end
            
             delete c
             from
                  #columns c
             where
                  c.column_name = @column_name and
                  c.data_type = @data_type
            
             set @counter = @counter - 1
       end
      
       set @columnstring = substring (@columnstring ,0 ,len (@columnstring ))
      
       --print @columnstring
      
       exec ('create table ##' + @tablename + ' ( ' + @columnstring + ' ) ');
      
       exec ('insert ##' + @tablename + ' select * from ' + @tablename )
go
