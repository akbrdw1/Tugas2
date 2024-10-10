import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> _todoList =
      []; // Ubah menjadi list yang menyimpan to-do dan date/time
  final TextEditingController _textController = TextEditingController();
  late String _currentTime;
  late String _currentDate;
  DateTime? _selectedDate; // Menyimpan tanggal yang dipilih
  TimeOfDay? _selectedTime; // Menyimpan waktu yang dipilih
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTodoList();
    _updateTime();
    _startClock();
  }

  Future<void> _loadTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(
      () {
        _todoList = (prefs.getStringList("todos") ?? [])
            .map((todoString) => {
                  "task": todoString.split('|')[0],
                  "date": todoString.split('|')[1],
                  "time": todoString.split('|')[2]
                })
            .toList();
      },
    );
  }

  Future<void> _saveTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        "todos",
        _todoList
            .map((todo) => "${todo['task']}|${todo['date']}|${todo['time']}")
            .toList());
  }

  void _removeTodoItem(int index) {
    setState(
      () {
        _todoList.removeAt(index);
        _saveTodoList();
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(
        () {
          _selectedDate = pickedDate;
        },
      );
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(
        () {
          _selectedTime = pickedTime;
        },
      );
    }
  }

  void _showAddToDoDialog() {
    _selectedDate = null;
    _selectedTime = null;
    _textController.clear(); // Mengosongkan input sebelumnya

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add To-Do Item with Reminder"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "New To Do Item",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(_selectedDate == null
                    ? "Pick a Date" // Pesan jika tanggal belum dipilih
                    : "Selected Date: ${_selectedDate!.toLocal()}"
                        .split(' ')[0]),
              ),
              ElevatedButton(
                onPressed: _pickTime,
                child: Text(_selectedTime == null
                    ? "Pick a Time" // Pesan jika waktu belum dipilih
                    : "Selected Time: ${_selectedTime!.format(context)}"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Validasi sebelum menambahkan item
                if (_textController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a to-do item!')),
                  );
                } else if (_selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please pick a date!')),
                  );
                } else if (_selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please pick a time!')),
                  );
                } else {
                  // Jika semua validasi lolos, tambahkan item ke to-do list
                  setState(
                    () {
                      String formattedDate =
                          "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
                      String formattedTime = _selectedTime!.format(context);

                      _todoList.add(
                        {
                          "task": _textController.text,
                          "date": formattedDate,
                          "time": formattedTime,
                        },
                      );
                      _saveTodoList();
                      _textController.clear();
                    },
                  );
                  Navigator.of(context)
                      .pop(); // Tutup dialog setelah menambah item
                }
              },
              child: const Text("Add"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _editToDoItem(int index) {
    _textController.text = _todoList[index]['task'];
    _selectedDate = DateTime.parse(_todoList[index]['date']);
    _selectedTime = TimeOfDay(
      hour: int.parse(_todoList[index]['time'].split(":")[0]),
      minute: int.parse(_todoList[index]['time'].split(":")[1]),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit To-Do Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "Edit To Do Item",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(_selectedDate == null
                    ? "Pick a Date"
                    : "Selected Date: ${_selectedDate!.toLocal()}"
                        .split(' ')[0]),
              ),
              ElevatedButton(
                onPressed: _pickTime,
                child: Text(_selectedTime == null
                    ? "Pick a Time"
                    : "Selected Time: ${_selectedTime!.format(context)}"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_textController.text.isNotEmpty &&
                    _selectedDate != null &&
                    _selectedTime != null) {
                  setState(() {
                    String formattedDate =
                        "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
                    String formattedTime = _selectedTime!.format(context);

                    _todoList[index] = {
                      "task": _textController.text,
                      "date": formattedDate,
                      "time": formattedTime
                    };
                    _saveTodoList();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  String capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  void _updateTime() {
    DateTime now = DateTime.now();
    _currentTime = "${now.hour}:${now.minute}:${now.second}";
    _currentDate = "${now.day}/${now.month}/${now.year}";
  }

  void _startClock() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(
          () {
            _updateTime();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 6, 30, 214),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To-Do List",
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          "Date: $_currentDate",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          "Time: $_currentTime",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: Text(
                        _todoList.length.toString(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _todoList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  capitalize(_todoList[index]["task"]),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  "Reminder: ${_todoList[index]["date"]} - ${_todoList[index]["time"]}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _editToDoItem(index), // Implementasi edit
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _removeTodoItem(index), // Hapus item
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToDoDialog,
        backgroundColor: Color.fromARGB(255, 6, 30, 214),
        child: const Icon(
          Icons.add,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
