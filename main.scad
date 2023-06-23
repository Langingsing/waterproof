include <constants.scad>

close = false;


mirror_normal=[1,0];

module one_circle(pos) { 
  translate(pos)
  circle(r=box_border_r);
}

module two_circles(pos) {
  one_circle(pos);
  
  mirror([1,0])
    one_circle(pos);
}

module four_circles(pos) {
  two_circles(pos);
  
  mirror([0,1])
    two_circles(pos);  
}

module box2d(pos) {
  hull()
    four_circles(pos);
}

module box(pos, h) {
  linear_extrude(h)
    box2d(pos);
}

module hinge2d() {
difference() {
  union(){
  circle(r=handler_hinge_r);
    translate([-handler_hinge_r,0])
  square([handler_hinge_r*2,handler_hinge_r]);
}
  circle(d=latch_d);
}
}
module hinge() {
  translate([0,0,handler_hinge_r])
  rotate([0,90,0])
  linear_extrude(handler_hinge_len,center=true)
  hinge2d();
}

module bottom_hinge() {
translate([-hinge_center_x,-box_w/2-handler_hinge_r+EPSILON,0])
hinge();
}

module ear() {
  translate([handler_hinge_r,0])
  rotate([0,0,90])
  linear_extrude(ear_h)
  hinge2d();
}

module box_ear() {
  translate([box_l/2-EPSILON,0,box_h-ear_h])
  ear();
}

module lid_ear() {
  translate([box_l/2-EPSILON,0,0])
  ear();
}

module whistle2d() {
  r=handler_hinge_r;
difference() {
  union(){
  circle(r=r);
    polygon([
      [-r,0],
      [r*cos(45),r*sin(45)],
      [-r,r/tan(45/2)],
    ]);
}
  circle(d=latch_d);
}
}

module whistle() {  
  translate([0,handler_hinge_r,0])
  rotate([90,0,90])
  linear_extrude(handler_hinge_len,center=true)
  whistle2d();
}

module top_hinge_pair() {
translate([-hinge_center_x-handler_hinge_len,box_w/2-EPSILON,box_h])
  mirror([0,0,1])
whistle();
translate([-hinge_center_x+handler_hinge_len,box_w/2-EPSILON,box_h])
  mirror([0,0,1])
whistle();
}

outer_pos=position(0);
inner_pos=position(5);
function position(index_to_outer)=let (len=box_thickness*index_to_outer/5)[box_l/2-box_border_r-len,box_w/2-box_border_r-len];
// case
difference() {
  box(outer_pos, box_h);
  
  translate([0,0,box_thickness+EPSILON])
  box(inner_pos, box_h-box_thickness);
  
  translate([0,0,box_h-box_thickness+EPSILON])
  box(position(1), box_thickness);
}
// inner round ridge
translate([0,0,box_h-box_thickness+EPSILON])
linear_extrude(box_thickness)
difference() {
  box2d(position(4));
  box2d(inner_pos);
}
bottom_hinge();
mirror(mirror_normal)
  bottom_hinge();

top_hinge_pair();
mirror(mirror_normal)
  top_hinge_pair();

// ears
box_ear();
mirror(mirror_normal)
  box_ear();

lid_h = handler_hinge_r / tan(45/2);
module lid() {
  color([1,1,.6],.7)
  box(outer_pos, lid_h);
  
  // round ridge
  color([.4,.8,.4])
  translate([0,0,-round_ridge+EPSILON])
  linear_extrude(round_ridge)
  difference() {
    box2d(position(2));
    box2d(position(3));
  }
  
  // line ridge
  translate([0,(-box_w+line_ridge)/2, lid_h+line_ridge/2])
  cube([box_l-30,line_ridge,line_ridge],center=true);
  
  translate([0,box_w/2-EPSILON]){
    translate([-hinge_center_x,0])
      whistle();
    translate([hinge_center_x,0])
      whistle();
  }
  // ears
  lid_ear();
  mirror(mirror_normal)
    lid_ear();
}

translate([0,0,box_h+(close?0:50)])
lid();

module handler2d() {
  circle_translate = [5,5];
  handler_hinge_d=2*handler_hinge_r;

  difference() {
    union(){
      translate(circle_translate)
        circle(r=handler_hinge_r);
      h=lid_h+box_h;
      translate([0,5])
        polygon([
          [0,0],
          [handler_hinge_d,0],
          [handler_hinge_d,h],
          [-2*line_ridge,h],
          [-2*line_ridge,h-5],
          [-line_ridge,h-5],
          [-line_ridge,h-3],
          [0,h-3],
        ]);
    }
    translate(circle_translate)
      circle(d=latch_d);
  }
}

module handler(width) {
  render()
  difference() {
    linear_extrude(width)
      handler2d();
    translate([0,0,(width-handler_hinge_len)/2])
      cube([handler_hinge_r*2,handler_hinge_r*2,handler_hinge_len]);
  }
}

module one_handler(width = 36){
  translate([width/2-hinge_center_x,-box_w/2-(close?0:20),0])
  rotate([90,0,-90])
  handler(width);
}

one_handler();
mirror(mirror_normal)
  one_handler();







