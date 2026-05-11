WITH	albums AS (
	SELECT DISTINCT album_name,
					release_date
    FROM sql_commands.all_albums
    ),
		song_count AS (
	SELECT	album_name,
			COUNT(title) AS 'tracks',
            (SUM(time_to_sec(duration))) / 60 AS 'album_duration',
            AVG(play_count) AS 'avg_playcount_in_M',
			(SUM(play_count)) AS sum_album_play_count,
            (COUNT(featuring) / COUNT(title))*100 AS feature_share
    FROM sql_commands.all_albums
    GROUP BY album_name
    ),
		song_rank AS (
	SELECT 	song_rank,
			title,
			album_name
	FROM	(SELECT	title,
					play_count,
					album_name,
					RANK() OVER(PARTITION BY album_name ORDER BY play_count DESC) AS song_rank
			FROM sql_commands.all_albums) aa
			WHERE	song_rank = 1
			),
		percentage AS (
			SELECT	(aa.play_count/sc.sum_album_play_count)*100 AS song_percentage, aa.title, sc.album_name
            FROM 	song_count sc JOIN sql_commands.all_albums aa ON sc.album_name = aa.album_name
            )
SELECT	a.album_name,
		a.release_date,
        sc.tracks,
        sc.album_duration,
        avg_playcount_in_M,
        sr.title AS 'Lead Single',
        ROUND(song_percentage, 2) AS 'Lead Single Share',
        sc.sum_album_play_count,
        ROUND(feature_share, 2) AS 'Feature Share [%]',
        (sc.sum_album_play_count/sc.album_duration) AS 'Song Density'
FROM albums a
JOIN song_count sc ON a.album_name = sc.album_name
JOIN song_rank sr ON sr.album_name = a.album_name
JOIN percentage p ON p.title = sr.title AND p.album_name = sr.album_name
ORDER BY release_date