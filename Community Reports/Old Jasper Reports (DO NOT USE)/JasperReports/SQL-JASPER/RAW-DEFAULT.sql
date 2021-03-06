WITH
   asset_vuln_age AS (
      SELECT fav.asset_id, fav.vulnerability_id, date_part('days', (CURRENT_DATE - MIN(fasv.date)) + INTERVAL '1 day') AS age
      FROM fact_asset_scan_vulnerability_instance fasv
         JOIN fact_asset_vulnerability_instance fav ON fasv.asset_id = fav.asset_id AND fasv.vulnerability_id = fav.vulnerability_id
      GROUP BY fav.asset_id, fav.vulnerability_id
   ),
   asset_metadata AS (
      SELECT da.asset_id, ds.name AS site_name, da.ip_address AS ip_address, da.host_name
      FROM dim_asset da
         JOIN dim_site_asset dsa ON dsa.asset_id = da.asset_id
         JOIN dim_site ds ON ds.site_id = dsa.site_id
   )
SELECT vfa.asset_id, am.site_name, am.ip_address, am.host_name, vfa.vulnerability_title, vfa.severity, vfa.vuln_count, vfa.age
FROM (
   -- List the age of vuln findings in scope, along with their title, site/asset information, and instance count
   SELECT avd.asset_id, dv.title AS vulnerability_title, dv.severity_score AS severity, avd.vuln_count, avd.age
   FROM (
      SELECT fav.asset_id, fav.vulnerability_id, 1 AS vuln_count, ava.age
      FROM asset_vuln_age ava
         JOIN fact_asset_vulnerability_finding fav ON fav.asset_id = ava.asset_id AND fav.vulnerability_id = ava.vulnerability_id
      GROUP BY fav.asset_id, fav.vulnerability_id, ava.age
   ) avd
   JOIN dim_vulnerability dv ON dv.vulnerability_id = avd.vulnerability_id
) vfa
JOIN asset_metadata am ON am.asset_id = vfa.asset_id
ORDER BY site_name, ip_address, vulnerability_title