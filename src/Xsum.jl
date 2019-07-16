module Xsum

export xsum, XAccumulator

# Load xsum libraries from our deps.jl
const depsjl_path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("Xsum not installed properly, run Pkg.build(\"Xsum\"), restart Julia and try again")
end
include(depsjl_path)

function __init__()
    check_deps()
end

include("xsum_h.jl")

"""
`acc = XAccumulator()` creates an object `acc` that can be used to accumulate an
exactly rounded double-precision sum.   The sum is accumulated by repeatedly
calling `accumulate!(acc, x)` on summands `x`, and then the final exactly-rounded
result is obtained by calling `float(acc)`.
"""
struct XAccumulator <: Real
    acc::Base.RefValue{xsum_small_accumulator}
    XAccumulator(acc::Base.RefValue{xsum_small_accumulator}) = new(acc)
    function XAccumulator()
        acc = Base.RefValue{xsum_small_accumulator}()
        xsum_small_init(acc)
        return new(acc)
    end
end
XAccumulator(s::XAccumulator) = XAccumulator(s.acc)
Base.float(s::XAccumulator) = xsum_small_round(s.acc)
XAccumulator(init::Real) = accumulate!(XAccumulator(), init)
Base.show(io::IO, s::XAccumulator) = print(io, "XAccumulator(", float(s), ")")

"""
    accumulate!(s::XAccumulator, x::Real)

Add `Float64(x)` to the accumulated sum `s`, with the sum performed in (effectively) infinite precision.
"""
Base.accumulate!(s::XAccumulator, x::Real) = begin; xsum_small_add1(s.acc, x); s; end

Base.accumulate!(s::Complex{XAccumulator}, x::Complex) = Complex(accumulate!(real(s), real(x)), accumulate!(imag(s), imag(x)))
Base.accumulate!(s::Complex{XAccumulator}, x::Real) = Complex(accumulate!(real(s), x), imag(s))
Base.accumulate!(s::XAccumulator, x::Complex) = Complex(accumulate!(s, x), XAccumulator())
XAccumulator(init::Complex) = Complex(XAccumulator(real(init)), XAccumulator(imag(init)))

"""
    xsum([f,] itr)

Compute the exactly rounded double-precision sum of calling `f` (which defaults to `identity`) on
the elements of the iterable collection `itr`. That is, return the sum as if (1) the elements of `f.(itr)`
were converted to double (`Float64`) precision, (2) summed in *infinite* precision, and
(3) rounded to the closest double-precision value in the final result.    Both real and complex
sums are supported.
"""
function xsum(f, itr)
    i = iterate(itr)
    if i === nothing
        zero = Base.mapreduce_empty_iter(f, +, itr, Base.IteratorEltype(itr))
        return zero isa Real ? Float64(zero) : zero isa Complex ? ComplexF64(zero) : zero
    end
    v, state = i
    s = XAccumulator(f(v))
    while true
        i = iterate(itr, state)
        i === nothing && return float(s)
        v, state = i
        accumulate!(s, f(v))
    end
end

xsum(itr) = xsum(identity, itr)

function xsum(a::StridedVector{Float64})
    stride(a,1) != 1 && return invoke(xsum, Tuple{Any}, a)
    n = length(a)
    if n < 256 # empirical threshold for small accumulator to be faster
        let acc = Base.RefValue{xsum_small_accumulator}()
            xsum_small_init(acc)
            xsum_small_addv(acc, a)
            return xsum_small_round(acc)
        end
    else
        let acc = Base.RefValue{xsum_large_accumulator}()
            xsum_large_init(acc)
            if n ≤ typemax(Cint)
                xsum_large_addv(acc, a)
            else # libxsum needs arrays in typemax(Cint) chunks
                i = firstindex(a)
                l = i + typemax(Cint) - 1
                e = lastindex(a)
                while l ≤ e
                    xsum_large_addv(acc, @view a[i:l])
                    i = l + 1
                    l = i + typemax(Cint) - 1
                end
                xsum_large_addv(acc, @view a[i:e])
            end
            return xsum_large_round(acc)
        end
    end
end

end # module
