#import "@preview/showybox:2.0.2":*

#let blockquote(body) = showybox(
  frame: (
    thickness: (left: 1pt),
    radius: 0pt
    ),
  par(text(size: 0pt, ""))
  + v(-1em-2.926pt)
  + body
)

== 2: 二元対象通信路問題

ハミング符号 $(n, k)$ は、情報ビット $k$ に対して符号語長 $n = 2^m - 1$ で構成される。
また、このとき $k$ ビットのビット列を $n$ ビットの符号語に置き換えるハミング符号が形成されるわけであるから、情報伝送速度は $R = k \/ n$ である。

ハミング符号は 1 重誤り訂正符号であるから、1 つの符号語内に誤りが 1 個以下であれば訂正でき、2 個以上だと復号誤りが生じる。
符号語長 $n$ のうち 2 ビット以上が誤る確率を考える。

#blockquote[
  $n$ 箇所すべてに誤りが生じる確率は、$p^n$

  $n - 1$ 箇所に誤りが生じる確率を考えると、$n p^(n-1) (p-1)$ となる。
  (誤りが生じ*ない*位置は $n$ 通りあり、個々の生起確率は $p^(n-1) (p-1)$ で、これらは排反であるため)

  同様に考えて、$i >= 2$ に誤りが生じるとき、

  $
  binom(n, i) p^i (1 - p)^(n - i)
  $

  したがって、

  $
  P_e = sum^(n)_(i = 2) binom(n, i) p^i (1 - p)^(n - i)
  $
]

#set enum(numbering: "(i)")

#let item(m) = [
  #let n = calc.pow(2, m) - 1
  #let k = n - m

+ $m = #m$ のとき、

  $n = 2^#m - 1 = #n, k = n - m = #k$ であるから、符号のレートは

  $
  R = k/n = #k/#n
  $

  また、復号誤り率は以下のように計算できる。

  #let result-math = range(2, n+1).map(i => [
    $#calc.binom(n, i) dot (0.01)^(#i) dot (0.99)^(#{n - i})$
  ]).chunks(3, exact: false).map(v => v.join($+$)).join(
    $\
    &+
    $
  )

  #let result-array = range(2, n+1).map(i => 
    calc.binom(n, i) * calc.pow(0.01, i) * calc.pow(0.99, n - i)
  )

  $
  P_e
  &= sum^(n)_(i = 2) binom(n, i) p^i (1 - p)^(n - i) \
  &= sum^(#n)_(i = 2) binom(#[#n], i) (0.01)^i dot (0.99)^(#n - i) \
  &= #result-math \
  &approx #calc.round(result-array.sum(), digits: 7)
  $
]

#item(2)
#item(3)
#item(4)
#item(5)

以上より、この結果を表にまとめると @table1 のようになる。

#let data = (2, 3, 4, 5).map(m => {
  let n = calc.pow(2, m) - 1
  let k = n - m
  let result = range(2, n+1).map(i => 
    calc.binom(n, i) * calc.pow(0.01, i) * calc.pow(0.99, n - i)
  )
  (m, calc.round(k / n, digits: 7), calc.round(result.sum(), digits: 7))
})

#show figure: set block(breakable: false)
#figure(
  table(
    columns: (auto, auto, auto),
    inset: 7pt,
    align: center,
    table.header(
      [*$m$*], [*$R$*], [*$P_e$*]
    ),
    ..data.flatten().map(v => [$#v$])
  ),
  caption: [$m, R, P_e$ の関係]
) <table1>
