/* EPL21/22 Portfolio project */
-- After importing data into SQL Server, i want to check if there are any errors via importation process

Select * from Project..Goalkeeperstats 
Select * from Project..Clubstadium 
Select * from Project..Matchinfo 
select * from Project..Matchstats 
Select * from Project..Allplayerstats

-- The data is all set, however, there are still minor errors with columns, data types due to the convertion


/* Begin data cleaning */
-- There are errors in the capacity of the club stadium where some of it displays the number without the comma so it differ from the actual capacity of the stadium

Select capacity from project..Clubstadium 

Select capacity, case
when capacity < 100 then capacity * 1000
when capacity < 1000 then capacity * 100
when capacity < 10000 then capacity * 10
else capacity 
end 
from project..Clubstadium

Update project..Clubstadium 
set capacity = case
when capacity < 100 then capacity * 1000
when capacity < 1000 then capacity * 100
when capacity < 10000 then capacity * 10
else capacity 
end 

-- In Matchinfo table, the date and time columns are displaying each other numbers falsely
-- The date presenting date + time  at 00:00:00
-- The time presenting date at 1899-12-30 + time 
-- This can be modified by changing the data types of the columns 

Alter table project..matchinfo
alter column Date date

Alter table project..matchinfo
alter column time time

-- Or can be fixed with the convert() function

Select time, convert(time,time) converted_time
from Project..Matchinfo 

Update Project..Matchinfo 
set time = convert(time,time)

-- In the matchstats table, the column fulltime_result and halftime_result only display the first letter of the winning team
-- I want to specify it to make a more clearly visualization

Select fulltime_result, case fulltime_result
when  'H ' then  'Home team' 
when  'A' then  'Away team'
else 'Draw'
end
from project..matchstats 

Update Project..Matchstats 
set fulltime_result = case fulltime_result
when  'H' then  'Home team' 
when  'A' then  'Away team'
else 'Draw'
end

-- The same patterns apply to the halftime_result column

Update Project..Matchstats 
set halftime_result = case halftime_result
when  'H' then  'Home team' 
when  'A' then  'Away team'
else 'Draw'
end

-- In different tables, the data show the club names in different contexts so in order to add constraints later on, they must be on the same page
-- First i want to find out what values doesn't match

select Hometeam from Project..Matchinfo 
WHERE HomeTeam  NOT IN
(SELECT Team from Project..Clubstadium )

Select club from Project..Allplayerstats 
where club not in
(SELECT Team from Project..Clubstadium )

Select club from Project..Goalkeeperstats 
where club not in
(SELECT Team from Project..Clubstadium )

Update Project..Clubstadium 
set team = case team
when 'Brighton & Hove Albion' then 'Brighton'
when 'Leeds United' then 'Leeds'
when 'Leicester City' then 'Leicester'
when 'Manchester City' then 'Man city'
when 'Manchester United' then 'Man united'
when 'Norwich City' then 'Norwich'
when 'Tottenham Hotspur' then 'Tottenham'
when 'Newcastle United' then 'Newcastle'
when 'West Ham United' then 'West Ham'
when 'Wolverhampton Wanderers' then 'Wolves'
else team 
end


Update Project..Allplayerstats 
Set club = case club
when 'Leeds United' then 'Leeds'
when 'Leicester City' then 'Leicester'
when 'Manchester City' then 'Man city'
when 'Manchester Utd' then 'Man united'
when 'Norwich City' then 'Norwich'
when 'Newcastle Utd' then 'Newcastle'
else club 
end

Update Project..Goalkeeperstats 
set club = case club
when 'Leeds United' then 'Leeds'
when 'Leicester City' then 'Leicester'
when 'Manchester City' then 'Man city'
when 'Manchester Utd' then 'Man united'
when 'Norwich City' then 'Norwich'
when 'Newcastle Utd' then 'Newcastle'
else club 
end

