using PotreeConverter
using FileManager

sourceFilenames = ["D:/pointclouds/cava.las"]
path = ""
numPoints = [123445]
boundingBoxes = [PotreeConverter.pAABB([0,0,0.],[1.,1.,1.])]


PotreeConverter.writeSources(path, sourceFilenames, numPoints, boundingBoxes)
