import java.nio.file.Files

// FUNCTIONS


def parseSupplementary ( supplementary, PARAMS ){

    if (supplementary && supplementary instanceof String) {

        supplementary
            // simplify delimiter
            .replaceAll(/\s+/, ' ')
            // seperate supplementary inputs
            .split(' ')
            // parse supplementary input
            .collectEntries { argument -> 

                def (parameter, flag) = argument.split('=')

                PARAMS[(flag)] = parameter

                return } }

    return }



def getUrlTag(url) {

    def urlObj = url.toURL()

    // extract path stem & file
    def (stemList, fileName) = urlObj
        .path
        .tokenize('/')
        .with { parts -> 
            return [parts[0..-2], parts.last()] }

    def hostTag = urlObj
        .host
        .replace('.','-')

    def stemTag = stemList
        .join('-')

    // remove final 1 or 2 file extensions
    def baseName = fileName
        .replaceAll(/(\.[^.]+){1,2}$/, '')

    def urlTag = [
        hostTag,
        stemTag,
        baseName,
        ]
        .join('-')

    return urlTag }



def collapseMap(map, linkList = [], delimiter = '.') {
    def result = [:]

    map
        .each { key, value ->
      
            def newPath = linkList + key
      
            ( value instanceof Map && !value.isEmpty() )
                ? result.putAll(collapseMap(value, newPath, delimiter))
                : result.putAt(newPath.join(delimiter), value)
      
            }

    return result }



def collapseParams( map, delimiter = '.' ) {

    def collapsedMap = collapseMap( map, [], delimiter )

    def listedMap = collapsedMap

        .collect{ key, value -> 
    
            value = value instanceof Map || value instanceof List || value == null
                ? 'N/A'
                : value
    
            return [ flag:key, parameter: value ] }

    return listedMap }



def prepBridge( args ){

    def coreMeta  = args.coreMeta
    def indexMeta = args.indexMeta
    def indexMetaNew = [:]

    // new header
    if ( !args.UPDATE && !args.INTERMEDIATE ) {

        indexMetaNew.putAll( [run  : coreMeta.RUN ] + indexMeta ) }

    // update original header
    else {

        // update original fields as required
        def fieldMeta = coreMeta.INFO.FIELDS

            .collectEntries { key ->
                def field = key.equals('name')
                    ? 'RUN' // updated; use run for name field
                    : key   // original
                return  [ (key) : coreMeta[field] ] }

        // original fields including updates
        if ( !args.INTERMEDIATE ) {

            indexMetaNew.putAll(fieldMeta) }

        // original fields including intermediary info
        else {

            // tag intermediary info
            def intermediaryMeta = indexMeta
                .collectEntries{ key, value ->
                    [ "${key}.${params.intTag}" : value ]}

            indexMetaNew.putAll( fieldMeta + intermediaryMeta ) }

        }

    return indexMetaNew }



def getFileInfo ( path, extensions ){

    def extensionRegex = !extensions 
        ? '[^.]+' // any extension
        : extensions.join('|') // extensions list

    def patternRegex = ~"(.*?)\\.(${extensionRegex})(?:\\.gz)?\$"

    def matcherRegex = file(path).getName() =~ patternRegex
    
    // check entire string matches
    assert matcherRegex.matches(): 
        "Unexpected filename; ${file(path).getName()} =~ $patternRegex "
    
    def fileName = matcherRegex[0][1]

    def fileExt =  matcherRegex[0][2]
    
    return [fileName, fileExt] }



def formatArguments (arguments, seperator, indent) {

	def argumentList = arguments

		.collect { flag, parameter -> 

			def argument = ((!parameter && !parameter == 0) || parameter == false) ? ''
				: (parameter == true) ? flag
				    : [flag, parameter].join(seperator)
			
			return argument }
		
		.join(" \\\n${indent}")

	return argumentList }



