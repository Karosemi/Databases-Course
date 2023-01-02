-- List 1.
-- author: Karolina Schmidt
-- SET GLOBAL log_bin_trust_function_creators = 1;
-- Task 1.  Find a way to select all the tables in the database
USE chinook;
SHOW TABLES;

--  Task 2. Check all the properties of table track, including the list of column,
--  their type, key types and default values.
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'track';

-- Task 3. For each track print out a pair of track title and album title.
SELECT track.Name AS 'Track name', album.Title AS 'Album title' 
FROM track
INNER JOIN album ON track.AlbumId = album.AlbumId;

-- Task 4. Select all albums by ’Various Artists’.

-- creating a view of all 'various artists' names
DROP VIEW IF EXISTS variousArtists;
CREATE VIEW variousArtists AS
SELECT ArtistId, Name FROM artist 
WHERE (Name NOT LIKE 'Big & Rich' AND Name NOT LIKE 'Mundo Livre S/A'
AND Name NOT LIKE 'AC/DC'
AND Name NOT LIKE 'Mercury, Freddie') AND 
 (Name LIKE "%&%" 
OR Name LIKE '%Feat.%'
OR Name LIKE '%/%');

SELECT * FROM VariousArtists;
SELECT * FROM artist;

SELECT * FROM album
WHERE ArtistId IN (SELECT ArtistId FROM VariousArtists);

--  Task 5.
-- Print out all the unique names of the artists
-- concept: take all singular artists and split artists List from 
-- previous task into artists names

-- I am preparing table with names of all artists, including names from various artists
START TRANSACTION;
    DROP TABLE IF EXISTS allArtistsNames;
    CREATE TABLE allArtistsNames
    (
        id INT UNSIGNED AUTO_INCREMENT,
        artistId INT,
        artistName VARCHAR(90),
        PRIMARY KEY (id)
    );
      -- insteting into table all individual artists
      INSERT INTO allArtistsNames(ArtistId, artistName)
      SELECT ArtistId, Name FROM artist
      WHERE ArtistId NOT IN (SELECT ArtistId FROM VariousArtists)
     ;
-- function to get part value of string on position
    DROP FUNCTION IF EXISTS SPLIT_STRING;
    
    CREATE FUNCTION SPLIT_STRING(artist VARCHAR(120), del VARCHAR(12), pos INT) RETURNS VARCHAR(120)
    DETERMINISTIC -- always returns same results for same input parameters
    BEGIN
        DECLARE splitText TEXT;
        SET splitText = REPLACE(SUBSTRING(SUBSTRING_INDEX(artist, del, pos),
             CHAR_LENGTH(SUBSTRING_INDEX(artist, del, pos - 1)) + 1), del, '');
        IF splitText = '' THEN
            SET splitText = NULL;
        END IF;
        RETURN splitText;

    END;
    SELECT SPLIT_STRING(Name, " & ", 1)
                  FROM VariousArtists;
-- procedure to fill new table by all records
    DROP PROCEDURE IF EXISTS tranferArtistsNames;
    CREATE PROCEDURE tranferArtistsNames()
        BEGIN
            DECLARE i INTEGER;
            DECLARE currentArtistName TEXT;
            SET i = 1;
            REPEAT
                  INSERT INTO allArtistsNames(ArtistId, artistName)
                  SELECT ArtistId, SPLIT_STRING(Name, " & ", i)
                  FROM variousArtists
                  WHERE SPLIT_STRING(Name," & ", i) IS NOT NULL
                  AND Name LIKE "% & %"
                  AND SPLIT_STRING(Name, " & ", i) NOT LIKE "%  Feat. %"
                  AND SPLIT_STRING(Name, " & ", i) NOT LIKE "%, %";
                  INSERT INTO allArtistsNames(ArtistId, artistName)
                  SELECT ArtistId, SPLIT_STRING(Name, " Feat. ", i)
                  FROM VariousArtists
                  WHERE SPLIT_STRING(Name, " Feat. ", i) IS NOT NULL
                  AND Name LIKE "%  Feat. %"
                  AND SPLIT_STRING(Name, " Feat. ", i) NOT LIKE "%  & %"
                  AND SPLIT_STRING(Name, " Feat. ", i) NOT LIKE "%, %";
                  INSERT INTO allArtistsNames(ArtistId, artistName)
                  SELECT ArtistId, SPLIT_STRING(Name, ", ", i)
                  FROM VariousArtists
                  WHERE SPLIT_STRING(Name, ", ", i) IS NOT NULL
                  AND Name LIKE "%, %"
                  AND SPLIT_STRING(Name, ", ", i) NOT LIKE "%  Feat. %"
                  AND SPLIT_STRING(Name, ", ", i) NOT LIKE "% & %";
                SET i = i + 1;
                UNTIL ROW_COUNT() = 0
            END REPEAT;
        END;

