-- --  Task 1.
-- Create Music database. Create two users1 – MusicAdmin and U, where U is your
-- name concatenated with 3 last digits of your index number. Set the passwords
-- for both users (remember about securing the passwords). Give MusicAdmin full
-- grants to the Music database and no privileges outside of it. Give U sufficient
-- privileges to select from the whole chinook and Music databases, to modify the
-- contents of the tables in Music database, but no privileges to create or modify
-- tables nor views.
DROP DATABASE Music;
CREATE DATABASE IF NOT EXISTS Music;

-- CREATE USER 'MusicAdmin'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
-- CREATE USER 'Karolina763'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
-- SELECT VERSION();
GRANT ALL PRIVILEGES ON Music . * TO 'MusicAdmin'@'localhost';
FLUSH PRIVILEGES;
GRANT SELECT ON chinook.* TO 'Karolina763'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Music.* TO 'Karolina763'@'localhost';
FLUSH PRIVILEGES;

-- Task 2.
-- In the Music database create tables:
-- * bands (id:int, name:varchar(90), noAlbums: int),
-- * albums(title: varchar(90), genre: varchar(30), band:int),
-- * songs(id:int, title: varchar(90), length: int, album: varchar(90), band: int).

USE Music;
SELECT database();

DROP TABLE IF EXISTS bands;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS songs;



