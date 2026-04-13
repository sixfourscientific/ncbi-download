
def initDefaults( json ){

    def jsonSlurper = new groovy.json.JsonSlurper()
    
    def jsonFile = new File(json)
    
    def defaultMap = jsonSlurper.parse(jsonFile)

    return defaultMap }


def initAlias() {
    
    def aliasMap = [
        'DEFAULT' : 'def',
        (null)    : 'NA',
        (true)    : 'T',
        (false)   : 'F'
        ]

    return aliasMap }


def initMap(Map config, Map parsed, Map defaults) {

    // collect available fields i.e. default + unique parsed
    def keys = (defaults.keySet() + parsed.keySet()).unique()

    keys.each { key ->

        def parsedVal = parsed[(key)]
        def defaultVal = defaults[(key)]

        // recursively initialise expected substructure
        if (defaultVal instanceof Map) {

            // initialise config submap
            config.putAt(key, [:])

            // extract any parsed submap
            def subMap = parsedVal instanceof Map
                ? parsedVal
                : [:]
            
            // recurse
            initMap(config[key], subMap, defaultVal)

            return } // continue

        // prioritise parsed value
        def entry = parsed.containsKey(key)
            ? parsedVal 
            : defaultVal

        // store entry
        config.putAt( key, entry )

        }

    }



def getExt( args ){

    def extension = args.extension
    def gunzipped = args.gunzipped

    def extList = (extension ?: [])
        // split file extensions
        .with { ext -> 
            ext instanceof List 
                ? ext 
                : ext.split(',') }
        // strip leading dots
        .collect { ext -> 
            ext.replaceAll('^\\.+', '') }

    // create ext & zip regex
    def extRegex = extList
        .collect{ ext -> 
            ext.replace( '.', '\\.' ) }
        .join('|')

    // create zip extension regex
    def zipRegex  = gunzipped 
        ? '(\\.gz)?' 
        : ''

    def fileRegex = extension
        ? ~".*\\.(${extRegex})${zipRegex}\$"
        : ~""

    return [extList, fileRegex] }


def switchClass( value ){

    switch (value) {

        case { value instanceof List }:                              break

        case { value.isLong() }:          value = value.toLong();    break

        case { value.isDouble() }:        value = value.toDouble();  break

        case ['true', 'false']:           value = value.toBoolean(); break

        case ['null']:                    value = null;              break 

        case { value instanceof String }:                            break 

        default: println ("Unhandled value class: \"$value\" (${value.getClass()})")

        }

    return value }


def logInfo ( info ){
    
    // make log direectory
    def validatedDir = "${params.logDir}/info"
    new File(validatedDir).mkdirs()

    // log info file contents
    def validatedFile = new File("${validatedDir}/${info.getName()}")
    validatedFile << info.text }


