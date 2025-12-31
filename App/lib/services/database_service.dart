import 'dart:io';
import 'package:path/path.dart' show dirname;

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../models/track.dart';

class DatabaseQueries {
    static const String countUserInteractions = '''
        SELECT 
                COUNT(*) AS total_interactions 
        FROM 
                tracks 
        WHERE 
                liked != 0;
    ''';

    static const String coldStartTracks = '''
        SELECT DISTINCT
                track_id, 
                track_name, 
                track_artist,
                Cluster_Style,
                track_popularity,
                liked,
                CP1, CP2, CP3, CP4, CP5, CP6, CP7, CP8
        FROM 
                tracks
        WHERE
                liked = 0 OR liked IS NULL
        ORDER BY
                track_popularity DESC 
        LIMIT 10;
    ''';

    static const String calculateProfileVector = '''
        SELECT
                CAST(SUM(CASE WHEN liked = 1 THEN CP1 ELSE -CP1 END) AS REAL) / COUNT(*) AS avg_cp1,
                CAST(SUM(CASE WHEN liked = 1 THEN CP2 ELSE -CP2 END) AS REAL) / COUNT(*) AS avg_cp2,
                CAST(SUM(CASE WHEN liked = 1 THEN CP3 ELSE -CP3 END) AS REAL) / COUNT(*) AS avg_cp3,
                CAST(SUM(CASE WHEN liked = 1 THEN CP4 ELSE -CP4 END) AS REAL) / COUNT(*) AS avg_cp4,
                CAST(SUM(CASE WHEN liked = 1 THEN CP5 ELSE -CP5 END) AS REAL) / COUNT(*) AS avg_cp5,
                CAST(SUM(CASE WHEN liked = 1 THEN CP6 ELSE -CP6 END) AS REAL) / COUNT(*) AS avg_cp6,
                CAST(SUM(CASE WHEN liked = 1 THEN CP7 ELSE -CP7 END) AS REAL) / COUNT(*) AS avg_cp7,
                CAST(SUM(CASE WHEN liked = 1 THEN CP8 ELSE -CP8 END) AS REAL) / COUNT(*) AS avg_cp8
        FROM 
                tracks
        WHERE 
                liked != 0;
    ''';

    static const String findSimilarTracks = '''
        SELECT DISTINCT
                track_id, track_name, track_artist, Cluster_Style, track_popularity,
                liked, CP1, CP2, CP3, CP4, CP5, CP6, CP7, CP8,
                (CP1 - ?) * (CP1 - ?) +
                (CP2 - ?) * (CP2 - ?) +
                (CP3 - ?) * (CP3 - ?) +
                (CP4 - ?) * (CP4 - ?) +
                (CP5 - ?) * (CP5 - ?) +
                (CP6 - ?) * (CP6 - ?) +
                (CP7 - ?) * (CP7 - ?) +
                (CP8 - ?) * (CP8 - ?) AS distance_sq
        FROM 
                tracks
        WHERE
                liked = 0 OR liked IS NULL
        ORDER BY 
                distance_sq ASC
        LIMIT 7;
    ''';

    static const String getLikedArtists = '''
        SELECT DISTINCT
                track_artist
        FROM 
                tracks
        WHERE 
                liked = 1;
    ''';

    static const String getLikedTracks = '''
        SELECT
                track_id, 
                track_name, 
                track_artist,
                Cluster_Style,
                track_popularity,
                liked,
                CP1, CP2, CP3, CP4, CP5, CP6, CP7, CP8
        FROM 
                tracks
        WHERE
                liked = 1 
        ORDER BY
                track_popularity DESC;
    ''';

    static const String findArtistTracks = '''
        SELECT
                track_id, 
                track_name, 
                track_artist,
                Cluster_Style,
                track_popularity,
                liked,
                CP1, CP2, CP3, CP4, CP5, CP6, CP7, CP8
        FROM 
                tracks
        WHERE
                liked = 0 
                AND track_artist IN (?) // Placeholder qui sera remplacé par ('Artiste A', 'Artiste B', ...)
        ORDER BY
                track_popularity DESC
        LIMIT 3;
    ''';

    static const String updateTrackInteraction = '''
        UPDATE 
                tracks
        SET 
                liked = ? 
        WHERE 
                track_id = ?;
    ''';
}

class DatabaseService {
    final Database _db;

    DatabaseService._(this._db);

    static Future<DatabaseService> init({String dbFileName = 'app_data.db'}) async {
        final databasesPath = await getDatabasesPath();
        final path = '$databasesPath/$dbFileName';

        try {
            final exists = await databaseExists(path);
            if (!exists) {
                print('*** DEBUG BDD: Fichier non existant. Copie de l\'asset...');
                try {
                    final data = await rootBundle.load('assets/$dbFileName');
                    final bytes = data.buffer.asUint8List();
                    await Directory(dirname(path)).create(recursive: true);
                    final file = File(path);
                    await file.writeAsBytes(bytes, flush: true);
                    print('*** DEBUG BDD: Copie de l\'asset terminée.');
                } catch (e) {
                    print('*** DEBUG BDD: ÉCHEC CRITIQUE de la copie de l\'asset: $e');
                }
            } else {
                print('*** DEBUG BDD: Fichier existant trouvé. Conservation de la BD et des données.');
            }
        } catch (e) {
            print('*** DEBUG BDD: Erreur lors de l\'initialisation: $e');
        }

        final db = await openDatabase(path);
        return DatabaseService._(db);
    }

    Future<int> countInteractions() async {
        final rows = await _db.rawQuery(DatabaseQueries.countUserInteractions);
        return Sqflite.firstIntValue(rows) ?? 0;
    }

    Future<List<Track>> getColdStartTracks() async {
        final rows = await _db.rawQuery(DatabaseQueries.coldStartTracks);
        return rows.map((r) => Track.fromMap(r)).toList();
    }

    Future<List<Track>> getHybridRecommendations() async {
        final profileRows = await _db.rawQuery(DatabaseQueries.calculateProfileVector);
        if (profileRows.isEmpty) return [];

        final profile = ProfileVector.fromMap(profileRows.first); 
        final avgList = profile.toSqlParams();

        final params = <dynamic>[];
        for (final v in avgList) {
            params.add(v);
            params.add(v);
        }

        final rows = await _db.rawQuery(DatabaseQueries.findSimilarTracks, params);
        return rows.map((r) => Track.fromMap(r)).toList();
    }

    Future<void> updateInteraction(String trackId, int status) async {
        await _db.rawUpdate(DatabaseQueries.updateTrackInteraction, [status, trackId]);
    }

    Future<void> close() async => await _db.close();
    
    Future<List<Track>> getLikedTracks() async {
        try {
            final List<Map<String, dynamic>> result = await _db.rawQuery(
                DatabaseQueries.getLikedTracks,
            );
            return result.map((map) => Track.fromMap(map)).toList();
        } catch (e) {
            print('ERREUR lors de la récupération de la playlist : $e');
            return [];
        }
    }
}