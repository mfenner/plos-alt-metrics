Welcome to ScienceCard
======================

ScienceCard is a web service that collects all scientific works published by an author and displays their aggregate work-level metrics. ScienceCard allows a researcher to create and maintain a researcher profile with minimal effort, and to export and reuse this information elsewhere. To make this as effortless as possible, ScienceCard relies on unique identifiers for authors (currently identifiers from Microsoft Academic Search and AuthorClaim) and works (currently digital object identifiers or DOIs). Future versions will add more author identifiers services, including ORCID when the service launches in 2012, as well as other identifiers for scholarly content (e.g. from ArXiV).

ScienceCard uses freely available sources for the work-level metrics. Some sources are only available from some publishers (e.g. HTML page views or PDF downloads), or when you are a publisher yourself (e.g. CrossRef).

Getting Started
---------------

You can search for ScienceCards by user name or Twitter nickname. You can also go directly to a ScienceCard using the Twitter nickname, e.g. http://sciencecard.org/mfenner. Only ScienceCards of users that have registered with ScienceCard are displayed.

To create your own ScienceCard, create an account by logging in via Twitter. Next add at least one author identifier - currently Microsoft Academic Search and AuthorClaim are supported.

ScienceCard will then fetch all papers associated with this author identifier, and their available work-level metrics (citations, bookmarks, etc.). This may take a while, so you should revisit some time after registering. Once set up, the publications and work-level metrics are then automatically updated.

The Content
-----------

ScienceCard would not be possible without the content retrieved from Twitter, Mendeley, PubMed Central, CiteULike, Scopus, Microsoft Academic Search and CrossRef. Other services will be added in the future.

The ScienceCard API
-------------------

ScienceCard is not only a website, but also provides an Application Programming Interface (API) so that the content can be reused elsewhere. All author pages are available in html, json, xml, csv, bib and ris formats, simply append the format to the author page, e.g. http://sciencecard.org/mfenner.json or http://sciencecard.org/mfenner.bib. You can import references into your reference manager using the bib or ris format. The Contact Info Options Wordpress plugin adds a ScienceCard field to the user profile, so you can display ScienceCard information in your Wordpress author page.

Setting up your own Server
--------------------------

ScienceCard is an open source application based on the PLoS Article-Level Metrics Developer API Server. This means that you can download and install the software and run your own ScienceCard server. here are at least two good reasons to do this: a) you are a publisher and want to provide work-level metrics for your authors or b) you are an institution and want to provide these metrics for your researchers. ScienceCard uses the Ruby on Rails web framework and can easily be extended, e.g. if you want to allow researchers to log in using their institutional accounts.

More Information
----------------

For more information about this application, please visit the Github repository at https://github.com/mfenner/plos-alt-metrics. This code is based on the PLoS Article-Level Metrics Developer API Server, more information is at http://work-level-metrics.plos.org/. Some icons by Glyphish. For questions about ScienceCard please contact Martin Fenner at his Blog, at Github or via Twitter.