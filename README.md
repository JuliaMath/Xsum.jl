# Xsum: Exactly rounded floating-point sums in Julia
[![CI](https://github.com/JuliaMath/Xsum.jl/workflows/CI/badge.svg)](https://github.com/JuliaMath/Xsum.jl/actions?query=workflow%3ACI)

The Xsum package is a Julia wrapper around Radford Neal's [xsum package](https://gitlab.com/radfordneal/xsum)
for exactly rounded double-precision floating-point summation.  The [xsum algorithm](https://arxiv.org/abs/1505.05571) takes `n` double precision (`Float64` or smaller) floating-point values as input and computes the "exactly rounded sum" — equivalent to summing the values in *infinite* precision and rounding the result to the nearest `Float64` value.

By clever use of additional precision, xsum can compute the exactly rounded sum only a few times more slowly than the naive summation algorithm (or the pairwise summation used in the built-in `sum` function), much faster than using generic arbitrary precision (like `BigFloat` operations).

## Usage

The Xsum package provides a function `xsum` to perform the summation.  To use it, simply do:
```jl
using Xsum
xsum(iterator)
```
where you can pass any iterable collection (arrays, generators, tuples, etcetera).  Real or complex collections can be summed, but note that each element is converted to double precision (`Float64` or `ComplexF64`) before it is summed, and the result is always double precision.

The variant `xsum(function, iterator)` is also supported, similar to `sum(function, iterator)`, which sums the result of the
given `function` applied to each element of the `iterator`.

There is also a lower-level object `XAccumulator()` that you can use to perform more
flexible sums.  A `s::XAccumulator` object represents partial sum, whose exactly
rounded `Float64` result is given by `float(s)`.   `s = XAccumulator()` initializes
a zero sum, and `accumulate!(s, x)` adds `x` to `s` where `x` is a real number
(converted to `Float64`), an array of `Float64` values, or another `XAccumulator`.
You can also add and subtract accumulators with `+` and `-` (which operate out-of-place
so they are less efficient), or negate one in-place with `Xsum.negate!(s)`.

For example, if you wanted to compute an exactly rounded sum of a large vector `x` in parallel, you could call `accumulate!(XAccumulator(), xslice)` on a sequence of *slices*
(portions) of `x` in parallel, and then combine the sub-accumulators to obtain the
final sum.
