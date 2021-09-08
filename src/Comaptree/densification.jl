function densify_leaves(folder_project::String, potree::String, LOD::Int)

    dense_path = FileManager.mkdir_project(folder_project, "DENSE_LOD$LOD")
    tmp = FileManager.mkdir_project(dense_path, "tmp")

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
    for i = 1:n_leaves
        leaf = leaves[i]
        # init
        println("leaf $i of $n_leaves processed")
        leaf_header, leaf_lasPoints = FileManager.read_LAS_LAZ(leaf)

        points_processed = 0
        aabb_leaf = FileManager.las2aabb(leaf_header)
        name_leaf = Base.split(splitdir(leaf)[2], ".")[1]

        output_new_leaf = joinpath(dense_path, name_leaf * ".las")
        tmp_leaf = joinpath(dense_path, "tmp_" * name_leaf * ".las")

        main_header = FileManager.newHeader(
            aabb_leaf,
            "DENSIFICATION",
            FileManager.SIZE_DATARECORD,
        )

        stream_tmp_leaf = open(tmp_leaf, "w")

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
                        plas = FileManager.newPointRecord(
                            lasPoint,
                            internal_header,
                            LasIO.pointformat(main_header),
                            main_header,
                        )
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
    rm(tmp)



    return true
end



function get_planes_and_poligons(files, folder_project, k=20 , par = 0.02, angle = pi/8)
    n_files = length(files)
    for i = 1:n_files

        Detection.flushprintln()
        Detection.flushprintln("==========================================================")
        Detection.flushprintln("= $(files[i]) =")
        Detection.flushprintln("= $i of $n_files =")
        Detection.flushprintln("==========================================================")

        file = files[i]

        name_leaf = Base.split(splitdir(file)[2], ".")[1]
        dir_leaf = joinpath(folder_project, String(name_leaf))

        if !isdir(dir_leaf)
            PC = FileManager.las2pointcloud(file)
            if PC.n_points > 200
                hyperplanes = get_planes(PC, k, par)

                for hyperplane in hyperplanes
                    inliers = hyperplane.inliers
                    plane = Plane(inliers.coordinates)
                    V = Common.apply_matrix(plane.matrix, inliers.coordinates)[1:2, :]

                    # alpha shape
                    if size(V, 2) > k
                        Detection.flushprintln()
                        Detection.flushprint("Alpha shapes....")
                        DT = Common.delaunay_triangulation(V)
                        filtration = AlphaStructures.alphaFilter(V, DT)
                        threshold = Features.estimate_threshold(V, k)
                        _, _, FV =
                            AlphaStructures.alphaSimplex(V, filtration, threshold)
                        Detection.flushprintln("Done")

                        # boundary extraction
                        Detection.flushprintln()
                        Detection.flushprint("Boundary extraction....")
                        EV_boundary = Common.get_boundary_edges(V, FV)
                        W, EW = Detection.simplifyCells(V, EV_boundary)
                        model = (W, EW)
                        Detection.flushprintln("Done")

                        # boundary semplification
                        try
                            Detection.flushprint("Boundary semplification....")
                            V2D, EV = Detection.simplify_model(
                                model;
                                par = par,
                                angle = angle,
                            )
                            Detection.flushprintln("Done")
                            V3D = Common.apply_matrix(
                                Common.inv(plane.matrix),
                                vcat(V2D, zeros(size(V2D, 2))'),
                            )

                            # save data
                            Detection.flushprintln()
                            Detection.flushprint("Saves $(length(EV)) edges....")
                            if length(EV) > 2
                                folder_leaf = FileManager.mkdir_project(folder_project, String(name_leaf))
                                FileManager.save_points_txt(
                                    joinpath(folder_leaf, "boundary_points2D.txt"),
                                    V2D,
                                )
                                FileManager.save_points_txt(
                                    joinpath(folder_leaf, "boundary_points3D.txt"),
                                    V3D,
                                )
                                Detection.save_cycles(
                                    joinpath(folder_leaf, "boundary_edges.txt"),
                                    V3D,
                                    EV,
                                )
                                FileManager.successful(
                                    true,
                                    folder_leaf;
                                    filename = "vectorize_2D_boundary.probe",
                                )
                            end

                            Detection.flushprintln("Done")
                            Detection.flushprintln()
                        catch y
                            Detection.flushprintln("NOT FOUND")
                        end
                    end
                end
            end
        end
    end
end
