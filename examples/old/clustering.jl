using Search.NearestNeighbors

covectors = [-1 -1 1 1;
              0 0.0001 0 0.;
              0 0 0 0.;
              1.2 1.20001 -1.2001 -1.3]

tree = KDTree(covectors)

a = inrange(tree,covectors,0.01)


function distance(X)
    function distance0(j)
        min = Inf
        for i in 1:size(X,2)
            value = Common.norm(X[j]+X[i])/(Common.norm(X[j])+Common.norm(X[i]))
            if value < min
                min = value
            end
        end
        return min
    end
    return distance0
end

distance(covectors)(4)

dir = [-0.4696, 0.8829,0.0024]
planes = Vector{Float64}[]
for v in cmtree.root.dict[dir]
    sign = rand(1:2)
    push!(planes,[(-1)^sign*dir...,Common.dot((-1)^sign*dir,v)])
end

planes = hcat(planes...)


distance(planes)(5)

using Visualization

norm = [0 0.594138  0.622634  0.685018  0.848583;
        0 0.797435  0.499612  0.431098  0.097823;
        0 0.105343  0.602258  0.587286  0.519940]
EV = [[1,2],[1,3],[1,4],[1,5]]

Visualization.VIEW([
    Visualization.GLGrid(norm,EV)
    Visualization.points([0.730071; 0.484693;0.481735])
])
