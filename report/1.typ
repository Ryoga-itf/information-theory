#import "@preview/codelst:2.0.2": sourcecode, sourcefile

== 1: 1月31日分課題

本課題については、以下に示すコードを用いて行った。
実装に際しては、Zig 0.13.0 #footnote[https://ziglang.org/documentation/0.13.0/] を用いた。

#show figure: set block(breakable: true)

#figure(
  sourcefile(read("../src/main.zig"), file:"../src/main.zig"),
  caption: [実装したコード]
) <code>
