import 'dart:async'; // Para usar Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Para manejar archivos
import 'package:image_picker/image_picker.dart'; // Paquete para seleccionar imágenes
import 'gradient_background.dart';
import 'main.dart';
import 'sphere3dview.dart'; // Asegúrate de importar tu esfera

class ChatPage extends StatefulWidget {
  final String userEmail;
  final int numCuentas; // Aceptar el número de cuentas activas

  ChatPage({required this.userEmail, required this.numCuentas}); // Asegurarse de que se pase el número de cuentas

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Controlador para la barra de búsqueda
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = []; // Lista para los mensajes filtrados
  bool isDarkMode = false; // Modo oscuro
  bool isTyping = false; // Indicador de "Escribiendo..."
  bool isSearching = false; // Indicador de búsqueda activa
  bool isConnected = true; // Variable para representar el estado de la conexión
  final ScrollController _scrollController = ScrollController(); // ScrollController para la lista de mensajes
  File? _profileImage; // Variable para almacenar la imagen de perfil seleccionada
  final ImagePicker _picker = ImagePicker(); // Instancia para seleccionar imágenes
  late Timer _connectionTimer; // Timer para verificar la conexión

  @override
  void initState() {
    super.initState();
    _filteredMessages = _messages; // Inicialmente, no hay filtro
    _startConnectionCheck(); // Iniciar la verificación de la conexión
  }

  @override
  void dispose() {
    _connectionTimer.cancel(); // Cancelar el timer cuando se cierre la página
    super.dispose();
  }

