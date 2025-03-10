/*
 Allows redirection from a topic page to index.html, e.g. index.html?TopicPage.html
 */
if (!document.getElementById("tree")) {
    var currentPage = top.location.href.substring(top.location.href.lastIndexOf("/") + 1, top.location.href.length);
    top.location.href = "index.html?" + currentPage;
}
