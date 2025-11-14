class PickerCircle < Hokusai::Block
  template <<-EOF
  [template]
    virtual
  EOF

  computed! :x
  computed! :y
  computed! :color
  computed! :radius

  def on_mounted
    node.meta.set_prop(:z, 3);
    node.meta.set_prop(:ztarget, "root")
  end

  def render(canvas)
    draw do
      circle(x, y - radius, radius + 2.0) do |command|
        command.color = Hokusai::Color.new(255, 255, 255)
      end
      circle(x, y - radius, radius) do |command|
        command.color = color
      end

      text("rgb(#{color.r.round(0)},#{color.g.round(0)},#{color.b.round(0)})", x - 90.0, y + radius) do |command|
        command.size = 15
        command.color = Hokusai::Color.new(255, 255, 255)
      end
    end
  end
end

class Hokusai::Blocks::ColorPicker < Hokusai::Block
  template <<~EOF
  [template]
    hblock { }
      vblock { 
        @mousedown="start_selection"
        @mousemove="update_selection"
      }
        shader_begin {
          :fragment_shader="picker_shader"
          :uniforms="values"
        }
          texture { :value="texture" :flip="false" }
          shader_end { :height="0.0" :width="0.0" }
      vblock {
        width="32"
        cursor="crosshair"
      }
        shader_begin { 
          @mousedown="save_position"
          :fragment_shader="hue_shader"
          :uniforms="values"
        }
          texture { :value="texture" :flip="false" }
          shader_end { :height="0.0" :width="0.0"}
      vblock { :z="3" ztarget="root"}
        [if="picking"]
          pickercircle {
            :radius="10.0"
            :x="pickerx"
            :y="pickery"
            :color="color"
          }
  EOF

  uses(
    rect: Hokusai::Blocks::Rect,
    empty: Hokusai::Blocks::Empty,
    shader_begin: Hokusai::Blocks::ShaderBegin, 
    shader_end: Hokusai::Blocks::ShaderEnd, 
    texture: Hokusai::Blocks::Texture,
    hblock: Hokusai::Blocks::Hblock,
    vblock: Hokusai::Blocks::Vblock,
    pickercircle: PickerCircle
  )

  attr_accessor :position, :top, :left, :height, :width, :selecting, :selection,
                :brightness, :saturation, :pickerx, :pickery, :texture
  

  def start_selection(event)
    if event.left.down
      self.selecting = true
    end
  end

  def picking
    selecting && pickerx && pickery
  end

  K1 = 0.206;
  K2 = 0.03;
  K3 = (1.0 + K1) / (1.0 + K2);

  def toe_inv(x)
    (x * x + K1 * x) / (K3 * (x + K2))
  end

  def compute_max_saturation(a, b)
    if -1.88170328 * a - 0.80936493 * b > 1.0
      k0 = +1.19086277
      k1 = +1.76576728
      k2 = +0.59662641
      k3 = +0.75515197
      k4 = +0.56771245
      wl = +4.0767416621
      wm = -3.3077115913
      ws = +0.2309699292
    elsif 1.81444104 * a - 1.19445276 * b > 1.0
      k0 = +0.73956515
      k1 = -0.45954404
      k2 = +0.08285427
      k3 = +0.12541070
      k4 = +0.14503204
      wl = -1.2684380046
      wm = +2.6097574011
      ws = -0.3413193965
    else
      k0 = +1.35733652
      k1 = -0.00915799
      k2 = -1.15130210
      k3 = -0.50559606
      k4 = +0.00692167
      wl = -0.0041960863
      wm = -0.7034186147
      ws = +1.7076147010
    end

    sat = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

    kl = +0.3963377774 * a + 0.2158037573 * b
    km = -0.1055613458 * a - 0.0638541728 * b
    ks = -0.0894841775 * a - 1.2914855480 * b

    l_ = 1.0 + sat * kl
    m_ = 1.0 + sat * km
    s_ = 1.0 + sat * ks

    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3

    lds = 3.0 * kl * l_ * l_
    mds = 3.0 * km * m_ * m_
    sds = 3.0 * ks * s_ * s_

    lds2 = 6.0 * kl ** 2 * l_
    mds2 = 6.0 * km ** 2 * m_
    sds2 = 6.0 * ks ** 2 * s_


    f = wl * l + wm * m + ws * s
    f1 = wl * lds + wm * mds + ws * sds
    f2 = wl * lds2 + wm * mds2 + ws * sds2

    sat = sat - (f * f1) / (f1 ** 2 - 0.5 * f * f2)

    sat
  end

  def find_cusp(a, b)
    s_cusp = compute_max_saturation(a, b)

    rgb = oklab_to_linear_srgb(1.0, s_cusp * a, s_cusp * b)
    l_cusp = cbrt(1.0 / rgb.max)
    c_cusp = l_cusp * s_cusp

    [l_cusp, c_cusp]
  end

  def to_st(cusp)
    l, c = cusp
    [c / l, c / (1.0 - l)]
  end
  
  def oklab_to_linear_srgb(*lab)
    r, g, b = lab
    
    l_ = r + 0.3963377774 * g + 0.2158037573 * b
    m_ = r - 0.1055613458 * g - 0.0638541728 * b
    s_ = r - 0.0894841775 * g - 1.2914855480 * b

    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_

    [
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    ]
  end

  def cbrt(x)
    (x <=> 0) * (x.abs ** (1.0 / 3.0))
  end

  def oklab
    h = hue
    s = saturation
    v = brightness

    tau = Math::PI * 2.0

      _a = Math.cos(tau * h)
      _b = Math.sin(tau * h)

      s_max, t_max = to_st(find_cusp(_a, _b))

      so = 0.5
      k = 1.0 - so / s_max

      lv = 1.0 - (s * so) / (so + t_max - t_max * k * s)
      cv = (s * t_max * so) / (so + t_max - t_max * k * s)

      l = v * lv
      c = v * cv

      lvt = toe_inv(lv)
      cvt = (cv * lvt) / lv

      l_new = toe_inv(l)
      c = (c * l_new) / l
      l = l_new

      rs, gs, bs = oklab_to_linear_srgb(lvt, _a * cvt, _b * cvt)
      scale_l = cbrt(1.0 / [rs, gs, bs, 0.0].max)

      l = l * scale_l
      c = c * scale_l

      a = c * _a
      b = c * _b


      l, a, b = oklab_to_linear_srgb(l, a, b)
    # end
    [srgb_transfer_function(l), srgb_transfer_function(a), srgb_transfer_function(b)]
  end

  def srgb_transfer_function(a)
    0.0031308 >= a ? 12.92 * a : 1.055 * (a ** 0.4166666666666667) - 0.055;
  end

  def color(alpha = 255)
    return if brightness.nil? || saturation.nil?
    r, g, b = oklab

    return Hokusai::Color.new(0, 0, 0, 0) if r.nan? || g.nan? || b.nan?

    return Hokusai::Color.new(r * 255, g * 255, b * 255)
  end

  def update_selection(event)
    if event.left.down && selecting
      # Hokusai.set_mouse_cursor(:none)
      w = width - 32.0
      posx = event.pos.x

      b = ((posx - left) / w)
      self.pickerx = posx
      unless b > 1.0 || b < 0.0
        self.saturation = b
      end

      posy = event.pos.y
      t = ((posy - top) / height)
      self.pickery = posy
      unless t > 1.0 || t < 0.0
        self.brightness = 1 - t 
      end

      emit("change", color)
    else
      # Hokusai.set_mouse_cursor(:pointer)

      self.selecting = false
    end
  end

  def save_position(event)
    self.position = [event.pos.x, event.pos.y]
  end

  def hue
    return 0.0 if position.nil?

    pos = (position[1] - (top || 0)) 
    y = (pos / height)
  end

  def values
   return {} unless position

   return {} if hue > 1 || hue < 0
  
   {
    "uHue" => [hue, HP_SHADER_UNIFORM_FLOAT]
   }
  end

  HUE_SHADER = <<~EOF
  #version 330

  in vec2 fragTexCoord;
  in vec4 fragColor;

  out vec4 finalColor;

  #define PI 3.1415926535897932384626433832795
  #define PICKER_SIZE_INV (1.0 / 255.0)

  float hsluv_fromLinear(float c) {
      return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
  }
  vec3 hsluv_fromLinear(vec3 c) {
      return vec3( hsluv_fromLinear(c.r), hsluv_fromLinear(c.g), hsluv_fromLinear(c.b) );
  }

  vec3 xyzToRgb(vec3 tuple) {
      const mat3 m = mat3( 
          3.2409699419045214  ,-1.5373831775700935 ,-0.49861076029300328 ,
        -0.96924363628087983 , 1.8759675015077207 , 0.041555057407175613,
          0.055630079696993609,-0.20397695888897657, 1.0569715142428786  );
      
      return hsluv_fromLinear(tuple*m);
  }

  float hsluv_lToY(float L) {
      return L <= 8.0 ? L / 903.2962962962963 : pow((L + 16.0) / 116.0, 3.0);
  }

  vec3 luvToXyz(vec3 tuple) {
      float L = tuple.x;

      float U = tuple.y / (13.0 * L) + 0.19783000664283681;
      float V = tuple.z / (13.0 * L) + 0.468319994938791;

      float Y = hsluv_lToY(L);
      float X = 2.25 * U * Y / V;
      float Z = (3./V - 5.)*Y - (X/3.);

      return vec3(X, Y, Z);
  }

  vec3 lchToLuv(vec3 tuple) {
      float hrad = radians(tuple.b);
      return vec3(
          tuple.r,
          cos(hrad) * tuple.g,
          sin(hrad) * tuple.g
      );
  }

  vec3 lchToRgb(vec3 tuple) {
      return xyzToRgb(luvToXyz(lchToLuv(tuple)));
  }

  vec3 hsluv_lengthOfRayUntilIntersect(float theta, vec3 x, vec3 y) {
      vec3 len = y / (sin(theta) - x * cos(theta));
      if (len.r < 0.0) {len.r=1000.0;}
      if (len.g < 0.0) {len.g=1000.0;}
      if (len.b < 0.0) {len.b=1000.0;}
      return len;
  }

  float hsluv_maxChromaForLH(float L, float H) {
      float hrad = radians(H);

      mat3 m2 = mat3(
          3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609,
          -1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ,
          -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  
      );
      float sub1 = pow(L + 16.0, 3.0) / 1560896.0;
      float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

      vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
      vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
      vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

      vec3 bound0x = top1 / bottom;
      vec3 bound0y = top2 / bottom;

      vec3 bound1x =              top1 / (bottom+126452.0);
      vec3 bound1y = (top2-769860.0*L) / (bottom+126452.0);

      vec3 lengths0 = hsluv_lengthOfRayUntilIntersect(hrad, bound0x, bound0y );
      vec3 lengths1 = hsluv_lengthOfRayUntilIntersect(hrad, bound1x, bound1y );

      return  min(lengths0.r,
              min(lengths1.r,
              min(lengths0.g,
              min(lengths1.g,
              min(lengths0.b,
                  lengths1.b)))));
  }

  vec3 hsluvToLch(vec3 tuple) {
      tuple.g *= hsluv_maxChromaForLH(tuple.b, tuple.r) * .01;
      return tuple.bgr;
  }

  vec3 hsluvToRgb(vec3 tuple) {
      return lchToRgb(hsluvToLch(tuple));
  }
  vec3 hsluvToRgb(float x, float y, float z) {return hsluvToRgb( vec3(x,y,z) );}

  void main() {
    float a_ = cos(2 * PI * fragTexCoord.y);
    float b_ = sin(2 * PI * fragTexCoord.y);

    float h = fragTexCoord.y;
    float s = 0.9;
    float l = 0.65 + 0.20 * b_ - 0.09 * a_;

    vec3 col = hsluvToRgb(h * 360, s * 100, l * 100);
    finalColor = vec4(col, 1.0);
  }
  EOF

  PICKER_SHADER = <<~EOF
  #version 330

  in vec2 fragTexCoord;
  in vec4 fragColor;

  uniform float uHue;

  out vec4 finalColor;

  #define M_PI 3.1415926535897932384626433832795

  float cbrt( float x ) {
      return sign(x)*pow(abs(x),1.0f/3.0f);
  }

  float srgb_transfer_function(float a) {
    return .0031308f >= a ? 12.92f * a : 1.055f * pow(a, .4166666666666667f) - .055f;
  }

  float srgb_transfer_function_inv(float a) {
    return .04045f < a ? pow((a + .055f) / 1.055f, 2.4f) : a / 12.92f;
  }

  vec3 linear_srgb_to_oklab(vec3 c) {
    float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
    float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
    float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

    float l_ = cbrt(l);
    float m_ = cbrt(m);
    float s_ = cbrt(s);

    return vec3(
      0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_,
      1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_,
      0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_
    );
  }

  vec3 oklab_to_linear_srgb(vec3 c) {
    float l_ = c.x + 0.3963377774f * c.y + 0.2158037573f * c.z;
    float m_ = c.x - 0.1055613458f * c.y - 0.0638541728f * c.z;
    float s_ = c.x - 0.0894841775f * c.y - 1.2914855480f * c.z;

    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;

    return vec3(
      +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s,
      -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s,
      -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s
    );
  }

  // Finds the maximum saturation possible for a given hue that fits in sRGB
  // Saturation here is defined as S = C/L
  // a and b must be normalized so a^2 + b^2 == 1
  float compute_max_saturation(float a, float b) {
    // Max saturation will be when one of r, g or b goes below zero.

    // Select different coefficients depending on which component goes below zero first
    float k0, k1, k2, k3, k4, wl, wm, ws;

    if (-1.88170328f * a - 0.80936493f * b > 1.f)
    {
      // Red component
      k0 = +1.19086277f; k1 = +1.76576728f; k2 = +0.59662641f; k3 = +0.75515197f; k4 = +0.56771245f;
      wl = +4.0767416621f; wm = -3.3077115913f; ws = +0.2309699292f;
    }
    else if (1.81444104f * a - 1.19445276f * b > 1.f)
    {
      // Green component
      k0 = +0.73956515f; k1 = -0.45954404f; k2 = +0.08285427f; k3 = +0.12541070f; k4 = +0.14503204f;
      wl = -1.2684380046f; wm = +2.6097574011f; ws = -0.3413193965f;
    }
    else
    {
      // Blue component
      k0 = +1.35733652f; k1 = -0.00915799f; k2 = -1.15130210f; k3 = -0.50559606f; k4 = +0.00692167f;
      wl = -0.0041960863f; wm = -0.7034186147f; ws = +1.7076147010f;
    }

    // Approximate max saturation using a polynomial:
    float S = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b;

    // Do one step Halley's method to get closer
    // this gives an error less than 10e6, except for some blue hues where the dS/dh is close to infinite
    // this should be sufficient for most applications, otherwise do two/three steps 

    float k_l = +0.3963377774f * a + 0.2158037573f * b;
    float k_m = -0.1055613458f * a - 0.0638541728f * b;
    float k_s = -0.0894841775f * a - 1.2914855480f * b;

    {
      float l_ = 1.f + S * k_l;
      float m_ = 1.f + S * k_m;
      float s_ = 1.f + S * k_s;

      float l = l_ * l_ * l_;
      float m = m_ * m_ * m_;
      float s = s_ * s_ * s_;

      float l_dS = 3.f * k_l * l_ * l_;
      float m_dS = 3.f * k_m * m_ * m_;
      float s_dS = 3.f * k_s * s_ * s_;

      float l_dS2 = 6.f * k_l * k_l * l_;
      float m_dS2 = 6.f * k_m * k_m * m_;
      float s_dS2 = 6.f * k_s * k_s * s_;

      float f = wl * l + wm * m + ws * s;
      float f1 = wl * l_dS + wm * m_dS + ws * s_dS;
      float f2 = wl * l_dS2 + wm * m_dS2 + ws * s_dS2;

      S = S - f * f1 / (f1 * f1 - 0.5f * f * f2);
    }

    return S;
  }

  // finds L_cusp and C_cusp for a given hue
  // a and b must be normalized so a^2 + b^2 == 1
  vec2 find_cusp(float a, float b) {
    // First, find the maximum saturation (saturation S = C/L)
    float S_cusp = compute_max_saturation(a, b);

    // Convert to linear sRGB to find the first point where at least one of r,g or b >= 1:
    vec3 rgb_at_max = oklab_to_linear_srgb(vec3( 1, S_cusp * a, S_cusp * b ));
    float L_cusp = cbrt(1.f / max(max(rgb_at_max.r, rgb_at_max.g), rgb_at_max.b));
    float C_cusp = L_cusp * S_cusp;

    return vec2( L_cusp , C_cusp );
  }

  // Finds intersection of the line defined by 
  // L = L0 * (1 - t) + t * L1;
  // C = t * C1;
  // a and b must be normalized so a^2 + b^2 == 1
  float find_gamut_intersection(float a, float b, float L1, float C1, float L0, vec2 cusp) {
    // Find the intersection for upper and lower half seprately
    float t;
    if (((L1 - L0) * cusp.y - (cusp.x - L0) * C1) <= 0.f)
    {
      // Lower half

      t = cusp.y * L0 / (C1 * cusp.x + cusp.y * (L0 - L1));
    }
    else
    {
      // Upper half

      // First intersect with triangle
      t = cusp.y * (L0 - 1.f) / (C1 * (cusp.x - 1.f) + cusp.y * (L0 - L1));

      // Then one step Halley's method
      {
        float dL = L1 - L0;
        float dC = C1;

        float k_l = +0.3963377774f * a + 0.2158037573f * b;
        float k_m = -0.1055613458f * a - 0.0638541728f * b;
        float k_s = -0.0894841775f * a - 1.2914855480f * b;

        float l_dt = dL + dC * k_l;
        float m_dt = dL + dC * k_m;
        float s_dt = dL + dC * k_s;


        // If higher accuracy is required, 2 or 3 iterations of the following block can be used:
        {
          float L = L0 * (1.f - t) + t * L1;
          float C = t * C1;

          float l_ = L + C * k_l;
          float m_ = L + C * k_m;
          float s_ = L + C * k_s;

          float l = l_ * l_ * l_;
          float m = m_ * m_ * m_;
          float s = s_ * s_ * s_;

          float ldt = 3.f * l_dt * l_ * l_;
          float mdt = 3.f * m_dt * m_ * m_;
          float sdt = 3.f * s_dt * s_ * s_;

          float ldt2 = 6.f * l_dt * l_dt * l_;
          float mdt2 = 6.f * m_dt * m_dt * m_;
          float sdt2 = 6.f * s_dt * s_dt * s_;

          float r = 4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s - 1.f;
          float r1 = 4.0767416621f * ldt - 3.3077115913f * mdt + 0.2309699292f * sdt;
          float r2 = 4.0767416621f * ldt2 - 3.3077115913f * mdt2 + 0.2309699292f * sdt2;

          float u_r = r1 / (r1 * r1 - 0.5f * r * r2);
          float t_r = -r * u_r;

          float g = -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s - 1.f;
          float g1 = -1.2684380046f * ldt + 2.6097574011f * mdt - 0.3413193965f * sdt;
          float g2 = -1.2684380046f * ldt2 + 2.6097574011f * mdt2 - 0.3413193965f * sdt2;

          float u_g = g1 / (g1 * g1 - 0.5f * g * g2);
          float t_g = -g * u_g;

          float b = -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s - 1.f;
          float b1 = -0.0041960863f * ldt - 0.7034186147f * mdt + 1.7076147010f * sdt;
          float b2 = -0.0041960863f * ldt2 - 0.7034186147f * mdt2 + 1.7076147010f * sdt2;

          float u_b = b1 / (b1 * b1 - 0.5f * b * b2);
          float t_b = -b * u_b;

          t_r = u_r >= 0.f ? t_r : 10000.f;
          t_g = u_g >= 0.f ? t_g : 10000.f;
          t_b = u_b >= 0.f ? t_b : 10000.f;

          t += min(t_r, min(t_g, t_b));
        }
      }
    }

    return t;
  }

  float find_gamut_intersection(float a, float b, float L1, float C1, float L0) {
    // Find the cusp of the gamut triangle
    vec2 cusp = find_cusp(a, b);

    return find_gamut_intersection(a, b, L1, C1, L0, cusp);
  }

  vec3 gamut_clip_preserve_chroma(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L0 = clamp(L, 0.f, 1.f);

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_project_to_0_5(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L0 = 0.5;

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_project_to_L_cusp(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    // The cusp is computed here and in find_gamut_intersection, an optimized solution would only compute it once.
    vec2 cusp = find_cusp(a_, b_);

    float L0 = cusp.x;

    float t = find_gamut_intersection(a_, b_, L, C, L0);

    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_adaptive_L0_0_5(vec3 rgb, float alpha) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float Ld = L - 0.5f;
    float e1 = 0.5f + abs(Ld) + alpha * C;
    float L0 = 0.5f * (1.f + sign(Ld) * (e1 - sqrt(e1 * e1 - 2.f * abs(Ld))));

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_adaptive_L0_L_cusp(vec3 rgb, float alpha) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    // The cusp is computed here and in find_gamut_intersection, an optimized solution would only compute it once.
    vec2 cusp = find_cusp(a_, b_);

    float Ld = L - cusp.x;
    float k = 2.f * (Ld > 0.f ? 1.f - cusp.x : cusp.x);

    float e1 = 0.5f * k + abs(Ld) + alpha * C / k;
    float L0 = cusp.x + 0.5f * (sign(Ld) * (e1 - sqrt(e1 * e1 - 2.f * k * abs(Ld))));

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  float toe(float x) {
    float k_1 = 0.206f;
    float k_2 = 0.03f;
    float k_3 = (1.f + k_1) / (1.f + k_2);
    return 0.5f * (k_3 * x - k_1 + sqrt((k_3 * x - k_1) * (k_3 * x - k_1) + 4.f * k_2 * k_3 * x));
  }

  float toe_inv(float x) {
    float k_1 = 0.206f;
    float k_2 = 0.03f;
    float k_3 = (1.f + k_1) / (1.f + k_2);
    return (x * x + k_1 * x) / (k_3 * (x + k_2));
  }

  vec2 to_ST(vec2 cusp) {
    float L = cusp.x;
    float C = cusp.y;
    return vec2( C / L, C / (1.f - L) );
  }

  // Returns a smooth approximation of the location of the cusp
  // This polynomial was created by an optimization process
  // It has been designed so that S_mid < S_max and T_mid < T_max
  vec2 get_ST_mid(float a_, float b_) {
    float S = 0.11516993f + 1.f / (
      +7.44778970f + 4.15901240f * b_
      + a_ * (-2.19557347f + 1.75198401f * b_
        + a_ * (-2.13704948f - 10.02301043f * b_
          + a_ * (-4.24894561f + 5.38770819f * b_ + 4.69891013f * a_
            )))
      );

    float T = 0.11239642f + 1.f / (
      +1.61320320f - 0.68124379f * b_
      + a_ * (+0.40370612f + 0.90148123f * b_
        + a_ * (-0.27087943f + 0.61223990f * b_
          + a_ * (+0.00299215f - 0.45399568f * b_ - 0.14661872f * a_
            )))
      );

    return vec2( S, T );
  }

  vec3 get_Cs(float L, float a_, float b_) {
    vec2 cusp = find_cusp(a_, b_);

    float C_max = find_gamut_intersection(a_, b_, L, 1.f, L, cusp);
    vec2 ST_max = to_ST(cusp);
    
    // Scale factor to compensate for the curved part of gamut shape:
    float k = C_max / min((L * ST_max.x), (1.f - L) * ST_max.y);

    float C_mid;
    {
      vec2 ST_mid = get_ST_mid(a_, b_);

      // Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
      float C_a = L * ST_mid.x;
      float C_b = (1.f - L) * ST_mid.y;
      C_mid = 0.9f * k * sqrt(sqrt(1.f / (1.f / (C_a * C_a * C_a * C_a) + 1.f / (C_b * C_b * C_b * C_b))));
    }

    float C_0;
    {
      // for C_0, the shape is independent of hue, so vec2 are constant. Values picked to roughly be the average values of vec2.
      float C_a = L * 0.4f;
      float C_b = (1.f - L) * 0.8f;

      // Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
      C_0 = sqrt(1.f / (1.f / (C_a * C_a) + 1.f / (C_b * C_b)));
    }

    return vec3( C_0, C_mid, C_max );
  }

  vec3 okhsl_to_srgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (l == 1.0f)
    {
      return vec3( 1.f, 1.f, 1.f );
    }

    else if (l == 0.f)
    {
      return vec3( 0.f, 0.f, 0.f );
    }

    float a_ = cos(2.f * M_PI * h);
    float b_ = sin(2.f * M_PI * h);
    float L = toe_inv(l);

    vec3 cs = get_Cs(L, a_, b_);
    float C_0 = cs.x;
    float C_mid = cs.y;
    float C_max = cs.z;

    float mid = 0.8f;
    float mid_inv = 1.25f;

    float C, t, k_0, k_1, k_2;

    if (s < mid)
    {
      t = mid_inv * s;

      k_1 = mid * C_0;
      k_2 = (1.f - k_1 / C_mid);

      C = t * k_1 / (1.f - k_2 * t);
    }
    else
    {
      t = (s - mid)/ (1.f - mid);

      k_0 = C_mid;
      k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
      k_2 = (1.f - (k_1) / (C_max - C_mid));

      C = k_0 + t * k_1 / (1.f - k_2 * t);
    }

    vec3 rgb = oklab_to_linear_srgb(vec3( L, C * a_, C * b_ ));
    return vec3(
      srgb_transfer_function(rgb.r),
      srgb_transfer_function(rgb.g),
      srgb_transfer_function(rgb.b)
    );
  }

  vec3 srgb_to_okhsl(vec3 rgb) {
    vec3 lab = linear_srgb_to_oklab(vec3(
      srgb_transfer_function_inv(rgb.r),
      srgb_transfer_function_inv(rgb.g),
      srgb_transfer_function_inv(rgb.b)
      ));

    float C = sqrt(lab.y * lab.y + lab.z * lab.z);
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L = lab.x;
    float h = 0.5f + 0.5f * atan(-lab.z, -lab.y) / M_PI;

    vec3 cs = get_Cs(L, a_, b_);
    float C_0 = cs.x;
    float C_mid = cs.y;
    float C_max = cs.z;

    // Inverse of the interpolation in okhsl_to_srgb:

    float mid = 0.8f;
    float mid_inv = 1.25f;

    float s;
    if (C < C_mid)
    {
      float k_1 = mid * C_0;
      float k_2 = (1.f - k_1 / C_mid);

      float t = C / (k_1 + k_2 * C);
      s = t * mid;
    }
    else
    {
      float k_0 = C_mid;
      float k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
      float k_2 = (1.f - (k_1) / (C_max - C_mid));

      float t = (C - k_0) / (k_1 + k_2 * (C - k_0));
      s = mid + (1.f - mid) * t;
    }

    float l = toe(L);
    return vec3( h, s, l );
  }


  vec3 okhsv_to_srgb(vec3 hsv) {
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;

    float a_ = cos(2.f * M_PI * h);
    float b_ = sin(2.f * M_PI * h);
    
    vec2 cusp = find_cusp(a_, b_);
    vec2 ST_max = to_ST(cusp);
    float S_max = ST_max.x;
    float T_max = ST_max.y;
    float S_0 = 0.5f;
    float k = 1.f- S_0 / S_max;

    // first we compute L and V as if the gamut is a perfect triangle:

    // L, C when v==1:
    float L_v = 1.f   - s * S_0 / (S_0 + T_max - T_max * k * s);
    float C_v = s * T_max * S_0 / (S_0 + T_max - T_max * k * s);

    float L = v * L_v;
    float C = v * C_v;

    // then we compensate for both toe and the curved top part of the triangle:
    float L_vt = toe_inv(L_v);
    float C_vt = C_v * L_vt / L_v;

    float L_new = toe_inv(L);
    C = C * L_new / L;
    L = L_new;

    vec3 rgb_scale = oklab_to_linear_srgb(vec3( L_vt, a_ * C_vt, b_ * C_vt ));
    float scale_L = cbrt(1.f / max(max(rgb_scale.r, rgb_scale.g), max(rgb_scale.b, 0.f)));

    L = L * scale_L;
    C = C * scale_L;

    vec3 rgb = oklab_to_linear_srgb(vec3( L, C * a_, C * b_ ));
    return vec3(
      srgb_transfer_function(rgb.r),
      srgb_transfer_function(rgb.g),
      srgb_transfer_function(rgb.b)
    );
  }

  vec3 srgb_to_okhsv(vec3 rgb) {
    vec3 lab = linear_srgb_to_oklab(vec3(
      srgb_transfer_function_inv(rgb.r),
      srgb_transfer_function_inv(rgb.g),
      srgb_transfer_function_inv(rgb.b)
      ));

    float C = sqrt(lab.y * lab.y + lab.z * lab.z);
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L = lab.x;
    float h = 0.5f + 0.5f * atan(-lab.z, -lab.y) / M_PI;

    vec2 cusp = find_cusp(a_, b_);
    vec2 ST_max = to_ST(cusp);
    float S_max = ST_max.x;
    float T_max = ST_max.y;
    float S_0 = 0.5f;
    float k = 1.f - S_0 / S_max;

    // first we find L_v, C_v, L_vt and C_vt

    float t = T_max / (C + L * T_max);
    float L_v = t * L;
    float C_v = t * C;

    float L_vt = toe_inv(L_v);
    float C_vt = C_v * L_vt / L_v;

    // we can then use these to invert the step that compensates for the toe and the curved top part of the triangle:
    vec3 rgb_scale = oklab_to_linear_srgb(vec3( L_vt, a_ * C_vt, b_ * C_vt ));
    float scale_L = cbrt(1.f / max(max(rgb_scale.r, rgb_scale.g), max(rgb_scale.b, 0.f)));

    L = L / scale_L;
    C = C / scale_L;

    C = C * toe(L) / L;
    L = toe(L);

    // we can now compute v and s:

    float v = L / L_v;
    float s = (S_0 + T_max) * C_v / ((T_max * S_0) + T_max * k * C_v);

    return vec3 (h, s, v );
  }

  void main() {
    vec3 col = okhsv_to_srgb(vec3(uHue, fragTexCoord.x, 1 - fragTexCoord.y));
    finalColor = vec4(col, 1.0);
  }
  EOF

  def hue_shader
    HUE_SHADER
  end

  def picker_shader
    PICKER_SHADER
  end

  def render(canvas)
    self.top = canvas.y
    self.left = canvas.x
    self.height = canvas.height
    self.width = canvas.width

    @texture ||= Hokusai::Texture.init(1, 1)

    yield canvas
  end
end