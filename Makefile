.PHONY: coffee haml sass docs angular
COFFEE_BIN=/usr/bin/coffee

all: coffee haml sass docs angular

angular: dist/mns-calendar.angular.js

dist/mns-calendar.angular.js: src/mns-calendar.angular.coffee
	$(COFFEE_BIN) --map --compile --output ./dist ./src/mns-calendar.angular.coffee

coffee: dist/mns_calendar.js

dist/mns_calendar.js: src/mns_calendar.coffee src/coffee/*.coffee src/coffee/event_sources/*.coffee
	$(COFFEE_BIN) --map --compile --output ./dist ./src/mns_calendar.coffee

src/mns_calendar.coffee: src/coffee/*.coffee src/coffee/event_sources/*.coffee
	coffeescript-concat -I ./src/coffee -I ./src/coffee/event_sources -o ./src/mns_calendar.coffee


haml: index.html

index.html: src/index.html.haml
	haml src/index.html.haml index.html

sass: dist/mns_calendar.css

dist/mns_calendar.css: src/mns_calendar.scss
	compass compile --sass-dir ./src/ --css-dir ./dist

docs: ;