CALL tranferArtistsNames();
COMMIT;

select * from allArtistsNames;
DROP VIEW IF EXISTS uniqueArtists;
CREATE VIEW uniqueArtists AS
SELECT DISTINCT id, ArtistId, artistName FROM allArtistsNames;
SELECT * FROM uniqueArtists;

-- Task 6. For each artist print out all the pairs (artist name, album title).
-- I Take the artists names from view from a previous task.

SELECT  DISTINCT uniqueArtists.artistName,  album.Title
FROM album INNER JOIN uniqueArtists ON uniqueArtists.ArtistId = album.ArtistId
ORDER BY uniqueArtists.artistName;


-- Task 7. Print out all the tracks except the ones performed by Queen.
SELECT * FROM track
WHERE Composer NOT LIKE '% Queen %';

-- Task 8. Print out all the audio files (both AAC and MPEG) that last between 275s and 400s.
SELECT * FROM track WHERE (Milliseconds/1000 BETWEEN 275 AND 400);

-- Task 9. Select all non-audio tracks and their album titles.
SELECT track.Name AS 'Track name', album.Title  AS 'Album title' FROM track
INNER JOIN album ON track.AlbumId = album.AlbumId 
WHERE track.MediaTypeId IN (SELECT MediaTypeId FROM MediaType 
WHERE MediaType.Name NOT LIKE '%audio%');

-- Task 10. Select all tracks from each playlist that contains Classic substring in its name.
-- The resulting schema should contain only track titles, album names, band names
-- and the genre.
SELECT track.Name AS "Track name", album.Title as "Album name",
track.Composer as "Band name", genre.Name as "Genre" FROM playlist 
INNER JOIN playlisttrack ON playlist.PlaylistId = playlisttrack.PlaylistId
INNER JOIN track ON playlisttrack.TrackId = track.TrackId
INNER JOIN album ON track.AlbumId = album.AlbumId
INNER JOIN genre ON track.GenreId = genre.GenreId
WHERE playlist.Name LIKE '%Classic%';


-- Task 11. Select all the cities, from which came the clients in the database.
SELECT DISTINCT city FROM customer;

-- Task 12. Check whether all American cities in the database have a state assigned.
SELECT COUNT(*) AS 'Cities without state assigned' 
FROM customer WHERE Country='USA' AND State IS NULL;

-- Task 13. List all the countries that do not have states assigned.
SELECT DISTINCT Country FROM customer WHERE State IS NULL;


-- Task 14. List all the domains of the clients’ e-mail

DROP FUNCTION IF EXISTS GET_EMAIL_DOMAIN;
CREATE FUNCTION GET_EMAIL_DOMAIN(email TEXT) RETURNS TEXT 
    BEGIN
        DECLARE domain TEXT;
        SET email = SUBSTRING(email, POSITION('@' IN email)+1, LENGTH(email));
        SET domain = SUBSTRING(email, 1, POSITION('.' IN email)-1);
        RETURN domain;
    END;

SELECT DISTINCT GET_EMAIL_DOMAIN(Email) AS "Email domain" FROM customer;

 -- Task 15.For each of the domains print out the number of clients using them. Count
