# Lorcana Proxy Card Generator

Quick-and-dirty project for generating PDFs of Lorcana proxy cards.  
Sorry for the mess. I may or may not bother cleaning it up later.

## Usage

Before your first use, build the Docker container.
```fish
docker build --tag ink:latest .
```

Update the `cards` variable in `main.rb` to specify the cards to include.  
Maybe I'll pull from a config file or something in the future.

Then, run this fish command to generate the proxies PDF.
```fish
docker run -v (pwd)/:/app -t ink:latest

xdg-open proxies.pdf 
```
