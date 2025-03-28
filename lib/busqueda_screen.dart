import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusquedaScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardarCarta;

  BusquedaScreen({required this.onGuardarCarta});

  @override
  _BusquedaScreenState createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  List<dynamic> cartas = [];
  bool cargando = false;
  final TextEditingController _controller = TextEditingController();

  Future<void> buscarCartas(String nombre) async {
    setState(() {
      cargando = true;
      cartas = [];
    });

    final url = Uri.parse("https://api.pokemontcg.io/v2/cards?q=name:$nombre");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        cartas = data['data'];
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
        cartas = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buscar cartas"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _controller,
              onSubmitted: buscarCartas,
              decoration: InputDecoration(
                labelText: 'Nombre de la carta',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => buscarCartas(_controller.text),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (cargando)
            Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          if (!cargando && cartas.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: cartas.length,
                itemBuilder: (context, index) {
                  final carta = cartas[index];
                  final nombre = carta['name'];
                  final imagen = carta['images']['small'];
                  final imagenGrande = carta['images']['large'];
                  final preciosAPI = carta['tcgplayer']?['prices'] ?? {};
                  final tipos = ['normal', 'holofoil', 'reverseHolofoil', '1stEditionHolofoil'];

                  Map<String, dynamic> preciosPorTipo = {};
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

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ZoomImageScreen(imageUrl: imagenGrande),
                                ),
                              );
                            },
                            child: Hero(
                              tag: imagenGrande,
                              child: Image.network(imagen),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              final cartaAGuardar = {
                                'nombre': nombre,
                                'imagen': imagenGrande,
                                'precios': preciosPorTipo,
                              };

                              widget.onGuardarCarta(cartaAGuardar);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Carta agregada al historial")),
                              );
                            },
                            child: Text("Agregar al historial"),
                          ),
                          SizedBox(height: 10),
                          if (preciosPorTipo.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: preciosPorTipo.entries.map((entry) {
                                final tipo = entry.key;
                                final datos = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(" Tipo: $tipo", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text("• Market: \$${datos['market']}"),
                                      Text("• Low: \$${datos['low']}"),
                                      Text("• High: \$${datos['high']}"),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text("Sin datos de precio"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (!cargando && cartas.isEmpty && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("No se encontraron cartas."),
            ),
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
