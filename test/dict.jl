# This file is a part of Julia. License is MIT: https://julialang.org/license

using Random

@testset "Pair" begin
    p = Pair(10,20)
    @test p == (10=>20)
    @test isequal(p,10=>20)
    @test iterate(p)[1] == 10
    @test iterate(p, iterate(p)[2])[1] == 20
    @test iterate(p, iterate(p, iterate(p)[2])[2]) === nothing
    @test firstindex(p) == 1
    @test lastindex(p) == length(p) == 2
    @test Base.indexed_iterate(p, 1, nothing) == (10,2)
    @test Base.indexed_iterate(p, 2, nothing) == (20,3)
    @test (1=>2) < (2=>3)
    @test (2=>2) < (2=>3)
    @test !((2=>3) < (2=>3))
    @test (2=>3) < (4=>3)
    @test (1=>100) < (4=>1)
    @test p[1] == 10
    @test p[2] == 20
    @test_throws BoundsError p[3]
    @test_throws BoundsError p[false]
    @test p[true] == 10
    @test p[2.0] == 20
    @test p[0x01] == 10
    @test_throws InexactError p[2.3]
    @test first(p) == 10
    @test last(p) == 20
    @test eltype(p) == Int
    @test eltype(4 => 5.6) == Union{Int,Float64}
    @test vcat(1 => 2.0, 1.0 => 2) == [1.0 => 2.0, 1.0 => 2.0]
end

@testset "Dict" begin
    h = Dict()
    for i=1:10000
        h[i] = i+1
    end
    for i=1:10000
        @test (h[i] == i+1)
    end
    for i=1:2:10000
        delete!(h, i)
    end
    for i=1:2:10000
        h[i] = i+1
    end
    for i=1:10000
        @test (h[i] == i+1)
    end
    for i=1:10000
        delete!(h, i)
    end
    @test isempty(h)
    h[77] = 100
    @test h[77] == 100
    for i=1:10000
        h[i] = i+1
    end
    for i=1:2:10000
        delete!(h, i)
    end
    for i=10001:20000
        h[i] = i+1
    end
    for i=2:2:10000
        @test h[i] == i+1
    end
    for i=10000:20000
        @test h[i] == i+1
    end
    h = Dict{Any,Any}("a" => 3)
    @test h["a"] == 3
    h["a","b"] = 4
    @test h["a","b"] == h[("a","b")] == 4
    h["a","b","c"] = 4
    @test h["a","b","c"] == h[("a","b","c")] == 4

    @testset "eltype, keytype and valtype" begin
        @test eltype(h) == Pair{Any,Any}
        @test keytype(h) == Any
        @test valtype(h) == Any

        td = Dict{AbstractString,Float64}()
        @test eltype(td) == Pair{AbstractString,Float64}
        @test keytype(td) == AbstractString
        @test valtype(td) == Float64
        @test keytype(Dict{AbstractString,Float64}) === AbstractString
        @test valtype(Dict{AbstractString,Float64}) === Float64
    end
    # test rethrow of error in ctor
    @test_throws DomainError Dict((sqrt(p[1]), sqrt(p[2])) for p in zip(-1:2, -1:2))
end

let x = Dict(3=>3, 5=>5, 8=>8, 6=>6)
    pop!(x, 5)
    for k in keys(x)
        Dict{Int,Int}(x)
        @test k in [3, 8, 6]
    end
end

let z = Dict()
    get_KeyError = false
    try
        z["a"]
    catch _e123_
        get_KeyError = isa(_e123_,KeyError)
    end
    @test get_KeyError
end

_d = Dict("a"=>0)
@test isa([k for k in filter(x->length(x)==1, collect(keys(_d)))], Vector{String})

