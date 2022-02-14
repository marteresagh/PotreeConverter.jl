function Point(lasPoint::LasIO.LasPoint, header::LasIO.LasHeader)::Point
    position = FileManager.xyz(lasPoint,header)
	color = [reinterpret(UInt16,lasPoint.red),reinterpret(UInt16,lasPoint.green),reinterpret(UInt16,lasPoint.blue)]
	normal = Float64[]
	intensity = lasPoint.intensity
	classification = lasPoint.raw_classification
	returnNumber = 0
	numberOfReturns = 0
	pointSourceID = lasPoint.pt_src_id
	gpsTime = 0.0
	return Point(position,
				color,
				normal,
				intensity,
				classification,
				returnNumber,
				numberOfReturns,
				pointSourceID,
				gpsTime,)
end

function Base.show(io::IO, point::Point)
    println(io, "position: $(point.position)")
	println(io, "color: $(point.color)")
end