def formatTags( CONFIG ){

    // LOOKUP ALIAS
    def checkAlias = { original, aliasMap -> 
        
        def updated = (aliasMap && aliasMap.containsKey(original))
            ? aliasMap[(original)]
            : original 

        return updated }

    // software tag (OPTIONAL)
    def softwareTag = !CONFIG.LABEL.SOFTWARE 
        ? null
        : checkAlias(CONFIG.LABEL.SOFTWARE, CONFIG.LABEL.ALIASES)

    // version tag (OPTIONAL)
    def versionTag = !softwareTag || !CONFIG.VERSION
        ? null
        : "v${CONFIG.VERSION}"

    // extra tag (OPTIONAL)
    def preTag = CONFIG.LABEL.PRE ?: null

    // copy object
    def settings = CONFIG.ARGS.clone()

    // remove arguments with null flag alias
    CONFIG.LABEL.ALIASES
        .findAll{ key, value -> !value }
        .keySet()
        .each { key -> settings.remove(key) }

    // extract relevant argument info
    def argumentTags = !CONFIG.LABEL.INCLUDE

        // no tag
        ? [null]

        : !settings

            // default tag
            ? [checkAlias('DEFAULT', CONFIG.LABEL.ALIASES)] 

            : settings

                .collect{ flag, parameter -> 

                    // reformat flag
                    def flagTag = checkAlias(flag, CONFIG.LABEL.ALIASES)
                        .toString()
                        .replaceFirst('^-+', '')
                        .toLowerCase()

                    // reformat parameter
                    def parameterTag = checkAlias(parameter, CONFIG.LABEL.ALIASES)
                        .toString()
                        .replace(' ','')
                        .capitalize()

                    // argument tag (OPTIONAL)
                    def tag = "${flagTag}${parameterTag}"

                    return tag }

    // collect tags & remove null values
    def tagList = [
        softwareTag,
        versionTag,
        *argumentTags,
        preTag,
        ]
        .findAll()     

    return tagList }



def preStage( coreMeta, configMeta ){

    def runTagNew = [
        coreMeta.RUN,
        *formatTags(configMeta),
        ]
        .findAll() 
        .join('.')

    def coreMetaNew = coreMeta + [
        RUN     : runTagNew,
        STAGING : configMeta,
        ]

    return coreMetaNew }



def joinList( object, wrap = '\"', separator = ', ' ) {

    assert object instanceof List,
        "Unexpected list object; found \"${object.getClass()}\" class"

    def wrapped = object.collect{ item -> "${wrap}${item}${wrap}" }

    def joined = wrapped.size() > 1 
        ? "${wrapped.init().join(', ')} & ${wrapped.last()}"
        : wrapped.first()

    return joined

    }


/*
def getNestStructure( Map object, List keys = [] ) {

    assert object.size() == 1 && object.values().every { value -> value instanceof Map },
        "Unexpected output submap structure; found ${object.size()} levels containing ${joinList(object.values().collect{ value -> value.getClass()})}"

    def entry = object.entrySet().first()

    // recurse if nested suubmap i.e. [ key : [:] ]
    if (entry.value instanceof Map) {

        // store key
        keys << entry.key

        // stop before the leaf map (where values are no longer maps)
        if (entry.value.values().any { value -> value instanceof Map }) {

            getNestStructure(entry.value, keys) 
            
            } 
        
        }

    return keys }



def updateOutputs( coreMeta, outputMeta ){

    // extraxt nested keys except leaf submap
    def nestList = getNestStructure( outputMeta, [] )
    
    // check SOFTWARE -> COMMAND -> BRANCH
    assert nestList.size() == 3, 
        "Unexpected output map structure; found ${nestList.size()} levels \"${nestList.join(', ')}\", "
            
    def (software, command, branch) = nestList

    // initialise OUTPUTS
    def coreOutputMeta   = coreMeta.OUTPUTS            ?: [:]
    def coreSoftwareMeta = coreOutputMeta[(software)]  ?: [:]
    def coreCommandMeta  = coreSoftwareMeta[(command)] ?: [:]
    def coreBranchMeta   = coreCommandMeta[(branch)]   ?: [:]
    def coreLeafMeta     = outputMeta[(software)][(command)][(branch)]

    // flatten nested lists
    def leafMetaNew = coreLeafMeta
        .collectEntries { key, value ->
            def valueNew = value instanceof List 
                ? value.flatten() 
                : value
            return [(key): (valueNew)] }

    // update OUTPUTS
    def branchMetaNew   = coreBranchMeta   + leafMetaNew
    def commandMetaNew  = coreCommandMeta  + [ (branch) : branchMetaNew ]
    def softwareMetaNew = coreSoftwareMeta + [ (command) : commandMetaNew ]
    def outputMetaNew   = coreOutputMeta   + [ (software) : softwareMetaNew ]

    return outputMetaNew }
*/



