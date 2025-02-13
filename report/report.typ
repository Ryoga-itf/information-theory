#import "@preview/tenv:0.1.1": parse_dotenv


#let env = parse_dotenv(read(".env"))

#let textL = 1.8em
#let textM = 1.6em
#let fontSerif = ("Noto Serif", "Noto Serif CJK JP")
#let fontSan = ("Noto Sans", "Noto Sans CJK JP")

#let title = "情報理論 最終レポート"
#set document(author: env.STUDENT_NAME, title: title)
#set page(numbering: "1", number-align: center)
#set text(font: fontSerif, lang: "ja")

#show heading: set text(font: fontSan, weight: "medium", lang: "ja")

#show heading.where(level: 2): it => pad(top: 1em, bottom: 0.4em, it)
#show heading.where(level: 3): it => pad(top: 1em, bottom: 0.4em, it)

// Figure
#show figure: it => pad(y: 1em, it)
#show figure.caption: it => pad(top: 0.6em, it)
#show figure.caption: it => text(size: 0.8em, it)

// Title row.
#align(center)[
  #block(text(textL, weight: 700, title))
  #v(1em, weak: true)
  2025 年 2 月 13 日
]

// Author information.
#pad(
  top: 0.5em,
  bottom: 0.5em,
  x: 2em,
  grid(
    columns: (1fr),
    gutter: 1em,
    align(center)[
      *#env.STUDENT_NAME* \
      学籍番号: #env.STUDENT_ID \
      所属: #env.STUDENT_AFFILIATION
    ]
  ),
)

// Main body.
#set par(justify: true)

#include "1.typ"
#include "2.typ"
#include "3.typ"
