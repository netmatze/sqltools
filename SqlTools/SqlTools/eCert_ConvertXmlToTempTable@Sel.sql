CREATE procedure eCert_ConvertXmlToTempTable@Sel
       @parameter XML ,
       @elementName nvarchar (256 )
as
declare @temptable table (columnName nvarchar( 256))
insert @temptable
(
    columnName
)
SELECT
       distinct y.i.value('local-name(.)' ,'nvarchar(256)' ) AS colname    
FROM @parameter .nodes('//*') y(i)
WHERE y.i.value('local-name(.)' ,'nvarchar(256)' ) <> @elementName

declare @counter int ;
declare @xmlString nvarchar (max );
declare @colname nvarchar (max )

set @xmlString = '' ;

select @counter = count (* ) from @temptable t

while(@counter > 0 )
begin
       select top 1 @colname = columnName
       from
             @temptable t;
      
       set @xmlString = @xmlString +
       'tableValue.columnValue.query(''' + @colname + ''').value(''.'', ''nvarchar(256)'') as [' + @colname + '],';
      
       delete t
       from
             @temptable t
       where
            t.columnName = @colname
       select
             @counter = count (* )
       from
             @temptable t
end

set @xmlString = substring (@xmlString , 0 , len (@xmlString ))

declare @execString nvarchar (max )
set @execString =
' declare @x xml; set @x = convert(xml,''' + convert (nvarchar (max ), @parameter) + ''') select ' + @xmlString +
' from @x.nodes(''' + @elementName + ''') tableValue(columnValue) ' ;

exec(@execString )
