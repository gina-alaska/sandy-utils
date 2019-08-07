## [[Unreleased]]
- added a few small fixes

## [[1.6.12]] - 2019-8-6
- random small fixes to the terascan processing

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.12-20190807235301-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: e6b5fa90c6da1f9b7abfe75bb7edc42aabc1f88f47ef7bc59d21d8c9194cc3b8
   sandy-utils: Blake2b Checksum: 479a9d130840ba6d45302d578df38c3225761a49b5c2e3f1b65fa7383942b5ca
```

## [[1.6.11]] - 2019-4-25
- added noaa viirs fires
- random small fixes
```
   sandy-utils: Source Path: /hab/cache/src/sandy-utils-1.6.11
   sandy-utils: Installed Path: /hab/pkgs/uafgina/sandy-utils/1.6.11/20190425202531
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.11-20190425202531-x86_64-linux.hart
```

## [[1.6.10]] - 2019-2-05
- switched mirs to scmi
```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.10-20190208011602-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: e87b7da16520c4e29974d0c151f43884931e14d3a91fe75b90335a917f9f227b
   sandy-utils: Blake2b Checksum: 329e656ba9e586fc7cb9b374a0d4b0925eae800b04e498c340fddb60ce5b4d2a
```


## [[1.6.7]] - 2018-9-04
- switched mirs to hi for everything
- fixed a few typos
- switched to clean env for geotifs generation
- added a few extra clavrx parts.

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.7-20180904213425-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: 14e3e4f8c2064287b22e394356eecba4ffe3813c165c0f48a11799104f780346
   sandy-utils: Blake2b Checksum: add7b263ad77373bfcc98e1ab360e3d9457d242a087e8beb6dc238416f365f67
```



## [[1.6.6]] - 2018-08-28
- added chavrx geotif for viirs

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.6-20180828233436-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: c9801fdccf7b730f47a4528da94c90dbc8750f39f35762147b4998e27a2a2c69
   sandy-utils: Blake2b Checksum: 438096cc4c15c6a17d7228972e462f19a834b983ccc49f2cd36b4be597b4592b
```

## [[1.6.4]] - 2018-07-25
- fixes for nucaps
```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.4-20180725235549-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: 5f9314584446eb3f9cb46bb97e2f8767144fa5a38bf4557134708d6c76085e85
   sandy-utils: Blake2b Checksum: c8d1d0b3276b028b2033fcdcbe3a7c379152c15b037d21b26dc4f112368c333d
```


## [[1.6.3]] - 2018-07-11
- hab pins, for libc issues, hab's update to libc 2.27 .
- removed a few bands for viirs

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.3-20180713010726-x86_64-linux.hart
   sandy-utils: SHA256 Checksum: 802cfea3820d7f377b055b9f51a5af5ec867d8bcb9becae443b9a29155b0f7b1
   sandy-utils: Blake2b Checksum: c2df4cad9eaa091cb2bab0049a7e5a4de70e05b5cad2a00532dbce65d3039bb4
```


## [[1.6.2]] - 2018-06-21
- added avhrr geotifs and a few other small changes

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.2-20180622002200-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: 52eae94fb93e5f363750cc5aa191a1934b5070db7305af02f9ceed2ef863092b
   sandy-utils: Blake2b Checksum: b02c8bbde47f9de8859ec1f3da3c78202cbe305f6b305a8a52e3858d6d4797fb
```

## [[1.6.1]] - 2018-06-06
- added cloud l2 and scmi processing

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.1-20180606231517-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: b2f5626e811f9d667e47d5e4850597eb0a659fe9c9b9cc19e34a810bf76730a4
   sandy-utils: Blake2b Checksum: 11312eeafa88603b4ce481f40d2f02869e2e2c4d755c516d712a9ee4b2614f9b
```


## [[1.6.0]] - 2018-05-31
- added prefix for ldm insert
- switched to lo for mirs poes
- added nucaps noaa20
- threaded scmi

```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.6.0-20180531214254-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: 73558aa43d342ee00377eafaa046999d93020b3e14b7f42d145d17d374fe0318
   sandy-utils: Blake2b Checksum: a639caff95f8ceef51852a5ba8d34c2690b207f329f7b252905e1f080e0340a4
```


## [[1.5.5]] - 2018-01-16
- changed shellout calls for awips generating for mirs and sst, as they fail when run against data that is valid but doesn't work because of daylight etc. 
```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.5.5-20180117013120-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: 3458b5e1f2ebf31689b37f036fa6cb5ba1ba8ac05232851764eb1c2cf7c9fd8d
   sandy-utils: Blake2b Checksum: ba36229023558ea44557e4965fbba89d4a0c5438631ca1f00f8eef2e7194cf11
```

## [[1.5.4]] - 2018-01-16
- added source to mirs awips generation 
```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.5.4-20180117000705-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: add78703852cf2125ba3ab25ba48084db4b8b0183107efbaa3a773115f389829
   sandy-utils: Blake2b Checksum: 6f8108a7b2769399866df9537449c734181249fafb1369130718b09fba63948a
```
## [[1.5.3]] - 2018-01-11
- added clean env to problem shell_out calls for noaa poes awips and mirs. 
```
   sandy-utils: Artifact: /src/results/uafgina-sandy-utils-1.5.3-20180111214024-x86_64-linux.hart
   sandy-utils: Build Report: /src/results/last_build.env
   sandy-utils: SHA256 Checksum: cbe69422cdf0f5b9f4add0246d5a42d78f61230f5a3c63073e2d576447a0b7d0
   sandy-utils: Blake2b Checksum: 349d8b96453682017f01975f5ab1d3a76f9c2e90a009625cfd327163d81dfa55
```
## [[1.5.2]] - 2017-12-28
- added NOAA20 support to geotif generation and SDR & RDR generation. 
- added nucaps support
- added scmi support
## [[1.5.1]] - 2017-12-15
- habitat and bundler fixes

## [[1.5.0]] - 2017-11-13
- SST and ASPO product generation

## [[1.4.6]] - 2017-09-28
- MIRS and AAPP additions
- Update for sport mods
