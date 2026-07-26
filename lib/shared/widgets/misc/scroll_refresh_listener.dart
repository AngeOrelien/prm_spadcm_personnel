import 'package:flutter/material.dart';

/// Enveloppe un contenu scrollable (typiquement une [ListView]) et appelle
/// [onAtteintLeBas] quand l'utilisateur scrolle près du bas du contenu —
/// pratique pour rafraîchir automatiquement une liste (équipe, patients,
/// rapports...) sans attendre un "tirer pour rafraîchir" explicite.
///
/// Un [cooldown] évite de déclencher le rafraîchissement en boucle tant que
/// l'utilisateur reste en bas de la liste (chaque petit micro-scroll
/// déclencherait sinon un nouvel appel réseau).
class ScrollRefreshListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onAtteintLeBas;
  final double seuil;
  final Duration cooldown;

  const ScrollRefreshListener({
    super.key,
    required this.child,
    required this.onAtteintLeBas,
    this.seuil = 120,
    this.cooldown = const Duration(seconds: 8),
  });

  @override
  State<ScrollRefreshListener> createState() => _ScrollRefreshListenerState();
}

class _ScrollRefreshListenerState extends State<ScrollRefreshListener> {
  DateTime? _dernierDeclenchement;

  bool _onNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    final procheDuBas = metrics.maxScrollExtent - metrics.pixels <= widget.seuil;
    if (!procheDuBas) return false;

    final maintenant = DateTime.now();
    if (_dernierDeclenchement != null && maintenant.difference(_dernierDeclenchement!) < widget.cooldown) {
      return false;
    }
    _dernierDeclenchement = maintenant;
    widget.onAtteintLeBas();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
