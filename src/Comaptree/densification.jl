function densify_leaves(folder_project::String, potree::String, LOD::Int)

    dense_path = FileManager.mkdir_project(folder_project, "DENSE")
    tmp = FileManager.mkdir_project(dense_path, "TMP")

    # trie
    trie = FileManager.potree2trie(potree)
    trie_truncated = deepcopy(trie)
    FileManager.cut_trie!(trie_truncated, LOD)

    # nodes of potree
    files = FileManager.get_all_values(trie_truncated)
    leaves = FileManager.get_leaf(trie_truncated)
    internals = setdiff(files, leaves)

    n_leaves = length(leaves)
    # densification
    for i in 1:n_leaves

        leaf = leaves[i]
        # init
        println("leaf $i of $n_leaves processed")
        leaf_header, leaf_lasPoints = FileManager.read_LAS_LAZ(leaf)

        points_processed = 0
        aabb_leaf = FileManager.las2aabb(leaf_header)
        name_leaf = Base.split(splitdir(leaf)[2], ".")[1]

        output_new_leaf = joinpath(dense_path, name_leaf * ".las")
        tmp_leaf = joinpath(dense_path, "tmp_" * name_leaf * ".las")

        main_header =
            FileManager.newHeader(aabb_leaf, "DENSIFICATION", FileManager.SIZE_DATARECORD)

        stream_tmp_leaf =
            open(tmp_leaf, "w")

        # copio i punti della foglia
        for lasPoint in leaf_lasPoints
            points_processed = points_processed + 1
            write(stream_tmp_leaf, lasPoint)
        end

        # salvo tutti i punti
        for internal in internals
            global internal_header
            points_internal_not_processed = LasPoint[]
            name_internal = Base.split(splitdir(internal)[2], ".")[1]

            tmp_internal = joinpath(tmp, name_internal * ".las")

            if occursin(name_internal, name_leaf)
                println("Process node $name_internal")
                if !isfile(tmp_internal)
                    internal_header, internal_lasPoints =
                        FileManager.read_LAS_LAZ(internal)
                else
                    internal_header, internal_lasPoints =
                        FileManager.read_LAS_LAZ(tmp_internal)
                end

                for lasPoint in internal_lasPoints
                    position = FileManager.xyz(lasPoint, internal_header)
                    if Common.isinbox(aabb_leaf, position)
                        plas = FileManager.newPointRecord(lasPoint, internal_header, LasIO.pointformat(main_header), main_header)
                        points_processed = points_processed + 1
                        write(stream_tmp_leaf, plas)
                    else
                        push!(points_internal_not_processed, lasPoint)
                    end
                end

            end
            internal_header.records_count =
                length(points_internal_not_processed)
            LasIO.FileIO.save(
                joinpath(tmp, name_internal * ".las"),
                internal_header,
                points_internal_not_processed,
            )
        end

        close(stream_tmp_leaf)

        if points_processed != 0 # if n == 0 nothing to save
            main_header.records_count = points_processed
            pointtype = LasIO.pointformat(main_header) # las point format
            # in temp : list of las point records
            open(tmp_leaf, "r") do s
                # write las
                open(output_new_leaf, "w") do t
                    write(t, LasIO.magic(LasIO.format"LAS"))
                    write(t, main_header)

                    for i = 1:main_header.records_count
                        p = Base.read(s, pointtype)
                        write(t, p)
                    end
                end
            end
        end

        rm(tmp_leaf)
    end

    FileManager.clearfolder(tmp)



    return true
end
