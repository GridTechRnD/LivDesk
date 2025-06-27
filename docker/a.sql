SELECT
    team_id,
    CASE
        WHEN team_id = 2 THEN 'Dúvidas Gerais'
        WHEN team_id = 3 THEN 'Inversor'
        WHEN team_id = 4 THEN 'Monitoramento - Wifi'
        WHEN team_id = 5 THEN 'Carregador Veicular'
        WHEN team_id = 11 THEN 'Garantias'
        WHEN team_id = 12 THEN 'Garantias Interno'
        ELSE 'Unknown' 
    END AS category_description,
    COUNT(*) AS occurrence_count
FROM
    chatwoot_production.public.conversations
WHERE
    team_id IS NOT NULL
GROUP BY
    team_id
ORDER BY
    team_id;
    