import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Carta {
  final String nombre;
  final String imagenUrl;
  final double precio;
  int cantidad;

  Carta({
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
    this.cantidad = 1,
  });
}

class Deck {
  final String nombre;
  final String subtitulo;
  final String imagenUrl;
  final List<Carta> cartas;

  Deck({
    required this.nombre,
    required this.subtitulo,
    required this.imagenUrl,
    required this.cartas,
  });
}

void _mostrarDialogoCrear(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Crear nuevo deck"),
        content: Text("Aquí puedes implementar la creación manual del deck."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cerrar"),
          ),
        ],
      );
    },
  );
}


class DecksScreen extends StatefulWidget {
  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> decks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tus Decks", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
    actions: [
    PopupMenuButton<String>(
    icon: Icon(Icons.add, color: Colors.black),
    onSelected: (value) {
    if (value == 'importar') {
    _mostrarDialogoImportar(context);
    } else if (value == 'crear') {
    _mostrarDialogoCrear(context);
    }
    },
    itemBuilder: (BuildContext context) => [
    PopupMenuItem(value: 'importar', child: Text('Importar Deck')),
    PopupMenuItem(value: 'crear', child: Text('Crear Deck')),
    ],
    ),
    ],
      ),
    body: decks.isEmpty
          ? Center(child: Text("No hay decks aún"))
          : ListView.builder(
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeckDetailScreen(deck: deck),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(deck.imagenUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black45, BlendMode.darken),
                ),
              ),
              height: 180,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.nombre,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(deck.subtitulo,
                        style:
                        TextStyle(color: Colors.white70, fontSize: 16)),
                    Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.catching_pokemon,
                          color: Colors.redAccent, size: 28),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoImportar(BuildContext context) {
    TextEditingController nombreController = TextEditingController();
    TextEditingController cartasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Importar deck'),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    hintText: "Nombre del deck",
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: cartasController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Pega tu deck aquí (ej: 4 Pikachu)",
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombreDeck = nombreController.text.trim();
                final textoCartas = cartasController.text.trim();
                final lineas = textoCartas.split('\n');

                if (nombreDeck.isEmpty || textoCartas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                Map<String, Carta> mapaCartas = {};

                for (var linea in lineas) {
                  final partes = linea.trim().split(' ');
                  if (partes.length < 2) continue;
                  final cantidad = int.tryParse(partes[0]) ?? 1;
                  final nombreCarta = partes.sublist(1).join(' ');

                  final carta = await _buscarCarta(nombreCarta);
                  if (carta != null) {
                    if (mapaCartas.containsKey(carta.nombre)) {
                      mapaCartas[carta.nombre]!.cantidad += cantidad;
                    } else {
                      carta.cantidad = cantidad;
                      mapaCartas[carta.nombre] = carta;
                    }
                  }
                }

                final cartas = mapaCartas.values.toList();

                if (cartas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se encontraron cartas válidas')),
                  );
                  return;
                }

                Deck nuevoDeck = Deck(
                  nombre: nombreDeck,
                  subtitulo: "Pokémon TCG",
                  imagenUrl: cartas.first.imagenUrl,
                  cartas: cartas,
                );

                setState(() {
                  decks.add(nuevoDeck);
                });

                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }


  Future<Carta?> _buscarCarta(String nombre) async {
    final url = Uri.parse(
        'https://api.pokemontcg.io/v2/cards?q=name:"${Uri.encodeComponent(nombre)}"');

    final response = await http.get(url, headers: {
      'X-Api-Key': '',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'].isNotEmpty) {
        final carta = data['data'][0];
        final imagen = carta['images']['small'] ?? '';
        final precio = double.tryParse(
          carta['tcgplayer']?['prices']?['market']?['usd']?.toString() ??
              carta['tcgplayer']?['prices']?['normal']?['market']?.toString() ??
              '0.0',
        ) ??
            0.0;

        return Carta(nombre: nombre, imagenUrl: imagen, precio: precio);
      }
    }

    return null;
  }
}

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  DeckDetailScreen({required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deck.nombre),
            Text(
              widget.deck.subtitulo,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),

      body: ListView.builder(
        itemCount: widget.deck.cartas.length,
        itemBuilder: (context, index) {
          final carta = widget.deck.cartas[index];
          return ListTile(
            leading: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: EdgeInsets.zero,
                    backgroundColor: Colors.black,
                    child: Stack(
                      children: [
                        Center(
                          child: InteractiveViewer(
                            child: Image.network(
                              carta.imagenUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 30,
                          right: 20,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Image.network(carta.imagenUrl, width: 50, height: 50),
            ),

            title: Text(carta.nombre),
            subtitle: Text('\$${carta.precio.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (carta.cantidad > 1) carta.cantidad--;
                    });
                  },
                ),
                Text('${carta.cantidad}'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      carta.cantidad++;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}