# Declarations mirroring the C declarations in xsum.h

struct xsum_small_accumulator
    chunk::NTuple{67,Int64}
    inf::Int64
    nan::Int64
    adds_until_propagate::Cint
end

struct xsum_large_accumulator
    chunk::NTuple{4096,UInt64}
    count::NTuple{4096,Int16}
    chunks_used::NTuple{64,UInt64}
    used_used::UInt64
    sacc::xsum_small_accumulator
end

# The following low-level functions do little checking of their arguments, e.g. they don't check
# that the array strides == 1 or that the dot product is of vectors with equal lengths.
for kind in ("xsum_small_", "xsum_large_")
    T = Symbol(kind, "accumulator")
    @eval begin
        $(Symbol(kind,"init"))(acc) =
            ccall(($(QuoteNode(Symbol(kind,"init"))),libxsum), Cvoid, (Ref{$T},), acc)
        $(Symbol(kind,"addv"))(acc, a::StridedVector{Float64}) =
            ccall(($(QuoteNode(Symbol(kind,"addv"))),libxsum), Cvoid, (Ref{$T},Ptr{Float64},Int), acc, a, length(a))
        $(Symbol(kind,"add_sqnorm"))(acc, a::StridedVector{Float64}) =
            ccall(($(QuoteNode(Symbol(kind,"add_sqnorm"))),libxsum), Cvoid, (Ref{$T},Ptr{Float64},Int), acc, a, length(a))
        $(Symbol(kind,"add_dot"))(acc, a::StridedVector{Float64}, b::StridedVector{Float64}) =
            ccall(($(QuoteNode(Symbol(kind,"add_dot"))),libxsum), Cvoid, (Ref{$T},Ptr{Float64},Ptr{Float64},Int), acc, a, b, length(a))
        $(Symbol(kind,"round"))(acc) =
            ccall(($(QuoteNode(Symbol(kind,"round"))),libxsum), Cdouble, (Ref{$T},), acc)
        $(Symbol(kind,"chunks_used"))(acc) =
            ccall(($(QuoteNode(Symbol(kind,"chunks_used"))),libxsum), Cint, (Ref{$T},), acc)
        $(Symbol(kind,"add_accumulator"))(accdest, accsrc) =
            ccall(($(QuoteNode(Symbol(kind,"add_accumulator"))),libxsum), Cvoid, (Ref{$T},Ref{$T}), accdest, accsrc)
        $(Symbol(kind,"add1"))(acc, x::Real) =
            ccall(($(QuoteNode(Symbol(kind,"add1"))),libxsum), Cvoid, (Ref{$T}, Cdouble), acc, x)
        $(Symbol(kind,"negate"))(acc) =
            ccall(($(QuoteNode(Symbol(kind,"negate"))),libxsum), Cvoid, (Ref{$T},), acc)
    end
end

xsum_large_to_small_accumulator(acc_small, acc_large) =
    ccall((:xsum_large_to_small_accumulator,libxsum), Cvoid, (Ref{xsum_small_accumulator}, Ref{xsum_large_accumulator}), acc_small, acc_large)
