var width = parseInt(d3.select('#friend_graph').style('width'), 10),
    height = 500;

var force = d3.layout.force()
    .charge(-120)
    .linkDistance(30)
    .size([width, height]);

var canvas = d3.select("#friend_graph").append("canvas")
    .attr("width", width)
    .attr("height", height)

d3.json("friend_graph.json", function(error, graph) {
  var context = canvas.node().getContext("2d");

  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start();

  // for(i = 0; i < graph.nodes.length; i++) {
  //   graph.nodes[i].r = 2
  // }

  // draw = function() {
  //     canvas.clearRect(0, 0, width, height);
  //     canvas.beginPath();
  //     var i = -1, cx, cy;
  //     while (++i < graph.nodes.length) {
  //       d = graph.nodes[i];
  //       cx = x( d.x );
  //       cy = y( d.y );
  //       canvas.moveTo(cx, cy);
  //       // canvas.arc(cx, cy, d.r, 0, 2 * Math.PI);
  //       canvas.arc(cx, cy, 2, 0, 2 * Math.PI);
  //     }
  //     canvas.fill();
  // };

  // var link = svg.selectAll(".link")
  //     .data(graph.links)
  //   .enter().append("line")
  //     .attr("class", "link")
  //     .style("stroke-width", function(d) { return Math.sqrt(d.value); })
  //     .style("visibility", "hidden");

  // var node = svg.selectAll(".node")
  //     .data(graph.nodes)
  //   .enter().append("circle")
  //     .attr("class", "node")
  //     .attr("r", 2);
      // .style("fill", function(d) { return color(d.group); })
      // .call(force.drag);

  // node.append("title")
  //     .text(function(d) { return d.sceen_name; });

  force.on("tick", function() {
    context.clearRect(0, 0, width, height);

    context.strokeStyle = "#ccc";
    context.beginPath();
    graph.links.forEach(function(d) {
      context.moveTo(d.source.x, d.source.y);
      context.lineTo(d.target.x, d.target.y);
    });
    context.stroke();

    context.fillStyle = "steelblue";
    context.beginPath();
    graph.nodes.forEach(function(d) {
      context.moveTo(d.x, d.y);
      context.arc(d.x, d.y, 2, 0, 2 * Math.PI);
    });
    context.fill();

    // link.attr("x1", function(d) { return d.source.x; })
    //     .attr("y1", function(d) { return d.source.y; })
    //     .attr("x2", function(d) { return d.target.x; })
    //     .attr("y2", function(d) { return d.target.y; });

    // node.attr("cx", function(d) { return d.x; })
    //     .attr("cy", function(d) { return d.y; });
  });
});
