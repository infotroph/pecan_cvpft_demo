
-- Invent some new cultivar PFTs and associate them with BIOCRO
INSERT INTO pfts (name, definition,  modeltype_id, pft_type) VALUES
    (
        'mxg_54',
        'unnamed Miscanthus cultivar ID 54',
        (SELECT id FROM modeltypes WHERE name='BIOCRO'),
        'cultivar'),
    (
        'mxg_79',
        'unnamed Miscanthus cultivar ID 79',
        (SELECT id FROM modeltypes WHERE name='BIOCRO'),
        'cultivar');

-- associate them with the relevant cultivar IDs
INSERT INTO cultivars_pfts (pft_id, cultivar_id) VALUES
    ((SELECT id FROM pfts WHERE name='mxg_54'), 54);
INSERT INTO cultivars_pfts (pft_id, cultivar_id) VALUES
    ((SELECT id FROM pfts WHERE name='mxg_79'), 79);

-- copy all priors from existing species-level miscathus PFT
SELECT prior_id, variables.name INTO TEMP mxg_priors
    FROM priors 
        JOIN pfts_priors ON (priors.id=prior_id)
        JOIN variables ON (variable_id=variables.id)
        JOIN pfts ON (pft_id=pfts.id)
    WHERE pfts.name='Miscanthus_x_giganteus';

-- associate copied Mxg priors with cultivar PFTs
INSERT INTO pfts_priors (pft_id, prior_id)
    SELECT (SELECT id FROM pfts WHERE name='mxg_54') AS pft_id,
        prior_id 
    FROM mxg_priors;

INSERT INTO pfts_priors (pft_id, prior_id)
    SELECT (SELECT id FROM pfts WHERE name='mxg_79') AS pft_id,
        prior_id
    FROM mxg_priors;

DROP TABLE mxg_priors;