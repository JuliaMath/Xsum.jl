using Xsum, Test, Random

Random.seed!(314159)
setprecision(65536)

@testset "xsum" begin
    for n in (100, 10^4)
        a = randn(n)
        exact = Float64(sum(big.(a)))
        @test exact == xsum(a)

        A = [a a]
        @test exact == xsum(@view A[:,1])
        @test exact == xsum(@view Array(A')[1,:])

        @test 2exact == xsum(2x for x in a) == xsum(x -> 2x, a)

        @test Complex(2exact, 4exact) == xsum(Complex(2x,4x) for x in a)

        @test Complex(2exact, 4exact) == xsum(Iterators.flatten((a, Complex(x,4x) for x in a)))
    end
end

@testset "XAccumulator" begin
    for n in (100, 10^4)
        a = randn(n)
        exact = Float64(sum(big.(a)))
        @test exact == xsum(a)

        s1 = accumulate!(XAccumulator(), a[1:n÷2])
        s2 = accumulate!(XAccumulator(), a[(n÷2)+1:end])
        @test exact == float(s1 + s2) == float(sum([s1,s2]))
        @test exact == float(accumulate!(s1, s2))
        @test exact == float(accumulate!(XAccumulator(), a[2:end]) + a[1]) ==
                       float(a[1] + accumulate!(XAccumulator(), a[2:end]))
    end
end


