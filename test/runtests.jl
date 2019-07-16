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
    end
end

