function convert(args::PotreeArguments)
    println("AABB: ")
    println(args.aabbValues)

    PotreeConverter.makeCubic(args.aabbValues)
    println("cubic AABB: ")
    println(args.aabbValues)

end
