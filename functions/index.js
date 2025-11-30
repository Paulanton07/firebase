const functions = require("firebase-functions");
const { SpeechClient } = require("@google-cloud/speech");
const client = new SpeechClient();

exports.transcribeAudio = functions.https.onCall(async (data, context) => {
  const gcsUri = data.gcsUri;
  const audio = {
    uri: gcsUri,
  };
  const config = {
    encoding: "MP3",
    sampleRateHertz: 16000,
    languageCode: "en-US",
  };
  const request = {
    audio: audio,
    config: config,
  };
  const [response] = await client.recognize(request);
  const transcription = response.results
    .map((result) => result.alternatives[0].transcript)
    .join("\n");
  return { transcription };
});
