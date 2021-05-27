# References
```@meta
CurrentModule = PotreeConverter
DocTestSetup = quote
    using PotreeConverter
end
```

## PotreeConverter
### Main Structures
```@docs
Point
pAABB
PotreeWriter
PWNode
SparseGrid
```

### Main references

```@docs
main
potreeconvert
add
processStore
flush
```


## Comaptree  
### Main Structures
```@docs
ComaptreeWriter
CWNode
```

### Main references

```@docs
potree2comaptree(potreeDir::String)
postorder
```
