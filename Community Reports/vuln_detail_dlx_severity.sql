WITH
   vuln_references AS (
      SELECT vulnerability_id, array_to_string(array_agg(reference), ', ') AS references
      FROM dim_vulnerability
         JOIN dim_vulnerability_reference USING (vulnerability_id)
      GROUP BY vulnerability_id
   )
SELECT da.ip_address, da.host_name, da.mac_address, 
   dv.title AS vulnerability, dvs.description AS status, favi.date AS discovered_date,
   CASE WHEN favi.port = -1 THEN NULL ELSE favi.port END AS port,
   dp.name AS protocol, dsvc.name AS service, proofAsText(dv.description) AS vulnerability_description,
   proofAsText(favi.proof) AS proof, round(dv.cvss_score::numeric, 2) AS cvss_score,
   round(dv.cvss_v3_score::numeric, 2) AS cvss_v3_score,
 
   --dlx_severity,
   CASE
      WHEN dv.cvss_v3_score IS NOT NULL THEN
         CASE
            WHEN round(dv.cvss_v3_score::numeric, 2) BETWEEN 9.00 AND 10.00 THEN 'Critical'
            WHEN round(dv.cvss_v3_score::numeric, 2) BETWEEN 7.00 AND 8.99 THEN 'High'
            WHEN round(dv.cvss_v3_score::numeric, 2) BETWEEN 4.00 AND 6.99 THEN 'Medium'
            ELSE 'Low'
         END
      ELSE
         CASE
            WHEN round(dv.cvss_score::numeric, 2) BETWEEN 9.00 AND 10.00 THEN 'Critical'
            WHEN round(dv.cvss_score::numeric, 2) BETWEEN 7.00 AND 8.99 THEN 'High'
            WHEN round(dv.cvss_score::numeric, 2) BETWEEN 4.00 AND 6.99 THEN 'Medium'
            ELSE 'Low'
         END
      END AS dlx_severity,
 
   vr.references, dv.exploits, dv.malware_kits
FROM fact_asset_vulnerability_instance favi
   JOIN dim_asset da USING (asset_id)
   JOIN dim_vulnerability dv USING (vulnerability_id)
   JOIN dim_site_asset dsa USING (asset_id)
   JOIN dim_site ds USING (site_id)
   JOIN dim_vulnerability_status dvs USING (status_id)
   JOIN dim_protocol dp USING (protocol_id)
   JOIN dim_service dsvc USING (service_id)
   JOIN vuln_references vr USING (vulnerability_id)
ORDER BY ds.name, da.ip_address