-- together the companies without distinction on their country suffix.
SELECT GET_EMAIL_DOMAIN(Email) as domain, COUNT(CustomerId) AS "Number of clients" 
FROM customer
GROUP BY domain;


 -- Task 16. Find country from which clients ordered products with highest joint value.
DROP VIEW IF EXISTS totalRevenue;
CREATE VIEW totalRevenue AS
SELECT BillingCountry, SUM(Total) AS totalInvoice FROM invoice
GROUP BY BillingCountry;

SELECT * FROM totalRevenue
WHERE totalInvoice IN (SELECT MAX(totalInvoice) FROM totalRevenue);

-- Task 17. For each country print out the average value of ordered goods.
SELECT BillingCountry AS 'Country', ROUND(AVG(Total),2) AS
 'Average value of ordered goods'
FROM invoice GROUP BY BillingCountry;

-- Task 18. Find the album of the highest value. The resulting scheme should contain the
-- name of the artist, the title of the album, the number of the tracks and the total
-- price.
DROP VIEW IF EXISTS totalAlbumPrice;
CREATE VIEW totalAlbumPrice AS
SELECT track.Composer, album.Title AS albumTitle, 
COUNT(track.TrackId) AS numberOfTracks, 
SUM(track.UnitPrice) AS totalPrice
FROM track 
INNER JOIN album ON track.AlbumId = album.AlbumId
GROUP BY track.AlbumId;

SELECT * FROM totalAlbumPrice
WHERE totalPrice IN (SELECT MAX(totalPrice) FROM totalAlbumPrice);


 -- Task 19. Find the artist with the second highest number of tracks.


DROP VIEW IF EXISTS tracksNumber;
CREATE VIEW tracksNumber AS 
SELECT COUNT(track.TrackId) as tracksNo, uniqueArtists.artistName 
FROM track INNER JOIN artist ON artist.Name = track.Composer
INNER JOIN uniqueArtists ON uniqueArtists.artistId = artist.ArtistId
GROUP BY uniqueArtists.artistName;


SELECT artistName, tracksNo FROM tracksNumber 
WHERE tracksNo IN (
SELECT MAX(tracksNo) FROM tracksNumber 
WHERE tracksNo NOT IN (SELECT MAX(tracksNo) FROM tracksNumber));

 -- Task 20. Using customer and employee tables,
--   list the employees who are not currently
-- responsible for customer service.
DROP VIEW IF EXISTS notCustomerService;
CREATE VIEW notCustomerService AS
SELECT employee.* FROM employee WHERE 
EmployeeId NOT IN (SELECT DISTINCT SupportRepId FROM customer);

SELECT * FROM notCustomerService;

-- Task 21. List all employees who do not 
-- serve any customer from their own city.

DROP VIEW IF EXISTS customerService;
CREATE VIEW customerService AS
SELECT DISTINCT customer.SupportRepId 
AS SupportRepId, employee.*, customer.City AS customerCity FROM customer 
INNER JOIN employee ON employee.EmployeeId = customer.SupportRepId;


SELECT * FROM employee WHERE EmployeeId 
NOT IN (SELECT SupportRepId FROM customerService
WHERE City = customerCity) AND EmployeeId 
NOT IN (SELECT EmployeeId FROM notCustomerService);


-- Task 22.
-- List all offered products belonging to Sci Fi & Fantasy
--  or Science Fiction. The
-- schema should include the titles and their price
SELECT Name AS title, UnitPrice AS price FROM track WHERE GenreId 
IN ( SELECT GenreId FROM genre 
WHERE Name LIKE 'Sci Fi & Fantasy'
OR Name LIKE 'Science Fiction');



-- Task 23.
-- Find out which artist has the most Metal and Heavy Metal songs (combined).
-- Display the band name and track count. Order the result by the number of
-- tracks in a descending manner.
SELECT Composer, count(TrackId) AS TrackCount FROM track 
WHERE (GenreId IN (SELECT GenreId FROM genre 
WHERE Name LIKE 'Metal'
OR Name LIKE 'Heavy Metal')
AND Composer IS NOT NULL)
GROUP BY Composer
ORDER BY TrackCount DESC;

-- Task 24.  Find the employee that was the youngest when first hired.

