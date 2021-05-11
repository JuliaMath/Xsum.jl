module Xsum

export xsum, XAccumulator

using xsum_jll

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
XAccumulator(s::XAccumulator) = XAccumulator(Ref(s.acc[]))
Base.float(s::XAccumulator) = xsum_small_round(s.acc)
XAccumulator(init::Real) = accumulate!(XAccumulator(), init)
Base.show(io::IO, s::XAccumulator) = print(io, "XAccumulator(", float(s), ")")

"""
    accumulate!(s::XAccumulator, x::Real)

Add `Float64(x)` to the accumulated sum `s`, with the sum performed in (effectively) infinite precision.
"""
Base.accumulate!(s::XAccumulator, x::Real) = begin; xsum_small_add1(s.acc, x); s; end

function Base.accumulate!(s::XAccumulator, s′::XAccumulator)
    xsum_small_add_accumulator(s.acc, s′.acc)
    return s
end

function Base.sum(a::AbstractVector{XAccumulator})
    s = XAccumulator()
    for s′ in a
        accumulate!(s, s′)
    end
    return s
end

# slower out-of-place variants for completeness
Base.:+(s::XAccumulator, s′::XAccumulator) = accumulate!(XAccumulator(s), s′)
Base.:+(s::XAccumulator, x::Real) = accumulate!(XAccumulator(s), x)
Base.:+(x::Real, s::XAccumulator) = s + x

function Base.accumulate!(s::XAccumulator, a::StridedVector{Float64})
    if stride(a,1) != 1
        for x in a
            accumulate!(s, x)
        end
    else
        n = length(a)
        if n < 256 # empirical threshold for small accumulator to be faster
            xsum_small_addv(s.acc, a)
        else
            acc = Base.RefValue{xsum_small_accumulator}()
            xsum_large_to_small_accumulator(acc, _xsum_large(a))
            xsum_small_add_accumulator(s.acc, acc)
        end
    end
    return s
end

Base.accumulate!(s::Complex{XAccumulator}, x::Complex) = Complex(accumulate!(real(s), real(x)), accumulate!(imag(s), imag(x)))
Base.accumulate!(s::Complex{XAccumulator}, x::Real) = Complex(accumulate!(real(s), x), imag(s))
Base.accumulate!(s::XAccumulator, x::Complex) = Complex(accumulate!(s, real(x)), XAccumulator(imag(x)))
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
        s = accumulate!(s, f(v))
    end
end

xsum(itr) = xsum(identity, itr)

function _xsum_large(a::StridedVector{Float64})
    @assert stride(a,1) == 1
    acc = Base.RefValue{xsum_large_accumulator}()
    xsum_large_init(acc)
    if length(a) ≤ typemax(Cint)
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
    return acc
end

function xsum(a::StridedVector{Float64})
    stride(a,1) != 1 && return xsum(identity, a)
    n = length(a)
    if n < 256 # empirical threshold for small accumulator to be faster
        let acc = Base.RefValue{xsum_small_accumulator}()
            xsum_small_init(acc)
            xsum_small_addv(acc, a)
            return xsum_small_round(acc)
        end
    else
        return xsum_large_round(_xsum_large(a))
    end
end

end # module
