
include { 
    makeTag as makeTag;
    } from "$params.importMap.functions/core/Utils"


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

                // store entry id & info fields
                if ( infoMap.DETAILED == true ) {

                    def idFieldList = infoMap.ID_FIELD instanceof List
                        ?  infoMap.ID_FIELD
                        : [infoMap.ID_FIELD]

                    // check entry id field
                    if ( infoMap.ID_FIELD ) {

                        assert idFieldList.any{ field -> entry.containsKey(field) }:
                            "Row ${idxRow}: \"$infoMap.ID_FIELD\" field not found; unable to initialise entry ID."

                    }

                    // initialise entry id
                    def entryTag = infoMap.ID_FIELD 
                        ? makeTag(
                            tags      : idFieldList.collect{ field -> entry[(field)] },
                            delimiter : '-',
                            )
                        : "entry$idxRow"

                    // remove any spaces
                    def entryID = entryTag
                        .toString()
                        .replaceAll( "\\s", "_" )

                    ValidatedInfo[idxRow].putAt( 'ID', entryID ) 

                    def fullFieldList = entry
                        .keySet()
                        .collect()
                        // exclude intermediate & run fields
                        .findAll{ key -> 
                            !key.endsWith(".$params.intTag") && !key.equals('run')}
                    
                    // store original fields
                    ValidatedInfo[idxRow].putAt( 'INFO', [FIELDS : fullFieldList, TYPE : infoMap.TYPE] )

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



def parseSubsets( args ){

    def parsedMap = args.batch
    def groupList = args.grouped

    // specify config defaults
    def defaultMap = initDefaults( "$workflow.projectDir/components/defaults/ENTRY_BATCH.json" )

    // initialise empty config map
    def batchMap = [:]

    // combine parsed & default maps
    initMap( batchMap, parsedMap, defaultMap )

    // batchMap from now on
    assert  (batchMap.BYTELIMIT || batchMap.BATCHSIZE): "Neither Byte nor File size limits were specified"
    assert !(batchMap.BYTELIMIT && batchMap.BATCHSIZE): "Both Byte & File size limits were specified"

    def examinedList = groupList
    
        .withIndex()
        
        .collect{ element, idx ->

            // calculate file sizes
            def fileBytes = batchMap.BYTELIMIT
                ? java.nio.file.Files.size(entry).toLong()
                : 0
            
            def elementMeta = [
                element : element,
                bytes   : fileBytes,
                ]

            return elementMeta }
        
        // sort files; smallest -> largest
     // .sort{ first, second -> first[0] <=> second[0] }


    // PARTITION ELEMENTS

    // create store
    def subsetMap = [:]

    // subset counters
    def batchBytes = 0
    def batchFiles = 0
    def elementCount = 0
    def batchCount = 0

    examinedList

        // cycle entries...
        .each{ elementMeta ->

            def element   = elementMeta.element
            def fileBytes = elementMeta.bytes

            elementCount += 1

            // record expected batch size
            def cumulativeBytes = batchBytes + fileBytes
            def cumulativeFiles = batchFiles + 1

            // assess batch size
            if (// initial file 
                elementCount == 1 || 
                // cumulative batch bytes exceeds byte limit (bytes limit only)
                ( batchMap.BYTELIMIT && cumulativeBytes > batchMap.BYTELIMIT) ||
                // cumulative batch files exceeds file limit (files limit only)
                ( batchMap.BATCHSIZE && cumulativeFiles > batchMap.BATCHSIZE) ||
                // cumulative batch files exceeds max files  (bytes limit only)
                ( batchMap.BYTELIMIT && cumulativeFiles > batchMap.BATCHMAX ) ){

                // start new batch &/or reset
                batchCount += 1
                batchBytes  = 0
                batchFiles  = 0 }

            // record batch size increase
            batchBytes += fileBytes
            batchFiles += 1

            // create list under relevant batch as required
            subsetMap.containsKey(batchCount) ?: subsetMap.putAt( batchCount, [] )

            // store file under relevant batch
            subsetMap[batchCount].add(element) }

    def elementInfo  = "${elementCount} element${elementCount > 1 ? 's' : ''}"
    def batchInfo    = "${batchCount} batch${batchCount > 1 ? 'es' : ''}"
    println "\nINFO ~ Subsets (${batchMap.NAME}); partitioned ${elementInfo} into ${batchInfo}.\n"


    // PACKAGE BATCHES

    def subsetMetaList = subsetMap

        .collect{ batchIdx, subsetList ->

            def batchMapNew = batchMap + [
                INDEX : batchIdx,
                FILE  : "${batchMap.NAME}-batch${batchIdx}.tsv",
                ]

            def subsetMeta = [ 
                BATCH  : batchMapNew,
                GROUPED : subsetList,
                ]

            if ( batchMap.VERBOSE ){

                // display batch info
                println "\nbatch ${batchIdx} (${subsetList.size()} element${subsetList.size() > 1 ? 's' : ''}):"

                subsetList.each{ element -> println " - ${element}" }; println('') }

            return subsetMeta }

    def Subsets = subsetMetaList

    return Subsets }
