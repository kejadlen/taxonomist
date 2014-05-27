var width = $( ".force" ).width(),
    height = $( window ).height();

var force = d3.layout.force()
    .size([width, height]);

var svg = d3.select(".force").append("svg")
    .attr("width", width)
    .attr("height", height);

var link = svg.selectAll(".link"),
    node = svg.selectAll(".node");

d3.json("friends.json", function(error, data) {
  force
      .nodes(data.nodes)
      .links(data.links)
      .start();

  var link = svg.append("g").selectAll(".link")
      .data(data.links)
    .enter().append("line")
      .attr("class", "link");

  var circle = svg.append("g").selectAll("circle")
      .data(data.nodes)
    .enter().append("circle")
      .attr("r", 5)
      .call(force.drag);

  var text = svg.append("g").selectAll("text")
      .data(data.nodes)
    .enter().append("text")
      .attr("x", 8)
      .attr("y", ".31em")
      .text(function(d) { return d.screen_name; });

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    circle.attr("transform", function(d) { return "translate(" + [d.x, d.y] + ")"; });
    text.attr("transform", function(d) { return "translate(" + [d.x, d.y] + ")"; });
  });

  d3.select("#startstop").on("click", function() {
    if (this.value == "Stop") {
      this.value = "Start";
      force.stop();
    } else {
      this.value = "Stop";
      force.start();
    }
  });

  d3.select("#stop").on("click", function() {
    force.stop();
  });

  d3.select("#charge").on("change", function() {
    force.charge(this.value).start();
  });

  d3.select("#gravity").on("change", function() {
    force.gravity(this.value).start();
  });
});
