var width = parseInt(d3.select('#friend_graph').style('width'), 10),
    height = 400,
    scaleFactor = 1,
    translation = [0,0],
    link,
    node;

var zoomer = d3.behavior.zoom()
    .scaleExtent([0.1,10])
    .on("zoom", zoom);

function zoom() {
    console.log("zoom", d3.event.translate, d3.event.scale);
    scaleFactor = d3.event.scale;
    translation = d3.event.translate;
    tick(); //update positions
}

function tick() {
    link.attr("x1", function(d) { return translation[0] + scaleFactor*d.source.x; })
        .attr("y1", function(d) { return translation[1] + scaleFactor*d.source.y; })
        .attr("x2", function(d) { return translation[0] + scaleFactor*d.target.x; })
        .attr("y2", function(d) { return translation[1] + scaleFactor*d.target.y; });

    node.attr("cx", function(d) { return translation[0] + scaleFactor*d.x; })
        .attr("cy", function(d) { return translation[1] + scaleFactor*d.y; });
}

var force = d3.layout.force()
    .linkDistance(25)
    .friction(0.8)
    .charge(-75)
    .gravity(0.2)
    .size([width, height]);

var svg = d3.select("#friend_graph").append("svg")
    .attr("width", width)
    .attr("height", height)
    .call(zoomer);

d3.json("friend_graph.json", function(error, graph) {
  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start();

  link = svg.selectAll(".link")
      .data(graph.links)
    .enter().append("line")
      .attr("class", "link");

  node = svg.selectAll(".node")
      .data(graph.nodes)
    .enter().append("circle")
      .attr("class", "node")
      .attr("r", 2);

  node.append("title")
      .text(function(d) { return d.sceen_name; });

  force.on("tick", tick)
});
