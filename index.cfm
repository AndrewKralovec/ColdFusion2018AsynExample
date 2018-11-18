<h3>Async Example</h3> 
 
<cfform name="asyncForm" 
    format="XML" 
    skin="basiccss"> 
    <cftextarea name="textInput" 
        wrap="virtual"
        rows="10" 
        cols="100" 
        validateAt="onBlur">https://en.wikipedia.org/wiki/Adobe_ColdFusion</cftextarea>
    <cfinput type="submit" name="submitInput" value="Submit"> 
</cfform>

<cfif isdefined("form.textInput") AND (form.textInput NEQ "")> 
    <cfset handler = CreateObject("component", "asyncHandler") > 
    <cfset urls = reReplace(trim(form.textInput), '\n', ',', 'ALL')> 
    <cfset futureArray = handler.run(listToArray(urls))>

    <cfloop array="#futureArray#" item="future">
        <cfset result = future.get()> 
        <cfdump var="#result#">
    </cfloop>
</cfif> 