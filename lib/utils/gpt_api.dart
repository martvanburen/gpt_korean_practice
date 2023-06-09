import "dart:convert";

import 'package:ai_yu/data/gpt_message.dart';
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;

Future<GPTMessageContent> callGptAPI(
    String? mission, List<GPTMessage> conversation,
    {int numTokensToGenerate = 600}) async {
  // TODO(Mart):
  // . Using dotenv to store the API key is not secure. Eventually
  // . this app should be upgraded to communicate with a backend server,
  // . which will then also hold the API key and make the calls for us.

  // Convert the conversation into the format the API expects.
  List<Map<String, String>> messages =
      await Future.wait(conversation.map((message) async {
    final content = await message.content;

    return {
      "role": message.sender == GPTMessageSender.user ? "user" : "assistant",
      "content": content.unparsedContent ?? content.body,
    };
  }));

  if (mission != null) {
    // Add mission statement as first message.
    messages.insert(0, {
      "role": "system",
      "content": mission,
    });
  }

  // Make API call.
  const String url = "https://api.openai.com/v1/chat/completions";
  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${dotenv.env["OPENAI_KEY"]}",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": messages,
      "max_tokens": numTokensToGenerate,
    }),
  );

  // Parse response.
  if (response.statusCode == 200) {
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    var messageContentRaw = data["choices"][0]["message"]["content"].trim();
    try {
      var messageContentParsed = jsonDecode(messageContentRaw);
      var responseField = messageContentParsed["response"];
      String? sentenceCorrection = messageContentParsed["corrected"];
      List<String>? sentenceFeedback;
      if (messageContentParsed["feedback"] is List<dynamic>) {
        sentenceFeedback = List<String>.from(messageContentParsed["feedback"]);
      }
      return GPTMessageContent(responseField,
          unparsedContent: messageContentRaw,
          sentenceFeedback: sentenceFeedback,
          sentenceCorrection: sentenceCorrection);
    } catch (e) {
      return GPTMessageContent(messageContentRaw);
    }
  } else {
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    return GPTMessageContent(data["error"]["message"]);
  }
}

Future<String> translateToEnglishUsingGPT(String text) async {
  // TODO(Mart):
  // . Using dotenv to store the API key is not secure. Eventually
  // . this app should be upgraded to communicate with a backend server,
  // . which will then also hold the API key and make the calls for us.

  const String url = "https://api.openai.com/v1/chat/completions";
  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${dotenv.env["OPENAI_KEY"]}",
    },
    body: jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "user",
          "content": """
Please translate the following text into English. Respond only with the result.
$text
""",
        },
      ],
      "max_tokens": 300,
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    return data["choices"][0]["message"]["content"].trim();
  } else {
    var data = jsonDecode(utf8.decode(response.bodyBytes));
    return data["error"]["message"];
  }
}
