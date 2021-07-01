# https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection

using PotreeConverter
using Visualization
using Common
using LinearAlgebra


# segment = (la,lb)
# plane = (p0,p1,p2)
function intersection(la, lb, p0, p1, p2)
    println("intersection")
    lab = lb - la
    p01 = p1 - p0
    p02 = p2 - p0

    n = Common.cross(p01, p02)
    det = Common.dot(-lab, n)
    if det != 0.0
        t = (Common.dot(n, la - p0)) / det
        u = Common.dot(Common.cross(p02, -lab), la - p0) / det
        v = Common.dot(Common.cross(-lab, p01), la - p0) / det
        return la + lab * t
    else
        println("segmento e piano paralleli: infite soluzioni o nessuna soluzione")
        return nothing
    end
end


#p = intersection(la,lb,p0,p1,p2)
#if !isnothing(p)
#    GL.VIEW( [GL.GLPoints(reshape(p,1,3),GL.COLORS[7]), GL.GLGrid(hcat(la,lb),[[1,2]],GL.COLORS[2]), GL.GLGrid(hcat(p0,p1,p2),[[1,2,3]],GL.COLORS[1],0.3), GL.GLFrame]);
#end


function testplane(V, EV, plane) # plane
    println("testplane")
    p0, p1, p2 = [plane[:, k] for k = 1:3]
    ps = []
    for (h, k) in EV
        la = V[:, h]
        lb = V[:, k]
        sa = sign(dot(cross(p1 - p0, p2 - p0), la - p0))
        sb = sign(dot(cross(p1 - p0, p2 - p0), lb - p0))
        if !(sa == sb)
            p = intersection(la, lb, p0, p1, p2)
            if (p[1] >= 0.0 && p[1] <= 1) &&
               (p[2] >= 0.0 && p[2] <= 1) &&
               (p[3] >= 0.0 && p[3] <= 1)
                push!(ps, p)
            end
        end
    end
    points = convert(Matrix, hcat(ps...)')
    return points
end

function verts2edgesface(points) # points by row
    println("verts2edgesface")
    # traslation
    center = sum(points, dims = 1) / size(points, 1)
    points = points .- center
    # compute the linear map from random plane (a,b,c,d) to z=0
    p0, p1, p2 = [points[k, :] for k = 1:3]
    M = inv([p1 + rand(3) p2 cross(p1 - p0, p2 - p0)])
    # map vertex points
    face = M * (convert(Matrix, points'))
    # radial ordering of mapped points
    rays = [(face[:, k] .- center) for k = 1:size(face, 2)]
    ordering = []
    for k = 1:size(face, 2)
        y, x = rays[k][2], rays[k][1]
        alpha = atan(y, x)
        if abs(0.0 - y) < 10^(-7)
            if abs(1.0 - y) < 10^(-7)
                alpha = pi / 2
            else
                abs(-1.0 - y) < 10^(-7)
                alpha = -pi / 2
            end
        end
        push!(ordering, (alpha, k))
    end
    order = sort(ordering)
    # compute the edges (back-mapping of vertices not needed)
    lines = []
    for k = 1:length(order)-1
        push!(lines, [order[k][2], order[k+1][2]])
    end
    push!(lines, [order[end][2], order[1][2]])
    face = sort(union(lines...))
    return lines, face
end

# polygon generation from plane data


function planes(box, plane)
    println("planes")
    # get random plane through three random points in [0,1]^3
    #plane = rand(3,3)
    # get points of intersection polygon of plane with unit cube
    points = testplane(V, EV, plane)
    verts = convert(Common.Points, points')
    # get output
    lines, face = verts2edgesface(points)
    edges = convert(Common.Cells, lines)
    # struct assembly of convex faces
    str = Common.Struct([(verts, [face], edges)])
    push!(box, str)
    #return box
end

# V,(VV,EV,FV,CV) = LinearAlgebraicRepresentation.cuboidGrid([1,1,1],true)
V = [
    0.000000 0.000000 0.000000 0.000000 1.000000 1.000000 1.000000 1.000000
    0.000000 0.000000 1.000000 1.000000 0.000000 0.000000 1.000000 1.000000
    0.000000 1.000000 0.000000 1.000000 0.000000 1.000000 0.000000 1.000000
]

EV = [
    [1, 2],
    [3, 4],
    [5, 6],
    [7, 8],
    [1, 3],
    [2, 4],
    [5, 7],
    [6, 8],
    [1, 5],
    [2, 6],
    [3, 7],
    [4, 8],
]

FV = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [1, 2, 5, 6],
    [3, 4, 7, 8],
    [1, 3, 5, 7],
    [2, 4, 6, 8],
]
#GL.VIEW( push!(GL.numbering(.5)((V,(VV,EV,FV,CV))), GL.GLFrame));
box = [Common.Struct([(V, FV, EV)])]

# theplanes = []
# push!(theplanes, [rand(2, 3); [0.1 0.1 0.1]]) # orth to z
# push!(theplanes, [rand(1, 3); [0.1 0.1 0.1]; rand(1, 3)])  # orth to y
# push!(theplanes, [rand(1, 3); [0.5 0.5 0.5]; rand(1, 3)])  # orth to y
# push!(theplanes, [[0.6 0.6 0.6]; rand(2, 3)])  # orth to x

theplanes = [[0.307586 0.376788 0.590940; 0.871370 0.248783 0.949716; 0.100000 0.100000 0.100000],
 [0.245464 0.992669 0.940056; 0.100000 0.100000 0.100000; 0.107074 0.574497 0.275482],
 [0.593242 0.430284 0.225134; 0.500000 0.500000 0.500000; 0.912263 0.987612 0.349528],
 [0.600000 0.600000 0.600000; 0.345328 0.977932 0.685681; 0.781430 0.910180 0.461460]]

for k = 1:length(theplanes)
    global box
    plane = theplanes[k]
    box = planes(box, plane)
end

W, FW, EW = Common.struct2lar(Common.Struct(box))

# GL.VIEW([
# 		#GL.GLPoints(points),
# 		GL.GLGrid(W, EW, GL.COLORS[7], 0.5),
# 		#GL.GLGrid(V,EV),
# 		GL.GLFrame
# ]);

# Unit box arrangement
#plane = [ rand(3,2) [.1;.1;.1] ]


cop_EV = PotreeConverter.coboundary_0(EW);
cop_FE = PotreeConverter.coboundary_1(W, FW, EW);
W = convert(Common.Points, W');
#
V, copEV, copFE, copCF = PotreeConverter.space_arrangement(
    W::Common.Points,
    cop_EV::Common.ChainOp,
    cop_FE::Common.ChainOp,
);
#
V = convert(Common.Points, V');
V, CVs, FVs, EVs = PotreeConverter.pols2tria(V, copEV, copFE, copCF) # whole assembly
Visualization.VIEW(Visualization.GLExplode(V,FVs,1.1,1.1,1.1,99,1));
Visualization.VIEW(Visualization.GLExplode(V,EVs,1.5,1.5,1.5,99,1));
Visualization.VIEW(Visualization.GLExplode(V,CVs,1,1,1,99,0.2));
