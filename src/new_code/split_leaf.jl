# dato un potree e partendo dalle foglie devo continuare a costruire nodi se questi hanno più di un piano
function upgrade_potree(potree::String)
    # Instantiate writer
    if isfile(joinpath(potree,"cloud.js"))
        writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
        cloudjs = PotreeConverter.loadStateFromDisk(writer)
    else
        return nothing
    end

    PotreeConverter.traverse(writer.root, split_leaf(writer))

    return writer
end

function split_leaf(potreeWriter::PotreeConverter.PotreeWriter)
    function split_leaf0(node::PotreeConverter.PWNode)
        if PotreeConverter.isLeafNode(node)
            if !node.isInMemory
                PotreeConverter.loadFromDisk(node,potreeWriter)
            end
            @show node.isInMemory
            if isempty(node.store)
                @show "vuoto"
            else
                @show "pieno"
            end
        end
    end
    return split_leaf0
end
