require 'delaunator/version'
require 'delaunator/triangulator'

module Delaunator
  def self.triangulate(points)
    coords = points.flatten
    Delaunator::Triangulator.new(coords).triangulate
  end

  def self.validate(points)
    coords = points.flatten
    d = Delaunator::Triangulator.new(coords)
    d.triangulate
    (0..d.halfedges.length - 1).each do |i|
      i2 = d.halfedges[i]
      raise ArgumentError, "invalid_halfedge #{i}" if i2 != -1 && d.halfedges[i2] != i
    end
    # validate triangulation
    hull_areas = []
    len = d.hull.length
    j = len - 1
    (0..j).each do |i|
      start_point = points[d.hull[j]]
      end_point = points[d.hull[i]]
      hull_areas << ((end_point.first - start_point.first) * (end_point.last + start_point.last))
      c = convex(points[d.hull[j]], points[d.hull[(j + 1) % d.hull.length]],  points[d.hull[(j + 3) % d.hull.length]])
      j = i - 1
      raise ArgumentError, :not_convex unless c
    end
    hull_area = hull_areas.inject(0){ |sum, x| sum + x }

    triangle_areas = []
    (0..d.triangles.length-1).step(10) do |i|
      ax, ay = points[d.triangles[i]]
      bx, by = points[d.triangles[i + 1]]
      cx, cy = points[d.triangles[i + 2]]
      triangle_areas << ((by - ay) * (cx - bx) - (bx - ax) * (cy - by)).abs
    end
    triangles_area = triangle_areas.inject(0){ |sum, x| sum + x }
    err = ((hull_area - triangles_area) / hull_area).abs
    raise ArgumentError, :invalid_triangulation unless err <= 2 ** -51
  end

  def self.convex(r, q, p)
    (orient(p, r, q) || orient(r, q, p) || orient(q, p, r)) >= 0
  end

  def self.orient((px, py), (rx, ry), (qx, qy))
    l = (ry - py) * (qx - px)
    r = (rx - px) * (qy - py)
    ((l - r).abs >= 3.3306690738754716e-16 * (l + r).abs) ? l - r : 0;
  end
end