-- the youngest employee
SELECT * FROM employee WHERE BirthDate IN(
SELECT MAX(BirthDate) FROM employee);

-- Task 25. Select all episodes of Battlestar Galactica on offer,
--  include all seasons. Order the
-- results by the title.
SELECT * FROM track WHERE Name LIKE '%Battlestar Galactica%'
ORDER BY Name ASC;
-- Task 26. Select artist names and album titles in cases where the same title is used by two
-- different bands. (Note: If (X, Y, A) is selected, the result should not include
-- (Y, X, A)).
SELECT firstArtist.Name AS firstArtistName, 
secondArtist.Name AS secondArtistName, 
firstAlbum.Title AS title 
FROM album AS firstAlbum 
INNER JOIN artist AS firstArtist ON firstArtist.ArtistId = firstAlbum.ArtistId 
INNER JOIN album AS secondAlbum ON firstAlbum.Title = secondAlbum.Title 
INNER JOIN artist AS secondArtist ON secondArtist.ArtistId = secondAlbum.ArtistId
WHERE firstArtist.Name > secondArtist.Name;

-- Task 27.
-- Select all the songs by Santana, regardless of who was featuring the record.
SELECT Name, Composer FROM track WHERE Composer LIKE '%Santana%';

-- Task 28. Print out all the records composed by a person named John,
--  ensure that none of
-- the records are repeated. Order the results alphabetically in terms of the track
-- title.
SELECT DISTINCT * FROM track 
WHERE Composer LIKE '%John %' 
ORDER BY Name ASC;

-- Task 29.
-- Sort all the artists in descending order of the average duration of their rock
-- song. Do not include artists who have recorded less than 7 for songs in the Rock
-- category.
SELECT Composer, count(TrackId) as tracksNumber, 
ROUND(avg(Milliseconds)/1000, 3) AS avgSeconds FROM track
WHERE (GenreId IN (SELECT GenreId FROM genre WHERE Name LIKE 'Rock')
AND Composer IS NOT NULL)
GROUP BY Composer
HAVING count(TrackId)>=7
ORDER BY avg(Milliseconds) DESC;

-- Task 30.
-- Enter a new customer into the customer table, do not create any invoices for
-- them.
-- delete from customer where CustomerId=60;
SELECT * FROM customer;

SELECT SupportRepId FROM customer WHERE Country = 'Poland';
INSERT INTO `Customer` (`CustomerId`, `FirstName`, `LastName`, `Address`, `City`, `Country`,
 `PostalCode`, `Phone`, `Email`, `SupportRepId`)
SELECT customer.CustomerId+1,  N'Karolina',
  N'Schmidt', N'Powstancow Slaskich 58b/8', N'Wroclaw', N'Poland', N'53333',
   N'+48 123456789', N'karolina.schmidt@gmail.com', 
   (SELECT SupportRepId FROM customer WHERE Country = 'Poland' LIMIT 1)
FROM customer
   ORDER BY customer.CustomerId DESC
   LIMIT 1;


-- Task 31.
--  Add a FavGenre column (as a last one) to the customer table. Set it, initially,
-- to NULL for all clients.
-- alter table customer drop column FavGenre;
SELECT * FROM customer;
ALTER TABLE customer ADD COLUMN FavGenre INT DEFAULT NULL;

-- Task 32.
-- For each customer, set the FavGenre value to genre ID of the genre he bought
-- the most tracks of.
DROP VIEW IF EXISTS genreCount;
CREATE VIEW genreCount AS
SELECT invoice.CustomerId, track.GenreId, 
COUNT(track.GenreId) AS genreCount
FROM invoice 
INNER JOIN invoiceline ON invoice.InvoiceId = invoiceline.InvoiceId
INNER JOIN track ON track.TrackId = invoiceline.TrackId
GROUP BY invoice.CustomerId, track.GenreId
ORDER BY invoice.CustomerId, genreCount DESC;

SELECT * FROM genreCount;
SELECT * FROM customer;

