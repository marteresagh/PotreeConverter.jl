"""
    expand(potree::String, callback::Function)

Further split leaves of Potree.
"""
function expand(potree::String, callback::Function)
    # Instantiate writer
    if isfile(joinpath(potree,"cloud.js"))
        writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
        cloudjs = PotreeConverter.loadStateFromDisk(writer)
    else
        return nothing
    end

    PotreeConverter.traverse(writer.root, callback(writer))
    PotreeConverter.flush(writer, cloudjs)
end

"""
    split_leaf(potreeWriter::PotreeConverter.PotreeWriter)

Split leaf of Potree.
"""
function split_leaf(potreeWriter::PotreeConverter.PotreeWriter)
    function split_leaf0(node::PotreeConverter.PWNode)
        if PotreeConverter.isLeafNode(node)
            if !node.isInMemory
                PotreeConverter.loadFromDisk(node,potreeWriter)
            end
            points_pos = map(s->s.position,node.store)
            points = hcat(points_pos...)

            #test for further split
            if size(points,2) > 10
                direction, centroid = Common.LinearFit(points)
                residuals = Common.distance_point2plane(centroid, direction).([c[:] for c in eachcol(points)])
                test = max(residuals...) > 0.2
                if test
                    PotreeConverter.split(node, potreeWriter)
                end
            end

        end
    end
    return split_leaf0
end




########################################
# function upgrade_potree(potree::String)
#     # Instantiate writer
#     if isfile(joinpath(potree,"cloud.js"))
#         writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
#         cloudjs = PotreeConverter.loadStateFromDisk(writer)
#     else
#         return nothing
#     end
#
#     leaves = PotreeConverter.PWNode[]
#     PotreeConverter.traverse(writer.root, callback(leaves))
#     for node in leaves
#         @show PotreeConverter.name(node)
#         if !node.isInMemory
#             PotreeConverter.loadFromDisk(node,writer)
#         end
#         points_pos = map(s->s.position,node.store)
#         points = hcat(points_pos...)
#
#         @show "leaf"
#         if size(points,2) > 10
#             direction, centroid = Common.LinearFit(points)
#             residuals = Common.distance_point2plane(centroid, direction).([c[:] for c in eachcol(points)])
#             test = max(residuals...) > 0.2
#             if test
#                 @show "divido"
#                 PotreeConverter.split(node, writer)
#             end
#         end
#     end
#
#     PotreeConverter.flush(writer, cloudjs)
#
#     #return writer, cloudjs
# end
#
# function callback(leaves::Vector{PotreeConverter.PWNode})
#     function callback0(node::PotreeConverter.PWNode)
#         if PotreeConverter.isLeafNode(node)
#             push!(leaves,node)
#         end
#     end
#     return callback0
# end
