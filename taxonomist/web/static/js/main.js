var width = parseInt(d3.select('#friend_graph').style('width'), 10),
    height = 400;

var force = d3.layout.force()
    .linkDistance(50)
    .friction(0.8)
    .charge(-100)
    .gravity(0.2)
    .size([width, height]);

var svg = d3.select("#friend_graph").append("svg")
    .attr("width", width)
    .attr("height", height);

d3.json("friend_graph.json", function(error, graph) {
  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start();

  var link = svg.selectAll(".link")
      .data(graph.links)
    .enter().append("line")
      .attr("class", "link");

  var node = svg.selectAll(".node")
      .data(graph.nodes)
    .enter().append("circle")
      .attr("class", "node")
      .attr("r", 2);

  node.append("title")
      .text(function(d) { return d.sceen_name; });

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node.attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });
  });
});
