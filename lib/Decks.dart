import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Carta {
  final String id;
  final String nombre;
  final String imagenUrl;
  final double precio;
  int cantidad;

  Carta({
    required this.id,
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

class DecksScreen extends StatefulWidget {
  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> decks = [];

  void _mostrarDialogoCrear(BuildContext context) {
    final TextEditingController _nombreDeckController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Importar deck"),
          content: TextField(
            controller: _nombreDeckController,
            decoration: const InputDecoration(
              labelText: "Nombre del deck",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                String nombre = _nombreDeckController.text.trim();
                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor, ingresa un nombre.")),
                  );
                  return;
                }

                Deck nuevoDeck = Deck(
                  nombre: nombre,
                  subtitulo: "Pokémon TCG",
                  imagenUrl: "https://images.pokemontcg.io/base1/58_hires.png",
                  cartas: [],
                );

                setState(() {
                  decks.add(nuevoDeck);
                });

                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<Carta?> _buscarCarta(String nombre) async {
    final url = Uri.parse('https://api.pokemontcg.io/v2/cards?q=name:"${Uri.encodeComponent(nombre)}"');
    final response = await http.get(url);

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

        return Carta(
          id: carta['id'],
          nombre: nombre,
          imagenUrl: imagen,
          precio: precio,
        );
      }
    }

    return null;
  }

  void _mostrarDialogoImportar(BuildContext context) {
    TextEditingController nombreController = TextEditingController();
    TextEditingController cartasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Importar deck'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    hintText: "Nombre del deck",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: cartasController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Pega tu deck aquí (ej: 4 Pikachu)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    if (mapaCartas.containsKey(carta.id)) {
                      mapaCartas[carta.id]!.cantidad += cantidad;
                    } else {
                      carta.cantidad = cantidad;
                      mapaCartas[carta.id] = carta;
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
                  colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
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
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(deck.subtitulo, style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.catching_pokemon, color: Colors.redAccent, size: 28),
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
}

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  DeckDetailScreen({required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> resultados = [];
  bool cargando = false;

  Future<void> buscarCarta(String nombre) async {
    setState(() {
      cargando = true;
      resultados = [];
    });

    final url = Uri.parse("https://api.pokemontcg.io/v2/cards?q=name:$nombre");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        resultados = data['data'];
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  void agregarCarta(Map<String, dynamic> data) {
    final id = data['id'];
    final nombre = data['name'];
    final imagen = data['images']['large'];
    final precios = data['tcgplayer']?['prices'] ?? {};
    final tipos = ['normal', 'holofoil', 'reverseHolofoil', '1stEditionHolofoil'];

    double precio = 0.0;
    for (var tipo in tipos) {
      if (precios[tipo]?['market'] != null) {
        precio = precios[tipo]['market'].toDouble();
        break;
      }
    }

    final indexExistente = widget.deck.cartas.indexWhere((c) => c.id == id);

    setState(() {
      if (indexExistente != -1) {
        widget.deck.cartas[indexExistente].cantidad++;
      } else {
        widget.deck.cartas.add(
          Carta(
            id: id,
            nombre: nombre,
            imagenUrl: imagen,
            precio: precio,
            cantidad: 1,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre agregada al deck.')),
    );
  }

  int obtenerTotalCartas() {
    return widget.deck.cartas.fold(0, (suma, carta) => suma + carta.cantidad);
  }

  double obtenerPrecioTotal() {
    return widget.deck.cartas.fold(
      0.0,
          (suma, carta) => suma + (carta.precio * carta.cantidad),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deck.nombre),
            Text(widget.deck.subtitulo, style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar carta',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => buscarCarta(_controller.text),
                ),
                border: OutlineInputBorder(),
              ),
              onSubmitted: buscarCarta,
            ),
          ),
          if (cargando) CircularProgressIndicator(),
          if (resultados.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final carta = resultados[index];
                  return ListTile(
                    leading: Image.network(carta['images']['small']),
                    title: Text(carta['name']),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => agregarCarta(carta),
                    ),
                  );
                },
              ),
            ),
          if (!cargando && resultados.isEmpty && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("No se encontraron cartas."),
            ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cartas en el deck:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${obtenerTotalCartas()}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Precio total:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\$${obtenerPrecioTotal().toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                                  child: Image.network(carta.imagenUrl),
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
                    child: Image.network(carta.imagenUrl, width: 50),
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
                            carta.cantidad--;
                            if (carta.cantidad <= 0) {
                              widget.deck.cartas.removeAt(index);
                            }
                          });
                        },
                      ),
                      Text('${carta.cantidad}', style: TextStyle(fontSize: 16)),
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
          ),
        ],
      ),
    );
  }
}
