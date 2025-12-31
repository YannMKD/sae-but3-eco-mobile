class ImageAssetUtil {

  static String getTrackBackgroundAsset(String clusterName) {
    switch (clusterName) {
      case "Musique Calme & Instrumentale":
        return 'assets/images/backgrounds/calm_instrumental.png'; 
      case "Hip-Hop / Électro Rythmé":
        return 'assets/images/backgrounds/hiphop_electro.png';
      case "Danse / Électronique Mélancolique":
        return 'assets/images/backgrounds/dance_melancholic.png';
      case "Rock / Pop Standard":
        return 'assets/images/backgrounds/rock_pop.png';
      case "Musique Triste / Indépendante":
        return 'assets/images/backgrounds/sad_indie.png';
      case "Pop Radio / Joyeuse & Dansante":
        return 'assets/images/backgrounds/pop_joyful.png';
      default:
        return 'assets/images/backgrounds/default_music.png'; 
    }
  }

  static String getGenreIconAsset(String clusterName) {
    switch (clusterName) {
      case "Musique Calme & Instrumentale":
        return 'assets/icons/genre_calm.png';
      case "Hip-Hop / Électro Rythmé":
        return 'assets/icons/genre_hiphop.png';
      case "Danse / Électronique Mélancolique":
        return 'assets/icons/genre_dance.png';
      case "Rock / Pop Standard":
        return 'assets/icons/genre_rock.png';
      case "Musique Triste / Indépendante":
        return 'assets/icons/genre_sad.png';
      case "Pop Radio / Joyeuse & Dansante":
        return 'assets/icons/genre_pop.png';
      default:
        return 'assets/icons/genre_default.png';
    }
  }
}