CREATE TABLE bands 
(
    id INT UNSIGNED AUTO_INCREMENT,
    name VARCHAR(90),
    noAlbums INT DEFAULT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE albums

-- I added id beacuse some titles are duplicated ex. Unplugged for the same
-- artist two same album names
(
    id INT UNSIGNED AUTO_INCREMENT,
    title VARCHAR(150),
    genre VARCHAR(90),
    band INT REFERENCES bands(id),
    PRIMARY KEY (id)
);

CREATE TABLE songs
(
    id INT UNSIGNED AUTO_INCREMENT,
    -- because titles are not unique, reference is its id
    album INT REFERENCES albums(id),
    title VARCHAR(150), -- some titles are longer
    length INT NOT NULL,
    band INT NOT NULL REFERENCES bands(id),
    CHECK (length>0),
    PRIMARY KEY (id)
);


-- Task 3.
-- Import the data from chinook database to Music. Do not 
-- import data concerning TV series, movies or songs that
--  include ’v’ in their title.
-- i need information from chinook:
-- - composer name (band name)
-- - album name
-- - genre
-- - song name
-- - length os songs (seconds)

-- I am creating a procedure v_track to get a general information
-- which I need to further tasks.

-- First i create a table (later I am going to delete it) for all important
-- information from chinook database.


DROP TABLE IF EXISTS temp_track;

CREATE TABLE temp_track
(
    artistName VARCHAR(90),
    trackId INT PRIMARY KEY,
    trackName VARCHAR(150),
    albumTitle VARCHAR(150),
    albumId INT,
    genreName VARCHAR(90),
    Seconds INT
);


DROP PROCEDURE IF EXISTS c_add_data_to_temp_track;

CREATE DEFINER=CURRENT_USER PROCEDURE c_add_data_to_temp_track()
BEGIN
    DROP VIEW IF EXISTS v_track_id;
    CREATE VIEW v_track_id AS SELECT TrackId FROM chinook.playlisttrack
    WHERE PlaylistId in (SELECT PlaylistId FROM chinook.playlist
    WHERE NAME NOT IN ('Movies', 'TV Shows', 'Audiobooks', 'Music Videos'));

    INSERT INTO temp_track(artistName, trackId, trackName, albumTitle, albumId, genreName, Seconds)

    SELECT chinook.artist.Name, trackId, track.name,
    album.Title, album.albumId,
    chinook.genre.Name,  Milliseconds/1000 FROM chinook.track
    INNER JOIN chinook.genre ON chinook.genre.GenreId=chinook.track.GenreId
    LEFT JOIN chinook.album ON chinook.track.AlbumId=chinook.album.AlbumId
    LEFT JOIN chinook.artist ON chinook.album.ArtistId=chinook.artist.ArtistId
    WHERE (track.name NOT LIKE '$v$' AND chinook.artist.Name IS NOT NULL
    AND chinook.genre.Name NOT IN ('TV Shows', 'Drama', 'Comedy', 'Science Fiction', 'Sci Fi & Fantasy')
    AND chinook.track.TrackId IN (SELECT trackId FROM v_track_id));
    DROP VIEW v_track_id;

END;

CALL c_add_data_to_temp_track();


-- On the next task I have to fill tables of music database on 
-- chinook databases, but in next tasks I will need to have music 
-- data to add new things. I dont wnt to have duplicates in my database
-- so I made a procedure which splits chinook data to 2 tables, which 
-- I am going to delete after improve all tasks.

DROP TABLE IF EXISTS temp_track_0;

CREATE TABLE temp_track_0
(
    artistName VARCHAR(90),
    trackName VARCHAR(150),
    albumTitle VARCHAR(150),
    genreName VARCHAR(90),
    Seconds INT
 );

DROP TABLE IF EXISTS temp_track_1;
CREATE TABLE temp_track_1
(
    artistName VARCHAR(90),
    trackName VARCHAR(150),
    albumTitle VARCHAR(150),
    albumId INT,
    genreName VARCHAR(90),
    Seconds INT
);

DROP PROCEDURE IF EXISTS c_splitTrackData;

CREATE PROCEDURE c_splitTrackData(p FLOAT)
BEGIN

    DECLARE amount FLOAT;
    DECLARE n INT;
    DECLARE firstSet INT;
    DECLARE artist VARCHAR(150);
    DECLARE albumName VARCHAR(150);
    DECLARE songName VARCHAR(150);
    DECLARE songGenre VARCHAR(90);
    DECLARE albumDone INT DEFAULT FALSE;
    DECLARE length INT;
    DECLARE albumCursor CURSOR FOR SELECT artistName, albumTitle 
        FROM temp_track GROUP BY albumTitle ORDER BY RAND();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET albumDone = TRUE;
    

    SET n = 0;

    OPEN albumCursor;
    SELECT FOUND_ROWS() into amount;
    SET firstSet = ROUND(amount * p, 0);

    cursor_loop: LOOP
    IF albumDone = TRUE THEN
            LEAVE cursor_loop;
    END IF;
    FETCH albumCursor INTO artist, albumName;
    IF n < firstSet THEN
        INSERT INTO temp_track_0(artistName, trackName, albumTitle, genreName, Seconds)
        SELECT artistName, trackName, albumTitle, genreName, Seconds FROM temp_track
        WHERE ((temp_track.artistName=artist) AND (temp_track.albumTitle=albumName));
    ELSE
        INSERT INTO temp_track_1(artistName, trackName, albumTitle, albumId, genreName, Seconds)
        SELECT artistName, trackName, albumTitle, albumId, genreName, Seconds FROM temp_track
        WHERE ((temp_track.artistName=artist) AND (temp_track.albumTitle=albumName));
    END IF;
    SET n = n + 1;
    END LOOP cursor_loop;
    CLOSE albumCursor;

END;

CALL c_splitTrackData(0.8);

-- add data to bands

INSERT INTO bands(name)
SELECT DISTINCT artistName
FROM temp_track_0;

-- add data to albums

INSERT INTO albums(title, genre, band) 
SELECT DISTINCT temp_track_0.albumTitle AS title, 
temp_track_0.genreName AS genre,
id AS band
FROM bands
INNER JOIN temp_track_0 ON temp_track_0.ArtistName=bands.name;


-- add data to songs


-- get id of artist from bands
DROP VIEW IF EXISTS v_track_bands;
CREATE view v_track_bands AS
SELECT albums.id AS albumId, temp_track_0.* FROM albums
INNER JOIN bands ON bands.id=albums.band
INNER JOIN temp_track_0 ON ((temp_track_0.artistName=bands.name)
                        AND (temp_track_0.albumTitle=albums.title)
                        AND (temp_track_0.genreName=albums.genre));



INSERT INTO songs(title, album, length, band)
SELECT v_track_bands.trackName, albums.id, ROUND(Seconds, 0),
albums.band
FROM v_track_bands
INNER JOIN albums ON albums.id=v_track_bands.albumId;

-- Task 4.
-- Create a procedure that counts the number of albums of each of the band and
-- fills out the table. Try to utilize cursors.
 
DROP PROCEDURE IF EXISTS GetNumberOfAlbums;

CREATE DEFINER=CURRENT_USER PROCEDURE GetNumberOfAlbums() 
BEGIN 
    DECLARE done  INT DEFAULT FALSE;
    DECLARE length INT;
    DECLARE newNoAlbums INT;
    DECLARE bandId INT;
    DECLARE bandsCursor CURSOR FOR SELECT count(band),
    band FROM albums GROUP BY band; 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN bandsCursor;
    cursor_loop: LOOP
    IF done = TRUE THEN
            LEAVE cursor_loop;
    END IF;
    FETCH bandsCursor INTO newNoAlbums, bandId;
        UPDATE bands SET noAlbums = newNoAlbums
        WHERE bands.id=bandId;

    END LOOP cursor_loop;
    CLOSE bandsCursor;
END;


CALL GetNumberOfAlbums();


-- Task 5. Create a trigger that updates noAlbums column every time that the contents of
-- albums table change.
DROP TRIGGER IF EXISTS albumCheck;

CREATE TRIGGER albumCheck AFTER INSERT ON albums FOR EACH ROW
BEGIN
UPDATE bands
INNER JOIN albums ON albums.band=bands.id
SET bands.noAlbums = bands.noAlbums + 1
WHERE NEW.band=bands.id;
END;


-- 6. Create a procedure with a single input parameter – the number of albums to
-- be generated k – and adds k random albums to the table, and then updates


--  adds k random albums to the table, and then updates the relevant information in the other tables?
--  ALBUM:
-- - should have between 4 and 25 songs
-- - may belong to a new or already present in the database band
-- - yet all generated in a single batch albums cannot be recorded by a single band (if k > 1)

DROP VIEW IF EXISTS v_songs;
CREATE VIEW v_songs AS
SELECT *, count(trackName) as noSongs from temp_track_1
group by albumId;
-- select * from v_songs;

DROP PROCEDURE IF EXISTS p_proc;
CREATE PROCEDURE p_proc(k INT)
BEGIN

    DECLARE n INT;
    DECLARE bandName VARCHAR(90);
    DECLARE albumIdt INT;
    DECLARE albumName VARCHAR(150);
    DECLARE genre VARCHAR(90);
    DECLARE sameBand INT;
    DECLARE bandId INT;
    DECLARE bandsCount INT;
    DECLARE lastBand VARCHAR(90);
    SET n = 0;
    SET sameBand = 1;
    WHILE k > n DO
        IF ((k = n + 1)  AND (k != 1)) THEN
        -- jezeli to jest ostatnia petla to sprawdz ilu dodalo wykonawcow
        -- ale jest to tez pierwsza dla k=1
           
            IF sameBand=1 THEN
                SELECT artistName, albumId, albumTitle, genreName  INTO
                bandName, albumIdt, albumName, genre
                FROM v_songs WHERE ((noSongs BETWEEN 4 AND 25) AND artistName!=lastBand)
                ORDER BY RAND() LIMIT 1;


            ELSE
                SELECT artistName, albumId, albumTitle, genreName 
                INTO 
                bandName, albumIdt, albumName, genre
                FROM v_songs WHERE (noSongs BETWEEN 4 AND 25)
                ORDER BY RAND() LIMIT 1;
            END IF;
        ELSE
            SELECT artistName, albumId, albumTitle, genreName 
            INTO bandName, albumIdt, albumName, genre
                FROM v_songs WHERE noSongs BETWEEN 4 AND 25
                ORDER BY RAND() LIMIT 1;
        END IF;
        IF NOT EXISTS(SELECT id  FROM bands
         WHERE name = bandName) THEN
                INSERT INTO bands(name) VALUES(bandName);
                SELECT id INTO bandId FROM bands ORDER BY id DESC LIMIT 1;
        ELSE
            SELECT id INTO bandId FROM bands WHERE name=bandName;
        END IF;
       
        
        INSERT INTO albums(title, genre, band) VALUES (albumName, genre, bandId);
        BLOCK2: BEGIN
        
        DECLARE done INT DEFAULT FALSE;
        DECLARE AlbumIdt INT;
        DECLARE bandId INT;
        DECLARE songName VARCHAR(150);
        DECLARE songSeconds INT;
        DECLARE songCursor CURSOR FOR SELECT trackName, Seconds 
         FROM temp_track_1
        WHERE (albumTitle = (SELECT title from albums ORDER BY id DESC LIMIT 1))
        AND (genreName = (SELECT genre from albums ORDER BY id DESC LIMIT 1));
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
        SELECT albums.id INTO AlbumIdt FROM albums ORDER BY id DESC LIMIT 1;
        SElECT albums.band INTO bandId FROM albums ORDER BY id DESC LIMIT 1;
        OPEN songCursor;
        cursor_loop: LOOP
        IF done = TRUE THEN
            LEAVE cursor_loop;
        END IF;
        FETCH songCursor INTO songName, songSeconds;
        INSERT INTO songs(title, length, album, band)
        VALUES (songName, songSeconds, albumIdt, bandId);       

        END LOOP cursor_loop;
        CLOSE songCursor;
        END BLOCK2;
        IF (lastBand IS NOT NULL) AND (lastBand!=bandName) THEN
            SET sameBand = 0;
        END IF;
        SET lastBand = bandName;
        SET n = n + 1;
    END WHILE;

END;

CALL p_proc(4);

-- Task 7. Create a function or a procedure that for a given band name returns the title of
-- its shortest album. Make sure that it is secure against errors or SQL injections.


DROP PROCEDURE IF EXISTS p_shortestName;
CREATE PROCEDURE p_shortestName(bandName VARCHAR(90))
BEGIN
    SELECT @var := bandName;
    PREPARE s_band FROM 
        'SELECT albums.title FROM albums 
        WHERE band = (SELECT id FROM bands WHERE name= ? )
        ORDER BY LENGTH(albums.title) ASC LIMIT 1';

    EXECUTE s_band USING @var;
    DEALLOCATE PREPARE s_band;
END;

select * from bands;
CALL p_shortestName("Led Zeppelin'; DROP TABLE bands;--");

-- Task 8. Create a view that includes all the information about songs longer than 3 minutes
-- and their authors.
DROP VIEW IF EXISTS v_onlyLongSongs;
CREATE VIEW v_onlyLongSongs AS
SELECT * FROM songs
WHERE length/60>3;

-- Task 9. Create a PREPARE statement that for a given 
-- genre returns the number of albums in it, recorded
--  by each of the bands. The genre name should be given
-- during EXECUTE. 
START TRANSACTION;
PREPARE s_stmt FROM 
'SELECT DISTINCT bands.name, bands.noAlbums FROM albums
INNER JOIN bands ON bands.id = albums.band
WHERE albums.genre = ? ';

-- SET @pc = "(SELECT Name FROM chinook.genre WHERE GenreId=1);";
SET @pc = "Rock";
EXECUTE s_stmt USING @pc;
DEALLOCATE PREPARE s_stmt;
COMMIT;

-- Task 10. 
-- procedure that allows selecting
-- all songs with length in a given 
-- relation rel with aggregate function agg.
-- czyli chce sobie np powiedziec, ze chcce wszytkie piosenki,
-- ktorych dlugosc jest wieksza niz n (relacja s>n)

-- Use transactions to make sure
-- that the restriction is not violated.

DROP FUNCTION IF EXISTS CHECK_INPUT_VALUE;
CREATE FUNCTION CHECK_INPUT_VALUE(relValue TEXT, aggValue TEXT) RETURNS INT 
BEGIN
    DECLARE isCorrect INT;
    IF relValue IN ('<', '<=', '>', '>=', '=') AND aggValue IN ( "AVG", "MIN", "MAX") THEN 
        SET isCorrect = 1;
    ELSE
        SET isCorrect = 0;
    END IF;
    RETURN isCorrect;
END;

DROP PROCEDURE IF EXISTS p_songs;
CREATE PROCEDURE p_songs (rel NVARCHAR(10), agg NVARCHAR(10))
-- AS
BEGIN
    IF agg = "std" THEN
        PREPARE song_stmt FROM "SELECT * FROM songs WHERE length BETWEEN
                            (SELECT AVG(length)- 2 * STD(length) FROM songs) 
                            AND  (SELECT AVG(length)+ 2 * STD(length) FROM songs)";
        EXECUTE song_stmt;
        DEALLOCATE PREPARE song_stmt;
    ELSE
        IF CHECK_INPUT_VALUE(rel, agg) = 1 THEN
            SET @prep = CONCAT("SELECT * FROM songs  WHERE length ", rel," (SELECT ", agg, "(length) FROM songs)");
            PREPARE song_stmt FROM @prep;
            EXECUTE song_stmt;
            DEALLOCATE PREPARE song_stmt;
        END IF;
    END IF;
      
END;    
        

START TRANSACTION;
SET @rel := ">";
SET @agg := "std";
CALL p_songs(@rel, @agg);
COMMIT;


-- Task 11. 
-- Create a procedure that selects a random2 playlist consisting of songs that last
-- not longer than a given input parameter thresh. Use transactions to make sure
-- that the restriction is not violated.

DROP PROCEDURE IF EXISTS c_playlist;

CREATE PROCEDURE c_playlist (IN threshold INT,IN size INT)
BEGIN
START TRANSACTION;
INSERT INTO playlist(thresh)
    VALUES (threshold);
SELECT @playlistId:= id from playlist ORDER BY id DESC LIMIT 1;
INSERT INTO playlistsong(playlistId, song)
    SELECT @playlistId, id from songs where length<threshold
ORDER BY rand() limit size;
COMMIT;
END;



-- 12.
DROP TABLE IF EXISTS playlist;
CREATE TABLE playlist
(
    id INT UNSIGNED AUTO_INCREMENT,
    thresh INT,
    PRIMARY KEY (id)
);
DROP TABLE IF EXISTS playlistsong;
CREATE TABLE playlistsong
(
    id INT UNSIGNED AUTO_INCREMENT,
    playlistId INT REFERENCES playlist(id),
    song INT,
    PRIMARY KEY (id)
);


DROP PROCEDURE IF EXISTS p_add_playlist;

CREATE PROCEDURE p_add_playlist(IN threshold INT)
BEGIN
    DECLARE size INT;
    SET size = ROUND(RAND()*25,0);
    CALL c_playlist(threshold, size);
END;



select * from playlistsong;
select * from playlist;
CALL p_add_playlist(180);

-- Task 13.
-- Create a backup of your database. Delete the database from your DBE and then
-- restore it using the backup made. Write and present a report of the backuping
-- and restoring both in a selected IDE and command line
-- in terminal mysqldump -u root -p music -n -d -t >D:\music.sql 
-- in terminal
-- mysqldump -u root -p music < D:\music.sql
-- mysql -u root -p
-- DROP DATABASE music;
-- CREATE DATABASE music;
-- USE music;
-- SOURCE D:\music.sql
-- Add a random price between $1$ and $5$ to each of the songs.
--  Create a procedure or a function that takes a string \texttt{A}
--   as an input and returns (as an output parameter or a returned value)
--    the total price of the album

SELECT * FROM songs;
-- ALTER TABLE songs
-- DROP COLUMN price;
ALTER TABLE songs ADD COLUMN price FLOAT;

UPDATE songs SET price = ROUND((RAND())*4+1, 2);

DROP PROCEDURE IF EXISTS p_albumsPrice;
CREATE PROCEDURE p_albumsPrice(albumName VARCHAR(90))
BEGIN
    SELECT @var := albumName;
    PREPARE s_album FROM 
        'SELECT ROUND(sum(price),2) FROM songs 
        INNER JOIN albums ON songs.album=albums.id
        WHERE albums.title= ?
        GROUP BY albums.title';

    EXECUTE s_album USING @var;
    DEALLOCATE PREPARE s_album;
END;

-- select * from albums;

-- SELECT ROUND(sum(price),2) FROM songs 
-- INNER JOIN albums ON songs.album=albums.id
-- WHERE albums.title="A-Sides"
-- GROUP BY albums.title;

CALL p_albumsPrice("A-Sides");


