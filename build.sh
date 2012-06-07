echo "Compiling less"
lessc CoffeeTalk.less public/css/coffeetalk.css
echo "Compiling coffee"
coffee -o ./public/ -c CoffeeTalkApp.coffee 