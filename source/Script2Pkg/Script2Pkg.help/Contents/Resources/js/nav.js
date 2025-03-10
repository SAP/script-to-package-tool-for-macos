$(function(){
    $("#tree").resizable({
        handles: "e"
    }); 
    $("#tree").fancytree({
        autoActivate: false,
        autoCollapse: false,
        autoFocus: false, 
        autoScroll: false,
        icons: false, 
        clickFolderMode: 1, 
        minExpandLevel: 1, 
        tabbable: false, 
        focus: function(event, data) {
            var node = data.node; 
            if(node.data.href){
				node.scheduleAction("activate", 1000);
			}
		}, 
		blur: function(event, data) {
			data.node.scheduleAction("cancel");
		}, 
		activate: function(event, data) {
			var node = data.node; 
			if (node.data.href) {
				$("#content").load(node.data.href); 
				if (window.history && parent.history.pushState) {
					window.history.pushState({title: node.title}, "", "?" + (node.data.href || ""));
				}
			}
		},
	});
});

function expandAll(tree) {
	tree.getRootNode().visit(function(node) {
		node.setExpanded(true);
	});	
}

function pageName(partialUrl) {
	var result = partialUrl;
	var queryLocation = partialUrl.lastIndexOf("?");
	if (queryLocation >= 0) {
		result = result.substring(queryLocation + 1);
	}
}

$(function() {
	window.onpopstate = function(event) { 
		var location = document.location.href;
		var pos = location.lastIndexOf("?"); 
		if (pos == -1) {
			tree.getFirstChild().setActive();
			tree.getRootNode().visit(function(node) {
				node.setExpanded(true); 
			});
	  	return;
		} 
		var href = location.substring(pos + 1, document.location.length); 
		var tree = $("#tree").fancytree("getTree"); 
		tree.visit(function(n) {
			if (n.data.href && n.data.href.toLowerCase() === href.toLowerCase()) {
				n.setActive(true, {noEvents:true});
				$("#content").load(n.data.href);
				return false;
			} 
			return true;
		});
 	};
});

$(function(){
	/*$("#debug").text(document.location.href);*/
	var tree = $("#tree").fancytree("getTree");
	var location = document.location.href;
	var pos = location.lastIndexOf("?");
	if (pos == -1) {
		tree.getFirstChild().setActive();
		var pageName = location.substring(location.lastIndexOf("/") + 1);
		if (pageName === "index.html") {
			expandAll(tree);
		}
	} else {
		var href = location.substring(pos + 1, document.location.length); 
		var fragment = href.lastIndexOf("#");
		var testHref = href;
		if(fragment != -1) {
			testHref = href.substring(0, fragment);
		}
		tree.visit(function(n) {
			if (n.data.href && n.data.href.toLowerCase() === testHref.toLowerCase()) {
				n.setActive(true, {noEvents:true});

				var loadString = n.data.href;
				var fragment = location.lastIndexOf("#");
				if (fragment != -1) {
					loadString = loadString + " " + location.substring(fragment + 1);
				}
				   
				$("#content").load(n.data.href);
				var pageName = location.substring(location.lastIndexOf("/") + 1);
				if (pageName === "index.html") {
					expandAll(tree);
				}
				else {
					n.setExpanded(true); 
				}
			}
		});
  } });