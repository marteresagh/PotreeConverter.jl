"""
create a header of file las
"""
function newHeader(aabb::pAABB; software = "potree-julia"::String, sizePointRecord = 26, npoints=0, scale=0.001)

	file_source_id=UInt16(0)
	global_encoding=UInt16(0)
	guid_1=UInt32(0)
	guid_2=UInt16(0)
	guid_3=UInt16(0)
	guid_4=""
	version_major=UInt8(1)
	version_minor=UInt8(2)
	system_id=""
	software_id = software
	creation_dayofyear = UInt16(FileManager.Dates.dayofyear(FileManager.Dates.today()))
	creation_year = UInt16(FileManager.Dates.year(FileManager.Dates.today()))
	header_size=UInt16(227) # valore fisso
	data_offset=UInt16(227) #valore fisso
	n_vlr=UInt32(0)
	data_format_id=UInt8(2)
	data_record_length=UInt16(sizePointRecord) #valore variabile
	records_count=UInt32(npoints)
	point_return_count=UInt32[0,0,0,0,0]
	x_scale=scale
	y_scale=scale
	z_scale=scale
	x_offset = aabb.min[1]
	y_offset = aabb.min[2]
	z_offset = aabb.min[3]
	x_max = aabb.max[1]
	x_min = aabb.min[1]
	y_max = aabb.max[2]
	y_min = aabb.min[2]
	z_max = aabb.max[3]
	z_min = aabb.min[3]
	variable_length_records=Vector{FileManager.LasIO.LasVariableLengthRecord}()
	user_defined_bytes=Vector{UInt8}()


	return LasIO.LasHeader(file_source_id,
    global_encoding,
    guid_1,
    guid_2,
    guid_3,
    guid_4,
    version_major,
    version_minor,
    system_id,
    software_id,
    creation_dayofyear,
    creation_year,
    header_size,
    data_offset,
    n_vlr,
    data_format_id,
    data_record_length,
    records_count,
    point_return_count,
    x_scale,
    y_scale,
    z_scale,
    x_offset,
    y_offset,
    z_offset,
    x_max,
    x_min,
    y_max,
    y_min,
    z_max,
    z_min,
    variable_length_records,
    user_defined_bytes
	)
end

function newPointRecord(point::Array{Float64,1},
	 					rgb::Array{LasIO.N0f16,1},
						type::LasIO.DataType,
						mainHeader::LasIO.LasHeader;
						raw_classification = UInt8(0),
						intensity = UInt16(0),
						pt_src_id = UInt16(0),
						gps_time = Float64(0)) #crea oggetto laspoint con vertici e colori

	x = LasIO.xcoord(point[1],mainHeader)
	y = LasIO.ycoord(point[2],mainHeader)
	z = LasIO.zcoord(point[3],mainHeader)
	flag_byte = UInt8(0)
	scan_angle = Int8(0)
	user_data = UInt8(0)

	if type == LasIO.LasPoint0
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id
					)

	elseif type == LasIO.LasPoint1
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id, gps_time
					)

	elseif type == LasIO.LasPoint2
		red = rgb[1]
		green = rgb[2]
		blue = rgb[3]
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id,
					red, green, blue
					)

	elseif type == LasIO.LasPoint3
		red = rgb[1]
		green = rgb[2]
		blue = rgb[3]
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id, gps_time,
					red, green, blue
					)

	end

end


function read(fname::String)
	if endswith(fname,".las")
		header, laspoints = FileManager.LasIO.FileIO.load(fname)
	elseif endswith(fname,".laz")
		header, laspoints = FileManager.LazIO.load(fname)
	end
	return header,laspoints
end

"""
	las2aabb(file::String) -> AABB

Return LAS file's bounding box.
"""
function las2aabb(file::String)::pAABB
	header = nothing
	open(file,"r") do s
	  LasIO.skiplasf(s)
	  header = read(s, LasHeader)
	end
	#header = LasIO.read(fname, LasIO.LasHeader)
	aabb = LasIO.boundingbox(header)
	return pAABB([aabb.xmin, aabb.ymin, aabb.zmin], [aabb.xmax, aabb.ymax, aabb.zmax])
end

##################################################
# using PyCall
# function las2aabb(file::String)::AABB
# 	py"""
# 	import pylas
#
# 	def ReadHeader(file):
# 		with pylas.open(file) as f:
# 			return f.header.x_min,f.header.y_min,f.header.z_min,f.header.x_max,f.header.y_max,f.header.z_max
# 	"""
#
# 	aabb = py"ReadHeader"(file)
#
# 	return pAABB(aabb[1:3], aabb[4:6])
# end

#
# function read(fname::String)
# 	py"""
# 	import pylas
# 	import numpy as np
#
# 	def ReadLas(file):
# 		las = pylas.read(file)
# 		return las
#
# 	"""
# 	las = py"ReadLas"(file)
# 	return las.header,las.points_data
# end
#
# """
# create a header of file las
# """
# function newHeader(aabb::pAABB; software = "potree-julia"::String, id_format = 2, npoints=0, scale=0.001)
#
# 	py"""
# 	import pylas
#
# 	def createHeader(x_max,x_min,y_max,y_min,z_max,z_min,software,id_format,scale):
# 		return LasHeader(version=Version(1, 2),
# 						generating_software = software,
# 		 				point_format=PointFormat(id_format),
# 						x_scale = scale,
# 						y_scale = scale,
# 						z_scale = scale,
# 						x_offset = x_min,
# 						y_offset = y_min,
# 						z_offset = z_min,
# 						x_min = x_min,
# 						y_min = y_min,
# 						z_min = z_min,
# 						x_max = x_max,
# 						y_max = y_max,
# 						z_max = z_max,)
# 	"""
# 	x_max = aabb.max[1]
# 	x_min = aabb.min[1]
# 	y_max = aabb.max[2]
# 	y_min = aabb.min[2]
# 	z_max = aabb.max[3]
# 	z_min = aabb.min[3]
# 	return py"createHeader"(x_max,x_min,y_max,y_min,z_max,z_min,software,id_format,scale)
# end
