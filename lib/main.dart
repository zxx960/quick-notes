import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuickNotesApp());
}

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '随手记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA726),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
      ),
      home: const NotesHomePage(),
    );
  }
}

class Note {
  const Note({
    required this.id,
    required this.text,
    required this.updatedAt,
    this.pinned = false,
  });

  final String id;
  final String text;
  final DateTime updatedAt;
  final bool pinned;

  Note copyWith({String? text, DateTime? updatedAt, bool? pinned}) {
    return Note(
      id: id,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
      'pinned': pinned,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      text: json['text'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  static const String _storageKey = 'quick_notes.items';

  final TextEditingController _quickInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _quickInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    final List<Note> notes = <Note>[];

    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      notes.addAll(
        decoded.map((item) => Note.fromJson(item as Map<String, dynamic>)),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _notes = _sorted(notes);
      _loading = false;
    });
  }

  Future<void> _saveNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_notes.map((note) => note.toJson()).toList()),
    );
  }

  List<Note> _sorted(List<Note> notes) {
    final List<Note> sorted = List<Note>.from(notes);
    sorted.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  List<Note> get _visibleNotes {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _notes;
    }
    return _notes
        .where((note) => note.text.toLowerCase().contains(query))
        .toList();
  }

  void _addQuickNote() {
    final String text = _quickInputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    final Note note = Note(
      id: now.microsecondsSinceEpoch.toString(),
      text: text,
      updatedAt: now,
    );

    setState(() {
      _notes = _sorted(<Note>[note, ..._notes]);
    });
    _quickInputController.clear();
    _saveNotes();
  }

  Future<void> _editNote(Note note) async {
    final TextEditingController controller = TextEditingController(
      text: note.text,
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑笔记'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '写点什么...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final String text = result?.trim() ?? '';
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _notes = _sorted(
        _notes.map((item) {
          if (item.id != note.id) {
            return item;
          }
          return item.copyWith(text: text, updatedAt: DateTime.now());
        }).toList(),
      );
    });
    _saveNotes();
  }

  void _togglePinned(Note note) {
    setState(() {
      _notes = _sorted(
        _notes.map((item) {
          if (item.id != note.id) {
            return item;
          }
          return item.copyWith(pinned: !item.pinned);
        }).toList(),
      );
    });
    _saveNotes();
  }

  void _deleteNote(Note note) {
    final int index = _notes.indexWhere((item) => item.id == note.id);
    if (index < 0) {
      return;
    }

    setState(() {
      _notes = List<Note>.from(_notes)..removeAt(index);
    });
    _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              final List<Note> restored = List<Note>.from(_notes);
              restored.insert(index.clamp(0, restored.length), note);
              _notes = _sorted(restored);
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Note> visibleNotes = _visibleNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('随手记'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索笔记',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleNotes.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                      itemCount: visibleNotes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Note note = visibleNotes[index];
                        return Dismissible(
                          key: ValueKey<String>(note.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteNote(note),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            elevation: 0,
                            color: note.pinned
                                ? const Color(0xFFFFF3D6)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              onTap: () => _editNote(note),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: IconButton(
                                tooltip: note.pinned ? '取消置顶' : '置顶',
                                icon: Icon(
                                  note.pinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  color: note.pinned
                                      ? Colors.orange.shade800
                                      : Colors.grey,
                                ),
                                onPressed: () => _togglePinned(note),
                              ),
                              title: Text(
                                note.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_formatTime(note.updatedAt)),
                              ),
                              trailing: IconButton(
                                tooltip: '删除',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteNote(note),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFFF7F4EF),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _quickInputController,
                onSubmitted: (_) => _addQuickNote(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '快速记录...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              onPressed: _addQuickNote,
              tooltip: '保存',
              child: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.edit_note, size: 76, color: Colors.orange.shade200),
          const SizedBox(height: 12),
          Text('还没有笔记', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('在下方输入，随手记下想法'),
        ],
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final DateTime now = DateTime.now();
  final bool sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;
  final String hourMinute =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  if (sameDay) {
    return '今天 $hourMinute';
  }
  return '${time.month}月${time.day}日 $hourMinute';
}