/* Begin constraints adding */
-- First of all, all the column contain primary key needs to be not null 
-- For the clubstadium tables, i will choose the team column as the primary key
-- I could also choose the stadium column as well in this table but for some cases 1 stadium can be the home stadium for several teams
-- For example: Ha Noi FC, Viettel FC and CAHN FC are all using Hang Day stadium as their home field so it can not be a primary key in such situation

Alter table project..clubstadium
alter column team nvarchar(255) not null

Alter table project..clubstadium
add constraint pk_team primary key (team)

-- As the matchinfo and the matchstats is an one-to-one relationship, i will choose Match_code as primarykey for both tables and link them with a foreign key

Alter table project..matchinfo
alter column match_code nvarchar(255) not null

Alter table project..matchinfo
add constraint pk_match_code primary key (match_code)

Alter table project..matchstats
alter column match_code nvarchar(255) not null 

Alter table project..matchstats
add constraint pk_match_cd primary key (match_code), 
constraint fk_match_code foreign key (match_code) references project..matchinfo (match_code)

-- Foreign key the hometeam and awayteam to team in clubstadium table 

alter table project..matchinfo
add constraint fk_hometeam foreign key (Hometeam) references project..clubstadium (team)

alter table project..matchinfo
add constraint fk_awayteam foreign key (Awayteam) references project..clubstadium (team)

-- Since there are some players who play for 2 clubs in the same season due to the transfer operation (for example Anwar El Ghazi), Allplayerstats cannot have this column as primary key
-- So in order to have the primary key for this column, i will add the player_code column to this table

Alter table project..allplayerstats
add players_code int identity(1,1)  not null

ALter table project..allplayerstats
add constraint pk_players_code  primary key  (players_code)

-- I will need to add this players_code column to goalkeeperstats table as well

alter table project..goalkeeperstats
add players_code  int 

Update Project..Goalkeeperstats 
set players_code = (select players_code from Project..Allplayerstats a
where a.players_name = Project..Goalkeeperstats.players) 

alter table project..goalkeeperstats
alter column players_code  int not null

alter table project..goalkeeperstats
add constraint pk_players_code_gk primary key (players_code) 


/* End of data populating */
/* Begin match data exploratory analysis */

Select * from Matchinfo 
select * from Matchstats 
select * from Clubstadium 

-- With this dataset, i want to start by computing the result of the EPL 21/22 
-- Categories: played, win, loss, draw, points, rank, qualification and relegation, goal for, goal against, goal difference 
-- Clearly for 20 teams to play home and away with others(excluding playing against themselves), there would be 38 games.
 
Select 19*2 played

-- I also can calculate this using the given data

Select c.team, (select count(hometeam) from Matchinfo mi where mi.HomeTeam = c.Team ) 
+ (select count(awayteam) from Matchinfo mi where mi.AwayTeam = c.Team) Played 
from clubstadium c join Matchinfo mi
on c.Team = mi.HomeTeam 
group by c.team 

-- Evaluate the win, loss, draw of every team in the EPL 21/22 
-- As you can see in the tables matchin and matchstats, we can only compute this by summing the win, loss, draw as hometeam + awayteam
-- This take me a while to figure out how to fabricate the queries,then realise how complicated these queries are because they are not only joining multiple times, they also use subqueries as the data source
-- Win

Create procedure win as

