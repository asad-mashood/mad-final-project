// screens/player_setup_screen.dart
import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../utils/profile_manager.dart';
import 'court_selection_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool _isLoadingProfile = true;
  String _selectedDifficulty = 'Medium';
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  String _selectedRacket = 'Beginner Racket';
  final List<String> _rackets = [
    'Beginner Racket',
    'Power Racket',
    'Control Racket',
  ];
  String _selectedShoes = 'Basic Shoes';
  final List<String> _shoes = [
    'Basic Shoes',
    'Sprint Shoes',
    'Endurance Shoes',
  ];
  String _selectedShirtStyle = 'Classic White';
  final List<String> _shirtStyles = ['Classic White', 'Pro Red', 'Neon Blue'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await ProfileManager.instance.loadProfile();
    final profile = ProfileManager.instance.profile;
    if (profile != null) {
      _nameController.text = profile.playerName;
      _ageController.text = profile.age.toString();
      _selectedDifficulty = profile.difficulty;
      _selectedRacket = profile.racket;
      _selectedShoes = profile.shoes;
      _selectedShirtStyle = profile.shirtStyle;
    } else {
      _ageController.text = '18';
    }
    setState(() {
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    final name =
        _nameController.text.trim().isEmpty
            ? 'Guest'
            : _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 18;
    final profile = PlayerProfile(
      playerName: name,
      age: age,
      difficulty: _selectedDifficulty,
      racket: _selectedRacket,
      shoes: _selectedShoes,
      shirtStyle: _selectedShirtStyle,
    );

    await ProfileManager.instance.saveProfile(profile);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CourtSelectionScreen(
              playerName: profile.playerName,
              age: profile.age,
              difficulty: profile.difficulty,
              racket: profile.racket,
              shoes: profile.shoes,
              shirtStyle: profile.shirtStyle,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFF2E7D32),
              const Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'PLAYER SETUP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_isLoadingProfile)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else ...[
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Name',
                            hintText: 'Enter Player Name',
                            hintStyle: const TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Leave blank to play as Guest with default equipment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Age',
                            hintText: 'Player Age',
                            hintStyle: const TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.cake,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      const Text(
                        'SELECT DIFFICULTY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDifficulty,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            items:
                                _difficulties.map((String difficulty) {
                                  return DropdownMenuItem<String>(
                                    value: difficulty,
                                    child: Text(difficulty),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedDifficulty = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'SHIRT STYLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedShirtStyle,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            items:
                                _shirtStyles.map((String shirt) {
                                  return DropdownMenuItem<String>(
                                    value: shirt,
                                    child: Text(shirt),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedShirtStyle = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'EQUIPMENT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRacket,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items:
                                      _rackets.map((String racket) {
                                        return DropdownMenuItem<String>(
                                          value: racket,
                                          child: Text(racket),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedRacket = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedShoes,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items:
                                      _shoes.map((String shoe) {
                                        return DropdownMenuItem<String>(
                                          value: shoe,
                                          child: Text(shoe),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedShoes = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEB3B),
                          foregroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'SAVE & CONTINUE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'BACK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
