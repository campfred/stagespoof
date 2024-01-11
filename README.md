# Stage spoof

It's not really the magic trick we see in the movies.

## About this project ℹ️

This is a simple script to automate spoofing domains into staging when testing changes in Akamai.

## Installation 📥

### Preferred method

Pull this repository and make a link going from the script file ([stagespoof.sh](stagespoof.sh)) to `/usr/local/bin/stagespoof`.

```bash
ln stagespoof.sh /usr/local/bin/stagespoof
```

> This is the preferred method as you will be able to test contributions and get updates more easily.

### Manual download

Copy stagespoof.sh directly into `/usr/local/bin`.

_OR_

Copy into your favourite scripts folder that's part of your `$PATH` variable.

## Usage 🚀

### Spoofing domains 🎭

Run `stagespoof` command with any domain needing to be spoofed.

```bash
stagespoof news sports noovomoi
```

### Resetting hosts file ⛑️

Run `stagespoof` command with the `reset` option.

```bash
stagespoof --reset
# or
stagespoof -r
```

## Contributing 🎁

Any and all contributions are welcome. ✨
Simply make a Merge Request from your own fork with your changes and I'll check it out. 😊

## Improvements wishlist

* Error handling
* Domain spoofing chaining (giving more than one domain as argument and going through all of them one by one)
* Proxy server setup argument
* Detect proxy server setup on other OSes
