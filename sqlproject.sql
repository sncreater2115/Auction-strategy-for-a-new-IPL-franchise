create table deliveries (id bigint,	inning int,	over int,	ball int,	
	batsman varchar,	non_striker varchar,	bowler varchar,	batsman_runs int,	extra_runs int,	
	total_runs int,	is_wicket int,	dismissal_kind varchar,	player_dismissed varchar,	
	fielder	varchar, extras_type varchar, batting_team varchar,	bowling_team varchar);

copy deliveries (id ,	inning ,	over ,	ball ,	
	batsman ,	non_striker ,	bowler ,	batsman_runs ,	extra_runs ,	
	total_runs ,	is_wicket ,	dismissal_kind ,	player_dismissed ,	
	fielder	, extras_type , batting_team ,	bowling_team )
 from 'C:\IPL Dataset\IPL_Ball.csv' 
delimiter ',' csv header;

create table matches(id	bigint, city varchar,	date date,	player_of_match varchar,	
	venue varchar,	neutral_venue int,	team1 varchar,	team2 varchar,	
	toss_winner varchar,	toss_decision varchar,	winner varchar,	result varchar,	
	result_margin int, 	eliminator varchar,	method varchar,	umpire1 varchar,	umpire2 varchar);

copy matches (id,	city,	date,	player_of_match,	venue,	neutral_venue,	team1,	team2,	
	toss_winner,	toss_decision,	winner,	result,	result_margin,	eliminator,	method,	umpire1,	
	umpire2) from 'C:\IPL Dataset\IPL_matches.csv' delimiter ',' csv header;

explain select * from deliveries;
select * from deliveries;
select * from matches;
--first aggressive batsman
select batsman, round((sum(batsman_runs*1.0)/count(ball))*100,2) as sr from deliveries
where extras_type not in('wides') group by batsman having count(ball)>500 
order by sr desc limit 10;
--second anchor batsman
select batsman, round(sum(batsman_runs*1.0)/sum(is_wicket),2) as Average from deliveries 
	group by batsman having sum(is_wicket)>0 and count(distinct id)>28
	order by Average desc limit 10; 
--third hard hitters
select batsman,sum(batsman_runs) as total_runs,sum(case when batsman_runs in(4,6) then batsman_runs else 0 end) as boundary_run,
	round(sum(case when batsman_runs in(4,6) then batsman_runs else 0 end)*1.0 / sum(batsman_runs)*100,2) as boundary_percentage
	from deliveries where extras_type not in ('wides') group by batsman having count(distinct id) > 28
	order by boundary_percentage desc limit 10;

--fourth economy bowler
select bowler, round(sum(total_runs)/(count(over)/6.0),2) as economy from deliveries 
	group by bowler having count(ball) >500
order by economy asc limit 10;
--fifth wicket taking bowler
select bowler, round(count(ball)*1.0/sum(is_wicket),2) as sr 
from deliveries group by bowler having count(ball)>500 
order by sr asc limit 10;
--six all rounder
with batsmen as (select batsman, count(ball) as balls_faced, round(sum(batsman_runs * 1.0) / count(ball) * 100, 2) as batsman_sr    
	from deliveries where extras_type not in ('wides') group by batsman having count(ball) > 500),
	bowlers as (select bowler, count(ball) as balls_bowled, round(count(ball) * 1.0 / sum(is_wicket), 2) as bowling_sr    
	from deliveries group by bowler having count(ball) > 300)
	select b.batsman as all_rounder, b.batsman_sr, bw.bowling_sr from batsmen b join bowlers bw on b.batsman = bw.bowler 
	order by b.batsman_sr desc, bw.bowling_sr asc limit 10;

--seven wicketkeeper
-- Step 1: Identify Wicketkeepers
WITH Wicketkeepers AS (SELECT DISTINCT fielder FROM deliveries
    WHERE dismissal_kind = 'stumped'),
-- Step 2: Count Dismissals
WicketkeeperDismissals AS (SELECT wk.fielder AS wicketkeeper, COUNT(ib.dismissal_kind) AS total_dismissals
    FROM deliveries ib JOIN Wicketkeepers wk ON ib.fielder = wk.fielder
    WHERE ib.dismissal_kind IN ('stumped', 'caught') GROUP BY wk.fielder),
-- Step 3: Calculate Runs Scored
WicketkeeperRuns AS (
    SELECT wk.fielder AS wicketkeeper, SUM(ib.batsman_runs) AS total_runs_scored
    FROM deliveries ib JOIN Wicketkeepers wk ON ib.batsman = wk.fielder
    WHERE ib.extras_type NOT IN ('wides') GROUP BY wk.fielder)
-- Step 4: Combine Results
SELECT wd.wicketkeeper, wd.total_dismissals, COALESCE(wr.total_runs_scored, 0) AS total_runs_scored
FROM WicketkeeperDismissals wd
LEFT JOIN WicketkeeperRuns wr ON wd.wicketkeeper = wr.wicketkeeper
ORDER BY wd.total_dismissals DESC, total_runs_scored DESC NULLS LAST
LIMIT 10;

--Additional Questions for Final Assessment
select * from matches;
--1
select count(distinct(city)) city_count from matches;
--2
create table deliveries_v02 as(select *, (case when total_runs>=4 then 'Boundary' 
	when total_runs = 0 then 'Dot' else 'Other' end) as ball_result
	from deliveries);
select * from deliveries_v02;
--3
select ball_result,count(ball_result)as ball_result_count
	from deliveries_v02 where ball_result in('Boundary','Dot') group by ball_result; 
--4
select batting_team as team,count(ball_result) as boundary_count from deliveries_v02 
where ball_result='Boundary' group by batting_team order by boundary_count desc;
--5
select bowling_team as team,count(ball_result) as dot_count from deliveries_v02 
where ball_result='Dot' group by team order by dot_count desc;
--6
select dismissal_kind,count(dismissal_kind) as dismissal from deliveries_v02
where dismissal_kind not in ('NA') group by dismissal_kind order by dismissal desc;
--7
select bowler,sum(extra_runs) extra from deliveries
group by bowler order by extra desc limit 5;
--8
create table deliveries_v03 as (
    select deliveries_v02.*, matches.venue, matches.date 
    from deliveries_v02 
    join matches on matches.id = deliveries_v02.id);
--9
select venue,sum(total_runs) as runs from deliveries_v03
group by venue order by runs desc;
--10
select extract(year from date) as year,sum(total_runs) as runs_eden from deliveries_v03 where venue ='Eden Gardens'
group by year order by runs_eden desc;

select * from deliveries_v03;