  // Función para iniciar el chequeo de conexión cada 3 segundos
  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _checkConnection();
    });
  }

  // Función para verificar la conexión con el servidor
  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('https://edb3-66-81-164-114.ngrok-free.app/ping')); // Cambia la ruta al endpoint adecuado
      if (response.statusCode == 200) {
        setState(() {
          isConnected = true; // Conexión exitosa
        });
      } else {
        setState(() {
          isConnected = false; // Respuesta del servidor no es exitosa
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false; // Error de conexión
      });
    }
  }

  // Función para enviar un mensaje
  void _sendMessage() async {
    String message = _messageController.text;
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({'text': message, 'isUserMessage': true, 'isImage': false});
        _filteredMessages = _messages; // Actualizar lista filtrada
        _messageController.clear();
        _scrollToBottom();
      });

      // Mostrar indicador de "Escribiendo..."
      setState(() {
        isTyping = true; // Mostrar que el chatbot está escribiendo
      });

      // Llamada a la API si es una pregunta
      final response = await _sendQuestionToApi(message);

      // Ocultar indicador de "Escribiendo..." cuando se recibe la respuesta
      if (response != null) {
        setState(() {
          _messages.add({'text': response, 'isUserMessage': false, 'isImage': false});
          _filteredMessages = _messages;
          isTyping = false; // El chatbot ha terminado de "escribir"
          _scrollToBottom(); // Desplazamos el scroll hacia abajo
        });
      }
    }
  }

  // Función para enviar la pregunta a la API y recibir una respuesta
  Future<String?> _sendQuestionToApi(String question) async {
    final String apiUrl = "https://edb3-66-81-164-114.ngrok-free.app/preguntar"; // Cambia la URL a la correcta
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pregunta": question}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['respuesta']; // Devuelve la respuesta de la API
      } else {
        return 'Error: No se pudo obtener la respuesta de la API.';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Función para hacer scroll hacia el último mensaje
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Función para seleccionar y subir una imagen
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Seleccionar imagen desde la galería
    if (image != null) {
      // Si se selecciona una imagen
      setState(() {
        _messages.add({
          'text': 'Subiendo imagen...',
          'isUserMessage': true,
          'isImage': true,
          'imagePath': image.path,
          'uploading': true
        });
        _filteredMessages = _messages;
      });

      final String uploadUrl = "https://edb3-66-81-164-114.ngrok-free.app/subir_imagen"; // Cambia la URL a la correcta
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await http.Response.fromStream(response);
          final Map<String, dynamic> jsonResponse = jsonDecode(responseData.body);

          setState(() {
            // Actualizamos el último mensaje con la miniatura de la imagen y los checkmarks
            _messages.removeLast();
            _messages.add({
              'text': jsonResponse['filename'],
              'isUserMessage': true,
              'isImage': true,
              'imagePath': image.path,
              'uploading': false
            });
            _filteredMessages = _messages;
            _scrollToBottom(); // Desplazar el scroll hacia abajo
          });
        } else {
          setState(() {
            _messages.add({'text': 'Error al subir imagen', 'isUserMessage': true, 'isImage': false});
            _filteredMessages = _messages;
            _scrollToBottom(); // Desplazar el scroll hacia abajo
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({'text': 'Error: No se pudo subir la imagen', 'isUserMessage': true, 'isImage': false});
          _filteredMessages = _messages;
          _scrollToBottom(); // Desplazar el scroll hacia abajo
        });
      }
    }
  }

  // Función para buscar mensajes
  void _searchMessages(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMessages = _messages; // Si la búsqueda está vacía, mostrar todos los mensajes
      });
    } else {
      setState(() {
        _filteredMessages = _messages
            .where((message) =>
            message['text'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filtramos los mensajes que contienen el texto
      });
    }
  }

  // Función para cambiar el modo oscuro
  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  // Función para seleccionar una imagen desde la galería
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path); // Almacenar la imagen seleccionada
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.55,
        child: Drawer(
          backgroundColor: Colors.black.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Configuraciones',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              ListTile(
                leading: Icon(Icons.brightness_6, color: Colors.white, size: 21),
                title: Text(
                  'Modo Oscuro',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                trailing: Transform.scale(
                  scale: 0.8,  // Ajusta el valor para reducir el tamaño, por ejemplo, 0.8 es el 80% del tamaño original
                  child: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      _toggleDarkMode();
                    },
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  children: [
                    Divider(color: Colors.white),
                    // Foto de perfil o botón para editar
                    ListTile(
                      leading: GestureDetector(
                        onTap: _pickProfileImage, // Llamamos a la función para seleccionar una imagen
                        child: _profileImage != null
                            ? CircleAvatar(
                          backgroundImage: FileImage(_profileImage!), // Mostrar la imagen seleccionada
                          radius: 20, // Ajusta el tamaño del círculo
                        )
                            : CircleAvatar(
                          child: Icon(Icons.person, color: Colors.white),
                          backgroundColor: Colors.grey,
                          radius: 20, // Ajusta el tamaño del círculo
                        ),
                      ),
                      title: Text(
                        widget.userEmail,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white), // Icono para editar la foto de perfil
                        onPressed: _pickProfileImage, // Permite editar la imagen cuando se toca el ícono de editar
                      ),
                    ),
                    // Opción para no poner una foto de perfil
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _profileImage = null; // Eliminar la foto de perfil
                        });
                      },
                      child: Text(
                        'Eliminar foto de perfil',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    Divider(color: Colors.white),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.white),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                              (Route<dynamic> route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Has cerrado sesión')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        child: Stack(
          children: [
            Column(
              children: [
                // Barra superior con el icono de engranaje y lupa
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 45.0),
                  child: Row(
                    children: [
                      // Ícono de ajustes a la izquierda
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black, size: 30),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),

                      // Mostrar un campo de búsqueda cuando esté activado el modo de búsqueda
                      Expanded(
                        child: isSearching
                            ? Stack(
                          alignment: Alignment.centerRight,  // Alineamos el input con el ícono de "X" a la derecha
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                _searchMessages(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Buscar...',
                                hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                              ),
                            ),
                          ],
                        )
                            : Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: Text(
                            "Tati-AI",
                            style: TextStyle(
                              fontSize: 18, // Ajusta el tamaño del texto aquí
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Ícono que alterna entre la lupa y la "X"
                      IconButton(
                        icon: Icon(
                          isSearching ? Icons.close : Icons.search,  // Alterna entre "X" y lupa
                          color: isDarkMode ? Colors.white : Colors.black,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isSearching) {
                              _searchController.clear();
                              _searchMessages(''); // Restablece la lista de mensajes
                            }
                            isSearching = !isSearching;
                          });
                        },
                      ),
                    ],
                  ),
                ),


                // Lista de mensajes
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredMessages.length + (isTyping ? 1 : 0), // Añadimos un elemento si está "escribiendo"
                    itemBuilder: (context, index) {
                      if (isTyping && index == _filteredMessages.length) {
                        // Mostrar el indicador de "Escribiendo..." como el último elemento
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Escribiendo...",
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );
                      }

                      final message = _filteredMessages[index];
                      bool isUserMessage = message['isUserMessage'];
                      bool isImage = message['isImage'];
                      bool uploading = message['uploading'] ?? false;

                      return Align(
                        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? (isDarkMode ? Colors.cyan[800] : Colors.cyan[300])
                                : (isDarkMode ? Colors.grey[900] : Colors.grey[350]),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: isUserMessage ? Radius.circular(12) : Radius.circular(0),
                              bottomRight: isUserMessage ? Radius.circular(0) : Radius.circular(12),
                            ),
                          ),
                          child: isImage
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.file(File(message['imagePath']), width: 150, height: 150, fit: BoxFit.cover),
                              SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: uploading ? Colors.grey : Colors.white,
                                  ),
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: uploading ? Colors.grey : Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          )
                              : Text(
                            message['text'],
                            style: TextStyle(
                              color: isUserMessage ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Campo de texto, ícono de clip y botón de envío
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Ícono de WiFi que cambia según la conexión
                      IconButton(
                        icon: Icon(
                          isConnected
                              ? Icons.wifi // Verde si hay conexión
                              : Icons.wifi_off, // Rojo si no hay conexión
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                        onPressed: () {
                          // Verificación manual opcional
                          _checkConnection();
                        },
                      ),
                      // Campo de texto de entrada de mensajes con ícono de adjuntar dentro
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40), // Bordes redondeados
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            // Añadimos un ícono de adjuntar dentro del TextField
                            suffixIcon: IconButton(
                              icon: Icon(Icons.attach_file, color: Color(0xFF46F4B3)),
                              onPressed: _pickAndUploadImage, // Funcionalidad para subir imagen
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0), // Ajuste de padding
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Botón de enviar mensaje redondeado
                      SizedBox(
                        width: 50,  // Ajusta el ancho
                        height: 50, // Ajusta la altura
                        child: FloatingActionButton(
                          onPressed: _sendMessage,
                          child: Icon(Icons.send, size: 20), // Ajusta el tamaño del icono
                          backgroundColor: Color(0xFF46F4B3),  // Cambia el color de fondo del botón
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Bordes redondeados
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
            // Añadir la esfera 3D en lugar del icono blur_on
            if (!isSearching) // Ocultar la esfera cuando se está buscando
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 40, // Ajustar el tamaño de la esfera
                    width: 40,
                    child: Sphere3DView(
                      activePointsCount: widget.numCuentas, // Pasar el número de cuentas al componente de la esfera
                      pointCount: 150, // Reducimos el número de puntos para la esfera pequeña
                      pointSize: 1, // Reducimos el tamaño de los puntos
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
