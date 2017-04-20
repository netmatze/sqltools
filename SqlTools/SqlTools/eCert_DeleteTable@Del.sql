CREATE procedure eCert_DeleteTable@Del
(
       @TableName nvarchar (256 ),
       @Join nvarchar (512 ) = null ,
       @Where nvarchar (1024 ) = null ,
       @Rollback bit = 0
)
as
       if( @Rollback = 1 )
       begin
             begin tran
       end
             select
                  f.name AS ForeignKey,
                   OBJECT_NAME(f.parent_object_id) AS TableName,
                   COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName,
                   OBJECT_NAME (f.referenced_object_id) AS ReferenceTableName,
                   COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferenceColumnName
             into #foreign_keysTable
             from
                   sys.foreign_keys AS f
                   INNER JOIN sys .foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id
             where
                   OBJECT_NAME (f.referenced_object_id) = @TableName
             order by TableName
            
             declare @counter int ,
                   @ForeignKey nvarchar (256 ),
                   @TableNameLocal nvarchar (256 ),
                   @ColumnName nvarchar (256 ),
                   @ReferenceTableName nvarchar (256 ),
                   @ReferenceColumnName nvarchar (256 ),
                   @PrimaryKeyColumnName nvarchar (256 ),
                   @SqlScriptString nvarchar (max ),
                   @SqlCountScriptString nvarchar (max ),
                   @DeletePossible bit
                  
             select @PrimaryKeyColumnName = name
             from sysobjects
             where xtype= 'pk' and
            parent_obj in ( select id from sysobjects where name = @TableName)
            
             CREATE TABLE #tmp
            (
               PK uniqueidentifier               
            )
             insert into #tmp
             exec('select ' + @PrimaryKeyColumnName + ' from ' + @Join + ' ' + @Where )
                  
             select @counter = count (* ) from #foreign_keysTable
            
             CREATE TABLE #tmpCounter
            (
               Counter int
            )
            
             while(@counter > 0 )
             begin
                   select top 1
                         @ForeignKey = fk.ForeignKey,
                         @TableNameLocal = fk.TableName,
                         @ColumnName = fk.ColumnName,
                         @ReferenceTableName = fk.ReferenceTableName,
                         @ReferenceColumnName = fk.ReferenceColumnName
                   from
                        #foreign_keysTable fk;
                  
                   --select @ForeignKey, @TableNameLocal, @ColumnName, @ReferenceTableName, @ReferenceColumnName;
                  
                   set @SqlCountScriptString = 'select count(*) from ' + @TableNameLocal + ' inner join ' +
                         @ReferenceTableName + ' on ' + @TableNameLocal + '.' + @ColumnName + ' = ' + @ReferenceTableName + '.' + @ReferenceColumnName +
                         ' where ' + @ReferenceTableName + '.' + @ReferenceColumnName + ' in (select PK from #tmp)' ;
                  
                   --print @SqlCountScriptString;
                  
                   delete #tmpCounter
                  
                   insert into #tmpCounter
                   exec(@SqlCountScriptString );
                  
                   select top 1 @DeletePossible = case when (Counter > 0) then 1 else 0 end from #tmpCounter
                  
                   if( @DeletePossible = 1 )
                   begin
                         set @SqlScriptString = ' delete ' + @TableNameLocal + ' from ' + @TableNameLocal + ' inner join ' +
                               @ReferenceTableName + ' on ' + @TableNameLocal + '.' + @ColumnName + ' = ' + @ReferenceTableName + '.' + @ReferenceColumnName +
                               ' where ' + @ReferenceTableName + '.' + @ReferenceColumnName + ' in (select PK from #tmp)' ;
                        
                         --print @SqlScriptString
                        
                         exec(@SqlScriptString );
                   end;
                                    
                   WITH deleter AS
                    (
                          SELECT TOP 1 *
                          FROM #foreign_keysTable                  
                    )
                   DELETE
                   FROM deleter
                   set @counter = @counter - 1
             end

             if( @Rollback = 1 )
             begin
                   rollback tran
             end
GO
