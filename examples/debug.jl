using PotreeConverter
using FileManager
source = "D:/pointclouds/cava.las"
open(source) do s
    FileManager.LasIO.skiplasf(s)
    header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)

    n = header.records_count
    pointtype = FileManager.LasIO.pointformat(header)
    pointdata = Vector{pointtype}(undef, n)

    for i in 1:10
        pointdata[i] = FileManager.LasIO.read(s, pointtype)
        point = PotreeConverter.Point(pointdata[i], header)
        @show point
    end
end