UPDATE customer 
INNER JOIN 
(SELECT CustomerId, GenreId, MAX(genreCount)
FROM genreCount
GROUP BY CustomerId) AS temp 
ON customer.CustomerId = temp.CustomerId
SET customer.FavGenre = temp.GenreId;

-- Task 33.
--  Remove the Fax column from the customer table.
ALTER TABLE customer DROP COLUMN Fax;

-- Task 34.
-- Delete from the invoice table all the invoices issued before 2010.

ALTER TABLE `invoiceline` 
DROP FOREIGN KEY `FK_InvoiceLineInvoiceId`;

DELETE FROM invoice WHERE year(InvoiceDate) < 2010;

SELECT year(InvoiceDate) FROM invoice;

-- Task 35.

-- Remove from the database information about customers who are not related to
-- any transaction.

DELETE FROM customer WHERE CustomerId 
NOT IN (SELECT DISTINCT CustomerId FROM invoice);
SELECT * FROM customer;

-- Task 36. 
-- Add information about tracks from albums The Unforgiving and Gigaton to the
-- track table, update the information in the other tables so that the database is
-- consistent (i.e. add information about previously non-existent bands, albums,
-- etc., and enter the correct ID for the existing ones). Try to automate this process.


DROP FUNCTION IF EXISTS COMPUTE_BYTES;
CREATE FUNCTION COMPUTE_BYTES(miliseconds INT, mediaType TEXT)
RETURNS INT
BEGIN
    DECLARE bytes INT;
    IF mediaType LIKE "%AAC%" THEN
        SET bytes = 16 * miliseconds;
    ELSEIF mediaType LIKE "%MPEG" THEN
        SET bytes = 24 * miliseconds;
    ELSEIF (mediaType LIKE "%MPEG-4%") THEN
        SET bytes = 1250 * miliseconds;
    ELSE
        SET bytes = NULL;
    END IF;
    RETURN bytes;
END;


DROP FUNCTION IF EXISTS GET_MEDIA_ID;
CREATE FUNCTION GET_MEDIA_ID(mediaName VARCHAR(120)) RETURNS INT 
BEGIN
    DECLARE mediaId INT DEFAULT NULL;
    IF mediaName LIKE "%MPEG%" THEN 
        SET mediaId = 1;
    ELSEIF mediaName LIKE "%MPEG-4%" THEN 
        SET mediaId = 3;
    ELSEIF mediaName LIKE "%AAC" THEN 
        SET mediaId = 2;
    END IF;
    RETURN mediaId;
END;

DROP PROCEDURE IF EXISTS addSong;
CREATE PROCEDURE addSong(artistName VARCHAR(120), albumName VARCHAR(160), 
                         songName VARCHAR(200), genreName VARCHAR(120), 
                         songMiliseconds INT, media VARCHAR(120), 
                         price decimal(10, 2))
    BEGIN
        DECLARE songId INT;
        DECLARE composerId INT;
        DECLARE songAlbumId INT;
        DECLARE genre INT;
        DECLARE mediaId INT;
        SELECT MAX(trackId)+1 FROM track INTO songId;
        IF artistName IN (SELECT Name FROM artist) THEN 
            SELECT ArtistId FROM artist 
            WHERE artist.Name = artistName INTO composerId;
        ELSE
            SELECT MAX(ArtistId)+1 FROM artist INTO composerId;
            INSERT INTO artist(ArtistId, Name) VALUES (composerId, artistName);
        END IF;
        IF albumName IN (SELECT Title FROM album WHERE ArtistId=composerId) THEN 
            SELECT albumId FROM album WHERE (composerId=ArtistId) AND (albumName=album.Title) INTO songAlbumId;
        ELSE
            SELECT MAX(albumId)+1 from album INTO songAlbumId;
           INSERT INTO album(AlbumId, Title, ArtistId) VALUES (songAlbumId, 
           albumName, composerId);
        END IF;
        IF genreName IN (SELECT Name FROM genre) THEN
            SELECT GenreId FROM genre WHERE Name=genreName INTO genre;
        ELSE
            SELECT MAX(GenreId)+1 FROM genre INTO genre;
            INSERT INTO genre(GenreId, Name) VALUES (genre, genreName);
        END IF;
        SELECT GET_MEDIA_ID(media) INTO mediaId;
        INSERT INTO track(TrackId, Name, AlbumId, MediaTypeId, GenreId, 
                            Composer, Milliseconds, Bytes, UnitPrice)
            VALUES (songId, songName, songAlbumId, GET_MEDIA_ID(media), 
                    genre, artistName, songMiliseconds, COMPUTE_BYTES(songMiliseconds, media), 
                    price);


    END;


