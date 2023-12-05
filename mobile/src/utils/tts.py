from dotenv import load_dotenv
import os

load_dotenv()


from pathlib import Path
from openai import OpenAI
import openai

openai.api_key = os.getenv('OPENAI_API_KEY')

client = OpenAI()

base_path = os.path.dirname(os.path.dirname(__file__))
speech_file_path = os.path.join(base_path, "..", 'sounds', "navigieren.mp3")

print(speech_file_path)
response = client.audio.speech.create(
  model="tts-1",
  voice="alloy",
  input="Navigieren."
)

response.stream_to_file(speech_file_path)