def getNestStructure( outputMeta, keyList = []) {
    
    // init structure store
    def structureList = []
    
    outputMeta

        // iterate output map keys
        .each { key, value ->

            // init path store
            def pathList = keyList + key

            value instanceof Map && !value.isEmpty()

                // recurse if nested submap
                ? structureList.addAll( getNestStructure(value, pathList) )
            
                // store path minus leaf within structure
                : structureList << pathList[0..-2]

            }

    // remove duplicate paths
    return structureList.unique() }



def updateNestPath( coreOutputMeta, outputMeta, pathList ) {

    // check SOFTWARE -> COMMAND -> BRANCH
    assert pathList.size() == 3, 
        "Unexpected output map structure; found ${pathList.size()} levels \"${pathList.join(', ')}\", "

    def ( software, command, branch ) = pathList

    // initialise path maps
    def coreSoftwareMeta = coreOutputMeta[(software)]  ?: [:]
    def coreCommandMeta  = coreSoftwareMeta[(command)] ?: [:]
    def coreBranchMeta   = coreCommandMeta[(branch)]   ?: [:]
    def coreLeafMeta     = outputMeta[(software)][(command)][(branch)]

    // flatten nested leaf lists
    def leafMetaNew = coreLeafMeta
        .collectEntries { key, value ->
            def valueNew = value instanceof List 
                ? value.flatten() 
                : value
            return [(key): (valueNew)] }

    // update OUTPUTS
    def branchMetaNew   = coreBranchMeta   + leafMetaNew
    def commandMetaNew  = coreCommandMeta  + [ (branch) : branchMetaNew ]
    def softwareMetaNew = coreSoftwareMeta + [ (command) : commandMetaNew ]
    def outputMetaNew   = coreOutputMeta   + [ (software) : softwareMetaNew ]

    return outputMetaNew }



def packageSubMap( subPath, value ){

    def subMap = subPath
        .reverse()
        .inject( value ) { acc, key -> return [(key): acc] }

    return subMap }



def updateOutputs( coreMeta, outputMeta ){

    // extract nested keys except leaf submap
    def structureList = getNestStructure( outputMeta, [] )

    // initialise OUTPUTS
    def coreOutputs = coreMeta.OUTPUTS ?: [:]

    structureList
        
        // iterate paths
        .each{ pathList ->
            
            // update individual paths
            coreOutputs = updateNestPath(coreOutputs, outputMeta, pathList ) }
    
    return coreOutputs }



def viewMeta( mapObj, entryID = null, linkList = [], level = 0 ){
    
    assert mapObj instanceof Map:
        "No map object found |$mapObj|"

    def seperator = ' ----------'
    
    // assign random ID if absent
    entryID = entryID ?: UUID.randomUUID().toString().toUpperCase().take(6)
        
    if ( level.equals(0) ) {  println("// ENTRY: $entryID\n$seperator") }

    mapObj
        .each{ key, value ->

            def newPath = linkList + key

            // recurse if nested submap 
            if (value instanceof Map) { viewMeta( value, entryID, newPath, level+1 ) }

            else {
                
                // conform list as required
                def valueList = value instanceof List
                    ?  value
                    : [value]

                println( " | ${newPath.join(' > ')}: (${valueList.size()})" )
                valueList
                    .each{ leaf -> 

                        def info = leaf

                        // extract basename & hash if process output
                        if (leaf instanceof Path){

                            // split path into segments
                            def segmentList = leaf.toString().replace('\\', '/').split('/') as List
                            
                            // get "work" segment index
                            def workIndex = segmentList.indexOf('work')

                            // get hash segments
                            def hashList = workIndex >= 0 && segmentList.size() > workIndex+2
                                ? segmentList[workIndex+1 .. workIndex+2]
                                : null
                            
                            info = "\'${leaf.getFileName()}\'; ${hashList.join('/')}"
                            
                            }

                        println("\t- $info") 
                        
                        }
                
                println("$seperator")   
                }

            }

    if ( level.equals(0) ) {  println("//\n\n") }

    return } 



