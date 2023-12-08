
import gettext
import os
import locale
import json

from plyer.utils import platform

_current_gettext = lambda s: s

_ = lambda s: _current_gettext(s)  # Default no-op translation function


def get_device_language():
    if platform == "android":
        from jnius import autoclass
        Locale = autoclass('java.util.Locale')
        return Locale.getDefault().getLanguage()
    else:
        import locale
        return locale.getdefaultlocale()[0]



def setup_i18n():
    language = get_device_language()
    print(f"Aktuelle Locale vor Setup: {language}")

    try:
        locale.setlocale(locale.LC_ALL, language)
    except locale.Error as e:
        print(f"Fehler beim Setzen der Locale '{language}': {e}")
        locale.setlocale(locale.LC_ALL, '')  # Use the system default

    print(f"Aktuelle Locale nach Setup: {language}")

    localedir = os.path.abspath(os.path.join(os.path.abspath(os.path.dirname(__file__)), "..", 'locales'))
    print(f"Verwende Lokalisierungsverzeichnis: {localedir}")

    try:
        translate = gettext.translation(domain='candle', localedir=localedir, languages=[language, language.split('_')[0]], fallback=True)
        global _current_gettext
        _current_gettext= translate.gettext
        print(_("TEST"))
        print(f"Übersetzung für '{language}' geladen.")
    except Exception as e:
        print(f"Fehler beim Laden der Übersetzung für '{language}': {e}")