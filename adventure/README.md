# Adventure Assembly Source

Annotated assembly source code for Adventure for the Atari 2600, created by Warren Robinett at Atari in 1979.

<img src="https://atariage.com/2600/boxes/b_Adventure_Color_front.jpg" width="400">
<img src="https://atariage.com/2600/boxes/b_Adventure_Color_back.jpg" width="400">

## Contents

Three binaries are built:

- `ADVNTURE.BIN` - An exact match of the original cartridge ROM, built from `ADVNTURE.s`
- `ADVeNTURE.BIN` - Minor updates to the original cartridge, denoted by FIXME conditional compilation directives in `ADVNTURE.s`
- `ADVeNTURE8K.BIN` - Enhanced version (`20261201`) using an 8KB bankswitched cart, built from `ADVeNTURE8K.s` (available on [EMU7800](http://emu7800.net/) as Adventure 8K)

Also, an ASCII-art `map.txt` file is included in the folder for reference.

## Building the Binaries

### Installing Build Tooling on Linux/WSL2

Binary [cc65](https://cc65.github.io/) linux packages may not be recent enough to successfully build the targets. Installing and compiling from source is an easy way to obtain the very latest  updates.

Create a folder `/srv/git/cc65` and change folder ownership:
```
sudo mkdir /srv/git/cc65
sudo chown /srv/git/cc65 youralias
sudo chgrp /src/git/cc65 youralias
```

Ensure `gcc` is installed:
```
sudo apt install gcc
```

Obtain the [cc65](https://cc65.github.io/) tool chain source:
```
cd /srv/git/cc65
git clone https://github.com/cc65/cc65
```

Build the [cc65](https://cc65.github.io/) tool chain:
```
cd /srv/git/cc65
make clean
make
```

Setup the `PATH`:
```
cd ~
nano .bashrc
```

Add the following lines to the bottom of the file:
```
export CC65_HOME=/srv/git/cc65
export $PATH:$CC65_HOME/bin
```

Restart your shell and verify the tooling is accessible in your path:
```
cc65 --version
```

Going forward, to install updates to the [cc65](https://cc65.github.io/) perform the following:
```
cd /src/git/cc65
git pull origin
make clean
make
```

Finally, it make be a good idea to run the following `git` configuration:
```
git config --global core.autocrlf false
```

## Building the ROMs

Once the build tooling is available, run the following in this repo:
```
make clean
make
```

The three `*.BIN` files and related artifacts will be created.

## Original Game Program Instructions

<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_1.jpg" width="400">
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_2.jpg" width="400"><br/>
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_3.jpg" width="400">
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_4.jpg" width="400"><br/>
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_5.jpg" width="400">
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_6.jpg" width="400"><br/>
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_7.jpg" width="400">
<img src="https://atariage.com/2600/manuals/Adventure_Black/m_Adventure_Black_8.jpg" width="400"><br/>

