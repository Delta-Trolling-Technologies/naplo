// Armand ide írjad a kódot, majd valahogy belinkelem a kódba xddd
import 'dart:math';
import 'dart:io';

List<String> randomInsults = [];

Random random = Random();

// Read dirtywords
File file = File('dirtywords.xml');
List<String> dirtyWords = file.readAsLinesSync();

List<String> mWords = [];
List<String> fWords = [];

// Put m and f type strings into list
for (String word in dirtyWords) {
    if (word.contains('type="m"')) {
        mWords.add(word);
    } else if (word.contains('type="f"')) {
        fWords.add(word);
    }
}

while (randomInsults.length < 3) {
    if (randomInsults.length < 2) {
        int index = random.nextInt(mWords.length);
        String insult = mWords[index];
        if (!randomInsults.contains(insult)) {
            randomInsults.add(insult);
        }
    } else {
        int index = random.nextInt(fWords.length);
        String insult = fWords[index];
        if (!randomInsults.contains(insult)) {
            randomInsults.add(insult);
        }
    }
}

String generatedString = randomInsults.join(', ');

print(generatedString); // output for testing purposes