def parseInfo( args ){

    def parsedMap = args.input

    // specify config defaults
    def defaultMap = initDefaults( "$workflow.projectDir/components/defaults/ENTRY_INPUT.json" )

    // initialise empty config map
    def infoMap = [:]

    // combine parsed & default maps
    initMap( infoMap, parsedMap, defaultMap )

    def infoPath = infoMap.INFO


    // VALIDATE INFO SHEET

    def ValidatedInfo = [:]

    // no file
    if (!infoPath){ println("WARNING ~ No info file.") }

    else {

        // import input file info
        def inputFile = file( 
            infoPath, 
            checkIfExists : true,
            type          : 'file', )

        assert inputFile.getName().endsWith('tsv'): 
            "InputInfo requires tsv extension" 


        // VALIDATE ENTRY LINES

        println "Checking ${inputFile.getBaseName()}..."

        // file empty
        if ( file(infoPath).countLines() == 0){ println("WARNING ~ Empty info file.") }

        // file contents 
        else {

            def InputInfo = inputFile
                .splitCsv(
                    header : true,
                    sep    : "\t", 
                    )

            def UniqueStore = [:]

            def EntryInfo = []

            // cycle rows...
            InputInfo.eachWithIndex{ entry, idxRow -> idxRow += 1 


                // CHECK RELEVANT

                // create entry string
                def info = entry.values().join(';')

                // skip comment
                if(info.startsWith('#')){ println("Skipping Row ${idxRow}"); return }

                // check entry string unique
                assert !( EntryInfo.contains(info) ):                
                    "Row ${idxRow}: Entry not unique; Found on Row ${EntryInfo.findIndexOf{ it == info } + 1}"

                // store unique entry string
                EntryInfo.add(info)


                // PROCEED

                // create entry store
                ValidatedInfo.putAt( idxRow, [:] )

                // check run field
                if ( infoMap.RUN_ID ) {

                    assert entry.containsKey(infoMap.RUN_ID),
                        "Row ${idxRow}: \"$infoMap.RUN_ID\" field not found; unable to initialise run ID."

                   }

                // store run id & info fields
                if ( infoMap.DETAILED == true ) {

                    // initialise run id
                    def runID = infoMap.RUN_ID 
                        ? entry[(infoMap.RUN_ID)]
                        : "run$idxRow"

                    ValidatedInfo[idxRow].putAt( 'RUN', runID ) 

                    def fieldList = entry
                        .keySet()
                        .collect()
                        // exclude intermediate & run fields
                        .findAll{ key -> 
                            !key.endsWith(".$params.intTag") && !key.equals('run')}
                    
                    // store original fields
                    ValidatedInfo[idxRow].putAt( 'INFO', [FIELDS : fieldList] )

                    }

                // VALIDATE VALUES

                // cycle columns...
                entry.each{ key, value ->

                    // check value provided
                    assert value :
                        "Row ${idxRow}: ${key.capitalize()} not provided"

                    // convert any intermediary keys to original
                    key = key.replaceAll(/\.$params.intTag$/, '')

                // VALUE CHECKS 

                    // create store for processed values
                    UniqueStore.containsKey(key) ?: UniqueStore.put(key,[])

                    if ( infoMap.UNIQUE.contains(key) ){

                        // check value not already processed                           
                        assert value.toString() !in UniqueStore[key]:
                            "Row ${idxRow}: \"${key}\" not unique; processed on Row ${UniqueStore[key].findIndexOf{ it == value } + 1}" 
                        }

                    // store processed value (as string)
                    UniqueStore[key].add( value.toString() )


                // PATH CHECKS 

                    // NEST PATH WITHIN STEM
                    if ( infoMap.NESTED.containsKey(key) ) {

                        // extract directory stem; must have already been validated
                        def stemDir = ValidatedInfo[idxRow][infoMap.NESTED[(key)]]

                        // extract directory nest; contents might be listed
                        def stemPath = stemDir instanceof List
                            ? stemDir.first().toString()
                            : stemDir.toString()

                        // combine stem & subdir
                        value = new File(stemPath, value).toString() // VALUE MODIFIED

                        }


                    // CHECK PATH EXISTS
                    if ( infoMap.EXISTS.contains(key) ){

                        assert new File( value ).exists():
                            "Row ${idxRow}: Path not found; ${value}"

                        }
                    

                    // LIST PATH CONTENTS
                    if ( infoMap.CONTENTS.contains(key) && file(value).isDirectory() ) {

                        def contentFiles = files( "${value}/**", hidden: true )

                        assert contentFiles:
                            "Row ${idxRow}: Directory contains no files; ${value}"

                        value = contentFiles // VALUE MODIFIED

                        } 


                    // CHECK PATH EXTENSION
                    if ( infoMap.EXTENSIONS.containsKey(key)){

                        // extract file extension info
                        def (extList, fileRegex) = getExt( extension: infoMap.EXTENSIONS[key], gunzipped: infoMap.GUNZIPPED)

                        def pathList = value instanceof LinkedList
                            ?  value
                            : [value]

                        pathList.each{ path ->

                            assert path.toString().matches(fileRegex):
                                "Row ${idxRow}: Incorrect file extension; expected \"${extList.join(', ')}\"${ infoMap.GUNZIPPED ? ' (gz optional)' : ''} but found \"${file(path).getName()}\""

                            }

                        }


                // CLASS CHECKS 

                    // convert value class as required
                    value = switchClass(value)

                    // record validated values
                    ValidatedInfo[idxRow].putAt( key, value ) 
                    
                    }

                println "Validated: Entry ${idxRow}" }


        // log info
        logInfo( inputFile )

        }

    }

    // remove keys (line number) from maps as required
    def Validated = ValidatedInfo
        ?  ValidatedInfo.values() // without lines
        : [ValidatedInfo] // no/empty info (no lines)

    println "Done\n"
    
    return Validated }



def parseConfig( args ){

    def parameters = args.parameters
    def software   = args.software
    def command    = args.command
    def branch     = args.branch

    // extract relevant parameters if parsed
    def parsedMap = parameters
        ?.get(software)
        ?.get(command)
        ?.get(branch)
        ?.CONFIG 
        ?: [:]

    // specify config defaults
    def defaultMap = initDefaults( "$workflow.projectDir/components/defaults/ENTRY_LEAF.json" )
    
    // add default alises
    defaultMap['LABEL'].putAt("ALIASES", initAlias())

    // initialise basic config map
    def configMap = [ BRANCH: branch ]

    // combine parsed & default maps
    initMap( configMap, parsedMap, defaultMap )

    // list versions
    def versionList = configMap.VERSION instanceof ArrayList
        ?  configMap.VERSION.isEmpty()
            ? [null]
            : configMap.VERSION
        : [configMap.VERSION] 
    
    // parse &/or list sweeps
    def sweepList = configMap.ARGS.SWEEP instanceof ArrayList
        ? configMap.ARGS.SWEEP 
        : parseInfo( input: [INFO: configMap.ARGS.SWEEP] )
    
    // pair versions & sweeps
    def configList = versionList

        .collectMany { version ->
    
            sweepList.collect { sweep ->

                def pairMap = configMap + [
                    VERSION : version,
                    ARGS    : configMap.ARGS.CORE + sweep
                    ]

                return pairMap }

            }

    def Parsed = configList

    return Parsed }
