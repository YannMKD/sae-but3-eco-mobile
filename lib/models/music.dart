import 'package:flutter/material.dart';

class Musique {
  final String titre;
  final String artiste;
  final Color couleur; 

  const Musique(this.titre, this.artiste, this.couleur);
}

final List<Musique> listeMusiquesRap = [
  const Musique('NWR', 'Maes', Colors.deepOrangeAccent),
  const Musique('Tallac', 'Booba', Colors.blue),
  const Musique('Voilà', 'Da Uzi',  Color.fromRGBO(121, 85, 72, 1)),
  const Musique('Rude Boy', 'Werenoi', Colors.green),
  const Musique('Bitume', 'Leto', Colors.redAccent),
];