def postStage( coreMeta, outputMeta ){

    def runTagNew = [
        coreMeta.RUN,
        coreMeta.STAGING.LABEL.POST,
        ]
        .findAll() 
        .join('.')

    def outputMetaNew = updateOutputs(coreMeta, outputMeta)
    
    def coreMetaNew = coreMeta + [
        RUN     : runTagNew,
        STAGING : null,
        OUTPUTS : outputMetaNew,
        ] 

    return coreMetaNew }



def splitOutputs( coreMeta, outputMeta, splitTag = null ){

    def runTagNew = [
        coreMeta.RUN,
        splitTag,
        ]
        .findAll() 
        .join('.')

    def outputMetaNew = updateOutputs(coreMeta, outputMeta)
    
    def coreMetaNew = coreMeta + [
        RUN     : runTagNew,
        OUTPUTS : outputMetaNew,
        ] 

    return coreMetaNew }



def getGroupKey( groupTag, groupPrefix = null ){

    def groupKey = [
        groupPrefix,
        groupTag,
        ]
        .findAll() 
        .join('.')

    return groupKey }



def groupOutputs( coreMeta, outputMeta, groupKey ){

    def outputMetaNew = updateOutputs(coreMeta, outputMeta)
    
    def coreMetaNew = coreMeta + [
        name    : groupKey,
        RUN     : groupKey,
        OUTPUTS : outputMetaNew,
        ] 

    return coreMetaNew }



def flattenMap( mapObj ) {

    def flatMap = mapObj.collectEntries { key, value ->

        value instanceof Map 
            // recurse if nested submap
            ? flattenMap(value).collectEntries{ subKey, subValue -> [ ("${key}_${subKey}"): subValue ] }
            // return flattened submap path
            : [ (key) : value ]
        }

    return flatMap }



def getSubMap( mapObj, pathList ){

    def subMap = [:]

    // validate nested structure
    pathList.each { subPath ->

        def targetValue = subPath.inject(mapObj) { accumulator, key ->

            // Check submap parent available within layer (will fail anyway e.g. cannot get property 'KEY' on null object)
            if (accumulator == null) {
                throw new Exception("Subpath not found; nested parent missing for key \"$key\"") }

            // 2. Check if the specific key exists in the current container
            if (!(accumulator instanceof Map) || !accumulator.containsKey(key)) {
                throw new Exception("Subpath not found; key \"$key\" missing in nested parent (${accumulator instanceof Map ? accumulator.keySet() : 'not a map'})") }
            
            return accumulator."$key" }

        // store within submap
        def current = subMap

        subPath.eachWithIndex { key, idx ->

            // create nested path (as required)
            if (idx != subPath.size() - 1) {

                current[key] = current[key] ?: [:]

                current = current[key] }

            // store leaf
            else {

                current[key] = targetValue } 
            
            }

        }

    return subMap }



def formatBasepairs (value) {

    // default
    def unit = 'bp'

    // gb
    if (value >= 10**9) {
        unit = 'g'
        value = value / 10**9 }
    
    // mb
    else if (value >= 10**6) {
        unit = 'm'
        value = value / 10**6 }
    
    // kb
    //else (value >= 10*3) {
    //    unit = 'k'
    //    value = value / 10**3 }

    return "$value$unit" }

def makeTag( args ){
    
    def tagList   = args.tags
    def delimiter = args.delimiter
    
    def tag = tagList
        // remove null
        .findAll()
        // join tags
        .join(delimiter)

    return tag }



def makeComplement(originalSeq) { // , reverse

    def complementMap = [ 
        A:'T', T:'A', G:'C', C:'G', U:'A', N:'N',
        S:'S', W:'W', K:'M', M:'K', Y:'R', R:'Y', 
        B:'V', V:'B', D:'H', H:'D', 
        ]

    def complementSeq = originalSeq
        .toUpperCase()
        .collect { base -> complementMap[ base ] ?: 'X' }
        .join()
    
    def modifiedSeq = complementSeq // !reverse ? complementSeq : complementSeq.reverse()

    return modifiedSeq }
