select ArtistId from artist
order by ArtistId desc
limit 1;

insert into `Artist` (`ArtistId`, `Name`) 
     select ArtistId + 1, 'Within Temptation' from artist
order by ArtistId desc
limit 1;



insert into `Genre` (`GenreId`, `Name`) 
select GenreId+1, 'Symphonic metal' from genre
order by GenreId desc
limit 1;


--teraz album


-- delete from artist where ArtistId=277;
insert into `Album` (`AlbumId`, `Title`, `ArtistId`)
select album.AlbumId+1, 'The Unforgiving', (select ArtistId from artist where
 artist.Name = 'Within Temptation'),  from album
 order by album.AlbumId desc
 limit 1;

-- delete from genre where GenreId=28;
insert into `Track`
 select track.TrackId + 1, 'Why Not Me', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 34000,
1104947, 0.99 from track
order by TrackId desc limit 1;


insert into `Track`
 select track.TrackId + 1, 'Shot in the Dark', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 302000,
9815000, 0.99 from track
order by TrackId desc limit 1;

-- select * from genre;

insert into `Track`
 select track.TrackId + 1, 'Faster', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 263000,
8547500, 0.99 from track
order by TrackId desc limit 1;

insert into `Track`
 select track.TrackId + 1,  'Fire and Ice', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 237000,
7702500, 0.99from track
order by TrackId desc limit 1;


insert into `Track`
 select track.TrackId + 1, 'Where Is the Edge', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
N'Within Temptation', 239000,
7767500, 0.99 from track
order by TrackId desc limit 1;

insert into `Track`
 select track.TrackId + 1, 'Sinéad', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 263000,
8547500, 0.99 from track
order by TrackId desc limit 1;


insert into `Track`
 select track.TrackId + 1, 'Lost', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 314000,
10205000, 0.99 from track
order by TrackId desc limit 1;

insert into `Track`
 select track.TrackId + 1, 'Murder', (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
 N'Within Temptation', 256000,
8320000, 0.99 from track
order by TrackId desc limit 1;

insert into `Track`
 select track.TrackId + 1, "A Demon's Fate", (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
N'Within Temptation', 330000,
10725000, 0.99 from track
order by TrackId desc limit 1;

insert into `Track`
 select track.TrackId + 1, "Stairway to the Skies", (select AlbumId from album where Title='The Unforgiving') ,
 (select MediaTypeId from MediaType where Name='MPEG audio file'), 
 (select GenreId from  genre where
 genre.Name = 'Symphonic metal'), 
N'Within Temptation', 332000,
10790000, 0.99 from track
order by TrackId desc limit 1;


select * from track;