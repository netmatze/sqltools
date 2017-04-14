create function StringParser
(
       @string nvarchar (max ),
       @seperator nvarchar (1 )
)
returns table
as
return (
       WITH CTE AS (
       SELECT
             case when (CHARINDEX (@seperator , @string ) > 0 )
             then
                   substring(@string , 0 , CHARINDEX (@seperator , @string ))
             else
                   @string
             end string,
             case when (CHARINDEX (@seperator , @string ) > 0 )
             then
                   substring(@string , CHARINDEX (@seperator , @string ) + 1 , len(@string ))
             else
                   null
             end rest,   
             cast(CHARINDEX (@seperator , @string ) as int ) [CharIndex]
             union all
             select
                   case when (CHARINDEX (@seperator , rest) > 0)
                   then
                         substring(rest, 0 , CHARINDEX (@seperator , rest))
                   else
                        rest
                   end,
                   case when (CHARINDEX (@seperator , rest) > 0)
                   then
                         substring(rest, CHARINDEX (@seperator , rest) + 1, len(rest)) --CHARINDEX(@seperator, @string, CHARINDEX(@seperator, @string)) - 1) substr
                   else
                         null
                   end,                    
                   cast(CHARINDEX (@seperator , rest, CHARINDEX( @seperator, rest)) as int )
             from
                  CTE
             where
                  CTE.rest != ''
      )
       SELECT string, rest, [CharIndex]
       FROM CTE
       --OPTION (MAXRECURSION 32000)
)
