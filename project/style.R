colour_alpha <- .7

colour_above <- alpha("green", colour_alpha)
colour_median <- alpha("blue", colour_alpha)
colout_below <- alpha("red", colour_alpha)

colours_rank <- c(
  "+" = colour_above,
  "=" = colour_median,
  "-" = colout_below)

emojis <- tribble(
  ~quartile_rank, ~emoji, ~colour,
  1, "fa-frown", colout_below,
  2, "fa-meh", colout_below,
  3, "fa-smile", colour_above,
  4, "fa-grin", colour_above
)