select Homewin_tbl.team, Homewin_tbl.Homewin + awaywin_tbl.awaywin win 
from (select distinct(c.team), count(case 
 when ms.fulltime_result = 'Home team' then Hometeam   
 end) over (partition by hometeam) Homewin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.HomeTeam) Homewin_tbl join 
 (select distinct(c.team), count(case 
 when ms.fulltime_result = 'away team' then awayteam   
 end) over (partition by awayteam) awaywin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaywin_tbl
 on Homewin_tbl.Team = awaywin_tbl.Team 

 exec win

 -- Loss
 
 Create procedure loss as

 Select awayloss_tbl.team, awayloss_tbl.awayloss + homeloss_tbl.homeloss loss 
 from (select distinct(c.team), count(case 
 when ms.fulltime_result = 'Home team' then awayteam   
 end) over (partition by awayteam) awayloss
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awayloss_tbl join 
 (select distinct(c.team), count(case 
 when ms.fulltime_result = 'away team' then hometeam   
 end) over (partition by hometeam) homeloss
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.homeTeam) homeloss_tbl
 on awayloss_tbl.Team = homeloss_tbl.Team 
 
 exec loss 

 -- Draw
 
 Create procedure Draw as

 Select homedraw_tbl.team, homedraw_tbl.homedraw + awaydraw_tbl.awaydraw  draw 
 from (select distinct(c.team), count(case 
 when ms.fulltime_result = 'Draw' then hometeam   
 end) over (partition by hometeam) homedraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.homeTeam) homedraw_tbl join 
 (select distinct(c.team), count(case 
 when ms.fulltime_result = 'draw' then awayteam   
 end) over (partition by awayteam) awaydraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaydraw_tbl
 on awaydraw_tbl.Team = homedraw_tbl.Team 

 exec draw

 -- The point of 20 team is calculate by 3 per win and 1 per draw = win*3 + draw
 -- In order to join the 2 complex queries above, i use CTE
 -- Qualification is to identify which team will play for the C1, C2, C3 in the europian league 
 -- Relegation is to identify which team going to be deported to the second division league in England
 
 Create procedure Point as
 
 With CTE_winpoint as(select Homewin_tbl.team, Homewin_tbl.Homewin + awaywin_tbl.awaywin win 
 from (select distinct(c.team), count(case 
 when ms.fulltime_result = 'Home team' then Hometeam   
 end) over (partition by hometeam) Homewin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.HomeTeam) Homewin_tbl join 
 (select distinct(c.team), count(case 
 when ms.fulltime_result = 'away team' then awayteam   
 end) over (partition by awayteam) awaywin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaywin_tbl
 on Homewin_tbl.Team = awaywin_tbl.Team), 
 
 CTE_drawpoint as (Select homedraw_tbl.team, homedraw_tbl.homedraw + awaydraw_tbl.awaydraw  draw 
 from (select distinct(c.team), count(case 
 when ms.fulltime_result = 'Draw' then hometeam   
 end) over (partition by hometeam) homedraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.homeTeam) homedraw_tbl join 
 (select distinct(c.team), count(case 
 when ms.fulltime_result = 'draw' then awayteam   
 end) over (partition by awayteam) awaydraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaydraw_tbl
 on awaydraw_tbl.Team = homedraw_tbl.Team)

 Select Cte_drawpoint.team, CTE_winpoint.win*3 + CTE_drawpoint.draw point, 
 Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) rank,
 case when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (1,2,3,4) then 'Qualified for the Champions league group stage'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (5,6) then 'Qualified for the Europa league group stage'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) = 7 then 'Qualified for the Europa Conference league play-off round'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (18,19,20) then 'Relegated to EFL Championship'
 end Qualification_and_relegation
 from CTE_winpoint join CTE_drawpoint 
 on CTE_winpoint.team = CTE_drawpoint.Team 
 
 exec Point 
 
 -- From this there are some interesting things worth to mention in the end of the EPL21/22
 -- The difference between Manchester city (1st) and Liverpool (2nd) is only 1 point
 -- Rank 1 team has 71 points more than rank 20 team
 -- Norwich (rank 20) needs about 6 more wins to not be in the automatic relegation
 -- Arsenal and West Ham both needs 3 more points to be qualified for the upper league, that's about 1 win


 -- Calculate Goals for, goals against, goal difference
 -- As i want to make these queries easier to understand, i will break them down into homegoalsfor and awaygoalsfor
 -- This is what i should have done in calculating the win, loss, draw matches to make it more interpretable 
 -- Hometeam Goals for
 -- This can be done by summing the homegoals of every team in every game
 
 Select distinct(c.team), sum(ms.fulltime_hometeamgoals) over (partition by hometeam) Hometeam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.HomeTeam 
 
 -- Awayteam goals for
 -- The similar pattern used for awayteam goals 
 
 Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by awayteam) Awayteam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.AwayTeam 
 
 -- Goals for
 -- As i use the 2 queries above as the datasource subqueries like i did in computing the win, loss, draw matches
 
 Create procedure Goals_for as
 
 Select Hometeamgf_tbl.team, Hometeamgf_tbl.Hometeam_goals + Awayteamgf_tbl.Awayteam_goals Goals_for
 from (Select distinct(c.team), sum(ms.fulltime_hometeamgoals) over (partition by hometeam) Hometeam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.HomeTeam) Hometeamgf_tbl join
 ( Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by awayteam) Awayteam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.AwayTeam ) Awayteamgf_tbl
 on Hometeamgf_tbl.Team = Awayteamgf_tbl.team
 Order by Goals_for desc
 
 exec Goals_for 
 -- Hometeam Goals against
 -- The hometeam goalsagainst is the awayteam goalsfor in the same game, so i will compute this summing the awayteams goals for on behalf of hometeam

 Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by hometeam) Hometeam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.HomeTeam = c.Team 

 -- Awayteam goals against
 -- The same thing as the hometeam goals against applied, but in contrast 
 
 Select distinct(c.team), sum(ms.fullTime_hometeamgoals ) over (partition by awayteam) Awayteam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.AwayTeam = c.team

 -- Goals against
 Create procedure Goals_against as

 Select Hometeamga_tbl.team, Hometeamga_tbl.Hometeam_goalsagainst + Awayteamga_tbl.Awayteam_goalsagainst Goals_against
 from (Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by hometeam) Hometeam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.HomeTeam = c.Team) Hometeamga_tbl
 join (Select distinct(c.team), sum(ms.fullTime_hometeamgoals ) over (partition by awayteam) Awayteam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.AwayTeam = c.team) Awayteamga_tbl
 on Hometeamga_tbl.Team = Awayteamga_tbl.Team 
 order by Goals_against asc

 exec Goals_against 

 -- Goals difference 
 -- I will use the same method as how i calculate the point for each team, which is using CTE

 Create procedure Goals_difference as
 
 With CTE_Goalsfor as (Select Hometeamgf_tbl.team, Hometeamgf_tbl.Hometeam_goals + Awayteamgf_tbl.Awayteam_goals Goals_for
 from (Select distinct(c.team), sum(ms.fulltime_hometeamgoals) over (partition by hometeam) Hometeam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.HomeTeam) Hometeamgf_tbl join
 ( Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by awayteam) Awayteam_goals
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on c.team = mi.AwayTeam ) Awayteamgf_tbl
 on Hometeamgf_tbl.Team = Awayteamgf_tbl.team),
 
 CTE_Goalsagainst as ( Select Hometeamga_tbl.team, Hometeamga_tbl.Hometeam_goalsagainst + Awayteamga_tbl.Awayteam_goalsagainst Goals_against
 from (Select distinct(c.team), sum(ms.fulltime_awayteamgoals) over (partition by hometeam) Hometeam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.HomeTeam = c.Team) Hometeamga_tbl
 join (Select distinct(c.team), sum(ms.fullTime_hometeamgoals ) over (partition by awayteam) Awayteam_goalsagainst
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 join Clubstadium c
 on mi.AwayTeam = c.team) Awayteamga_tbl
 on Hometeamga_tbl.Team = Awayteamga_tbl.Team)

 Select CTE_Goalsfor.Team ,CTE_Goalsfor.Goals_for - CTE_goalsagainst.Goals_against Goals_difference
 from CTE_Goalsfor join CTE_Goalsagainst 
 on CTE_Goalsfor.Team = CTE_Goalsagainst.Team 
 order by Goals_difference desc

 exec Goals_difference 

 -- As the winner of the EPL 21/22, Manchester city also has the most goals difference, which is really well-deserved based on their performance throughout the season
 -- Norwich, on the other hand, claim the least goals difference which is -61 (23 gf, 84 ga)
 -- Goals difference is the factor to rank teams when they have the same point

 -- In every query, i create a stored procedure to help with the visualization later on
 
 exec Win 
 exec Loss 
 exec Draw
 exec Point 
 exec Goals_for 
 exec Goals_against 
 exec Goals_difference 


 /* There are some fun facts about this season that i want to share using the match data. */

 -- Liverpool had never lost when they play their home stadium
 
 Select mi.HomeTeam, ms.FullTime_Result  from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code 
 where mi.HomeTeam = 'liverpool'

 -- No wonders why Anfield is known for being "the most heated stadium in Europe" - said by the legendary coach Arsene Wenger himself
 
 -- What if all games end at half time? Will Manchester city still claim their championship? How the table would have turned? Let's find out
 -- I'll use the same queries as the point calculating but this time, instead using fulltime_result i'll use the halftime_result 
 
 With CTE_winpoint as(select Homewin_tbl.team, Homewin_tbl.Homewin + awaywin_tbl.awaywin win 
 from (select distinct(c.team), count(case 
 when ms.halftime_result = 'Home team' then Hometeam   
 end) over (partition by hometeam) Homewin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.HomeTeam) Homewin_tbl join 
 (select distinct(c.team), count(case 
 when ms.halftime_result = 'away team' then awayteam   
 end) over (partition by awayteam) awaywin
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaywin_tbl
 on Homewin_tbl.Team = awaywin_tbl.Team), 
 
 CTE_drawpoint as (Select homedraw_tbl.team, homedraw_tbl.homedraw + awaydraw_tbl.awaydraw  draw 
 from (select distinct(c.team), count(case 
 when ms.halftime_result = 'Draw' then hometeam   
 end) over (partition by hometeam) homedraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.homeTeam) homedraw_tbl join 
 (select distinct(c.team), count(case 
 when ms.halftime_result = 'draw' then awayteam   
 end) over (partition by awayteam) awaydraw
 from Matchinfo mi join Matchstats ms
 on mi.Match_code = ms.Match_code
 join Clubstadium c
 on c.team = mi.awayTeam) awaydraw_tbl
 on awaydraw_tbl.Team = homedraw_tbl.Team)

 Select Cte_drawpoint.team, CTE_winpoint.win*3 + CTE_drawpoint.draw point, 
 Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) rank,
 case when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (1,2,3,4) then 'Qualified for the Champions league group stage'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (5,6) then 'Qualified for the Europa league group stage'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) = 7 then 'Qualified for the Europa Conference league play-off round'
 when Rank() over (order by CTE_winpoint.win*3 + CTE_drawpoint.draw desc) in (18,19,20) then 'Relegated to EFL Championship'
 end Qualification_and_relegation
 from CTE_winpoint join CTE_drawpoint 
 on CTE_winpoint.team = CTE_drawpoint.Team 

 -- The championship did slip away from the citizen hand when they would be lesser than liverpool 2 points if all games ended at half time
 -- Another major difference is that Manchester united dropped down to rank 7 and west ham dropped to rank 8, which means they will not be qualified for the europian league as they did if the results are in full 90 minutes
 -- In contrast, the relegation group observed the similar faces. I guess neither fulltime nor halftime Burnley, Watford and Norwich plays good enough to keep them out of the relegation
 
 -- But there is something a relegated team did better than half of the premier league this season. The goals they conceded is even less than the top 6 team manchester united
 -- I can check this out by query the goal against table again
 
 exec Goals_against 

 -- Only 53 goals was conceded by Burnley at the end of the season, less than half of the teams participated and the top 6 team Manchester United
 -- Looks like Burnley's deffensive players could not offset for the poor attacking ones which only scores 34 times throughout 38 games


 -- In conclusion, there are much more interesting insights to be explored using this dataset but these queries shows how most of them can be conducted using SQL language



 /* Start exploring players data */

 Select * from Allplayerstats 
 Select * from Goalkeeperstats  

 -- Statistic calculated from this dataset
 -- Since there are some columns contain value of 0 which can not be divided. So i will need to set the divide by 0 show null 

