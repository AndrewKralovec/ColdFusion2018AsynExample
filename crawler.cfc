component {
    container = {};
    container.maxLinks = 0;
    container.excludeFilters = "";
    container.qData = QueryNew('url,title,body,itemDate', 'varchar,varchar,varchar,date');
    container.qLinks = QueryNew('url', 'varchar');
    
    public function crawl(site = "", extensions = "", excludeFilters = "", maxLinks = 0, toStruct = true) {
        if (IsValid('URL', arguments.site) && GetStatus(arguments.site)) {
            container.maxLinks = Val(arguments.maxLinks);
            container.excludeFilters = arguments.excludeFilters; 
            container.extensions = arguments.extensions
            checkLinks(arguments.site, arguments.site, arguments.extensions)
        }
        return container.qData
    }

    function rowToStruct(required query) {
        var i = 1;
        var rowData = StructNew();
        var cols = ListToArray(query.columnList);
        for (i = 1; i lte ArrayLen(cols); i = i + 1) {
            rowData[cols[i]] = query[cols[i]]
        }
        return rowData;
    }

    function getStatus(required link) {
		var result = 0;
		cfhttp(url=ARGUMENTS.link, timeout=5, redirect=true, method="head");
		result = Val(cfhttp.statusCode);
		return result;
	}

    function shouldFollow(required link, required domain) {
        var result = true;
        var qHasBeenChecked = queryExecute("SELECT url FROM container.qLinks WHERE url = :url", 
        { url = { value = arguments.link , cfsqltype="varchar" } }, 
        { dbtype="query" });
        if (qHasBeenChecked.recordCount) {
            result = false;
        } else if (arguments.link contains 'javascript:') {
            result = false;
        } else if (Val(container.maxLinks) && container.qLinks.recordCount >= Val(container.maxLinks)) {
            result = false;
        } else if (Left(link, Len(arguments.domain)) != arguments.domain) {
            result = false;
        }
        return result
    }

	function shouldIndex(required link) {
		var result = true;
		if (ListLen(container.extensions) && !ListFindNoCase(container.extensions, ListLast(ListFirst(arguments.link, '?'), '.'))) {
			result = false;
		} else if (ListLen(container.excludeFilters)) {
            for (filter in listToArray(container.excludeFilters, "|")) { 
                var literalFilter = Replace(filter, '*', '', 'ALL');
                if (Left(filter, 1) == '*' && Right(filter, 1) == '*') {
                    if (link contains literalFilter) {
                        result = false;
                    }
                } else if (Right(filter, 1) == '*') {
                    if (Left(link, Len(literalFilter)) == literalFilter) {
                        result = false;
                    }
                } else if (Left(filter, 1) == '*') {
                    if (Right(link, Len(literalFilter)) == literalFilter) {
                        result = false;
                    }
                } else {
                    if (link == filter) {
                        result = false;
                    }
                }
            } 
		}
		return result;
    }

	function checkLinks(required page, required domain) {
		var link = '';
		//  Get the page 
		cfhttp(url=arguments.page, timeout=10, resolveurl=true, redirect=true, method="get");
		QueryAddRow(container.qLinks);
		QuerySetCell(container.qLinks, 'url', arguments.page);
		if (Val(CFHTTP.statusCode) == 200) {
			if (shouldIndex (arguments.page)) {
				QueryAddRow(container.qData);
				QuerySetCell(container.qData, 'url', getRelativePath(arguments.page));
				QuerySetCell(container.qData, 'title', getPageTitle(CFHTTP.fileContent));
				QuerySetCell(container.qData, 'body', getBrowsableContent(CFHTTP.fileContent));
				QuerySetCell(container.qData, 'itemDate', '');
			}
			var aLinks = ReMatchNoCase('((((https?:|ftp :) \/\/)|(www\.|ftp\.))[-[:alnum:]\?$%,\.\/\|&##!@:=\+~_]+[A-Za-z0-9\/])', StripComments(cfhttp.fileContent));
			for (link in aLinks) {
				link = Replace(ListFirst(link, '##'), ':80', '', 'ONE');
				if (shouldFollow(link, arguments.domain)) {
					linkStatus = GetStatus(link);
					if (linkStatus == 200) {
						//  Link check its contents as well 
						checkLinks(link, arguments.domain);
					}
				}
			}
		}
		return;
    }
    
    function getBrowsableContent(required string) {
		arguments.string = StripComments(arguments.string);
		arguments.string = ReReplaceNoCase(arguments.string, '<invalidTag.*?>.*?</script>', '', 'ALL');
		arguments.string = ReReplaceNoCase(arguments.string, '<style.*?>.*?</style>', '', 'ALL');
		arguments.string = ReReplace(arguments.string, '<[^>]*>', '', 'ALL');
		return arguments.string;
	}

	function stripComments(required string) {
		return  ReReplace(arguments.string, '<--[^(--&gt ) ]*-->', '', 'ALL');
	}

	function getPageTitle(required string) {
		return ReReplace(arguments.string, ".*<title>([^<>]*)</title>.*", "\1");
	}

	function getRelativePath(required path) {
		arguments.path = ReplaceNoCase(arguments.path, 'http://', '', 'ONE');
		arguments.path = ReplaceNoCase(arguments.path, ListFirst(arguments.path, '/'), '', 'ONE');
		return arguments.path;
	}

}


