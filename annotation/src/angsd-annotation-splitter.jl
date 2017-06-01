#!/usr/bin/env julia
# julia -e 'for p in ["Bio", "Iterators", "DataStructures", "Libz", "ArgParse"] Pkg.add(p) end'
module AngsdAnnoSplit

import Bio.Intervals: Interval, GFF3, IntervalCollection, eachoverlap
import Iterators: imap
import DataStructures: counter
import Libz: ZlibInflateInputStream, ZlibDeflateOutputStream

function load_intervaltree(filename)
    stream = open(filename, "r")
    if endswith(filename, ".gz")
        stream = ZlibInflateInputStream(stream)
    end
    return IntervalCollection(GFF3.Reader(stream))
end


immutable AngsdLocus
    chrom::String
    pos::Int
    genotypes::Vector{String}
end

function AngsdLocus(s::String)
    s = rstrip(s)
    cols = split(s, '\t')
    return AngsdLocus(cols[1], parse(Int, cols[2]), cols[3:end])
end

Interval(loc::AngsdLocus) = Interval(loc.chrom, loc.pos, loc.pos)

function Base.write(io::IO, loc::AngsdLocus)
    write(io, loc.chrom, '\t')
    print(io, loc.pos, '\t')
    join(io, loc.genotypes, '\t')
    write(io, '\n')
end

Base.show(io::IO, loc::AngsdLocus) = write(io, loc)


function featuretype(loc::AngsdLocus, anno::IntervalCollection)
    i = Interval(loc)
    try
        feats = map(x -> GFF3.featuretype(x.metadata), eachoverlap(anno, i))
        if "CDS" in feats
            return "coding"
        elseif "mRNA" in feats
            return "noncoding"
        else
            return "intergenic"
        end
    catch x
        # Not found
        return "intergenic"
    end
end

function Base.basename(path::String, ext::String)
    bn = basename(path)
    if endswith(bn, ext)
        bn = bn[1:length(bn)-length(ext)]
    end
    return bn
end

function assign_features(genofile::String, annofile::String;
                         outdir::Nullable{String}=Nullable{String}(),
                         silent::Bool=false, writebed::Bool=false)

    anno = load_intervaltree(annofile)
    if !silent println(STDERR, "Annotation loaded") end

    if isnull(outdir) outdir = dirname(genofile) end
    if !isdir(get(outdir)) mkdir(get(outdir)) end

    genobase = get(outdir) * "/" * basename(genofile, ".geno.gz")
    outgenos = Dict{String, Any}(
            "coding" => open("$(genobase)_coding.geno.gz", "w") |> ZlibDeflateOutputStream,
            "noncoding" => open("$(genobase)_noncoding.geno.gz", "w") |> ZlibDeflateOutputStream,
            "intergenic" => open("$(genobase)_intergenic.geno.gz", "w") |> ZlibDeflateOutputStream,
    )
    bedout = writebed ? open("$genobase.bed.gz", "w") |> ZlibDeflateOutputStream : nothing

    genos = open(genofile) |> ZlibInflateInputStream

    ctr = counter(String)
    if !silent println(STDERR, "Assigning Loci") end
    for (i, loc) in enumerate(imap(AngsdLocus, eachline(genos)))
        feattype = featuretype(loc, anno)
        write(outgenos[feattype], loc)
        push!(ctr, feattype)
        if i % 100000 == 0 && !silent
            println(STDERR, "   ... $(i) loci processed")
        end

        if writebed
            println(bedout, "$(loc.chrom)\t$(loc.pos-1)\t$(loc.pos)\t$feattype")
        end
    end
    if !silent println(STDERR, "Done") end
    # Close files
    foreach(close, values(outgenos))
    return ctr
end


using ArgParse

function main()
    ap = ArgParseSettings()
    @add_arg_table ap begin
        "--annotation"
            help="GFF3 exon-level genome annotation"
            required=true
            arg_type=String
        "--outdir"
            help="Output directory"
            required=false
            arg_type=Nullable{String}
            default=Nullable{String}()
        "--writebed"
            help="Write a BED of loci and feature types"
            action=:store_true
        "--quiet"
            help="Don't print logging"
            action=:store_true
        "genofile"
            help="ANGSD .geno.gz file of genotypes"
            arg_type=String
            required=true
    end
    args = parse_args(ap)

    assign_features(args["genofile"], args["annotation"],
                    outdir=args["outdir"], silent=args["quiet"],
                    writebed=args["writebed"])
end

end # module AngsdAnnoSplit

AngsdAnnoSplit.main()
