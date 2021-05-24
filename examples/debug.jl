using FileManager

testfile = raw"D:\pointclouds\cava.las"
header, pointdata = FileManager.LasIO.FileIO.load(testfile)
