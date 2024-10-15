import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Para manejar archivos
import 'package:image_picker/image_picker.dart'; // Paquete para seleccionar imágenes
import 'gradient_background.dart';
import 'main.dart';
import 'dart:async'; // Para usar Timer
import 'dart:math'; // Para generar colores aleatorios

class ChatPage extends StatefulWidget {
  final String userEmail;

  ChatPage({required this.userEmail});

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
  final ScrollController _scrollController = ScrollController(); // ScrollController para la lista de mensajes
  File? _profileImage; // Variable para almacenar la imagen de perfil seleccionada
  final ImagePicker _picker = ImagePicker(); // Instancia para seleccionar imágenes
  Color _iconColor = Colors.black; // Color inicial del icono
  final Random _random = Random(); // Instancia para generar colores aleatorios

  @override
  void initState() {
    super.initState();
    _filteredMessages = _messages; // Inicialmente, no hay filtro
    _startColorChange(); // Iniciar el cambio de colores al iniciar la página
  }

  // Función para iniciar el cambio de colores con animación suave
  void _startColorChange() {
    setState(() {
      // Cambiar el color cada vez que se llama esta función
      _iconColor = Color.fromRGBO(
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
        1,
      );
    });

    // Repetimos el proceso cada 3 segundos con suavidad
    Future.delayed(Duration(seconds: 1), _startColorChange);
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
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              ListTile(
                leading: Icon(Icons.brightness_6, color: Colors.white, size: 21),
                title: Text(
                  'Modo Oscuro',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    _toggleDarkMode();
                  },
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
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: isSearching
                            ? TextField(
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
                          ),
                        )
                            : Text(
                          "Tati-AI",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isSearching ? Icons.close : Icons.search, color: isDarkMode ? Colors.white : Colors.black),
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
                                : (isDarkMode ? Colors.grey[900] : Colors.grey[400]),
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
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.cyan),
                        onPressed: _pickAndUploadImage, // Seleccionar y subir imagen
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      FloatingActionButton(
                        onPressed: _sendMessage,
                        child: Icon(Icons.send),
                        backgroundColor: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Ícono blur_on centrado y cambiando de color aleatoriamente
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.blur_on,
                  size: 35,
                  color: _iconColor, // Color aleatorio que cambia cada segundo
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
