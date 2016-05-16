.PHONY: coffee haml sass docs

all: coffee haml sass docs

coffee: dist/mns_calendar.js

dist/mns_calendar.js: src/mns_calendar.coffee src/coffee/*.coffee
	coffee --map --compile --output ./dist ./src/mns_calendar.coffee

src/mns_calendar.coffee: src/coffee/*.coffee
	coffeescript-concat -I ./src/coffee -o ./src/mns_calendar.coffee


haml: index.html

index.html: src/index.html.haml
	haml src/index.html.haml index.html
	
sass: dist/mns_calendar.css

dist/mns_calendar.css: src/mns_calendar.scss
	compass compile --sass-dir ./src/ --css-dir ./dist
	
docs: ;


