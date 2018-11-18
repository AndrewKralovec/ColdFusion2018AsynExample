component {

    public function run(urls) {
        var result = [];
        for(item in arguments.urls) {
            result.append(
                runasync(function() {
                    return item
                })
                .then(crawlUrl)
                .error(errorHandler)
            );
        }
        return result;
    }

    function crawlUrl(url) {
        var webCrawler = CreateObject("component", "crawler");
        return webCrawler.crawl(site = arguments.url);
    }
        
    function errorHandler() {
        throw (message="Error processing data!!!", type="error");
    }
}
