//! WGS84 ↔ GCJ-02 conversion.
//!
//! GCJ-02 is the encrypted offset coordinate system used by mainland-China
//! map providers (AMap, Baidu's pre-bd09 form, etc). Coordinates outside the
//! mainland bounding box are returned unchanged — the algorithm is a no-op.
//!
//! Reference: the public algorithm published widely (e.g. in the
//! `coordtransform` family of libs). Accuracy is typically <1 meter.
#![allow(clippy::excessive_precision)]

const PI: f64 = std::f64::consts::PI;
const A: f64 = 6378245.0; // semi-major axis
const EE: f64 = 0.00669342162296594323; // eccentricity squared

/// True when a point lies outside mainland China's bounding box — in which
/// case GCJ-02 is identical to WGS84 and we skip the offset.
fn outside_china(lng: f64, lat: f64) -> bool {
    !(73.66..=135.05).contains(&lng) || !(3.86..=53.55).contains(&lat)
}

fn transform_lat(x: f64, y: f64) -> f64 {
    let mut ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * x.abs().sqrt();
    ret += (20.0 * (6.0 * x * PI).sin() + 20.0 * (2.0 * x * PI).sin()) * 2.0 / 3.0;
    ret += (20.0 * (y * PI).sin() + 40.0 * (y / 3.0 * PI).sin()) * 2.0 / 3.0;
    ret += (160.0 * (y / 12.0 * PI).sin() + 320.0 * (y * PI / 30.0).sin()) * 2.0 / 3.0;
    ret
}

fn transform_lng(x: f64, y: f64) -> f64 {
    let mut ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * x.abs().sqrt();
    ret += (20.0 * (6.0 * x * PI).sin() + 20.0 * (2.0 * x * PI).sin()) * 2.0 / 3.0;
    ret += (20.0 * (x * PI).sin() + 40.0 * (x / 3.0 * PI).sin()) * 2.0 / 3.0;
    ret += (150.0 * (x / 12.0 * PI).sin() + 300.0 * (x / 30.0 * PI).sin()) * 2.0 / 3.0;
    ret
}

fn delta(lng: f64, lat: f64) -> (f64, f64) {
    let dlat = transform_lat(lng - 105.0, lat - 35.0);
    let dlng = transform_lng(lng - 105.0, lat - 35.0);
    let radlat = lat / 180.0 * PI;
    let mut magic = radlat.sin();
    magic = 1.0 - EE * magic * magic;
    let sqrtmagic = magic.sqrt();
    let dlat = (dlat * 180.0) / ((A * (1.0 - EE)) / (magic * sqrtmagic) * PI);
    let dlng = (dlng * 180.0) / (A / sqrtmagic * radlat.cos() * PI);
    (dlng, dlat)
}

/// Encode a WGS84 (lng, lat) into GCJ-02. No-op outside mainland China.
pub fn wgs84_to_gcj02(lng: f64, lat: f64) -> (f64, f64) {
    if outside_china(lng, lat) {
        return (lng, lat);
    }
    let (dlng, dlat) = delta(lng, lat);
    (lng + dlng, lat + dlat)
}

/// Decode a GCJ-02 (lng, lat) back to WGS84. Uses one-step iterative inverse;
/// accuracy is typically sub-meter.
pub fn gcj02_to_wgs84(lng: f64, lat: f64) -> (f64, f64) {
    if outside_china(lng, lat) {
        return (lng, lat);
    }
    let (dlng, dlat) = delta(lng, lat);
    (lng - dlng, lat - dlat)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn approx(a: f64, b: f64, eps: f64) -> bool {
        (a - b).abs() < eps
    }

    #[test]
    fn wgs_to_gcj_then_back_roundtrips_within_2m() {
        // Tiananmen Square in WGS84 (approx).
        let (lng, lat) = (116.391, 39.907);
        let (g_lng, g_lat) = wgs84_to_gcj02(lng, lat);
        let (back_lng, back_lat) = gcj02_to_wgs84(g_lng, g_lat);
        // 1° lat ≈ 111 km → 0.00002° ≈ 2.2 m.
        assert!(
            approx(back_lng, lng, 0.00002),
            "lng drift {} vs {}",
            back_lng,
            lng
        );
        assert!(
            approx(back_lat, lat, 0.00002),
            "lat drift {} vs {}",
            back_lat,
            lat
        );
    }

    #[test]
    fn outside_china_is_identity() {
        let (lng, lat) = (-122.4194, 37.7749); // San Francisco
        assert_eq!(wgs84_to_gcj02(lng, lat), (lng, lat));
        assert_eq!(gcj02_to_wgs84(lng, lat), (lng, lat));
    }

    #[test]
    fn shanghai_offset_is_observable() {
        // Bund, Shanghai WGS84 (well-known reference point).
        let (lng, lat) = (121.4737, 31.2304);
        let (g_lng, g_lat) = wgs84_to_gcj02(lng, lat);
        // Real-world offset is roughly 0.005° lng, 0.001° lat.
        assert!((g_lng - lng).abs() > 0.001);
        assert!((g_lat - lat).abs() > 0.0005);
    }
}
