import 'package:flutter/material.dart';
import 'package:chess_tactics_master/src/services/ai_opponent_engine.dart';

/// Widget for selecting AI difficulty level
class DifficultySelector extends StatefulWidget {
  final Function(AIDifficulty) onDifficultySelected;
  final AIDifficulty? initialDifficulty;

  const DifficultySelector({
    Key? key,
    required this.onDifficultySelected,
    this.initialDifficulty,
  }) : super(key: key);

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector> {
  late AIDifficulty _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty ?? AIDifficulty.medium;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'Select AI Difficulty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...AIDifficulty.values.map((difficulty) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Card(
                child: ListTile(
                  title: Text(difficulty.displayName),
                  subtitle: Text(difficulty.description),
                  trailing: Radio<AIDifficulty>(
                    value: difficulty,
                    groupValue: _selectedDifficulty,
                    onChanged: (AIDifficulty? value) {
                      setState(() {
                        if (value != null) {
                          _selectedDifficulty = value;
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                  },
                ),
              ),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDifficultySelected(_selectedDifficulty);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Start Game'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
