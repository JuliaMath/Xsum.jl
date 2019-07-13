using Xsum, Test, Random

Random.seed!(314159)
setprecision(65536)

@testset "xsum" begin
    for n in (100, 10^4)
        a = randn(n)
        exact = Float64.(sum(big.(a)))
        @test exact == xsum(a)

        A = [a a]
        @test exact == xsum(@view A[:,1])
        @test exact == xsum(@view Array(A')[1,:])

        @test 2*exact == xsum(2*x for x in a)
    end
end

