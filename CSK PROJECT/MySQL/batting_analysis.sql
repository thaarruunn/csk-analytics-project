-- runs scored in powerplay season wise

SELECT m.season,sum(runs_batter) as runs_scored FROM fact_deliveries f JOIN dim_match m on f.match_id=m.match_id 
WHERE batting_team LIKE 'Chennai%'  and phase='powerplay' GROUP BY m.season ORDER by m.season DESC;

-- RUNS SCORED by ruturaj gaikwad seasonwise

SELECT batter,m.season,sum(runs_batter) as runs_scored FROM fact_deliveries f JOIN dim_match m on f.match_id=m.match_id 
WHERE batting_team LIKE 'Chennai%'  AND batter LIKE '%Gaikwad%' GROUP BY batter,m.season ORDER by m.season DESC;


-- MOST runs scored since 2024 

SELECT batter,m.season,sum(runs_batter) as runs_scored FROM fact_deliveries f JOIN dim_match m on f.match_id=m.match_id 
WHERE batting_team LIKE 'Chennai%' AND m.season>=2024 GROUP BY batter,m.season ORDER by runs_scored DESC LIMIT 10; 

-- FOURS scored playerwise 

SELECT m.season,batter,COUNT(*) AS fours 
FROM fact_deliveries f JOIN dim_match m ON f.match_id = m.match_id 
WHERE batting_team LIKE 'Chennai%' AND runs_batter = 4 GROUP BY m.season, batter 
ORDER BY m.season DESC , fours desc;

-- SIXES scored playerwise

SELECT m.season,batter,COUNT(*) AS fours
 FROM fact_deliveries f JOIN dim_match m ON f.match_id = m.match_id
 WHERE batting_team LIKE 'Chennai%' AND runs_batter = 6 
 GROUP BY m.season, batter ORDER BY m.season DESC , fours desc;
 
 
 -- CHASING win percentage

SELECT
    season,
    COUNT(*) AS chasing_matches,
    SUM(CASE WHEN winner LIKE 'Chennai%' THEN 1 ELSE 0 END) AS chasing_wins,
    ROUND(
        SUM(CASE WHEN winner LIKE 'Chennai%' THEN 1 ELSE 0 END)*100.0
        / COUNT(*),
        2
    ) AS chasing_win_pct
FROM dim_match
WHERE batting_first NOT LIKE 'Chennai%'
GROUP BY season
ORDER BY season desc;
 
 -- DEFENDING win percentage by season

SELECT
    season,
    COUNT(*) AS defending_matches,
    SUM(CASE WHEN winner LIKE 'Chennai%' THEN 1 ELSE 0 END) AS defending_wins,
    ROUND(
        SUM(CASE WHEN winner LIKE 'Chennai%' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS defending_win_pct
FROM dim_match
WHERE batting_first LIKE 'Chennai%' -- This ensures they batted first and are defending!
GROUP BY season
ORDER BY season DESC;


-- dot ball percentage seasonwise

SELECT 
    d.season,
    COUNT(*) AS total_balls_faced,
    SUM(CASE WHEN f.runs_total = 0 THEN 1 ELSE 0 END) AS dot_balls_counted,
    -- Your logic turned into a percentage using ROUND
    ROUND(
        AVG(CASE WHEN f.runs_total = 0 THEN 1 ELSE 0 END) * 100, 
        2
    ) AS dot_ball_percentage
FROM fact_deliveries f 
JOIN dim_match d ON d.match_id = f.match_id
WHERE f.batting_team LIKE 'Chennai%'
GROUP BY d.season
ORDER BY d.season DESC;
 
-- Combined Openers Runs (Grouped by Season)
-- starts here:

-- Findinh the 2 players who opened the batting in every single match
WITH MatchOpeners AS (
    SELECT DISTINCT
        match_id,
        batting_team,
        batter
    FROM fact_deliveries
    -- ts decides who faced the 1st ball of the innings
    WHERE over_num = 0 
      AND ball_num = 1 
)

-- Step 2: add their runs together, grouped by season
SELECT 
    m.season,
    COUNT(DISTINCT f.match_id) AS total_matches,
    SUM(f.runs_batter) AS combined_openers_runs,
    -- Tracks total times either opener got out that season
    SUM(CASE WHEN f.is_wicket = 1 THEN 1 ELSE 0 END) AS total_opener_dismissals,
    -- Combined Openers Average per dismissal (NULLIF prevents division by zero)
    ROUND(SUM(f.runs_batter) / NULLIF(SUM(CASE WHEN f.is_wicket = 1 THEN 1 ELSE 0 END), 0), 2) AS openers_combined_average
FROM fact_deliveries f
JOIN dim_match m ON f.match_id = m.match_id
-- Keeps ONLY rows belonging to the two designated openers for each specific match
JOIN MatchOpeners mo ON f.match_id = mo.match_id 
                    AND f.batting_team = mo.batting_team 
                    AND f.batter = mo.batter
WHERE f.batting_team LIKE 'Chennai%'
GROUP BY m.season  
ORDER BY m.season DESC;


-- runs scored by middle order batsmen (Wicket 1 to Wicket 5 ):
-- starts here:
-- Track the running count of wickets fallen BEFORE each ball is bowled
WITH WicketCounter AS (
    SELECT 
        f.match_id,
        m.season,
        f.runs_batter,
        -- Window function tracks chronological wickets down per match innings
        SUM(f.is_wicket) OVER (
            PARTITION BY f.match_id, f.innings_num 
            ORDER BY f.over_num, f.ball_num
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS wickets_before_this_ball
    FROM fact_deliveries f
    JOIN dim_match m ON f.match_id = m.match_id
    WHERE f.batting_team LIKE 'Chennai%'
)

-- Sum the runs only when the current wicket partnership state is between Wicket 1 and 5
SELECT 
    season,
    COUNT(DISTINCT match_id) AS total_matches,
    -- If 1, 2, 3, or 4 wickets are down, it means Wicket 1 has fallen, but Wicket 5 has not.
    SUM(CASE WHEN COALESCE(wickets_before_this_ball, 0) BETWEEN 1 AND 4 THEN runs_batter ELSE 0 END) AS middle_wicket_runs
FROM WicketCounter
GROUP BY season
ORDER BY season DESC;
