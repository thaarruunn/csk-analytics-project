-- PACE VS SPIN FULL COMPARISION

SELECT 
    m.season AS Season,
    t.bowling_type AS "Bowling Type",
    
    -- Total Wickets taken
    SUM(CASE WHEN f.is_wicket = 1 AND f.wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field', 'retired out') THEN 1 ELSE 0 END) AS "Total Wickets",
    
    -- Total Overs Bowled (Total legal balls / 6.0)
    ROUND(
        COUNT(CASE WHEN f.extra_type IS NULL OR LOWER(f.extra_type) NOT IN ('wide', 'no ball') THEN 1 END) / 6.0, 
        1
    ) AS "Total Overs",
    
    -- NEW: Total Runs Conceded
    SUM(f.runs_total) AS "Total Runs Conceded",
    
    -- Pure Bowling Strike Rate (Total Legal Balls / Total Wickets)
    ROUND(
        COUNT(CASE WHEN f.extra_type IS NULL OR LOWER(f.extra_type) NOT IN ('wide', 'no ball') THEN 1 END) * 1.0 / 
        NULLIF(SUM(CASE WHEN f.is_wicket = 1 AND f.wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field', 'retired out') THEN 1 ELSE 0 END), 0),
        2
    ) AS "Bowling Strike Rate",
    
    -- Economy Rate (Total Runs * 6.0 / Total Legal Balls)
    ROUND(
        SUM(f.runs_total) * 6.0 / 
        NULLIF(COUNT(CASE WHEN f.extra_type IS NULL OR LOWER(f.extra_type) NOT IN ('wide', 'no ball') THEN 1 END), 0),
        2
    ) AS "Economy Rate"

FROM fact_deliveries f
JOIN dim_bowler_type t ON f.bowler = t.bowler_name
JOIN dim_match m ON CAST(f.match_id AS CHAR) = CAST(m.match_id AS CHAR)
WHERE f.bowling_team LIKE 'Chennai%'
GROUP BY m.season, t.bowling_type
ORDER BY m.season DESC, t.bowling_type ASC;