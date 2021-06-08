using PotreeConverter
# using Profile
using ProfileView

sources = [raw"D:\pointclouds\cava.las"]
outdir = "C:/Users/marte/Documents/GEOWEB/TEST/Potree"
pageName = "TEST"
# @profview  @profile
@profview PotreeConverter.main(sources,outdir,pageName)

# open("profile.txt", "w") do s
#     Profile.print(IOContext(s, :displaysize => (24, 500)))
# end

# PotreeConverter.exe  "D:\pointclouds\cava.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TEST
# PotreeConverter.exe  "D:\pointclouds\Casaletto\casale.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p CASALE
# PotreeConverter.exe  "D:\pointclouds\nuvole\TFA16_nuvola UX5.las" -o C:/Users/marte/Documents/GEOWEB/TEST/Potree --output-format LAS -p TFA



# using LasIO
# using LasIO.FileIO
# using BenchmarkTools
# @btime load(raw"D:\pointclouds\cava.las", mmap=true)