CALL addSong("Within Temptation", "The Unforgiving", 'Why Not Me', "Symphonic metal", 
                         34000, "MPEG",  0.99);
                        

SELECT * FROM track;
SELECT * FROM album;
SELECT * FROM artist;
START TRANSACTION;
SET @artistName := "Within Temptation";
SET @firstGenreName := "Symphonic metal";
SET @secondGenreName := "Rock";
SET @firstAlbum := "The Unforgiving";
SET @secondAlbum := "Gigaton";
SET @price := 0.99;
SET @mediaName := "MPEG";

-- CALL addSong(@artistName, @firstAlbum, 'Shot in the Dark', @genreName, 
--                          302000, @mediaName, @price);

-- CALL addSong(@artistName, @firstAlbum, 'Faster', @firstGenreName, 
--                          263000, @mediaName, @price);

-- CALL addSong(@artistName, @firstAlbum, 'Fire and Ice', @firstGenreName, 
--                          237000, @mediaName, @price);

                         
-- CALL addSong(@artistName, @firstAlbum, 'Where Is the Edge', @firstGenreName, 
--                          239000, @mediaName, @price);
           
-- CALL addSong(@artistName, @firstAlbum, 'Sinéad', @firstGenreName, 
--                          263000, @mediaName, @price);

-- CALL addSong(@artistName, @firstAlbum, 'Lest', @firstGenreName, 
--                          314000, @mediaName, @price);


-- CALL addSong(@artistName, @firstAlbum, 'Murder', @firstGenreName, 
--                          256000, @mediaName, @price);


-- CALL addSong(@artistName, @firstAlbum, "A Demon's Fate", @firstGenreName, 
--                          330000, @mediaName, @price);

-- CALL addSong(@artistName, @firstAlbum, "Stairway to the Skies", @firstGenreName, 
--                          332000, @mediaName, @price);

CALL addSong(@artistName, @secondAlbum, "Who Ever Said", @secondGenreName, 
                         311000, @mediaName, @price);


CALL addSong(@artistName, @secondAlbum, "Superblood Wolfmoon", @secondGenreName, 
                         229000, @mediaName, @price);


CALL addSong(@artistName, @secondAlbum, "Dance of the Clairvoyants", @secondGenreName, 
                         266000, @mediaName, @price);



CALL addSong(@artistName, @secondAlbum, "Quick Escape", @secondGenreName, 
                         287000, @mediaName, @price);



CALL addSong(@artistName, @secondAlbum, "Alright", @secondGenreName, 
                         224000, @mediaName, @price);

 
CALL addSong(@artistName, @secondAlbum, "Seven O'Clock", @secondGenreName, 
                         374000, @mediaName, @price);


CALL addSong(@artistName, @secondAlbum, "Never Destination", @secondGenreName, 
                         257000, @mediaName, @price);


CALL addSong(@artistName, @secondAlbum, "Take the Long Way", @secondGenreName, 
                         222000, @mediaName, @price);


CALL addSong(@artistName, @secondAlbum, "Buckle Up", @secondGenreName, 
                         217000, @mediaName, @price);



CALL addSong(@artistName, @secondAlbum, "Comes Then Goes", @secondGenreName, 
                         362000, @mediaName, @price);

CALL addSong(@artistName, @secondAlbum, "Retrograde", @secondGenreName, 
                         322000, @mediaName, @price);

                        
CALL addSong(@artistName, @secondAlbum, "River Cross", @secondGenreName, 
                         353000, @mediaName, @price);

COMMIT;
