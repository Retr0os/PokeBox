import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'busqueda_screen.dart';
import 'Decks.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeBox',
      home: MainApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cartasGuardadas = [];
  Map<String, dynamic>? cartaPendiente;

  Future<Map<String, dynamic>?> fetchCarta() async {
    final random = Random();
    final page = random.nextInt(1000) + 1;
    final url = Uri.parse('https://api.pokemontcg.io/v2/cards?page=$page&pageSize=1');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final carta = data['data'][0];

      Map<String, dynamic> preciosPorTipo = {};
      if (carta['tcgplayer'] != null && carta['tcgplayer']['prices'] != null) {
        final preciosAPI = carta['tcgplayer']['prices'];
        final tipos = ['normal', 'holofoil', 'reverseHolofoil', '1stEditionHolofoil'];

        for (var tipo in tipos) {
          if (preciosAPI[tipo] != null) {
            final p = preciosAPI[tipo];
            preciosPorTipo[tipo] = {
              'market': p['market'] ?? 'N/D',
              'low': p['low'] ?? 'N/D',
              'high': p['high'] ?? 'N/D',
            };
          }
        }
      }

      return {
        'nombre': carta['name'],
        'imagen': carta['images']['large'],
        'precios': preciosPorTipo,
      };
    }

    return null;
  }

  void guardarCartaPendiente() {
    if (cartaPendiente != null) {
      setState(() {
        cartasGuardadas.insert(0, cartaPendiente!);
        if (cartasGuardadas.length > 10) {
          cartasGuardadas.removeLast();
        }
        cartaPendiente = null;
      });
    }
  }

  void cambiarPestana(int index) {
    guardarCartaPendiente();
    setState(() {
      _selectedIndex = index;
    });
  }

  void generarNuevaCarta() async {
    guardarCartaPendiente();
    final nueva = await fetchCarta();
    if (nueva != null) {
      setState(() {
        cartaPendiente = nueva;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;

    if (_selectedIndex == 0) {
      contenido = SingleChildScrollView(
        child: Column(
          children: [
            AppBar(title: Text("¡PokeBox!"), centerTitle: true),
            if (cartaPendiente != null)
              Column(
                children: [
                  SizedBox(height: 10),
                  Text(
                    cartaPendiente!['nombre'],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ZoomImageScreen(imageUrl: cartaPendiente!['imagen']),
                        ),
                      );
                    },
                    child: Hero(
                      tag: cartaPendiente!['imagen'],
                      child: Image.network(cartaPendiente!['imagen'], height: 200),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(" Precios por tipo:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (cartaPendiente!['precios'] as Map<String, dynamic>)
                          .entries
                          .map((entry) {
                        final tipo = entry.key;
                        final precios = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(" Tipo: $tipo"),
                            Text("• Market: \$${precios['market']}"),
                            Text("• Low: \$${precios['low']}"),
                            Text("• High: \$${precios['high']}"),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ElevatedButton(
              onPressed: generarNuevaCarta,
              child: Text("Carta aleatoria"),
            ),
            Divider(height: 30),
            Text("Historial", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            cartasGuardadas.isEmpty
                ? Text("Aún no has guardado cartas")
                : SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cartasGuardadas.length,
                itemBuilder: (context, index) {
                  final carta = cartasGuardadas[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ZoomImageScreen(imageUrl: carta['imagen']),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.all(10),
                      width: 160,
                      child: Hero(
                        tag: carta['imagen'],
                        child: Image.network(carta['imagen']),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      contenido = BusquedaScreen(
        onGuardarCarta: (carta) {
          setState(() {
            cartasGuardadas.insert(0, carta);
            if (cartasGuardadas.length > 10) {
              cartasGuardadas.removeLast();
            }
          });
        },
      );
    } else {
      contenido = DecksScreen(); // 👉 Aquí se muestra la nueva pestaña
    }

    return Scaffold(
      body: contenido,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: cambiarPestana,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Decks'),
        ],
      ),
    );
  }
}

// Pantalla para hacer zoom a la imagen
class ZoomImageScreen extends StatelessWidget {
  final String imageUrl;

  ZoomImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              child: Image.network(imageUrl),
              maxScale: 5,
              minScale: 0.5,
              panEnabled: true,
            ),
          ),
        ),
      ),
    );
  }
}


