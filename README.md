# Xsum: Exactly rounded floating-point sums in Julia
[![Travis Status](https://travis-ci.org/stevengj/Xsum.jl.svg)](https://travis-ci.org/stevengj/Xsum.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/3gxr4kf0a6uwly1y?svg=true)](https://ci.appveyor.com/project/StevenGJohnson/xsum-jl)


The Xsum package is a Julia wrapper around Radford Neal's [xsum package](https://gitlab.com/radfordneal/xsum)
for exactly rounded double-precision floating-point summation.  The [xsum algorithm](https://arxiv.org/abs/1505.05571) takes `n` double precision (`Float64` or smaller) floating-point values as input and computes the "exactly rounded sum" — equivalent to summing the values in *infinite* precision and rounding the result to the nearest `Float64` value.

By clever use of additional precision, xsum can compute the exactly rounded sum only a few times more slowly than the naive summation algorithm (or the pairwise summation used in the built-in `sum` function), much faster than using generic arbitrary precision (like `BigFloat` operations).

## Usage

The Xsum package provides a function `xsum` to perform the summation.  To use it, simply do:
```jl
using Xsum
xsum(iterator)
```
where you can pass any iteratable collection (arrays, generators, tuples, etcetera).  Real or complex collections can be summed, but note that each element is converted to double precision (`Float64` or `ComplexF64`) before it is summed, and the result is always double precision.

The variant `xsum(function, iterator)` is also supported, similar to `sum(function, iterator)`, which sums the result of the
given `function` applied to each element of the `iterator`.