-- chasing win percentage 

SELECT 
    m.season AS Season,
    -- 
    COUNT(DISTINCT m.match_id) AS "Chasing Matches",
    
    -- 
    COUNT(DISTINCT CASE WHEN m.winner LIKE 'Chennai%' THEN m.match_id END) AS "Chasing Wins",
    
    -- 
    ROUND(
        COUNT(DISTINCT CASE WHEN m.winner LIKE 'Chennai%' THEN m.match_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT m.match_id), 0), 
        2
    ) AS "Chasing Win %"
FROM dim_match m
JOIN fact_deliveries f ON CAST(f.match_id AS CHAR) = CAST(m.match_id AS CHAR)
WHERE f.bowling_team LIKE 'Chennai%'
  AND m.batting_first NOT LIKE 'Chennai%' 
GROUP BY m.season
ORDER BY m.season DESC;

-- defending win percentage 

SELECT 
    m.season AS Season,
    -- Counts unique match IDs where Chennai batted first
    COUNT(DISTINCT m.match_id) AS "Defending Matches",
    
    -- Counts unique matches where Chennai batted first AND Chennai won
    COUNT(DISTINCT CASE WHEN m.winner LIKE 'Chennai%' THEN m.match_id END) AS "Defending Wins",
    
    -- Computes exact win percentage for defending scenarios
    ROUND(
        COUNT(DISTINCT CASE WHEN m.winner LIKE 'Chennai%' THEN m.match_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT m.match_id), 0), 
        2
    ) AS "Defending Win %"
FROM dim_match m
JOIN fact_deliveries f ON CAST(f.match_id AS CHAR) = CAST(m.match_id AS CHAR)
WHERE f.bowling_team LIKE 'Chennai%'
  AND m.batting_first LIKE 'Chennai%' -- CSK set the target, CSK is defending
GROUP BY m.season
ORDER BY m.season DESC;

-- chepauk batting score by season

SELECT m.season, SUM(f.runs_total) AS total_runs FROM 
dim_match M 
JOIN fact_deliveries F
on M.match_id=F.match_id 
JOIN dim_venue v
ON v.venue_id=M.venue_id
WHERE batting_team LIKE 'Chennai%'
and 
V.venue_id IN (2,21) 
GROUP BY SEASON 
ORDER BY SEASON DESC;

-- bowling runs conceded in chepauk


SELECT m.season, SUM(f.runs_total) AS total_runs_conceded FROM 
dim_match M 
JOIN fact_deliveries F
on M.match_id=F.match_id 
JOIN dim_venue v
ON v.venue_id=M.venue_id
WHERE batting_team NOT LIKE 'Chennai%'
and 
V.venue_id IN (2,21) 
GROUP BY SEASON 
ORDER BY SEASON DESC;

-- batting first chepauk runs


SELECT m.season, SUM(f.runs_total) AS total_runs_firstbatting FROM 
dim_match M 
JOIN fact_deliveries F
on M.match_id=F.match_id 
JOIN dim_venue v
ON v.venue_id=M.venue_id
WHERE batting_team LIKE 'Chennai%'
and 
V.venue_id IN (2,21) 
AND
innings_num=1
GROUP BY SEASON 
ORDER BY SEASON DESC;

-- chasing in chepauk

SELECT m.season, SUM(f.runs_total) AS chasing_runs FROM 
dim_match M 
JOIN fact_deliveries F
on M.match_id=F.match_id 
JOIN dim_venue v
ON v.venue_id=M.venue_id
WHERE batting_team LIKE 'Chennai%'
and 
V.venue_id IN (2,21) 
AND
innings_num=2
GROUP BY SEASON 
ORDER BY SEASON DESC;


-- home wins season wise

SELECT season , count(*) as home_wins FROM dim_match WHERE venue_id in (2,21) AND winner LIKE 'Chennai%' 
GROUP BY season
ORDER BY season DESC;

-- away wins season wise

SELECT season , count(*) as away_wins FROM dim_match WHERE venue_id  NOT in (2,21) AND winner LIKE 'Chennai%' 
GROUP BY season
ORDER BY season DESC;


-- total home and away games

SELECT season,count(*) AS homegamecount FROM dim_match WHERE venue_id IN (2,21) GROUP BY season; -- ts computes home games
SELECT season,count(*) AS awaygamecount FROM dim_match WHERE venue_id NOT IN (2,21) GROUP BY season; -- computes away games

