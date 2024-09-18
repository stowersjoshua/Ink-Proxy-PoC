# Lorcana Proxy Card Generator

Quick-and-dirty project for generating PDFs of Lorcana proxy cards.  
Sorry for the mess. I may or may not bother cleaning it up later.

## Usage

Update the `cards` variable in `main.rb` to specify the cards to include.  
Then run this fish command to build and run the Docker container.
```fish
docker run --privileged -v (pwd)/:/app -it ink:latest
```

Or to build the image and not run anything:
```fish
docker build --tag ink:latest .
```
