/*
This a simple example of a data import and conversion using T-SQL with some analysis mixed in. The data comes from a football mock
drafts with each plaer being selected 8 times. Data was captured using a web scraping script and 
imported via SQL server integration services

Notes:
-Data and inserts can be found in this same project directory
-Designed to be run sequentially

*/


SELECT TOP (1000)    --Quick overview
	   [Draft Results For 1R DynastyPick]
      ,[Ovr]
      ,[Franchise]
      ,[Selection]
  FROM [MFL].[dbo].Draft6_15

EXEC sp_RENAME 'mfl.dbo.draft6_15.[Draft Results For 1R DynastyPick]' , 'Pick', 'COLUMN' --Rename the first column to 'Pick'
  
 /*The web scraper grabs some extra data, lets clear those rows */

  begin tran 
  delete from Draft6_15 where selection is null OR selection  like '%pre-draft selection made%' or
  selection  like 'pick will be automatically%' or selection like '%waiting on franchise%'
  --rollback commit

 /*Rookie players have an (R) next to their name, lets remove this and make it its own column*/
 Alter table Draft6_15
 Add IsRookie nvarchar(1)                          --Creating IsRookie column. 1 = rookie 0 = not rookie
 
 Update Draft6_15                                -- Initializing by setting all to 0 
 Set IsRookie = '0'

 Update Draft6_15
 Set Isrookie = '1'                               --Setting rookies to 1
 Where selection like '%(R)%' 

 Update Draft6_15
 SET selection  = Replace(Selection, '(R)', '')   --Getting rid of the (R) next to player name
 
 /*Within the selection column is the player postions (EX. Beckham, Odell NYG WR) Lets get rid of this and make it its own column*/
 Alter Table Draft6_15
 Add Position Varchar(3)

 Update Draft6_15
 Set Position = Right(selection, 2) --populates the postion column
 
 Update Draft6_15
 SET Selection = Replace(Replace(Replace(Replace(selection, ' RB', ''),' WR',''),' TE',''),' QB', '') --Gets rid of the postion in the selection column

 /*Getting a count of players chosen */
  select
  count(*)[# Drafted],
  selection
  from Draft6_15
  group by Selection
  having count(*) < 8
  Order by count(*) DESC

  /*For fun, bulding a parameterized query to show how many copies of a player were chosen*/

  DECLARE @player VARCHAR(30) 
  Set @player = 'henry' --type any player name 
  
  Select
  8 - count(*)[# of players left],
  selection,
  max(pick)
  from Draft6_15
  group by selection
  having selection like CONCAT('%', @player, '%')

  --Measuring the spread of picks(when first copy chosen vs last copy) and looking at variance 
  select max(pick) - Min(pick), Selection from Draft6_15 group by Selection Order by max(pick) - Min(pick) DESC
  select STDEV(pick)[stdev], Selection from Draft6_15 group by Selection Order by STDEV(pick) DESC

