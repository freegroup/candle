DOMAIN = candle
SOURCES = $(shell find src -name '*.py') $(shell find src -name '*.kv')
LOCALES = src/locales/de src/locales/en # Add more locales as needed
BUILD_DIR = ./bin/
APK_NAME = candle-0.1-arm64-v8a-debug.apk

.PHONY: i18n build clean install

# Target for internationalization
i18n:
	for locale in $(LOCALES); do \
		echo $$locale/LC_MESSAGES; \
		mkdir -p $$locale/LC_MESSAGES; \
		xgettext --language=Python --keyword=_ --output=$$locale/LC_MESSAGES/$(DOMAIN).pot $(SOURCES); \
		if [ ! -f $$locale/LC_MESSAGES/$(DOMAIN).po ]; then \
			msginit --locale=$$(basename $$locale) --input=$$locale/LC_MESSAGES/$(DOMAIN).pot --output-file=$$locale/LC_MESSAGES/$(DOMAIN).po; \
		else \
			msgmerge --update $$locale/LC_MESSAGES/$(DOMAIN).po $$locale/LC_MESSAGES/$(DOMAIN).pot; \
		fi; \
		msgfmt $$locale/LC_MESSAGES/$(DOMAIN).po --output-file $$locale/LC_MESSAGES/$(DOMAIN).mo; \
	done

# Target to build the app
build: i18n
	buildozer -v android debug

# Target for cleaning up
clean:
	for locale in $(LOCALES); do \
		rm -f $$locale/LC_MESSAGES/*.mo; \
		rm -f $$locale/LC_MESSAGES/*.pot; \
	done
	buildozer android clean

# Target to install the app
install:
	adb install $(BUILD_DIR)$(APK_NAME)

log:
	adb logcat | grep -i python