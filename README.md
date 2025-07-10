# Dictionary fun
Playing with the benchmarking of different large data algorithms, like search or insertion.

## Dependencies
* Zig 0.14.0
* wget

## Download dictionary sample
```sh
wget https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_alpha.txt
```

## Build and run
```sh
zig build run --release=fast -- ./YourDictionaryFilepath.txt
```
