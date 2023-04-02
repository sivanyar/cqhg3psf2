# Choro Q HG 3 (Gadget Racers) PSF2 Driver

This repository contains the IOP module for playing TSQ/TVB sound files with the PSF2 player.

There are also several scriptss included that can be used to create PSF2 files.

Note that this is only for Playstation 2 games and is not compatible with Playstation 1 TSQ/TVB files.

For Playstation 1 games, use [tsq2psf](https://github.com/loveemu/tsq2psf) by loveemu.


## Requirements

* PowerShell `>=5.1`  
  * Can also be used with [cross-platform PowerShell](https://learn.microsoft.com/ja-jp/powershell/) on Linux or macOS.
* [PS2DEV](https://github.com/ps2dev/ps2dev) (`v1.2.0` is recommended) or Docker
* [PSF2Kit](https://web.archive.org/web/20060420042034/http://www.neillcorlett.com/psf/PSF2Kit.zip)
* [mkpsf2](https://www.zophar.net/utilities/converters/mkpsf2.html)


## Build

With PS2DEV environment:

```sh
cd ./src && make
```

With Docker:

```sh
./build-docker.ps1
```


## Usage

1.  Extract `SNDMOD.IRX`, `*.TSQ`, `*.TVB` files from the game disc.
2.  Put `SNDMOD.IRX` to this directory and execute the following:

```sh
./scripts/fix-iopmod.ps1 -LiteralPath SNDMOD.IRX
```

3. Create PSF2.INI in any text editor and write the following :

```
myhost.irx
cdvdnul.irx
fakesif.irx
libsd.irx
sndmod_linkfix.irx
tsqdrv.irx -b=[TVB filename] -s=[TSQ filename]
```

4. Place the following files into their own directory. 

| Filename            | Where to get                                        |
| ---                 | ---                                                 |
| PSF2.IRX            | From PSF2Kit                                        |
| PSF2.INI            | You have to create/edit this yourself in step 3.    |
| MYHOST.IRX          | From PSF2Kit                                        |
| CDVDNUL.IRX         | From PSF2Kit                                        |
| FAKESIF.IRX         | From PSF2Kit                                        |
| LIBSD.IRX           | From the game itself                                |
| SNDMOD_linxfix.IRX  | Generated in step 2.                                |
| TSQDRV.IRX          | Just this module                                    |
| \[basename\].TSQ    | From the game itself                                |
| \[basename\].TVB    | From the game itself<br>Must correspond to TSQ file |

5. Use mkpsf2 to bundle these files into a PSF2 file.

6. Calculate the length of the songs and apply it to the PSF2 files using [psfpoint](https://github.com/loveemu/psfpoint).

```sh
./scripts/tsqtimer.ps1 -LiteralPath [TSQ path] -Loop [loop count]
```
