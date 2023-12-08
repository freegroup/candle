import threading
from plyer import tts

def _tts_speak(text):
    tts.speak(message=text)


def say(text):
    print("SAY: "+text)
    threading.Thread(target=_tts_speak, args=(text,)).start()

