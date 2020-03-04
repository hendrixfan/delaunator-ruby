module Delaunator
  class Triangulator
    attr_reader :halfedges, :hull, :triangles, :coords

    EPSILON = 2 ** -52

    EDGE_STACK = Array.new(512, 0)

    def initialize(coords)
      @coords = coords
      @n = @coords.length >> 1
      @max_triangles = [2 * @n - 5, 0].max
      @triangles_len = 0
      @_triangles = Array.new(@max_triangles * 3, 0)
      @_halfedges = Array.new(@max_triangles * 3, 0)

      @hash_size = Math.sqrt(@n).ceil
      @hull_prev = Array.new(@n, 0)
      @hull_next = Array.new(@n, 0)
      @hull_tri = Array.new(@n, 0)
      @hull_hash = Array.new(@hash_size, -1)
    end

    def triangulate
      dists = Array.new(@n, 0.0)
      ids = Array.new(@n, 0)
      min_x = Float::INFINITY
      min_y = Float::INFINITY
      max_x = -Float::INFINITY
      max_y = -Float::INFINITY
      # compute bounds
      (0..@n - 1).each do |i|
        x = @coords[2 * i]
        y = @coords[2 * i + 1]
        min_x = x if x < min_x
        min_y = y if y < min_y
        max_x = x if x > max_x
        max_y = y if y > max_y
      end

      cx = (min_x + max_x).to_f / 2
      cy = (min_y + max_y).to_f / 2
      min_dist = Float::INFINITY
      i0 = 0
      i1 = 0
      i2 = 0

      # pick a seed point close to midpoint i0
      (0..@n - 1).each do |i|
        d = dist(cx, cy, @coords[2 * i], @coords[2 * i + 1])
        if d < min_dist
          i0 = i
          min_dist = d
        end
      end
      i0x = @coords[2 * i0]
      i0y = @coords[2 * i0 + 1]

      min_dist = Float::INFINITY

      (0..@n - 1).each do |i|
        next if i == i0

        d = dist(i0x, i0y, @coords[2 * i], @coords[2 * i + 1])
        if (d < min_dist) && (d > 0)
          i1 = i
          min_dist = d
        end
      end
      i1x = @coords[2 * i1]
      i1y = @coords[2 * i1 + 1]

      min_radius = Float::INFINITY

      # find the third point which forms the smallest circumcircle with the first two

      (0..@n - 1).each do |i|
        next if (i == i0) || (i == i1)

        r = circumradius(i0x, i0y, i1x, i1y, @coords[2 * i], @coords[2 * i + 1])
        if r < min_radius
          i2 = i
          min_radius = r
        end
      end

      i2x = @coords[2 * i2]
      i2y = @coords[2 * i2 + 1]
      if min_radius == Float::INFINITY
        # order collinear points by dx (or dy if all x are identical)
        # and return the list as a hull
        (0..n - 1).each do |i|
          dists[i] = (@coords[2 * i] - @coords[0]) || (@coords[2 * i + 1] - @coords[1])
        end
        ids = dists.map.with_index.sort.map(&:last)
        @hull = Array.new(@n, 0)
        j = 0
        d0 = -Float::INFINITY
        (0..@n - 1).each do |i|
          id = ids[i]
          next unless dists[id] > d0

          @hull[j] = id
          j += 1
          d0 = dists[id]
        end
        @hull = hull.slice(0, j)
        @triangles = []
        @halfedges = []
        return
      end

      # swap the order of the seed points for counter-clockwise orientation
      if orient(i0x, i0y, i1x, i1y, i2x, i2y)
        i = i1
        x = i1x
        y = i1y
        i1 = i2
        i1x = i2x
        i1y = i2y
        i2 = i
        i2x = x
        i2y = y
      end
      center = circumcenter(i0x, i0y, i1x, i1y, i2x, i2y)
      @cx, @cy = center

      (0..@n - 1).each do |k|
        dists[k] = dist(@coords[2 * k], @coords[2 * k + 1], center[0], center[1])
      end
      # sort the points by distance from the seed triangle circumcenter
      ids = dists.map.with_index.sort.map(&:last)

      @hull_start = i0
      @hull_size = 3

      @hull_next[i0] = @hull_prev[i2] = i1
      @hull_next[i1] = @hull_prev[i0] = i2
      @hull_next[i2] = @hull_prev[i1] = i0

      @hull_tri[i0] = 0
      @hull_tri[i1] = 1
      @hull_tri[i2] = 2

      @hull_hash.fill(-1)
      @hull_hash[hash_key(i0x, i0y)] = i0
      @hull_hash[hash_key(i1x, i1y)] = i1
      @hull_hash[hash_key(i2x, i2y)] = i2

      @triangles_len = 0
      add_triangle(i0, i1, i2, -1, -1, -1)
      xp = 0
      yp = 0
      (0..ids.length - 1).each do |k|
        i = ids[k]
        x = @coords[2 * i]
        y = @coords[2 * i + 1]
        if (k > 0 && (x - xp).abs <= EPSILON && (y - yp).abs <= EPSILON)
          next
        end
        xp = x
        yp = y
        #skip seed triangle points
        if i == i0 || i == i1 || i == i2
          next
        end
        # find a visible edge on the convex hull using edge hash

        start = 0

        key = hash_key(x, y)
        (0..@hash_size - 1).each do |m|
          start = @hull_hash[(key + m) % @hash_size]
          break if (start != -1) && (start != @hull_next[start])
        end
        start = @hull_prev[start]
        e = start
        q = nil
        loop do
          q = @hull_next[e]
          break if orient(x, y, @coords[2 * e], @coords[2 * e + 1], @coords[2 * q], @coords[2 * q + 1])
          e = q
          if e == start
            e = -1
            break
          end
        end

        if e == -1
          next
        end
        t = add_triangle(e, i, @hull_next[e], -1, -1, @hull_tri[e])
        @hull_tri[i] = legalize(t + 2)
        @hull_tri[e] = t
        @hull_size += 1
        n = @hull_next[e]
        loop do
          q = @hull_next[n]
          break if !orient(x, y, @coords[2 * n], @coords[2 * n + 1], @coords[2 * q], @coords[2 * q + 1])
          t = add_triangle(n, i, q, @hull_tri[i], -1, @hull_tri[n])
          @hull_tri[i] = legalize(t + 2)
          @hull_next[n] = n
          @hull_size -= 1
          n = q
        end

        if e == start
          loop do
            q = @hull_prev[e]
            break if !orient(x, y, @coords[2 * q], @coords[2 * q + 1], @coords[2 * e], @coords[2 * e + 1])

            t = add_triangle(q, i, e, -1, @hull_tri[e], @hull_tri[q])

            legalize(t + 2)
            @hull_tri[q] = t
            @hull_next[e] = e
            @hull_size -= 1
            e = q
          end
        end
        @hull_start = e
        @hull_prev[i] = e
        @hull_next[e] = i
        @hull_prev[n] = i
        @hull_next[i] = n

        # save the two new edges in the hash table
        @hull_hash[hash_key(x, y)] = i
        @hull_hash[hash_key(@coords[2 * e], @coords[2 * e + 1])] = e
      end
      @hull = Array.new(@hull_size, 0)
      e = @hull_start
      (0..@hull_size - 1).each do |k|
        @hull[k] = e
        e = @hull_next[e]
      end

      # trim typed triangle mesh arrays
      @halfedges = @_halfedges.slice(0, @triangles_len)
      @triangles = @_triangles.slice(0, @triangles_len)
      @triangles
    end

    def dist(ax, ay, bx, by)
      dx = ax - bx
      dy = ay - by
      dx * dx + dy * dy
    end

    # return 2d orientation sign if we're confident in it through J. Shewchuk's error bound check
    def orient_if_sure(px, py, rx, ry, qx, qy)
      l = (ry - py) * (qx - px)
      r = (rx - px) * (qy - py)
      ((l - r).abs >= (3.3306690738754716e-16 * (l + r).abs)) ? l - r : 0
    end

    # a more robust orientation test that's stable in a given triangle (to fix robustness issues)
    def orient(rx, ry, qx, qy, px, py)
      (orient_if_sure(px, py, rx, ry, qx, qy) || orient_if_sure(rx, ry, qx, qy, px, py) || orient_if_sure(qx, qy, px, py, rx, ry)) < 0
    end

    def circumcenter(ax, ay, bx, by, cx, cy)
      dx = bx - ax
      dy = by - ay
      ex = cx - ax
      ey = cy - ay

      bl = dx * dx + dy * dy
      cl = ex * ex + ey * ey
      d = 0.5 / ( dx * ey - dy * ex).to_f

      x = ax + (ey * bl - dy * cl) * d
      y = ay + (dx * cl - ex * bl) * d
      [x, y]
    end

    def circumradius(ax, ay, bx, by, cx, cy)
      dx = bx - ax
      dy = by - ay
      ex = cx - ax
      ey = cy - ay

      bl = dx * dx + dy * dy
      cl = ex * ex + ey * ey
      d = 0.5 / (dx * ey - dy * ex).to_f

      x = (ey * bl - dy * cl) * d
      y = (dx * cl - ex * bl) * d

      r = x * x + y * y

      return 0 if [bl, cl, d, r].include? 0

      r
    end

    def in_circle(ax, ay, bx, by, cx, cy, px, py)
      dx = ax - px
      dy = ay - py
      ex = bx - px
      ey = by - py
      fx = cx - px
      fy = cy - py

      ap = dx * dx + dy * dy
      bp = ex * ex + ey * ey
      cp = fx * fx + fy * fy

      (
        dx * (ey * cp - bp * fy) -
        dy * (ex * cp - bp * fx) +
        ap * (ex * fy - ey * fx)
      ) < 0
    end

    def pseudo_angle(dx, dy)
      p = dx / (dx.abs + dy.abs).to_f
      (dy > 0 ? 3 - p : 1 + p) / 4.to_f
    end

    def add_triangle(i0, i1, i2, a, b, c)
      i = @triangles_len
      @_triangles[i] = i0
      @_triangles[i + 1] = i1
      @_triangles[i + 2] = i2
      link(i, a)
      link(i + 1, b)
      link(i + 2, c)
      @triangles_len += 3
      i
    end

    def hash_key(x, y)
      angle = (pseudo_angle(x - @cx, y - @cy) * @hash_size).floor()
      angle % @hash_size
    end

    def link(a, b)
      @_halfedges[a] = b
      @_halfedges[b] = a if b != -1
    end

    def legalize(a)
      # if the pair of triangles doesn't satisfy the Delaunay condition
      # (p1 is inside the circumcircle of [p0, pl, pr]), flip them,
      # then do the same check/flip recursively for the new pair of triangles
      #
      #           pl                    pl
      #          /||\                  /  \
      #       al/ || \bl            al/    \a
      #        /  ||  \              /      \
      #       /  a||b  \    flip    /___ar___\
      #     p0\   ||   /p1   =>   p0\---bl---/p1
      #        \  ||  /              \      /
      #       ar\ || /br             b\    /br
      #          \||/                  \  /
      #           pr                    pr
      i = 0
      ar = 0
      loop do
        b = @_halfedges[a]
        a0 = a - a % 3

        ar = a0 + (a + 2) % 3
        # convex hull edge
        if b == -1
          break if i.zero?
          i -= 1
          a = EDGE_STACK[i]
          next
        end

        b0 = b - b % 3
        al = a0 + (a + 1) % 3
        bl = b0 + (b + 2) % 3

        p0 = @_triangles[ar]
        pr = @_triangles[a]
        pl = @_triangles[al]
        p1 = @_triangles[bl]

        illegal = in_circle(@coords[2 * p0], @coords[2 * p0 + 1],
                            @coords[2 * pr], @coords[2 * pr + 1],
                            @coords[2 * pl], @coords[2 * pl + 1],
                            @coords[2 * p1], @coords[2 * p1 + 1])

        if illegal
          @_triangles[a] = p1
          @_triangles[b] = p0
          hbl = @_halfedges[bl]
          # edge swapped on the other side of the hull (rare)
          # fix the halfedge reference
          if hbl == -1
            e = @hull_start
            loop do
              if @hull_tri[e] == bl
                @hull_tri[e] = a
                break
              end
              e = @hull_prev[e]
              break if e != @hull_start
            end
          end
          link(a, hbl)
          link(b, @_halfedges[ar])
          link(ar, bl)

          br = b0 + (b + 1) % 3

          if i < EDGE_STACK.length
            EDGE_STACK[i] = br
            i += 1
          end
        else
          break if i.zero?

          i -= 1
          a = EDGE_STACK[i]
        end
      end
      ar
    end
  end
end

class Array
  def swap!(a, b)
    self[a], self[b] = self[b], self[a]
    self
  end
end