SET ARITHABORT OFF 
SET ANSI_WARNINGS OFF

 -- Started

 select players_name, club,matches_started/match_played *100 start_rate
 from Allplayerstats 
 
 -- Passes,dribbles, shots and goals 
 
 Select players_name, club, (dribbles_successful/dribbles_attempted)*100 dribble_winrate,
 (passes_completed/passes_attempted)*100 pass_comp_rate, (passes_received/pass_targeted)*100 pass_rec_rate,
 (shots_ontarget/shots)*100 shotont_rate, (shots/90) shots_per90m, (shots_ontarget/90) shotsont_per90m,
 (goals/shots) goals_per_shotfired, (goals/shots_ontarget) goals_per_shotsont, (penalties_goals/penalties_attempted)*100 penalties_successrate
 from Allplayerstats 

 -- Deffensive stats
 Select players_name, club,aerial_won/(aerial_lost + aerial_won)*100 aerial_winrate, 
 dribbles_tackled/(dribbles_tackled + dribbled_past)*100 tackle_winrate, shot_creating_act/90 shotcreating_act_per90m,
 goal_creating_act/90 goalcreating_act_per90m, yellowcard/fouls_drawn card_perfoul
 from Allplayerstats

 -- Goalkeeper stats
 Select players, club, goalsscored_against/90 goalsscored_against_per90, (saves/shotontarget_against)*100 savemade_rate,
 cleansheet/(win + loss + draw)*100 cleansheet_rate
 from Goalkeeperstats 


 -- Top performance identify
 -- Putting the ball into the oponent's net is the most compulsory thing in the game, so whoever score more goals have a better chance of leading his team to victory and increase his value on the player market
 -- Let's see who scored most in EPL 21/22
 
 Select players_name, position, club, goals
 from Allplayerstats 
 order by goals desc

 -- Mohamed Salah and Son Heung-Min both shares the 'golden boot' title after both ended the season on 23 goals
 -- Son Heung-Min is the first Asian player ever who claimed the award 
 -- Cristiano Ronaldo was the third best scorer in the season, which is very impressive due to Manchester United poor performance 
 -- Manchester city, regards wining the whole campaign, does not contribute any players in the top 5 best scorer.  

 -- Most assists
 
 Select players_name, position, club, assists 
 from Allplayerstats 
 order by assists desc

 -- Mohamed Salah claimed another title of providing the best assitance to his teamates to score with 13 assits. What a player
 -- Top 3 assits are all liverpool players.
 -- Still no sign of the trophyowner-club players until top 10, where Grabiel Jesus have 8 assits

  -- Most cards
 select players_name, club, yellowcard
 from Allplayerstats 
 order by yellowcard  desc

 select players_name, club, redcard
 from Allplayerstats 
 order by redcard  desc

 -- 3 players who got 11 yellow cards are all from the lower half of the league
 -- The maximum number of redcards was 2
 
 -- Most penalty goals
 
 Select players_name, club, penalties_goals 
 from Allplayerstats 
 order by penalties_goals desc
 
 -- The golden boot winner Mohamed Salah goals 5 penalties, but still the number 2 best pelnalty scorer, Jorginho from Chelsea was on top with 6 goals
 
 -- Highest salary player

 Select players_name,club, weekly_wage 
 from Allplayerstats 
 order by weekly_wage desc

 -- Cristiano Ronaldo claimed to have the highest salary, 515385 pounds per week. Liam McCarron from Leeds United, who has the lowest wage, needs 670 weeks~14years of his salary to get the same number 
 -- In fact, 4/5 players who are most well-paid are from Manchester United. Investing such money just to be in top 6 of the league is quite sad for MU fans

 /* End */