@testset "typeof" begin
    d = Dict(((1, 2), (3, 4)))
    @test d[1] === 2
    @test d[3] === 4
    d2 = Dict(1 => 2, 3 => 4)
    d3 = Dict((1 => 2, 3 => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == Dict{Int,Int}

    d = Dict(((1, 2), (3, "b")))
    @test d[1] === 2
    @test d[3] == "b"
    d2 = Dict(1 => 2, 3 => "b")
    d3 = Dict((1 => 2, 3 => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == Dict{Int,Any}

    d = Dict(((1, 2), ("a", 4)))
    @test d[1] === 2
    @test d["a"] === 4
    d2 = Dict(1 => 2, "a" => 4)
    d3 = Dict((1 => 2, "a" => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == Dict{Any,Int}

    d = Dict(((1, 2), ("a", "b")))
    @test d[1] === 2
    @test d["a"] == "b"
    d2 = Dict(1 => 2, "a" => "b")
    d3 = Dict((1 => 2, "a" => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == Dict{Any,Any}
end

@test_throws ArgumentError first(Dict())
@test first(Dict(:f=>2)) == (:f=>2)

@testset "constructing Dicts from iterators" begin
    d = @inferred Dict(i=>i for i=1:3)
    @test isa(d, Dict{Int,Int})
    @test d == Dict(1=>1, 2=>2, 3=>3)
    d = Dict(i==1 ? (1=>2) : (2.0=>3.0) for i=1:2)
    @test isa(d, Dict{Real,Real})
    @test d == Dict{Real,Real}(2.0=>3.0, 1=>2)

    # issue #39117
    @test Dict(t[1]=>t[2] for t in zip((1,"2"), (2,"2"))) == Dict{Any,Any}(1=>2, "2"=>"2")

    @testset "issue #33147" begin
        expected = try; Base._throw_dict_kv_error(); catch e; e; end
        @test_throws expected Dict(i for i in 1:2)
        @test_throws expected Dict(nothing for i in 1:2)
        @test_throws expected Dict(() for i in 1:2)
        @test_throws expected Dict((i, i, i) for i in 1:2)
        @test_throws expected Dict(nothing)
        @test_throws expected Dict((1,))
        @test_throws expected Dict(1:2)
        @test_throws expected Dict(((),))
        @test_throws expected IdDict(((),))
        @test_throws expected WeakKeyDict(((),))
        @test_throws expected IdDict(nothing)
        @test_throws expected WeakKeyDict(nothing)
        @test Dict(1:0) isa Dict
        @test Dict(()) isa Dict
        try
            Dict(i => error("$i") for i in 1:3)
        catch ex
            @test ex isa ErrorException
            @test length(Base.current_exceptions()) == 1
        end
    end
end

@testset "empty tuple ctor" begin
    h = Dict(())
    @test length(h) == 0
end

@testset "type of Dict constructed from varargs of Pairs" begin
    @test Dict(1=>1, 2=>2.0) isa Dict{Int,Real}
    @test Dict(1=>1, 2.0=>2) isa Dict{Real,Int}
    @test Dict(1=>1.0, 2.0=>2) isa Dict{Real,Real}

    for T in (Nothing, Missing)
        @test Dict(1=>1, 2=>T()) isa Dict{Int,Union{Int,T}}
        @test Dict(1=>T(), 2=>2) isa Dict{Int,Union{Int,T}}
        @test Dict(1=>1, T()=>2) isa Dict{Union{Int,T},Int}
        @test Dict(T()=>1, 2=>2) isa Dict{Union{Int,T},Int}
    end
end

@test_throws KeyError Dict("a"=>2)[Base.secret_table_token]

@testset "issue #1821" begin
    d = Dict{String, Vector{Int}}()
    d["a"] = [1, 2]
    @test_throws MethodError d["b"] = 1
    @test isa(repr(d), AbstractString)  # check that printable without error
end

@testset "issue #2344" begin
    local bar
    bestkey(d, key) = key
    bestkey(d::AbstractDict{K,V}, key) where {K<:AbstractString,V} = string(key)
    bar(x) = bestkey(x, :y)
    @test bar(Dict(:x => [1,2,5])) === :y
    @test bar(Dict("x" => [1,2,5])) == "y"
end

mutable struct I1438T
    id
end
import Base.hash
hash(x::I1438T, h::UInt) = hash(x.id, h)

@testset "issue #1438" begin
    seq = [26, 28, 29, 30, 31, 32, 33, 34, 35, 36, -32, -35, -34, -28, 37, 38, 39, 40, -30,
           -31, 41, 42, 43, 44, -33, -36, 45, 46, 47, 48, -37, -38, 49, 50, 51, 52, -46, -50, 53]
    xs = [ I1438T(id) for id = 1:53 ]
    s = Set()
    for id in seq
        if id > 0
            x = xs[id]
            push!(s, x)
            @test in(x, s)                 # check that x can be found
        else
            delete!(s, xs[-id])
        end
    end
end

@testset "equality" for eq in (isequal, ==)
    @test  eq(Dict(), Dict())
    @test  eq(Dict(1 => 1), Dict(1 => 1))
    @test !eq(Dict(1 => 1), Dict())
    @test !eq(Dict(1 => 1), Dict(1 => 2))
    @test !eq(Dict(1 => 1), Dict(2 => 1))

    # Generate some data to populate dicts to be compared
    data_in = [ (rand(1:1000), randstring(2)) for _ in 1:1001 ]

    # Populate the first dict
    d1 = Dict{Int, AbstractString}()
    for (k, v) in data_in
        d1[k] = v
    end
    data_in = collect(d1)
    # shuffle the data
    for i in 1:length(data_in)
        j = rand(1:length(data_in))
        data_in[i], data_in[j] = data_in[j], data_in[i]
    end
    # Inserting data in different (shuffled) order should result in
    # equivalent dict.
    d2 = Dict{Int, AbstractString}()
    for (k, v) in data_in
        d2[k] = v
    end

    @test eq(d1, d2)
    d3 = copy(d2)
    d4 = copy(d2)
    # Removing an item gives different dict
    delete!(d1, data_in[rand(1:length(data_in))][1])
    @test !eq(d1, d2)
    # Changing a value gives different dict
    d3[data_in[rand(1:length(data_in))][1]] = randstring(3)
    !eq(d1, d3)
    # Adding a pair gives different dict
    d4[1001] = randstring(3)
    @test !eq(d1, d4)

    @test eq(Dict(), sizehint!(Dict(),96))

    # Dictionaries of different types
    @test !eq(Dict(1 => 2), Dict("dog" => "bone"))
    @test eq(Dict{Int,Int}(), Dict{AbstractString,AbstractString}())
end

@testset "sizehint!" begin
    d = Dict()
    sizehint!(d, UInt(3))
    @test d == Dict()
    sizehint!(d, 5)
    @test isempty(d)
end

@testset "equality special cases" begin
    @test Dict(1=>0.0) == Dict(1=>-0.0)
    @test !isequal(Dict(1=>0.0), Dict(1=>-0.0))

    @test Dict(0.0=>1) != Dict(-0.0=>1)
    @test !isequal(Dict(0.0=>1), Dict(-0.0=>1))

    @test Dict(1=>NaN) != Dict(1=>NaN)
    @test isequal(Dict(1=>NaN), Dict(1=>NaN))

    @test Dict(NaN=>1) == Dict(NaN=>1)
    @test isequal(Dict(NaN=>1), Dict(NaN=>1))

    @test ismissing(Dict(1=>missing) == Dict(1=>missing))
    @test isequal(Dict(1=>missing), Dict(1=>missing))
    d = Dict(1=>missing)
    @test ismissing(d == d)
    d = Dict(1=>[missing])
    @test ismissing(d == d)
    d = Dict(1=>NaN)
    @test d != d
    @test isequal(d, d)

    @test Dict(missing=>1) == Dict(missing=>1)
    @test isequal(Dict(missing=>1), Dict(missing=>1))
end

@testset "get!" begin # (get with default values assigned to the given location)
    f(x) = x^2
    d = Dict(8=>19)
    @test get!(d, 8, 5) == 19
    @test get!(d, 19, 2) == 2

    @test get!(d, 42) do  # d is updated with f(2)
        f(2)
    end == 4

    @test get!(d, 42) do  # d is not updated
        f(200)
    end == 4

    @test get(d, 13) do   # d is not updated
        f(4)
    end == 16

    @test d == Dict(8=>19, 19=>2, 42=>4)
end

@testset "getkey" begin
   h = Dict(1=>2, 3 => 6, 5=>10)
   @test getkey(h, 1, 7) == 1
   @test getkey(h, 4, 6) == 6
   @test getkey(h, "1", 8) == 8
end

@testset "show" begin
    for d in (Dict("\n" => "\n", "1" => "\n", "\n" => "2"),
              Dict(string(i) => i for i = 1:30),
              Dict(reshape(1:i^2,i,i) => reshape(1:i^2,i,i) for i = 1:24),
              Dict(String(Char['α':'α'+i;]) => String(Char['α':'α'+i;]) for i = (1:10)*10),
              Dict("key" => zeros(0, 0)))
        for cols in (12, 40, 80), rows in (2, 10, 24)
            # Ensure output is limited as requested
            s = IOBuffer()
            io = Base.IOContext(s, :limit => true, :displaysize => (rows, cols))
            Base.show(io, MIME("text/plain"), d)
            out = split(String(take!(s)),'\n')
            for line in out[2:end]
                @test textwidth(line) <= cols
            end
            @test length(out) <= rows

            for f in (keys, values)
                s = IOBuffer()
                io = Base.IOContext(s, :limit => true, :displaysize => (rows, cols))
                Base.show(io, MIME("text/plain"), f(d))
                out = split(String(take!(s)),'\n')
                for line in out[2:end]
                    @test textwidth(line) <= cols
                end
                @test length(out) <= rows
            end
        end
        # Simply ensure these do not throw errors
        Base.show(IOBuffer(), d)
        @test !isempty(summary(d))
        @test !isempty(summary(keys(d)))
        @test !isempty(summary(values(d)))
    end
    # show on empty Dict
    io = IOBuffer()
    d = Dict{Int, String}()
    show(io, d)
    str = String(take!(io))
    @test str == "Dict{$(Int), String}()"
    close(io)
end


struct RainbowString
    s::String
    bold::Bool
    other::Bool
    valid::Bool
    offset::Int
end
RainbowString(s, bold=false, other=false, valid=true) = RainbowString(s, bold, other, valid, 0)

function Base.show(io::IO, rbs::RainbowString)
    for (i, s) in enumerate(rbs.s)
        if i ≤ rbs.offset
            print(io, s)
            continue
        end
        color = rbs.other ? string("\033[4", rand(1:7), 'm') : Base.text_colors[rand(0:255)]
        if rbs.bold
            printstyled(io, color, s; bold=true)
        else
            print(io, color, s)
        end
        if rbs.valid
            print(io, '\033', '[', rbs.other ? "0" : "39", 'm')  # end of color marker
        end
    end
end

@testset "Display with colors" begin
    d = Dict([randstring(8) => [RainbowString(randstring(8)) for i in 1:10] for j in 1:5]...)
    str = sprint(io -> show(io, MIME("text/plain"), d); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    lines = split(str, '\n')
    @test all(endswith("\033[0m…"), lines[2:end])
    @test all(x -> length(x) > 100, lines[2:end])

    d2 = Dict(:foo => RainbowString("bar"))
    str2 = sprint(io -> show(io, MIME("text/plain"), d2); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    @test !occursin('…', str2)
    @test endswith(str2, "\033[0m")

    d3 = Dict(:foo => RainbowString("bar", true))
    str3 = sprint(io -> show(io, MIME("text/plain"), d3); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    @test !occursin('…', str3)
    @test endswith(str3, "\033[0m")

    d4 = Dict(RainbowString(randstring(8), true) => nothing)
    str4 = sprint(io -> show(io, MIME("text/plain"), d4); context = (:displaysize=>(30,20), :color=>true, :limit=>true))
    @test endswith(str4, "\033[0m… => nothing")

    d5 = Dict(RainbowString(randstring(30), false, true, false) => nothing)
    str5 = sprint(io -> show(io, MIME("text/plain"), d5); context = (:displaysize=>(30,30), :color=>true, :limit=>true))
    @test endswith(str5, "\033[0m… => nothing")

    d6 = Dict(randstring(8) => RainbowString(randstring(30), true, true, false) for _ in 1:3)
    str6 = sprint(io -> show(io, MIME("text/plain"), d6); context = (:displaysize=>(30,30), :color=>true, :limit=>true))
    lines6 = split(str6, '\n')
    @test all(endswith("\033[0m…"), lines6[2:end])
    @test all(x -> length(x) > 100, lines6[2:end])
    str6_long = sprint(io -> show(io, MIME("text/plain"), d6); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    lines6_long = split(str6_long, '\n')
    @test all(endswith("\033[0m"), lines6_long[2:end])

    d7 = Dict(randstring(8) => RainbowString(randstring(30)))
    str7 = sprint(io -> show(io, MIME("text/plain"), d7); context = (:displaysize=>(30,20), :color=>true, :limit=>true))
    line7 = split(str7, '\n')[2]
    @test endswith(line7, "\033[0m…")
    @test length(line7) > 100

    d8 = Dict(:x => RainbowString(randstring(10), false, false, false, 6))
    str8 = sprint(io -> show(io, MIME("text/plain"), d8); context = (:displaysize=>(30,14), :color=>true, :limit=>true))
    line8 = split(str8, '\n')[2]
    @test !occursin("\033[", line8)
    @test length(line8) == 14
    str8_long = sprint(io -> show(io, MIME("text/plain"), d8); context = (:displaysize=>(30,16), :color=>true, :limit=>true))
    line8_long = split(str8_long, '\n')[2]
    @test endswith(line8_long, "\033[0m…")
    @test length(line8_long) > 20

    d9 = Dict(:x => RainbowString(repeat('苹', 5), false, true, false))
    str9 = sprint(io -> show(io, MIME("text/plain"), d9); context = (:displaysize=>(30,15), :color=>true, :limit=>true))
    @test endswith(str9, "\033[0m…")
    @test count('苹', str9) == 3

    d10 = Dict(:xy => RainbowString(repeat('苹', 5), false, true, false))
    str10 = sprint(io -> show(io, MIME("text/plain"), d10); context = (:displaysize=>(30,15), :color=>true, :limit=>true))
    @test endswith(str10, "\033[0m…")
    @test count('苹', str10) == 2

    d11 = Dict(RainbowString("abcdefgh", false, true, false) => 0, "123456" => 1)
    str11 = sprint(io -> show(io, MIME("text/plain"), d11); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    _, line11_a, line11_b = split(str11, '\n')
    @test endswith(line11_a, "h\033[0m => 0") || endswith(line11_b, "h\033[0m => 0")
    @test endswith(line11_a, "6\" => 1") || endswith(line11_b, "6\" => 1")

    d12 = Dict(RainbowString(repeat(Char(48+i), 4), (i&1)==1, (i&2)==2, (i&4)==4) => i for i in 1:8)
    str12 = sprint(io -> show(io, MIME("text/plain"), d12); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    @test !occursin('…', str12)

    d13 = Dict(RainbowString("foo\nbar") => 74)
    str13 = sprint(io -> show(io, MIME("text/plain"), d13); context = (:displaysize=>(30,80), :color=>true, :limit=>true))
    @test count('\n', str13) == 1
    @test occursin('…', str13)
end

@testset "Issue #15739" begin # Compact REPL printouts of an `AbstractDict` use brackets when appropriate
    d = Dict((1=>2) => (3=>45), (3=>10) => (10=>11))
    buf = IOBuffer()
    show(IOContext(buf, :compact => true), d)

    # Check explicitly for the expected strings, since the CPU bitness effects
    # dictionary ordering.
    result = String(take!(buf))
    @test occursin("Dict", result)
    @test occursin("(1=>2)=>(3=>45)", result)
    @test occursin("(3=>10)=>(10=>11)", result)
end

mutable struct Alpha end
Base.show(io::IO, ::Alpha) = print(io,"α")
@testset "issue #9463" begin
    sbuff = IOBuffer()
    io = Base.IOContext(sbuff, :limit => true, :displaysize => (10, 20))

    Base.show(io, MIME("text/plain"), Dict(Alpha()=>1))
    local str = String(take!(sbuff))
    @test !occursin("…", str)
    @test endswith(str, "α => 1")
end

@testset "issue #2540" begin
    d = Dict{Any,Any}(Dict(x => 1 for x in ['a', 'b', 'c']))
    @test d == Dict('a'=>1, 'b'=>1, 'c'=> 1)
end

@testset "issue #2629" begin
    d = Dict{AbstractString,AbstractString}(Dict(a=>"foo" for a in ["a","b","c"]))
    @test d == Dict("a"=>"foo","b"=>"foo","c"=>"foo")
end

@testset "issue #5886" begin
    d5886 = Dict()
    for k5886 in 1:11
       d5886[k5886] = 1
    end
    for k5886 in keys(d5886)
       # undefined ref if not fixed
       d5886[k5886] += 1
    end
end

@testset "issue #8877" begin
    a = Dict("foo" => 0.0, "bar" => 42.0)
    b = Dict("フー" => 17, "バー" => 4711)
    @test typeof(merge(a, b)) === Dict{String,Float64}
end

@testset "issue 9295" begin
    d = Dict()
    @test push!(d, 'a' => 1) === d
    @test d['a'] == 1
    @test push!(d, 'b' => 2, 'c' => 3) === d
    @test d['b'] == 2
    @test d['c'] == 3
    @test push!(d, 'd' => 4, 'e' => 5, 'f' => 6) === d
    @test d['d'] == 4
    @test d['e'] == 5
    @test d['f'] == 6
    @test length(d) == 6
end

mutable struct T10647{T}; x::T; end
@testset "issue #10647" begin
    a = IdDict()
    a[1] = a
    a[a] = 2
    a[3] = T10647(a)
    @test isequal(a, a)
    show(IOBuffer(), a)
    Base.show(Base.IOContext(IOBuffer(), :limit => true), a)
    Base.show(IOBuffer(), a)
    Base.show(Base.IOContext(IOBuffer(), :limit => true), a)
end

@testset "IdDict{Any,Any} and partial inference" begin
    a = IdDict{Any,Any}()
    a[1] = a
    a[a] = 2

    sa = empty(a)
    @test isempty(sa)
    @test isa(sa, IdDict{Any,Any})

    @test length(a) == 2
    @test 1 in keys(a)
    @test a in keys(a)
    @test a[1] === a
    @test a[a] === 2

    ca = copy(a)
    @test length(ca) == length(a)
    @test isequal(ca, a)
    @test ca !== a # make sure they are different objects

    ca = empty!(ca)
    @test length(ca) == 0
    @test length(a) == 2

    d = Dict('a'=>1, 'b'=>1, 'c'=> 3)
    @test a != d
    @test !isequal(a, d)

    @test length(IdDict{Any,Any}(1=>2, 1.0=>3)) == 2
    @test length(Dict(1=>2, 1.0=>3)) == 1

    d = @inferred IdDict{Any,Any}(i=>i for i=1:3)
    @test isa(d, IdDict{Any,Any})
    @test d == IdDict{Any,Any}(1=>1, 2=>2, 3=>3)

    d = @inferred IdDict{Any,Any}(Pair(1,1), Pair(2,2), Pair(3,3))
    @test isa(d, IdDict{Any,Any})
    @test d == IdDict{Any,Any}(1=>1, 2=>2, 3=>3)
    @test eltype(d) == Pair{Any,Any}

    d = IdDict{Any,Int32}(:hi => 7)
    let c = Ref{Any}(1.5)
        f() = c[]
        @test @inferred(get!(f, d, :hi)) === Int32(7)
        @test_throws InexactError(:Int32, Int32, 1.5) get!(f, d, :hello)
    end
end

@testset "IdDict" begin
    a = IdDict()
    a[1] = a
    a[a] = 2

    sa = empty(a)
    @test isempty(sa)
    @test isa(sa, IdDict)

    @test length(a) == 2
    @test 1 in keys(a)
    @test a in keys(a)
    @test a[1] === a
    @test a[a] === 2

    ca = copy(a)
    @test length(ca) == length(a)
    @test isequal(ca, a)
    @test ca !== a # make sure they are different objects

    ca = empty!(ca)
    @test length(ca) == 0
    @test length(a) == 2

    d = Dict('a'=>1, 'b'=>1, 'c'=> 3)
    @test a != d
    @test !isequal(a, d)

    @test length(IdDict(1=>2, 1.0=>3)) == 2
    @test length(Dict(1=>2, 1.0=>3)) == 1

    d = @inferred IdDict(i=>i for i=1:3)
    @test isa(d, IdDict)
    @test d == IdDict(1=>1, 2=>2, 3=>3)

    d = @inferred IdDict(Pair(1,1), Pair(2,2), Pair(3,3))
    @test isa(d, IdDict)
    @test d == IdDict(1=>1, 2=>2, 3=>3)
    @test eltype(d) == Pair{Int,Int}
    @test_throws KeyError d[:a]
    @test_throws TypeError d[:a] = 1
    @test_throws MethodError d[1] = :a

    # copy constructor
    d = IdDict(Pair(1,1), Pair(2,2), Pair(3,3))
    @test collect(values(IdDict{Int,Float64}(d))) == collect(values(d))
    @test_throws TypeError IdDict{Float64,Int}(d)

    # misc constructors
    @test typeof(IdDict(1=>1, :a=>2)) == IdDict{Any,Int}
    @test typeof(IdDict(1=>1, 1=>:a)) == IdDict{Int,Any}
    @test typeof(IdDict(:a=>1, 1=>:a)) == IdDict{Any,Any}
    @test typeof(IdDict(())) == IdDict{Any,Any}

    # check that returned values are inferred
    d = @inferred IdDict(Pair(1,1), Pair(2,2), Pair(3,3))
    @test 1 == @inferred d[1]
    @inferred setindex!(d, -1, 10)
    @test d[10] == -1
    @test 1 == @inferred d[1]
    @test get(d, -111, nothing) === nothing
    @test 1 == @inferred get(d, 1, 1)
    @test pop!(d, -111, nothing) === nothing
    @test 1 == @inferred pop!(d, 1)

    # get! and delete!
    d = @inferred IdDict(Pair(:a,1), Pair(:b,2), Pair(3,3))
    @test get!(d, "a", -1) == -1
    @test d["a"] == -1
    @test get!(d, "a", "b") == -1
    @test_throws MethodError get!(d, "b", "b")
    @test delete!(d, "a") === d
    @test !haskey(d, "a")
    @test_throws TypeError get!(IdDict{Symbol,Any}(), 2, "b")
    @test get!(IdDict{Int,Int}(), 1, 2.0) === 2
    @test get!(()->2.0, IdDict{Int,Int}(), 1) === 2

    # sizehint! & rehash!
    d = IdDict()
    @test sizehint!(d, 10^4) === d
    @test length(d.ht) >= 10^4
    d = IdDict()
    for jj=1:30, i=1:10^4
        d[i] = i
    end
    for i=1:10^4
        @test d[i] == i
    end
    @test length(d.ht) >= 10^4
    @test d === Base.rehash!(d, 123452) # number needs to be even

    # filter!
    d = IdDict(1=>1, 2=>3, 3=>2)
    filter!(x->isodd(x[2]), d)
    @test d[1] == 1
    @test d[2] == 3
    @test !haskey(d, 3)

    # not an iterator of tuples or pairs
    @test_throws ArgumentError IdDict([1, 2, 3, 4])
    # test rethrow of error in ctor
    @test_throws DomainError   IdDict((sqrt(p[1]), sqrt(p[2])) for p in zip(-1:2, -1:2))
end

@testset "issue 30165, get! for IdDict" begin
    f(x) = x^2
    d = IdDict(8=>19)
    @test get!(d, 8, 5) == 19
    @test get!(d, 19, 2) == 2

    @test get!(d, 42) do  # d is updated with f(2)
        f(2)
    end == 4

    @test get!(d, 42) do  # d is not updated
        f(200)
    end == 4

    @test get(d, 13) do   # d is not updated
        f(4)
    end == 16

    @test d == IdDict(8=>19, 19=>2, 42=>4)
end

@testset "issue #26833, deletion from IdDict" begin
    d = IdDict()
    i = 1
    # generate many hash collisions
    while length(d) < 32 # expected to occur at i <≈ 2^16 * 2^5
        if objectid(i) % UInt16 == 0x1111
            push!(d, i => true)
        end
        i += 1
    end
    k = collect(keys(d))
    @test haskey(d, k[1])
    delete!(d, k[1])
    @test length(d) == 31
    @test !haskey(d, k[1])
    @test haskey(d, k[end])
    push!(d, k[end] => false)
    @test length(d) == 31
    @test haskey(d, k[end])
    @test !pop!(d, k[end])
    @test !haskey(d, k[end])
    @test length(d) == 30
end


@testset "Issue #7944" begin
    d = Dict{Int,Int}()
    get!(d, 0) do
        d[0] = 1
    end
    @test length(d) == 1
end

@testset "iteration" begin
    d = Dict('a'=>1, 'b'=>1, 'c'=> 3)
    @test [d[k] for k in keys(d)] == [d[k] for k in eachindex(d)] ==
          [v for (k, v) in d] == [d[x[1]] for (i, x) in enumerate(d)]
end

@testset "consistency of dict iteration order (issue #56841)" begin
    dict = Dict(randn() => randn() for _ = 1:100)
    @test all(zip(dict, keys(dict), values(dict), pairs(dict))) do (d, k, v, p)
        d == p && first(d) == first(p) == k && last(d) == last(p) == v
    end
end

@testset "generators, similar" begin
    d = Dict(:a=>"a")
    # TODO: restore when 0.7 deprecation is removed
    #@test @inferred(map(identity, d)) == d
end

@testset "Issue 12451" begin
    @test_throws ArgumentError Dict(0)
    @test_throws ArgumentError Dict([1])
    @test_throws ArgumentError Dict([(1,2),0])
end

# test Dict constructor's argument checking (for an iterable of pairs or tuples)
# make sure other errors can propagate when the nature of the iterator is not the problem
@test_throws InexactError Dict(convert(Int,1.5) for i=1:1)
@test_throws InexactError WeakKeyDict(convert(Int,1.5) for i=1:1)

import Base.ImmutableDict
@testset "ImmutableDict" begin
    d = ImmutableDict{String, String}()
    k1 = "key1"
    k2 = "key2"
    v1 = "value1"
    v2 = "value2"
    d1 = ImmutableDict(d, k1 => v1)
    d2 = ImmutableDict(d1, k2 => v2)
    d3 = ImmutableDict(d2, k1 => v2)
    d4 = ImmutableDict(d3, k2 => v1)
    dnan = ImmutableDict{String, Float64}(k2, NaN)
    dnum = ImmutableDict(dnan, k2 => 1)
    f(x) = x^2

    @test isempty(collect(d))
    @test !isempty(collect(d1))
    @test isempty(d)
    @test !isempty(d1)
    @test length(d) == 0
    @test length(d1) == 1
    @test length(d2) == 2
    @test length(d3) == 3
    @test length(d4) == 4
    @test !(k1 in keys(d))
    @test k1 in keys(d1)
    @test k1 in keys(d2)
    @test k1 in keys(d3)
    @test k1 in keys(d4)

    @test !haskey(d, k1)
    @test haskey(d1, k1)
    @test haskey(d2, k1)
    @test haskey(d3, k1)
    @test haskey(d4, k1)
    @test !(k2 in keys(d1))
    @test k2 in keys(d2)
    @test !(k1 in values(d4))
    @test v1 in values(d4)
    @test collect(d1) == [Pair(k1, v1)]
    @test collect(d4) == reverse([Pair(k1, v1), Pair(k2, v2), Pair(k1, v2), Pair(k2, v1)])
    @test d1 == ImmutableDict(d, k1 => v1)
    @test !((k1 => v2) in d2)
    @test (k1 => v2) in d3
    @test (k1 => v1) in d4
    @test (k1 => v2) in d4
    @test in(k2 => "value2", d4, ===)
    @test in(k2 => v2, d4, ===)
    @test in(k2 => NaN, dnan, isequal)
    @test in(k2 => NaN, dnan, ===)
    @test !in(k2 => NaN, dnan, ==)
    @test !in(k2 => 1, dnum, ===)
    @test in(k2 => 1.0, dnum, ===)
    @test !in(k2 => 1, dnum, <)
    @test in(k2 => 0, dnum, <)
    @test get(d1, "key1", :default) === v1
    @test get(d4, "key1", :default) === v2
    @test get(d4, "foo", :default) === :default
    @test get(d, k1, :default) === :default
    @test get(d1, "key1") do
        f(2)
    end === v1
    @test get(d4, "key1") do
        f(4)
    end === v2
    @test get(d4, "foo") do
        f(6)
    end === 36
    @test get(d, k1) do
        f(8)
    end === 64
    @test d1["key1"] === v1
    @test d4["key1"] === v2
    @test empty(d3) === d
    @test empty(d) === d

    @test_throws KeyError d[k1]
    @test_throws KeyError d1["key2"]

    v = [k1 => v1, k2 => v2]
    d5 = ImmutableDict(v...)
    @test d5 == d2
    @test reverse(collect(d5)) == v
    d6 = ImmutableDict(:a => 1, :b => 3, :a => 2)
    @test d6[:a] == 2
    @test d6[:b] == 3

    @test !haskey(ImmutableDict(-0.0=>1), 0.0)
end

@testset "filtering" begin
    d = Dict(zip(1:1000,1:1000))
    f = p -> iseven(p.first)
    @test filter(f, d) == filter!(f, copy(d)) ==
          invoke(filter!, Tuple{Function,AbstractDict}, f, copy(d)) ==
          Dict(zip(2:2:1000, 2:2:1000))
    d = Dict(zip(-1:3,-1:3))
    f = p -> sqrt(p.second) > 2
    # test rethrowing error from f
    @test_throws DomainError filter(f, d)
end

struct MyString <: AbstractString
    str::String
end
struct MyInt <: Integer
    val::UInt
end

import Base.==
const global hashoffset = [UInt(190)]

Base.hash(s::MyString) = hash(s.str) + hashoffset[]
Base.lastindex(s::MyString) = lastindex(s.str)
Base.iterate(s::MyString, v::Int=1) = iterate(s.str, v)
Base.isequal(a::MyString, b::MyString) = isequal(a.str, b.str)
==(a::MyString, b::MyString) = (a.str == b.str)

Base.hash(v::MyInt) = v.val + hashoffset[]
Base.lastindex(v::MyInt) = lastindex(v.val)
Base.iterate(v::MyInt, i...) = iterate(v.val, i...)
Base.isequal(a::MyInt, b::MyInt) = isequal(a.val, b.val)
==(a::MyInt, b::MyInt) = (a.val == b.val)
@testset "issue #15077" begin
    let badKeys = [
        "FINO_emv5.0","FINO_ema0.1","RATE_ema1.0","NIBPM_ema1.0",
        "SAO2_emv5.0","O2FLOW_ema5.0","preop_Neuro/Psych_","gender_",
        "FIO2_ema0.1","PEAK_ema5.0","preop_Reproductive_denies","O2FLOW_ema0.1",
        "preop_Endocrine_denies","preop_Respiratory_",
        "NIBPM_ema0.1","PROPOFOL_MCG/KG/MIN_decay5.0","NIBPD_ema1.0","NIBPS_ema5.0",
        "anesthesiaStartTime","NIBPS_ema1.0","RESPRATE_ema1.0","PEAK_ema0.1",
        "preop_GU_denies","preop_Cardiovascular_","PIP_ema5.0","preop_ENT_denies",
        "preop_Skin_denies","preop_Renal_denies","asaCode_IIIE","N2OFLOW_emv5.0",
        "NIBPD_emv5.0", # <--- here is the key that we later can't find
        "NIBPM_ema5.0","preop_Respiratory_complete","ETCO2_ema5.0",
        "RESPRATE_ema0.1","preop_Functional Status_<2","preop_Renal_symptoms",
        "ECGRATE_ema5.0","FIO2_emv5.0","RESPRATE_emv5.0","7wu3ty0a4fs","BVO",
        "4UrCWXUsaT"
    ]
        local d = Dict{AbstractString,Int}()
        for i = 1:length(badKeys)
            d[badKeys[i]] = i
        end
        # Check all keys for missing values
        for i = 1:length(badKeys)
            @test d[badKeys[i]] == i
        end

        # Walk through all possible hash values (mod size of hash table)
        for offset = 0:1023
            local d2 = Dict{MyString,Int}()
            hashoffset[] = offset
            for i = 1:length(badKeys)
                d2[MyString(badKeys[i])] = i
            end
            # Check all keys for missing values
            for i = 1:length(badKeys)
                @test d2[MyString(badKeys[i])] == i
            end
        end
    end


    let badKeys = UInt16[0xb800,0xa501,0xcdff,0x6303,0xe40a,0xcf0e,0xf3df,0xae99,0x9913,0x741c,
                         0xd01f,0xc822,0x9723,0xb7a0,0xea25,0x7423,0x6029,0x202a,0x822b,0x492c,
                         0xd02c,0x862d,0x8f34,0xe529,0xf938,0x4f39,0xd03a,0x473b,0x1e3b,0x1d3a,
                         0xcc39,0x7339,0xcf40,0x8740,0x813d,0xe640,0xc443,0x6344,0x3744,0x2c3d,
                         0x8c48,0xdf49,0x5743]
        # Walk through all possible hash values (mod size of hash table)
        for offset = 0:1023
            local d2 = Dict{MyInt, Int}()
            hashoffset[] = offset
            for i = 1:length(badKeys)
                d2[MyInt(badKeys[i])] = i
            end
            # Check all keys for missing values
            for i = 1:length(badKeys)
                @test d2[MyInt(badKeys[i])] == i
            end
        end
    end
end

# #18213
Dict(1 => rand(2,3), 'c' => "asdf") # just make sure this does not trigger a deprecation

@testset "WeakKeyDict" begin
    A = [1]
    B = [2]
    C = [3]

    # construction
    wkd = WeakKeyDict()
    wkd[A] = 2
    wkd[B] = 3
    wkd[C] = 4
    dd = convert(Dict{Any,Any},wkd)
    @test WeakKeyDict(dd) == wkd
    @test convert(WeakKeyDict{Any, Any}, dd) == wkd
    @test isa(WeakKeyDict(dd), WeakKeyDict{Any,Any})
    @test WeakKeyDict(A=>2, B=>3, C=>4) == wkd
    @test isa(WeakKeyDict(A=>2, B=>3, C=>4), WeakKeyDict{Array{Int,1},Int})
    @test WeakKeyDict(a=>i+1 for (i,a) in enumerate([A,B,C]) ) == wkd
    @test WeakKeyDict([(A,2), (B,3), (C,4)]) == wkd
    @test WeakKeyDict{typeof(A), Int64}(Pair(A,2), Pair(B,3), Pair(C,4)) == wkd
    @test WeakKeyDict(Pair(A,2), Pair(B,3), Pair(C,4)) == wkd
    D = [[4.0]]
    @test WeakKeyDict(Pair(A,2), Pair(B,3), Pair(D,4.0)) isa WeakKeyDict{Any, Any}
    @test isa(WeakKeyDict(Pair(A,2), Pair(B,3.0), Pair(C,4)), WeakKeyDict{Array{Int,1},Any})
    @test isa(WeakKeyDict(Pair(convert(Vector{Number}, A),2), Pair(B,3), Pair(C,4)), WeakKeyDict{Any,Int})
    @test copy(wkd) == wkd

    @test length(wkd) == 3
    @test !isempty(wkd)
    res = pop!(wkd, C)
    @test res == 4
    @test length(wkd) == 2
    res = pop!(wkd, C, 3)
    @test res == 3
    @test C ∉ keys(wkd)
    @test 4 ∉ values(wkd)
    @test length(wkd) == 2
    @test !isempty(wkd)
    wkd = filter!( p -> p.first != B, wkd)
    @test B ∉ keys(wkd)
    @test 3 ∉ values(wkd)
    @test length(wkd) == 1
    @test WeakKeyDict(Pair(A, 2)) == wkd
    @test !isempty(wkd)

    wkd = empty!(wkd)
    @test wkd == empty(wkd)
    @test typeof(wkd) == typeof(empty(wkd))
    @test length(wkd) == 0
    @test isempty(wkd)
    @test isa(wkd, WeakKeyDict)

    @test_throws ArgumentError WeakKeyDict([1, 2, 3])

    wkd = WeakKeyDict(A=>1)
    @test delete!(wkd, A) == empty(wkd)
    @test delete!(wkd, A) === wkd

    # issue #26939
    d26939 = WeakKeyDict()
    (@noinline d -> d[big"1" + 1] = 1)(d26939)
    GC.gc() # primarily to make sure this doesn't segfault
    @test count(d26939) == 0
    @test length(d26939.ht) == 1
    @test length(d26939) == 0
    @test isempty(d26939)
    empty!(d26939)
    for i in 1:8
        (@noinline (d, i) -> d[big(i + 12345)] = 1)(d26939, i)
    end
    lock(GC.gc, d26939)
    @test length(d26939.ht) == 8
    @test count(d26939) == 0
    @test !haskey(d26939, nothing)
    @test_throws KeyError(nothing) d26939[nothing]
    @test_throws KeyError(nothing) get(d26939, nothing, 1)
    @test_throws KeyError(nothing) get(() -> 1, d26939, nothing)
    @test_throws KeyError(nothing) pop!(d26939, nothing)
    @test getkey(d26939, nothing, 321) === 321
    @test pop!(d26939, nothing, 321) === 321
    @test delete!(d26939, nothing) === d26939
    @test length(d26939.ht) == 8
    @test_throws ArgumentError d26939[nothing] = 1
    @test_throws ArgumentError get!(d26939, nothing, 1)
    @test_throws ArgumentError get!(() -> 1, d26939, nothing)
    @test isempty(d26939)
    @test length(d26939.ht) == 0
    @test length(d26939) == 0

    # WeakKeyDict does not convert keys on setting
    @test_throws ArgumentError WeakKeyDict{Vector{Int},Any}([5.0]=>1)
    wkd = WeakKeyDict(A=>2)
    @test_throws ArgumentError get!(wkd, [2.0], 2)
    @test get!(wkd, [1.0], 2) === 2

    # WeakKeyDict does convert on getting
    wkd = WeakKeyDict(A=>2)
    @test keytype(wkd)==Vector{Int}
    @test wkd[[1.0]] == 2
    @test haskey(wkd, [1.0])
    @test pop!(wkd, [1.0]) == 2
    @test get(()->3, wkd, [2.0]) == 3

    # map! on values of WKD
    wkd = WeakKeyDict(A=>2, B=>3)
    map!(v -> v-1, values(wkd))
    @test wkd == WeakKeyDict(A=>1, B=>2)

    # get!
    wkd = WeakKeyDict(A=>2)
    @test get!(wkd, B, 3) == 3
    @test wkd == WeakKeyDict(A=>2, B=>3)
    @test get!(()->4, wkd, C) == 4
    @test wkd == WeakKeyDict(A=>2, B=>3, C=>4)
    @test get!(()->5, wkd, [1.0]) == 2

    GC.@preserve A B C D nothing
end

import Base.PersistentDict
@testset "PersistentDict" begin
    @testset "HAMT HashState" begin
        key = :key
        h = Base.HAMT.HashState(key)
        h1 = Base.HAMT.HashState(key, objectid(key), 0, 0)
        h2 = Base.HAMT.HashState(h, key) # reconstruct
        @test h.hash == h1.hash
        @test h.hash == h2.hash

        hs = Base.HAMT.next(h1)
        @test hs.depth == 1
        recompute_depth = (Base.HAMT.MAX_SHIFT ÷ Base.HAMT.BITS_PER_LEVEL) + 1
        for i in 2:recompute_depth
            hs = Base.HAMT.next(hs)
            @test hs.depth == i
        end
        @test hs.depth == recompute_depth
        @test hs.shift == 0
        hsr = Base.HAMT.HashState(hs, key)
        @test hs.hash == hsr.hash
        @test hs.depth == hsr.depth
        @test hs.shift == hsr.shift

        @test Core.Compiler.is_removable_if_unused(Base.infer_effects(Base.HAMT.init_hamt, (Type{Vector{Any}},Type{Int},Vector{Any},Int)))
        @test Core.Compiler.is_removable_if_unused(Base.infer_effects(Base.HAMT.HAMT{Vector{Any},Int}, (Pair{Vector{Any},Int},)))
    end
    @testset "basics" begin
        dict = PersistentDict{Int, Int}()
        @test_throws KeyError dict[1]
        @test length(dict) == 0
        @test isempty(dict)

        dict = PersistentDict{Int, Int}(1=>2.0)
        @test dict[1] == 2

        dict = PersistentDict(1=>2)
        @test dict[1] == 2

        dict = PersistentDict(dict, 1=>3.0)
        @test dict[1] == 3

        dict = PersistentDict(dict, 1, 1)
        @test dict[1] == 1
        @test get(dict, 2, 1) == 1
        @test get(()->1, dict, 2) == 1

        @test (1 => 1) ∈ dict
        @test (1 => 2) ∉ dict
        @test (2 => 1) ∉ dict

        @test haskey(dict, 1)
        @test !haskey(dict, 2)

        dict2 = PersistentDict{Int, Int}(dict, 1=>2)
        @test dict[1] == 1
        @test dict2[1] == 2

        dict3 = Base.delete(dict2, 1)
        @test_throws KeyError dict3[1]
        @test dict3 == Base.delete(dict3, 1)
        @test dict3.trie != Base.delete(dict3, 1).trie

        dict = PersistentDict(dict, 1, 3)
        @test dict[1] == 3
        @test dict2[1] == 2

        @test length(dict) == 1
        @test length(dict2) == 1

        dict = PersistentDict(1=>2, 2=>3, 4=>1)
        @test eltype(dict) == Pair{Int, Int}
        @test dict[1] == 2
        @test dict[2] == 3
        @test dict[4] == 1
    end

    @testset "objectid" begin
        c = [0]
        dict = PersistentDict{Any, Int}(c => 1, [1] => 2)
        @test dict[c] == 1
        c[1] = 1
        @test dict[c] == 1

        c[1] = 0
        dict = PersistentDict{Any, Int}((c,) => 1, ([1],) => 2)
        @test dict[(c,)] == 1

        c[1] = 1
        @test dict[(c,)] == 1
    end

    @testset "stress" begin
        N = 2^14
        dict = PersistentDict{Int, Int}()
        for i in 1:N
            dict = PersistentDict(dict, i, i)
        end
        @test length(dict) == N
        length(collect(dict)) == N
        values = sort!(collect(dict))
        @test values[1] == (1=>1)
        @test values[end] == (N=>N)

        dict = Base.delete(dict, 16384)
        @test !haskey(dict, 16384)
        for i in 1:N
            dict = Base.delete(dict, i)
        end
        @test isempty(dict)
    end
end

@testset "issue #19995, hash of dicts" begin
    @test hash(Dict(Dict(1=>2) => 3, Dict(4=>5) => 6)) != hash(Dict(Dict(4=>5) => 3, Dict(1=>2) => 6))
    a = Dict(Dict(3 => 4, 2 => 3) => 2, Dict(1 => 2, 5 => 6) => 1)
    b = Dict(Dict(1 => 2, 2 => 3, 5 => 6) => 1, Dict(3 => 4) => 2)
    @test hash(a) != hash(b)
end

mutable struct Foo_15776
    x::Vector{Pair{Tuple{Function, Vararg{Int}}, Int}}
end
@testset "issue #15776, convert for pair" begin
    z = [Pair((+,1,5,7), 3), Pair((-,6,5,3,5,8), 1)]
    f = Foo_15776(z)
    @test f.x[1].first == (+, 1, 5, 7)
    @test f.x[1].second == 3
    @test f.x[2].first == (-, 6, 5, 3, 5, 8)
    @test f.x[2].second == 1
end

@testset "issue #18708 error type for dict constructor" begin
    @test_throws UndefVarError Dict(x => y for x in 1:10)
end

mutable struct Error19179 <: Exception
end

@testset "issue #19179 throwing error in dict constructor" begin
    @test_throws Error19179 Dict(i => throw(Error19179()) for i in 1:10)
end

# issue #18090
let
    d = Dict(i => i^2 for i in 1:10_000)
    z = zip(keys(d), values(d))
    for (pair, tupl) in zip(d, z)
        @test pair[1] == tupl[1] && pair[2] == tupl[2]
    end
end

struct NonFunctionCallable end
(::NonFunctionCallable)(args...) = +(args...)

@testset "Dict merge" begin
    d1 = Dict("A" => 1, "B" => 2)
    d2 = Dict("B" => 3.0, "C" => 4.0)
    @test @inferred merge(d1, d2) == Dict("A" => 1, "B" => 3, "C" => 4)
    # merge with combiner function
    @test @inferred mergewith(+, d1, d2) == Dict("A" => 1, "B" => 5, "C" => 4)
    @test @inferred mergewith(*, d1, d2) == Dict("A" => 1, "B" => 6, "C" => 4)
    @test @inferred mergewith(-, d1, d2) == Dict("A" => 1, "B" => -1, "C" => 4)
    @test @inferred mergewith(NonFunctionCallable(), d1, d2) == Dict("A" => 1, "B" => 5, "C" => 4)
    @test foldl(mergewith(+), [d1, d2]; init=Dict{Union{},Union{}}()) ==
        Dict("A" => 1, "B" => 5, "C" => 4)
    # backward compatibility
    @test @inferred merge(+, d1, d2) == Dict("A" => 1, "B" => 5, "C" => 4)
end

@testset "Dict merge!" begin
    d1 = Dict("A" => 1, "B" => 2)
    d2 = Dict("B" => 3, "C" => 4)
    @inferred merge!(d1, d2)
    @test d1 == Dict("A" => 1, "B" => 3, "C" => 4)
    # merge! with combiner function
    @inferred mergewith!(+, d1, d2)
    @test d1 == Dict("A" => 1, "B" => 6, "C" => 8)
    @inferred mergewith!(*, d1, d2)
    @test d1 == Dict("A" => 1, "B" => 18, "C" => 32)
    @inferred mergewith!(-, d1, d2)
    @test d1 == Dict("A" => 1, "B" => 15, "C" => 28)
    @inferred mergewith!(NonFunctionCallable(), d1, d2)
    @test d1 == Dict("A" => 1, "B" => 18, "C" => 32)
    @test foldl(mergewith!(+), [d1, d2]; init=empty(d1)) ==
        Dict("A" => 1, "B" => 21, "C" => 36)
    # backward compatibility
    merge!(+, d1, d2)
    @test d1 == Dict("A" => 1, "B" => 21, "C" => 36)
end

@testset "Dict reduce merge" begin
    function check_merge(i::Vector{<:Dict}, o)
        r1 = reduce(merge, i)
        r2 = merge(i...)
        t = typeof(o)
        @test r1 == o
        @test r2 == o
        @test typeof(r1) == t
        @test typeof(r2) == t
    end
    check_merge([Dict(1=>2), Dict(1.0=>2.0)], Dict(1.0=>2.0))
    check_merge([Dict(1=>2), Dict(2=>Complex(1.0, 1.0))],
      Dict(2=>Complex(1.0, 1.0), 1=>Complex(2.0, 0.0)))
    check_merge([Dict(1=>2), Dict(3=>4)], Dict(3=>4, 1=>2))
    check_merge([Dict(3=>4), Dict(:a=>5)], Dict(:a => 5, 3 => 4))
end

@testset "AbstractDict mergewith!" begin
# we use IdDict to test the mergewith! implementation for AbstractDict
    d1 = IdDict(1 => 1, 2 => 2)
    d2 = IdDict(2 => 3, 3 => 4)
    d3 = IdDict{Int, Float64}(1 => 5, 3 => 6)
    d = copy(d1)
    @inferred mergewith!(-, d, d2)
    @test d == IdDict(1 => 1, 2 => -1, 3 => 4)
    d = copy(d1)
    @inferred mergewith!(-, d, d3)
    @test d == IdDict(1 => -4, 2 => 2, 3 => 6)
    d = copy(d1)
    @inferred mergewith!(+, d, d2, d3)
    @test d == IdDict(1 => 6, 2 => 5, 3 => 10)
    @inferred mergewith(+, d1, d2, d3)
    d = mergewith(+, d1, d2, d3)
    @test d isa Dict{Int, Float64}
    @test d == Dict(1 => 6, 2 => 5, 3 => 10)
end

@testset "misc error/io" begin
    d = Dict('a'=>1, 'b'=>1, 'c'=> 3)
    @test_throws ErrorException 'a' in d
    key_str = sprint(show, keys(d))
    @test 'a' ∈ key_str
    @test 'b' ∈ key_str
    @test 'c' ∈ key_str
end

@testset "Dict pop!" begin
    d = Dict(1=>2, 3=>4)
    @test pop!(d, 1) == 2
    @test_throws KeyError pop!(d, 1)
    @test pop!(d, 1, 0) == 0
    @test pop!(d) == (3=>4)
    @test_throws ArgumentError pop!(d)
end

@testset "keys as a set" begin
    d = Dict(1=>2, 3=>4)
    @test keys(d) isa AbstractSet
    @test empty(keys(d)) isa AbstractSet
    let i = keys(d) ∩ Set([1,2])
        @test i isa AbstractSet
        @test i == Set([1])
    end
    @test Set(string(k) for k in keys(d)) == Set(["1","3"])
end

@testset "find" begin
    @test findall(isequal(1), Dict(:a=>1, :b=>2)) == [:a]
    @test sort(findall(isequal(1), Dict(:a=>1, :b=>1))) == [:a, :b]
    @test isempty(findall(isequal(1), Dict()))
    @test isempty(findall(isequal(1), Dict(:a=>2, :b=>3)))

    @test findfirst(isequal(1), Dict(:a=>1, :b=>2)) === :a
    @test findfirst(isequal(1), Dict(:a=>1, :b=>1, :c=>3)) in (:a, :b)
    @test findfirst(isequal(1), Dict()) === nothing
    @test findfirst(isequal(1), Dict(:a=>2, :b=>3)) === nothing
end

@testset "Dict printing with limited rows" begin
    local buf
    buf = IOBuffer()
    io = IOContext(buf, :displaysize => (4, 80), :limit => true)
    d = Base.ImmutableDict(1=>2)
    show(io, MIME"text/plain"(), d)
    @test String(take!(buf)) == "Base.ImmutableDict{$Int, $Int} with 1 entry: …"
    show(io, MIME"text/plain"(), keys(d))
    @test String(take!(buf)) ==
        "KeySet for a Base.ImmutableDict{$Int, $Int} with 1 entry. Keys: …"

    io = IOContext(io, :displaysize => (5, 80))
    show(io, MIME"text/plain"(), d)
    @test String(take!(buf)) == "Base.ImmutableDict{$Int, $Int} with 1 entry:\n  1 => 2"
    show(io, MIME"text/plain"(), keys(d))
    @test String(take!(buf)) ==
        "KeySet for a Base.ImmutableDict{$Int, $Int} with 1 entry. Keys:\n  1"
    d = Base.ImmutableDict(d, 3=>4)
    show(io, MIME"text/plain"(), d)
    @test String(take!(buf)) == "Base.ImmutableDict{$Int, $Int} with 2 entries:\n  ⋮ => ⋮"
    show(io, MIME"text/plain"(), keys(d))
    @test String(take!(buf)) ==
        "KeySet for a Base.ImmutableDict{$Int, $Int} with 2 entries. Keys:\n  ⋮"

    io = IOContext(io, :displaysize => (6, 80))
    show(io, MIME"text/plain"(), d)
    @test String(take!(buf)) ==
        "Base.ImmutableDict{$Int, $Int} with 2 entries:\n  3 => 4\n  1 => 2"
    show(io, MIME"text/plain"(), keys(d))
    @test String(take!(buf)) ==
        "KeySet for a Base.ImmutableDict{$Int, $Int} with 2 entries. Keys:\n  3\n  1"
    d = Base.ImmutableDict(d, 5=>6)
    show(io, MIME"text/plain"(), d)
    @test String(take!(buf)) ==
        "Base.ImmutableDict{$Int, $Int} with 3 entries:\n  5 => 6\n  ⋮ => ⋮"
    show(io, MIME"text/plain"(), keys(d))
    @test String(take!(buf)) ==
        "KeySet for a Base.ImmutableDict{$Int, $Int} with 3 entries. Keys:\n  5\n  ⋮"
end

@testset "copy!" begin
    s = Dict(1=>2, 2=>3)
    for a = ([3=>4], [0x3=>0x4], [3=>4, 5=>6, 7=>8], Pair{UInt,UInt}[3=>4, 5=>6, 7=>8])
        @test s === copy!(s, Dict(a)) == Dict(a)
        if length(a) == 1 # current limitation of Base.ImmutableDict
            @test s === copy!(s, Base.ImmutableDict(a[])) == Dict(a[])
        end
    end
    s2 = copy(s)
    @test copy!(s, s) == s2
end

@testset "map!(f, values(dict))" begin
    @testset "AbstractDict & Fallback" begin
        mutable struct TestDict{K, V}  <: AbstractDict{K, V}
            dict::Dict{K, V}
            function TestDict(args...)
                d = Dict(args...)
                new{keytype(d), valtype(d)}(d)
            end
        end
        Base.setindex!(td::TestDict, args...) = setindex!(td.dict, args...)
        Base.getindex(td::TestDict, args...) = getindex(td.dict, args...)
        Base.pairs(D::TestDict) = pairs(D.dict)
        testdict = TestDict(:a=>1, :b=>2)
        map!(v->v-1, values(testdict))
        @test testdict[:a] == 0
        @test testdict[:b] == 1
        @test sizehint!(testdict, 1) === testdict
    end
    @testset "Dict" begin
        testdict = Dict(:a=>1, :b=>2)
        map!(v->v-1, values(testdict))
        @test testdict[:a] == 0
        @test testdict[:b] == 1
    end
end

# WeakKeyDict soundness (#38727)
mutable struct ComparesWithGC38727
    i::Int
end
const armed = Ref{Bool}(true)
@noinline fwdab38727(a, b) = invoke(Base.isequal, Tuple{Any, WeakRef}, a, b)
function Base.isequal(a::ComparesWithGC38727, b::WeakRef)
    # This GC.gc() here simulates a GC during compilation in the original issue
    armed[] && GC.gc()
    armed[] = false
    fwdab38727(a, b)
end
Base.isequal(a::WeakRef, b::ComparesWithGC38727) = isequal(b, a)
Base.:(==)(a::ComparesWithGC38727, b::ComparesWithGC38727) = a.i == b.i
Base.hash(a::ComparesWithGC38727, u::UInt) = Base.hash(a.i, u)
function make_cwgc38727(wkd, i)
    f = ComparesWithGC38727(i)
    function fin(f)
        f.i = -1
    end
    finalizer(fin, f)
    f
end
@noinline mk38727(wkd) = wkd[make_cwgc38727(wkd, 1)] = nothing
function bar()
    wkd = WeakKeyDict{Any, Nothing}()
    mk38727(wkd)
    armed[] = true
    z = getkey(wkd, ComparesWithGC38727(1), missing)
end
# Run this twice, in case compilation the first time around
# masks something.
let c = bar()
    @test c === missing || c == ComparesWithGC38727(1)
end
let c = bar()
    @test c === missing || c == ComparesWithGC38727(1)
end

@testset "shrinking" begin
    d = Dict(i => i for i = 1:1000)
    filter!(x -> x.first < 10, d)
    sizehint!(d, 10)
    @test length(d.slots) < 100
    sizehint!(d, 1000)
    sizehint!(d, 1; shrink = false)
    @test length(d.slots) >= 1000
    sizehint!(d, 1; shrink = true)
    @test length(d.slots) < 1000
end

# getindex is :effect_free and :terminates but not :consistent
for T in (Int, Float64, String, Symbol)
    @testset let T=T
        @test !Core.Compiler.is_consistent(Base.infer_effects(getindex, (Dict{T,Any}, T)))
        @test Core.Compiler.is_effect_free(Base.infer_effects(getindex, (Dict{T,Any}, T)))
        @test !Core.Compiler.is_nothrow(Base.infer_effects(getindex, (Dict{T,Any}, T)))
        @test Core.Compiler.is_terminates(Base.infer_effects(getindex, (Dict{T,Any}, T)))
    end
end

struct BadHash
    i::Int
end
Base.hash(::BadHash, ::UInt)=UInt(1)
@testset "maxprobe reset #51595" begin
    d = Dict(BadHash(i)=>nothing for i in 1:20)
    empty!(d)
    sizehint!(d, 0)
    @test d.maxprobe < length(d.keys)
    d[BadHash(1)]=nothing
    @test !(BadHash(2) in keys(d))
    d = Dict(BadHash(i)=>nothing for i in 1:20)
    for _ in 1:20
        pop!(d)
    end
    sizehint!(d, 0)
    @test d.maxprobe < length(d.keys)
    d[BadHash(1)]=nothing
    @test !(BadHash(2) in keys(d))
end

# Issue #52066
let d = Dict()
    d[1] = 'a'
    d[1.0] = 'b'
    @test only(d) === Pair{Any,Any}(1.0, 'b')
end

@testset "UnionAll `keytype` and `valtype` (issue #53115)" begin
    K = Int8
    V = Int16
    dicts = (
        AbstractDict, IdDict, Dict, WeakKeyDict, Base.ImmutableDict,
        Base.PersistentDict, Iterators.Pairs
    )

    @testset "D: $D" for D ∈ dicts
        @test_throws MethodError keytype(D)
        @test_throws MethodError keytype(D{<:Any,V})
        @test                    keytype(D{K      }) == K
        @test                    keytype(D{K,    V}) == K

        @test_throws MethodError valtype(D)
        @test                    valtype(D{<:Any,V}) == V
        @test_throws MethodError valtype(D{K      })
        @test                    valtype(D{K,    V}) == V
    end
end
