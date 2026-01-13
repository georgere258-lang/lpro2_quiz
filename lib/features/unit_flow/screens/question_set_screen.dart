// PATH: lib/features/unit_flow/screens/question_set_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/curriculum/unit_model.dart';
import '../controller/unit_flow_bloc.dart';

class QuestionSetScreen extends StatefulWidget {
  final List<Question> questions;

  const QuestionSetScreen({
    super.key,
    required this.questions,
  });

  @override
  State<QuestionSetScreen> createState() => _QuestionSetScreenState();
}

class _QuestionSetScreenState extends State<QuestionSetScreen> {
  final Map<String, int> _selectedAnswers = {};

  bool get _isFormComplete =>
      widget.questions.isNotEmpty &&
      _selectedAnswers.length == widget.questions.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                itemCount: widget.questions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 48),
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(question.options.length, (optionIndex) {
                        return RadioListTile<int>(
                          title: Text(
                            question.options[optionIndex],
                            style: const TextStyle(fontSize: 16),
                          ),
                          value: optionIndex,
                          groupValue: _selectedAnswers[question.id],
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              _selectedAnswers[question.id] = value!;
                            });
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFormComplete
                      ? () {
                          context
                              .read<UnitFlowBloc>()
                              .add(SubmitAnswers(_selectedAnswers));
                        }
                      : null,
                  child: const Text("متابعة"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
