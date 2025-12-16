CREATE DATABASE bibliotheque
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE bibliotheque;
CREATE TABLE AUTEUR (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);
CREATE TABLE OUVRAGE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,
    disponible BOOLEAN DEFAULT TRUE,
    auteur_id INT,
    CONSTRAINT fk_ouvrage_auteur
        FOREIGN KEY (auteur_id)
        REFERENCES AUTEUR(id)
        ON DELETE CASCADE
);
CREATE TABLE ABONNE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE
);
CREATE TABLE EMPRUNT (
    ouvrage_id INT,
    abonne_id INT,
    date_debut DATE NOT NULL,
    date_fin DATE,
    PRIMARY KEY (ouvrage_id, abonne_id, date_debut),
    CONSTRAINT fk_emprunt_ouvrage
        FOREIGN KEY (ouvrage_id)
        REFERENCES OUVRAGE(id),
    CONSTRAINT fk_emprunt_abonne
        FOREIGN KEY (abonne_id)
        REFERENCES ABONNE(id),
    CONSTRAINT chk_dates
        CHECK (date_fin IS NULL OR date_fin >= date_debut)
);
SELECT titre
FROM OUVRAGE
WHERE disponible = TRUE;
SELECT *
FROM ABONNE
WHERE email LIKE '%@gmail.com';
SELECT *
FROM EMPRUNT
WHERE date_fin IS NULL;
SELECT a.nom AS abonne, o.titre
FROM EMPRUNT e
JOIN ABONNE a ON e.abonne_id = a.id
JOIN OUVRAGE o ON e.ouvrage_id = o.id;
SELECT a.nom, COUNT(*) AS nb_emprunts
FROM EMPRUNT e
JOIN ABONNE a ON e.abonne_id = a.id
GROUP BY a.id, a.nom;
SELECT au.nom, COUNT(o.id) AS nb_ouvrages
FROM AUTEUR au
LEFT JOIN OUVRAGE o ON o.auteur_id = au.id
GROUP BY au.id, au.nom
ORDER BY nb_ouvrages DESC;
SELECT au.nom, COUNT(o.id) AS nb_ouvrages
FROM AUTEUR au
JOIN OUVRAGE o ON o.auteur_id = au.id
GROUP BY au.id, au.nom
HAVING COUNT(o.id) >= 3;
UPDATE OUVRAGE
SET disponible = FALSE
WHERE id = 5;

DELETE FROM EMPRUNT
WHERE date_fin < '2025-01-01';
UPDATE EMPRUNT
SET date_fin = CURDATE()
WHERE ouvrage_id = 3
  AND abonne_id = 2
  AND date_fin IS NULL;
START TRANSACTION;

INSERT INTO ABONNE (nom, email)
VALUES ('Asma', 'asma@gmail.com');

SET @id_abonne = LAST_INSERT_ID();

SELECT COUNT(*)
INTO @nb_dispo
FROM OUVRAGE
WHERE id IN (1, 2)
  AND disponible = TRUE;

INSERT INTO EMPRUNT (ouvrage_id, abonne_id, date_debut)
VALUES
(1, @id_abonne, CURDATE()),
(2, @id_abonne, CURDATE());

UPDATE OUVRAGE
SET disponible = FALSE
WHERE id IN (1, 2);

COMMIT;
INSERT INTO OUVRAGE (titre, slug, disponible, auteur_id)
VALUES ('1984', '1984-orwell', TRUE, 1)
ON DUPLICATE KEY UPDATE
titre = VALUES(titre),
disponible = VALUES(disponible),
auteur_id = VALUES(auteur_id);
DELIMITER $$

CREATE PROCEDURE creer_emprunt (
    IN p_ouvrage_id INT,
    IN p_abonne_id INT
)
BEGIN
    DECLARE v_dispo BOOLEAN;

    SELECT disponible
    INTO v_dispo
    FROM OUVRAGE
    WHERE id = p_ouvrage_id;

    IF v_dispo = TRUE THEN
        INSERT INTO EMPRUNT (ouvrage_id, abonne_id, date_debut)
        VALUES (p_ouvrage_id, p_abonne_id, CURDATE());

        UPDATE OUVRAGE
        SET disponible = FALSE
        WHERE id = p_ouvrage_id;
    ELSE
        SIGNAL SQLSTATE '45000';
    END IF;
END$$

DELIMITER ;

