import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:math';

List<Question> questions = [];
int correctAnswersCount = 0;
int index = 0;
late DateTime startTime;

void main() async {
  questions = await fetchQuestions();
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => MyApp(),
      '/question': (context) => QuestionScreen(),
      '/result': (context) => ResultScreen()
    },
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Quiz App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: ElevatedButton(
              child: Text('Start Quiz'),
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)))),
              onPressed: () {
                startTime = DateTime.now();
                index++;
                Navigator.pushNamed(context, '/question',
                    arguments: questions[0]);
              }),
        ),
      ),
    );
  }
}

class QuestionScreen extends StatefulWidget {
  @override
  _QuestionScreen createState() => _QuestionScreen();
}

class _QuestionScreen extends State<QuestionScreen> {
  Question question = new Question(
      category: '',
      correctAnswer: '',
      difficulty: '',
      incorrectAnswers: [],
      question: '',
      type: '');
  List<String> stringQuestions = [];
  String selectedQuestion = '';
  List<dynamic> tempList = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      question = ModalRoute.of(context)!.settings.arguments as Question;
      tempList = question.incorrectAnswers;
      tempList.add(question.correctAnswer);
      var totalCount = tempList.length;
      for (var i = 0; i < totalCount; i++) {
        var randomNumber = Random().nextInt(tempList.length);
        stringQuestions.add(tempList[randomNumber]);
        tempList.remove(tempList[randomNumber]);
      }
      setState(() => {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question $index/${questions.length}'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                question.question,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                  child: new ListView.builder(
                      itemCount: stringQuestions.length,
                      itemBuilder: (context, idx) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: ListTile(
                            title: Text(
                              '${stringQuestions[idx]}',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => setState(() =>
                                {selectedQuestion = stringQuestions[idx]}),
                            hoverColor: Color(0xFFFAFAFA),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: selectedQuestion == stringQuestions[idx]
                                ? Colors.pink
                                : Colors.purple,
                          ),
                        );
                      })),
              ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: 150, height: 40),
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedQuestion == '') {
                      return;
                    }
                    if (selectedQuestion == question.correctAnswer) {
                      correctAnswersCount++;
                    }
                    index++;
                    if (index - 1 == questions.length) {
                      Navigator.pushNamed(context, '/result');
                    } else {
                      Navigator.pushNamed(context, '/question',
                          arguments: questions[index - 1]);
                    }
                  },
                  child: Text(
                      index == questions.length ? 'Finish' : 'Next question!'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        selectedQuestion == ''
                            ? Colors.grey
                            : Theme.of(context).primaryColor),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var spendTime = DateTime.now().difference(startTime);
    return MaterialApp(
      title: 'Result',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Result'),
        ),
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  image: NetworkImage(
                      'https://www.iconpacks.net/icons/1/free-badge-icon-1361-thumb.png'),
                  height: 50,
                  width: 50,
                ),
                Text(
                  '$correctAnswersCount/${questions.length} correct answers in ${spendTime.inSeconds} seconds.',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: () async {
                      questions = await fetchQuestions();
                      index = 1;
                      correctAnswersCount = 0;
                      startTime = DateTime.now();
                      Navigator.pushNamed(context, '/question',
                          arguments: questions[0]);
                    },
                    child: Text('Play again'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<Question>> fetchQuestions() async {
  final response =
      await http.get(Uri.parse('https://opentdb.com/api.php?amount=1'));

  if (response.statusCode == 200) {
    List<Question> listResult = [];
    List<dynamic> jsonList = jsonDecode(response.body)['results'];
    for (var item in jsonList) {
      listResult.add(Question.fromJon(item));
    }
    return listResult;
  } else {
    throw Exception('Faild to load data');
  }
}

class Question {
  String category;
  String correctAnswer;
  String difficulty;
  List<dynamic> incorrectAnswers;
  String question;
  String type;

  Question(
      {required this.category,
      required this.correctAnswer,
      required this.difficulty,
      required this.incorrectAnswers,
      required this.question,
      required this.type});

  factory Question.fromJon(Map<String, dynamic> json) {
    return Question(
        category: json['category'],
        correctAnswer: json['correct_answer'],
        difficulty: json['difficulty'],
        incorrectAnswers: json['incorrect_answers'],
        question: json['question'],
        type: json['type']);
  }
}
