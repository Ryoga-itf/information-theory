#import "@preview/codelst:2.0.2": sourcecode, sourcefile

== 1: 1月31日分課題

本課題については、以下に示すコードを用いて行った。
実装に際しては、Zig 0.13.0 #footnote[https://ziglang.org/documentation/0.13.0/] を用いた。

#show figure: set block(breakable: true)

#figure(
  sourcefile(read("../src/main.zig"), file:"../src/main.zig"),
  caption: [実装したコード]
) <code>

作成したプログラムは以下の仕様を満たす。

- 引数に渡されたテキストファイルを処理する。
- テキストファイルの内容について以下のことを行う。
  - filter 関数で渡された条件を満たす文字に対してのみ処理を行う。今回はアルファベットと数字のみ (`A-Z, a-z, 0-9`) としている。
  - filter 関数に適合する文字数を報告する。
  - 各文字の出現頻度・出現確率を計算し、報告する。
  - また、この文章のエントロピーを計算し、報告する。
  - 算出した確率をもとにハフマン符号化し、各文字の符号語を求め報告する。
  - 浮動小数点の計算については IEEE 754 四倍精度 (`f128`) を用いている

ハフマン符号化の処理については再帰関数を用いて実装した。

Ernest Vincent Wright 著の
「Gadsby a story of over 50,000 words without using the letter "E"」 の第 3 章の内容（9449文字）に対してこのコードを実行した結果を以下に示す。
なお、用いた文章は https://www.gutenberg.org/cache/epub/47342/pg47342-images.html より確認できる。

#figure(
  sourcefile(read("gadsby.txt"), file:"gadsby.txt"),
  caption: [結果]
) <result>

Gadsby は文字として E が含まれないことで有名である #footnote[https://en.wikipedia.org/wiki/Gadsby_(novel)] が、結果としても `E, e` が含まれていないことが確認できる。

また、エントロピーはおよそ $4.2450769$ bits/文字、平均符号語長はおよそ $4.2829929$ bits/文字となった。

=== エントロピーと平均符号語長の関係

エントロピーと平均符号語長は非常に近い値を示している。

情報源符号化定理により、
記憶のない定常情報源 $X$ に対して、1 記号あたりの平均符号語長 $L$ とエントロピーレート $H(X)$ に対して以下の関係が成り立つ。

$
H(X) <= L < H + epsilon
$

今回得られた結果も、平均符号語長はエントロピーよりも大きくなっていることがわかる。

また、元の文章を圧縮するとしたらファイルサイズがどこまで小さくできるかを考える。
元のサイズは一文字に対して 8bit 使うため、全体として 75592 bits となっている。
実際には文字と符号の関係を持つためのテーブルを含ませる必要があるため、もう少し大きくなってしまうが、
ハフマン符号化により圧縮すると 40470 bits と半分程度くらいには圧縮することができる。
