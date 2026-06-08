-- No of wickets per season

SELECT season,count(*) as total_wickets
 FROM fact_deliveries f JOIN dim_match d 
on d.match_id=f.match_id 
WHERE is_wicket=1 AND bowling_team LIKE 'Chennai%' 
GROUP BY season
ORDER BY season DESC;

-- TOP wicket takers per season

WITH BowlerWickets AS (
    SELECT 
        p.player_name AS bowler_name, 
        m.season, 
        SUM(CASE 
            WHEN f.is_wicket = 1 
            AND f.wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field', 'retired out') 
            THEN 1 ELSE 0 
        END) AS true_wickets
    FROM fact_deliveries f  
    JOIN dim_player p ON f.bowler = p.player_name
    JOIN dim_match m  ON f.match_id = m.match_id 
    WHERE f.bowling_team LIKE 'Chennai%' 
    GROUP BY p.player_name, m.season
),
RankedBowlers AS (
    SELECT 
        season,
        bowler_name,
        true_wickets,
        DENSE_RANK() OVER (PARTITION BY season ORDER BY true_wickets DESC) AS wicket_rank
    FROM BowlerWickets
)
SELECT 
    season,
    bowler_name,
    true_wickets AS wickets
FROM RankedBowlers
WHERE wicket_rank = 1
ORDER BY season DESC;

-- powerplay economy and wickets

SELECT 
    m.season,
    SUM(CASE 
        WHEN f.is_wicket = 1 
        AND f.wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field', 'retired out') 
        THEN 1 ELSE 0 
    END) AS powerplay_wickets_taken,
    
    -- FORCING DECIMAL MATH: This guarantees the economy is a normal number (e.g., 7.45)
    ROUND(
        (SUM(f.runs_total) * 6.0) / 
        NULLIF(COUNT(CASE WHEN f.extra_type IS NULL OR (f.extra_type != 'wide' AND f.extra_type != 'no ball') THEN 1 END), 0), 
        2
    ) AS powerplay_economy
FROM fact_deliveries f
JOIN dim_match m ON f.match_id = m.match_id
WHERE f.bowling_team LIKE 'Chennai%'
  AND f.phase ='Powerplay'
GROUP BY m.season
ORDER BY m.season DESC;

-- dot balls per season


SELECT 
    m.season,
    COUNT(*) AS total_balls_bowled,
    SUM(CASE WHEN f.runs_batter = 0 AND f.runs_extras = 0 THEN 1 ELSE 0 END) AS total_dot_balls,
    ROUND(
        AVG(CASE WHEN f.runs_batter = 0 AND f.runs_extras = 0 THEN 1 ELSE 0 END) * 100, 
        2
    ) AS bowling_dot_ball_pct
FROM fact_deliveries f
JOIN dim_match m ON f.match_id = m.match_id
WHERE f.bowling_team LIKE 'Chennai%'
GROUP BY m.season
ORDER BY m.season DESC;

-- economy rate of bowlers per season

SELECT 
    m.season,
    -- In cricket analytics, Economy = (Total Runs Conceded * 6) / Total Legal Balls Bowled
    ROUND(
        SUM(f.runs_total) * 6.0 / 
        COUNT(CASE WHEN f.is_wide = 0 AND f.is_no_ball = 0 THEN 1 END), 
        2
    ) AS season_economy_rate
FROM fact_deliveries f
JOIN dim_match m ON f.match_id = m.match_id
WHERE f.bowling_team LIKE 'Chennai%'
GROUP BY m.season
ORDER BY m.season DESC;


-- spin vs pace

SELECT 
    m.season,
    -- Pace Economy
    ROUND(
        SUM(CASE WHEN f.bowler IN ('DL Chahar', 'SR Watson', 'MA Wood', 'DJ Bravo', 'SN Thakur', 'L Ngidi', 'KM Asif', 'DJ Willey', 'MM Sharma', 'SC Kuggeleijn', 'SM Curran', 'JR Hazlewood', 'Monu Kumar', 'TU Deshpande', 'AF Milne', 'Mukesh Choudhary', 'D Pretorius', 'CJ Jordan', 'Simarjeet Singh', 'M Pathirana', 'RS Hangargekar', 'BA Stokes', 'SSB Magala', 'Akash Singh', 'Mustafizur Rahman', 'J Overton', 'A Kamboj', 'MJ Henry', 'Gurjapneet Singh', 'SH Johnson', 'KK Ahmed', 'NT Ellis', 'S Dube') THEN f.runs_total ELSE 0 END) * 6.0 /
        NULLIF(COUNT(CASE WHEN f.bowler IN ('DL Chahar', 'SR Watson', 'MA Wood', 'DJ Bravo', 'SN Thakur', 'L Ngidi', 'KM Asif', 'DJ Willey', 'MM Sharma', 'SC Kuggeleijn', 'SM Curran', 'JR Hazlewood', 'Monu Kumar', 'TU Deshpande', 'AF Milne', 'Mukesh Choudhary', 'D Pretorius', 'CJ Jordan', 'Simarjeet Singh', 'M Pathirana', 'RS Hangargekar', 'BA Stokes', 'SSB Magala', 'Akash Singh', 'Mustafizur Rahman', 'J Overton', 'A Kamboj', 'MJ Henry', 'Gurjapneet Singh', 'SH Johnson', 'KK Ahmed', 'NT Ellis', 'S Dube') AND (f.extra_type IS NULL OR LOWER(f.extra_type) NOT IN ('wide', 'no ball')) THEN 1 END), 0),
        2
    ) AS pace_economy,
    
    -- Spin Economy
    ROUND(
        SUM(CASE WHEN f.bowler IN ('Harbhajan Singh', 'RA Jadeja', 'Imran Tahir', 'KV Sharma', 'SK Raina', 'MJ Santner', 'PP Chawla', 'MM Ali', 'M Theekshana', 'PH Solanki', 'DJ Mitchell', 'R Ravindra', 'RJ Gleeson', 'R Ashwin', 'Noor Ahmad', 'DJ Hooda', 'MW Short', 'RD Chahar', 'AJ Hosein', 'PR Veer', 'RS Ghosh') THEN f.runs_total ELSE 0 END) * 6.0 /
        NULLIF(COUNT(CASE WHEN f.bowler IN ('Harbhajan Singh', 'RA Jadeja', 'Imran Tahir', 'KV Sharma', 'SK Raina', 'MJ Santner', 'PP Chawla', 'MM Ali', 'M Theekshana', 'PH Solanki', 'DJ Mitchell', 'R Ravindra', 'RJ Gleeson', 'R Ashwin', 'Noor Ahmad', 'DJ Hooda', 'MW Short', 'RD Chahar', 'AJ Hosein', 'PR Veer', 'RS Ghosh') AND (f.extra_type IS NULL OR LOWER(f.extra_type) NOT IN ('wide', 'no ball')) THEN 1 END), 0),
        2
    ) AS spin_economy
FROM fact_deliveries f
JOIN dim_match m ON f.match_id = m.match_id
WHERE f.bowling_team LIKE 'Chennai%'
GROUP BY m.season
ORDER BY m.season DESC;


-- Powerplay economy 

SELECT
    m.season,
    ROUND(
        (SUM(f.runs_total) * 6.0) / COUNT(*),
        2
    ) AS death_over_economy
FROM fact_deliveries f
JOIN dim_match m
    ON f.match_id = m.match_id
WHERE
    f.bowling_team LIKE 'Chennai%'
    AND f.phase = 'death'
GROUP BY m.season
ORDER BY m.season DESC;